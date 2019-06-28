######            This Terraform Template Builds a
###       Load Balancer Sandwich with a Managed Instance Group for
######             VM-Series Autoscaling in GCP
###          As of March 2019 this only works with PAYGO Images &
######             HealthCheck Predefined NAT Rules

###########################################
################### Terraform Provider and SSH Key Information      #############
######################################
provider "google" {
  region      = "${var.region}"
  project     = "${var.project_name}"
  credentials = "${file("${var.credentials_file_path}")}"
  zone        = "${var.region_zone}"
}

// Adding SSH Public Key Project Wide
resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "${var.public_key}"
}

###########################################
##############         AutoScale Settings      #############
######################################

resource "google_compute_autoscaler" "fw-autoscale" {
  provider = "google-beta"
  project  = "djs-gcp-2018"
  name     = "fw-autoscale"
  zone     = "us-central1-a"
  target   = "${google_compute_instance_group_manager.fw-autoscale-igm.self_link}"

  autoscaling_policy {
    max_replicas    = 3
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.55
    }
  }
}

###########################################
###########                Networking Information      #############
######################################

// Adding VPC Networks to Project  MANAGEMENT
resource "google_compute_subnetwork" "management-sub" {
  name          = "management-suba"
  ip_cidr_range = "10.0.0.0/24"
  network       = "${google_compute_network.management.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "management" {
  name                    = "${var.interface_0_name}"
  auto_create_subnetworks = "false"
}

// Adding VPC Networks to Project  UNTRUST
resource "google_compute_subnetwork" "untrust-sub" {
  name          = "untrust-suba"
  ip_cidr_range = "10.0.1.0/29"
  network       = "${google_compute_network.untrust.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "untrust" {
  name                    = "${var.interface_1_name}"
  auto_create_subnetworks = "false"
}

// Adding VPC Networks to Project  TRUST
resource "google_compute_subnetwork" "trust-sub" {
  name          = "trust-suba"
  ip_cidr_range = "10.0.2.0/24"
  network       = "${google_compute_network.trust.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "trust" {
  name                    = "${var.interface_2_name}"
  auto_create_subnetworks = "false"
}

// Adding GCP Firewall Rules for MANGEMENT
resource "google_compute_firewall" "allow-mgmt" {
  name    = "allow-mgmta"
  network = "${google_compute_network.management.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["443", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Adding GCP Firewall Rules for INBOUND
resource "google_compute_firewall" "allow-inbound" {
  name    = "allow-inbounda"
  network = "${google_compute_network.untrust.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Adding GCP Firewall Rules for OUTBOUND
resource "google_compute_firewall" "allow-outbound" {
  name    = "allow-outbounda"
  network = "${google_compute_network.trust.self_link}"

  allow {
    protocol = "all"

    # ports    = ["all"]
  }

  source_ranges = ["0.0.0.0/0"]
}

###########################################
###########           No Route Set for Outbound Internet Gateway By Default     #############
######################################
/*
// Adding GCP ROUTE to TRUST Interface
resource "google_compute_route" "trust" {
  name                   = "trust-route"
  dest_range             = "0.0.0.0/0"
  network                = "${google_compute_network.trust.self_link}"
  next_hop_instance      = "${element(google_compute_instance_group_manager.fw-autoscale-igm.*.base_instance_name,count.index)}"
  next_hop_instance_zone = "${var.zone}"
  priority               = 100


  depends_on = ["google_compute_network.trust",
    "google_compute_network.untrust",
    "google_compute_network.management",
  ]
}
*/
###########################################
###################  Instance Group Template Requires For MIG    #############
######################################

resource "google_compute_instance_template" "fw-autoscale-it" {
  provider     = "google-beta"
  project      = "djs-gcp-2018"
  name         = "${var.fw_instance_group_template_name}"
  machine_type = "${var.machine_type_fw}"

  # min_cpu_platform          = "${var.machine_cpu_fw}"
  can_ip_forward = true
  count          = 1

  disk {
    source_image = "${var.image_fw}"
  }

  // Swapped Network Order on Interface for Load Balancer
  network_interface {
    subnetwork    = "${google_compute_subnetwork.untrust-sub.self_link}"
    access_config = {}
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.management-sub.self_link}"
    access_config = {}
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.trust-sub.self_link}"
  }

  // Adding METADATA Key Value pairs to GCE VM
  // init-cfg.txt will perform interface swap of VM-Series on bootstrap for ELB
  metadata {
    vmseries-bootstrap-gce-storagebucket = "${var.bootstrap_bucket_fw}"
    serial-port-enable                   = true

    # sshKeys                              = "${var.public_key}"
  }

  service_account {
    scopes = "${var.scopes_fw}"
  }

  depends_on = ["google_compute_network.trust",
    "google_compute_network.untrust",
    "google_compute_network.management",
  ]
}

resource "google_compute_instance_group_manager" "fw-autoscale-igm" {
  provider = "google-beta"
  project  = "djs-gcp-2018"
  name     = "fw-autoscale-mig"
  zone     = "us-central1-a"

  version {
    instance_template = "${google_compute_instance_template.fw-autoscale-it.self_link}"
    name              = "primary"
  }

  # base_instance_name = "vm-series-fw"
  base_instance_name = "${var.firewall_name}-${count.index + 1}"
}

provider "google-beta" {
  region = "us-central1"
  zone   = "us-central1-a"
}

###########################################
##########               HTTP ELB Backend VM-Series    #############
######################################
resource "google_compute_global_address" "external-address" {
  name = "tf-external-address"
}

resource "google_compute_health_check" "health-check" {
  name              = "elb-health-check"
  http_health_check = {}
}

resource "google_compute_backend_service" "fw-backend" {
  name     = "fw-backend"
  protocol = "HTTP"

  backend {
    group = "${google_compute_instance_group_manager.fw-autoscale-igm.instance_group}"
  }

  health_checks = ["${google_compute_health_check.health-check.self_link}"]
}

resource "google_compute_url_map" "http-elb" {
  name            = "http-elb"
  default_service = "${google_compute_backend_service.fw-backend.self_link}"
}

resource "google_compute_target_http_proxy" "http-lb-proxy" {
  name    = "tf-http-lb-proxy"
  url_map = "${google_compute_url_map.http-elb.self_link}"
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "http-content-gfrule"
  target     = "${google_compute_target_http_proxy.http-lb-proxy.self_link}"
  ip_address = "${google_compute_global_address.external-address.address}"
  port_range = "80"
}

###########################################
###################  INTERNAL LOAD BALANCER and WEB SERVER SETUP BELOW      #############
######################################

resource "google_compute_instance" "webserver-1" {
  name                      = "webserver-1"
  machine_type              = "${var.machine_type_web}"
  zone                      = "${var.region_zone}"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.trust-sub.name}"
  }

  metadata_startup_script = "sudo bash -c 'echo Webserver1 > index.html && nohup busybox httpd -f -p 80 &'"

  service_account {
    scopes = "${var.scopes_web}"
  }

  depends_on = ["google_compute_network.trust",
    "google_compute_network.untrust",
    "google_compute_network.management",
  ]
}

resource "google_compute_instance" "webserver-2" {
  name                      = "webserver-2"
  machine_type              = "${var.machine_type_web}"
  zone                      = "${var.zone_2}"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.trust-sub.name}"
  }

  metadata_startup_script = "sudo bash -c 'echo Webserver2 > index.html && nohup busybox httpd -f -p 80 &'"

  service_account {
    scopes = "${var.scopes_web}"
  }

  depends_on = ["google_compute_network.trust",
    "google_compute_network.untrust",
    "google_compute_network.management",
  ]
}

resource "google_compute_instance" "webserver-3" {
  name                      = "webserver-3"
  machine_type              = "${var.machine_type_web}"
  zone                      = "${var.region_zone}"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.trust-sub.name}"
  }

  metadata_startup_script = "sudo bash -c 'echo Webserver3 > index.html && nohup busybox httpd -f -p 80 &'"

  service_account {
    scopes = "${var.scopes_web}"
  }

  depends_on = ["google_compute_network.trust",
    "google_compute_network.untrust",
    "google_compute_network.management",
  ]
}

resource "google_compute_instance" "webserver-4" {
  name                      = "webserver-4"
  machine_type              = "${var.machine_type_web}"
  zone                      = "${var.zone_2}"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.trust-sub.name}"
  }

  metadata_startup_script = "sudo bash -c 'echo Webserver4 > index.html && nohup busybox httpd -f -p 80 &'"

  service_account {
    scopes = "${var.scopes_web}"
  }

  depends_on = ["google_compute_network.trust",
    "google_compute_network.untrust",
    "google_compute_network.management",
  ]
}

resource "google_compute_instance_group" "websrvr-ig1" {
  name = "websrvr-ig1"

  instances = [
    "${google_compute_instance.webserver-1.self_link}",
    "${google_compute_instance.webserver-3.self_link}",
  ]

  zone = "${var.region_zone}"
}

resource "google_compute_instance_group" "websrvr-ig2" {
  name = "websrvr-ig2"

  instances = [
    "${google_compute_instance.webserver-2.self_link}",
    "${google_compute_instance.webserver-4.self_link}",
  ]

  zone = "${var.zone_2}"
}

resource "google_compute_health_check" "websrvr-tcp-health-check" {
  name = "websrvr-tcp-health-check"

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_region_backend_service" "websrvr-ilb" {
  name          = "websrvr-ilb"
  health_checks = ["${google_compute_health_check.websrvr-tcp-health-check.self_link}"]
  region        = "${var.region}"

  backend {
    group = "${google_compute_instance_group.websrvr-ig1.self_link}"
  }

  backend {
    group = "${google_compute_instance_group.websrvr-ig2.self_link}"
  }
}

resource "google_compute_forwarding_rule" "ilb-forwarding-rule" {
  name                  = "ilb-forwarding-rule"
  load_balancing_scheme = "INTERNAL"
  ports                 = ["80"]
  network               = "${google_compute_network.trust.self_link}"
  subnetwork            = "${google_compute_subnetwork.trust-sub.self_link}"
  ip_address            = "10.0.2.7"
  backend_service       = "${google_compute_region_backend_service.websrvr-ilb.self_link}"
}

#################
####################
######################
##########################


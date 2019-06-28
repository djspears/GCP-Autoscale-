// PROJECT Variables

variable "region" {
  default = "us-central1"
}

variable "region_zone" {
  default = "us-central1-a"
}

variable "project_name" {
  description = "The ID of the Google Cloud project"
  default     = "djs-gcp-2018"
}

variable "credentials_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
  default     = "/Users/dspears/GCP/Autoscale/djs-gcp-2018-creds.json"
}

variable "zone" {
  default = "us-central1-a"
}

variable "zone_2" {
  default = "us-central1-b"
}

variable "public_key" {
  default = "dspears@SJCMAC3024G8WL:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3bjwWN/LY87FOZH/uuRXS5ku3OXkxsFIvecXMNDoeTNZU5QSM3bAV8t/IU52GsdQO+f2hv9iVulMfYPwxsMcVen32q+t6dcgtChUXPSk+giGqf71iR2xiqGdk6GgC705SUXG/AX1whNI1qT84wP0nOrJaoGo/SZq4Ryel9mptu1Ifj1vMphyw2WOFOMB3IuUYckZHgwbQxZK4iCGJSZmzP+M03oSKZATwvuI1XXUIUVTCcV45NofgCW3Ocfk0UjhK01l1SO3H4+c+v40Zufpqo4vPMOQajTggygpJ7SRCgOYWJxcdx4cr9ASNteii5LQFqAixJD0+0izXfQEUm0/T dspears@SJCMAC3024G8WL"
}

// FIREWALL Variables
variable "firewall_name" {
  default = "firewall"
}

variable "fw_instance_group_template_name" {
  default = "fw-autoscale-template"
}

variable "image_fw" {
  default = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-bundle2-814"
}

variable "machine_type_fw" {
  default = "n1-standard-4"
}

variable "machine_cpu_fw" {
  default = "Intel Skylake"
}

variable "bootstrap_bucket_fw" {
  default = "auto-scale-bootstrap2"
}

variable "interface_0_name" {
  default = "managementa"
}

variable "interface_1_name" {
  default = "untrusta"
}

variable "interface_2_name" {
  default = "trusta"
}

variable "scopes_fw" {
  default = ["https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
  ]
}

// WEB-SERVER Vaiables
variable "web_server_name" {
  default = "webserver"
}

variable "machine_type_web" {
  default = "f1-micro"
}

variable "image_web" {
  default = "debian-9"
}

variable "scopes_web" {
  default = ["https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
  ]
}

##################
####################################

variable "gcp_region" {
  description = "Google Compute region to use for the cluster"
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Google Container Cluster name to use for the cluster"
  default     = "gkecluster"
}

variable "gcp_zone" {
  description = "Google Computer zone to use for the cluster"
  default     = "us-central1-a"
}

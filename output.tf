/*
output "firewall-untrust-ips-for-nat-healthcheck" {
  value = "${google_compute_instance.firewall.*.network_interface.0.address}"
}
*/
#output "firewall-name" {
#  value = "${google_compute_instance.firewall.*.name}"
#}
output "elb_public_ip" {
  value = "${google_compute_global_forwarding_rule.default.ip_address}"
}

output "ILB IP for HealthCheck should be 10.0.2.7 if not update ILB IP Object on FW to -->" {
  value = "${google_compute_forwarding_rule.ilb-forwarding-rule.ip_address}"
}

// Health check
resource "google_compute_http_health_check" "cf-tcp" {
  name                = "${var.gcp_terraform_prefix}-tcp-lb"
  host                = "tcp.sys.${google_dns_managed_zone.env_dns_zone.dns_name}"
  port                = 80
  request_path        = "/health"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 10
  unhealthy_threshold = 2
}

// TCP target pool
resource "google_compute_target_pool" "cf-tcp" {
  name = "${var.gcp_terraform_prefix}-cf-tcp"

  health_checks = [
    "${google_compute_http_health_check.cf-tcp.name}",
  ]
}

// TCP forwarding rule
resource "google_compute_forwarding_rule" "cf-tcp" {
  name        = "${var.gcp_terraform_prefix}-cf-tcp"
  target      = "${google_compute_target_pool.cf-tcp.self_link}"
  port_range  = "1024-65535"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_address.cf-tcp.address}"
}

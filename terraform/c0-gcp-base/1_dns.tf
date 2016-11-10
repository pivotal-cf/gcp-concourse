///////////////////////////////////////////////
//////// Create DNS Zone //////////////////////
///////////////////////////////////////////////

resource "google_dns_managed_zone" "env_dns_zone" {
  name        = "${var.gcp_terraform_prefix}-zone"
  dns_name    = "${var.pcf_ert_domain}."
  description = "DNS zone (var.pcf_ert_domain)for the var.gcp_terraform_prefix deployment"
}

///////////////////////////////////////////////
//////// Add DNS Zone Records /////////////////
///////////////////////////////////////////////

resource "google_dns_record_set" "ops-manager-dns" {
  name       = "opsman.${google_dns_managed_zone.env_dns_zone.dns_name}"
  type       = "A"
  ttl        = 300

  managed_zone = "${google_dns_managed_zone.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_opsman}"]
}

resource "google_dns_record_set" "wildcard-sys-dns" {
  name       = "*.sys.${google_dns_managed_zone.env_dns_zone.dns_name}"
  type       = "A"
  ttl        = 300

  managed_zone = "${google_dns_managed_zone.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_global_pcf}"]
}

resource "google_dns_record_set" "wildcard-apps-dns" {
  name       = "*.cfapps.${google_dns_managed_zone.env_dns_zone.dns_name}"
  type       = "A"
  ttl        = 300

  managed_zone = "${google_dns_managed_zone.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_global_pcf}"]
}

resource "google_dns_record_set" "app-ssh-dns" {
  name       = "ssh.sys.${google_dns_managed_zone.env_dns_zone.dns_name}"
  type       = "A"
  ttl        = 300

  managed_zone = "${google_dns_managed_zone.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "doppler-dns" {
  name       = "doppler.sys.${google_dns_managed_zone.env_dns_zone.dns_name}"
  type       = "A"
  ttl        = 300

  managed_zone = "${google_dns_managed_zone.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "loggregator-dns" {
  name       = "loggregator.sys.${google_dns_managed_zone.env_dns_zone.dns_name}"
  type       = "A"
  ttl        = 300

  managed_zone = "${google_dns_managed_zone.env_dns_zone.name}"

    rrdatas = ["${var.pub_ip_ssh_and_doppler}"]
}

resource "google_dns_record_set" "tcp-dns" {
  name       = "tcp.${google_dns_managed_zone.env_dns_zone.dns_name}"
  type       = "A"
  ttl        = 300

  managed_zone = "${google_dns_managed_zone.env_dns_zone.name}"

  rrdatas = ["${var.pub_ip_ssh_tcp_lb}"]
}

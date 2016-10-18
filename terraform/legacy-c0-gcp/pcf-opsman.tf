///////////////////////////////////////////////
//// (1) Declare Vars /////////////////////////
///////////////////////////////////////////////


variable "gcp_proj_id" {}
variable "gcp_region_1" {}
variable "gcp_terraform_prefix" {}
variable "gcp_terraform_subnet_bosh" {}
variable "gcp_zone_1" {}
variable "gcp_zone_2" {}
variable "gcp_zone_3" {}
variable "gcp_terraform_subnet_ert_region_1" {}
variable "gcp_terraform_subnet_services_1_region_1" {}
variable "pcf_ert_sys_domain" {}
variable "gcp_svc_acct_key" {}


///////////////////////////////////////////////
//// (2) Set GCP Provider info ////////////////
///////////////////////////////////////////////


provider "google" {
  project = "${var.gcp_proj_id}"
  region = "${var.gcp_region}"
  credentials = "${var.gcp_svc_acct_key}"
}


///////////////////////////////////////////////
//// (3) Create Network Objects   /////////////
///////////////////////////////////////////////

///////////======================//////////////
//// Network(s) =================//////////////
///////////======================//////////////

  //// Create GCP Virtual Network
  resource "google_compute_network" "vnet" {
    name       = "${var.gcp_terraform_prefix}-vnet"
  }

///////////======================//////////////
//// Static IP(s) ===============//////////////
///////////======================//////////////

  //// Create CloudFoundry Static IP address
  resource "google_compute_address" "cloudfoundry-public-ip" {
    name   = "${var.gcp_terraform_prefix}-cloudfoundry-public-ip"
    region = "${var.gcp_region_1}"
  }

  //// Create NAT 1 Static IP address
  resource "google_compute_address" "nat1-public-ip" {
    name   = "${var.gcp_terraform_prefix}-nat1-public-ip"
    region = "${var.gcp_region_1}"
  }

  //// Create NAT 2 Static IP address
  resource "google_compute_address" "nat2-public-ip" {
    name   = "${var.gcp_terraform_prefix}-nat2-public-ip"
    region = "${var.gcp_region_1}"
  }

  //// Create NAT 3 Static IP address
  resource "google_compute_address" "nat3-public-ip" {
    name   = "${var.gcp_terraform_prefix}-nat3-public-ip"
    region = "${var.gcp_region_1}"
  }

///////////======================//////////////
//// Subnet(s) ==================//////////////
///////////======================//////////////

  //// Create Subnet for the BOSH director
  resource "google_compute_subnetwork" "subnet-bosh" {
    name          = "${var.gcp_terraform_prefix}-subnet-bosh-${var.gcp_region_1}"
    ip_cidr_range = "${var.gcp_terraform_subnet_bosh}"
    network       = "${google_compute_network.vnet.self_link}"
  }

  //// Create Subnet for ERT
  resource "google_compute_subnetwork" "subnet-ert" {
    name          = "${var.gcp_terraform_prefix}-subnet-ert-${var.gcp_region_1}"
    ip_cidr_range = "${var.gcp_terraform_subnet_ert_region_1}"
    network       = "${google_compute_network.vnet.self_link}"
  }

  //// Create Subnet for Services Tile 1
  resource "google_compute_subnetwork" "subnet-services-1" {
    name          = "${var.gcp_terraform_prefix}-subnet-services-1-${var.gcp_region_1}"
    ip_cidr_range = "${var.gcp_terraform_subnet_services_1_region_1}"
    network       = "${google_compute_network.vnet.self_link}"
  }

///////////======================//////////////
//// Firewall Rule(s) ===========//////////////
///////////======================//////////////

  //// Create Firewall Rule for allow-ssh from public
  resource "google_compute_firewall" "allow-ssh" {
    name    = "${var.gcp_terraform_prefix}-allow-ssh"
    network = "${google_compute_network.vnet.name}"

    allow {
      protocol = "tcp"
      ports    = ["22"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["allow-ssh"]
  }

  //// Create Firewall Rule for allow-http from public
  resource "google_compute_firewall" "allow-http" {
    name    = "${var.gcp_terraform_prefix}-allow-http"
    network = "${google_compute_network.vnet.name}"

    allow {
      protocol = "tcp"
      ports    = ["80"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["allow-http"]
  }

  //// Create Firewall Rule for allow-https from public
  resource "google_compute_firewall" "allow-https" {
    name    = "${var.gcp_terraform_prefix}-allow-https"
    network = "${google_compute_network.vnet.name}"

    allow {
      protocol = "tcp"
      ports    = ["443"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["allow-https"]
  }

  //// Create Firewall Rule for allow-ert-all com between bosh deployed ert jobs
  //// This will match the default OpsMan tag configured for the deployment
  resource "google_compute_firewall" "allow-ert-all" {
    name    = "${var.gcp_terraform_prefix}-allow-ert-all"
    network = "${google_compute_network.vnet.name}"

    allow {
      protocol = "icmp"
    }

    allow {
      protocol = "tcp"
    }

    allow {
      protocol = "udp"
    }
    target_tags = ["${var.gcp_terraform_prefix}"]
    source_tags = ["${var.gcp_terraform_prefix}"]
  }

  //// Create Firewall Rule for allow-ert-egress-no-nat for com from ert-jobs to instances with-pub ips
  resource "google_compute_firewall" "allow-ert-egress-no-nat" {
    name    = "${var.gcp_terraform_prefix}-allow-ert-egress-no-nat"
    network = "${google_compute_network.vnet.name}"

    allow {
      protocol = "icmp"
    }

    allow {
      protocol = "tcp"
    }

    allow {
      protocol = "udp"
    }

    source_tags = ["${var.gcp_terraform_prefix}"]
    target_tags = ["no-nat-route"]
  }

  //// Create Firewall Rule for allow-ert-ingress-no-nat for com from instances with-pub ips to ert-jobs
  resource "google_compute_firewall" "allow-ert-ingress-no-nat" {
    name    = "${var.gcp_terraform_prefix}-allow-ert-ingress-no-nat"
    network = "${google_compute_network.vnet.name}"

    allow {
      protocol = "icmp"
    }

    allow {
      protocol = "tcp"
    }

    allow {
      protocol = "udp"
    }

    source_tags = ["no-nat-route"]
    target_tags = ["${var.gcp_terraform_prefix}"]
  }

  //// Create Firewall Rule for PCF Public Network Access
  resource "google_compute_firewall" "pcf-public" {
    name    = "${var.gcp_terraform_prefix}-pcf-public"
    network = "${google_compute_network.vnet.name}"

    allow {
      protocol = "tcp"
      ports    = ["80","443","2222"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["${var.gcp_terraform_prefix}-pcf-public-ert","${var.gcp_terraform_prefix}-pcf-public-cfcli-ssh"]
}


///////////======================//////////////
//// Load Balancing =============//////////////
///////////======================//////////////

  //// Create HTTP Health Check Rule for PCF ERT
  resource "google_compute_http_health_check" "pcf-public-ert" {
  name         = "${var.gcp_terraform_prefix}-pcf-public-ert"
  request_path = "/v2/info"
  host         = "api.${var.pcf_ert_sys_domain}"
  port         = 80

  healthy_threshold   = 10
  unhealthy_threshold = 2
  timeout_sec         = 5
  check_interval_sec  = 30
}


  //// Create Target Pool for PCF ERT
  resource "google_compute_target_pool" "pcf-public-ert" {
  name          = "${var.gcp_terraform_prefix}-pcf-public-ert"
  health_checks = [
    "${google_compute_http_health_check.pcf-public-ert.name}",
  ]
}

  //// Create Target Pool for cf cli - SSH
  resource "google_compute_target_pool" "pcf-public-cfcli-ssh" {
  name          = "${var.gcp_terraform_prefix}-pcf-public-cfcli-ssh"
}


  //// Create Forwarding for PCF - http
  resource "google_compute_forwarding_rule" "pcf-http" {
  name       = "${var.gcp_terraform_prefix}-pcf-http"
  target     = "${google_compute_target_pool.pcf-public-ert.self_link}"
  ip_address = "${google_compute_address.cloudfoundry-public-ip.address}"
  port_range = "80"
}

  //// Create Forwarding for PCF - https
  resource "google_compute_forwarding_rule" "pcf-https" {
  name       = "${var.gcp_terraform_prefix}-pcf-https"
  target     = "${google_compute_target_pool.pcf-public-ert.self_link}"
  ip_address = "${google_compute_address.cloudfoundry-public-ip.address}"
  port_range = "443"
}

  //// Create Forwarding for cf cli - ssh
  resource "google_compute_forwarding_rule" "pcf-ssh" {
  name       = "${var.gcp_terraform_prefix}-pcf-ssh"
  target     = "${google_compute_target_pool.pcf-public-cfcli-ssh.self_link}"
  ip_address = "${google_compute_address.cloudfoundry-public-ip.address}"
  port_range = "2222"
}



///////////////////////////////////////////////
//// (4)Create BOSH bastion instance //////////
///////////////////////////////////////////////


resource "google_compute_instance" "bosh-bastion" {
  name         = "${var.gcp_terraform_prefix}-bosh-bastion"
  machine_type = "n1-standard-1"
  zone         = "${var.gcp_zone_1}"

  tags = ["no-nat-route", "allow-ssh"]

  disk {
    image = "ubuntu-1404-trusty-v20160610"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      // Ephemeral
    }
  }

  service_account {
    #email = "c0-concourse@pcf-demos.google.com.iam.gserviceaccount.com"
    scopes = [
              "https://www.googleapis.com/auth/compute",
              "https://www.googleapis.com/auth/logging.write",
              "https://www.googleapis.com/auth/monitoring.write",
              "https://www.googleapis.com/auth/servicecontrol",
              "https://www.googleapis.com/auth/service.management",
              "https://www.googleapis.com/auth/devstorage.full_control"
            ]
  }

  metadata {
    zone="${var.gcp_zone_1}"
    region="${var.gcp_region_1}"
  }

  metadata_startup_script = <<EOF

#! /bin/bash
adduser --disabled-password --gecos "" bosh
apt-get update -y
apt-get upgrade -y
apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3
wget "https://cli.run.pivotal.io/stable?release=debian64&source=github" -O /tmp/cf-cli.deb
dpkg --install /tmp/cf-cli.deb
wget $(wget -q -O- https://bosh.io/docs/install-bosh-init.html | grep "bosh-init for Linux (amd64)" | awk -F "\'" '{print$2}') -O /sbin/bosh-init
chmod 755 /sbin/bosh-init
tar -zxvf /tmp/cf.tgz && mv cf /usr/bin/cf && chmod +x /usr/bin/cf
gcloud config set compute/zone $zone
gcloud config set compute/region $region
mkdir -p /home/bosh/.ssh
ssh-keygen -t rsa -f /home/bosh/.ssh/bosh -C bosh -N ''
sed '1s/^/bosh:/' /home/bosh/.ssh/bosh.pub >> /tmp/metadata_users.pub.gcp
chown -R bosh:bosh /home/bosh/.ssh
adduser --disabled-password --gecos "" vcap
mkdir -p /home/vcap/.ssh
ssh-keygen -t rsa -f /home/vcap/.ssh/vcap -C vcap -N ''
sed '1s/^/vcap:/' /home/vcap/.ssh/vcap.pub >> /tmp/metadata_users.pub.gcp
chown -R vcap:vcap /home/vcap/.ssh
gcloud compute project-info add-metadata --metadata-from-file sshKeys=/tmp/metadata_users.pub.gcp
rm -rf /tmp/metadata_users.pub.gcp
gem install bosh_cli
gem install cf-uaac
EOF

}

///////////////////////////////////////////////
//// (4)Create NAT instance(s) ////////////////
///////////////////////////////////////////////


//// NAT Primary Instance

resource "google_compute_instance" "nat-gateway-pri" {
  name           = "${var.gcp_terraform_prefix}-nat-gateway-pri"
  machine_type   = "n1-standard-1"
  zone           = "${var.gcp_zone_1}"
  can_ip_forward = true
  tags = ["no-nat-route"]

  disk {
    image = "ubuntu-1404-trusty-v20160610"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      nat_ip = "${google_compute_address.nat1-public-ip.address}"
    }
  }

  metadata_startup_script = <<EOF
#! /bin/bash
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOF
}

//// NAT 2nd Instance

resource "google_compute_instance" "nat-gateway-sec" {
  name           = "${var.gcp_terraform_prefix}-nat-gateway-sec"
  machine_type   = "n1-standard-1"
  zone           = "${var.gcp_zone_2}"
  can_ip_forward = true
  tags = ["no-nat-route"]

  disk {
    image = "ubuntu-1404-trusty-v20160610"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      nat_ip = "${google_compute_address.nat2-public-ip.address}"
    }
  }

    metadata_startup_script = <<EOF
  #! /bin/bash
  sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
  sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  EOF
}

//// NAT 3rd Instance

resource "google_compute_instance" "nat-gateway-ter" {
  name           = "${var.gcp_terraform_prefix}-nat-gateway-ter"
  machine_type   = "n1-standard-1"
  zone           = "${var.gcp_zone_3}"
  can_ip_forward = true
  tags = ["no-nat-route"]

  disk {
    image = "ubuntu-1404-trusty-v20160610"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      nat_ip = "${google_compute_address.nat3-public-ip.address}"
    }
  }

    metadata_startup_script = <<EOF
  #! /bin/bash
  sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
  sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  EOF

}


///////////////////////////////////////////////
//// (5)Create Route(s)  //////////////////////
///////////////////////////////////////////////


resource "google_compute_route" "nat-primary" {
  name        = "${var.gcp_terraform_prefix}-nat-pri"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.vnet.name}"
  next_hop_instance = "${google_compute_instance.nat-gateway-pri.name}"
  next_hop_instance_zone = "${var.gcp_zone_1}"
  priority    = 800
  tags        = ["${var.gcp_terraform_prefix}"]
}

resource "google_compute_route" "nat-secondary" {
  name        = "${var.gcp_terraform_prefix}-nat-sec"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.vnet.name}"
  next_hop_instance = "${google_compute_instance.nat-gateway-sec.name}"
  next_hop_instance_zone = "${var.gcp_zone_2}"
  priority    = 801
  tags        = ["${var.gcp_terraform_prefix}"]
}

resource "google_compute_route" "nat-tertiary" {
  name        = "${var.gcp_terraform_prefix}-nat-ter"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.vnet.name}"
  next_hop_instance = "${google_compute_instance.nat-gateway-ter.name}"
  next_hop_instance_zone = "${var.gcp_zone_3}"
  priority    = 802
  tags        = ["${var.gcp_terraform_prefix}"]
}


///////////////////////////////////////////////
//// (6)Create Pivotal Opsman  ////////////////
///////////////////////////////////////////////


resource "google_compute_instance" "opsmgr-18-alpha" {
  name           = "${var.gcp_terraform_prefix}-opsmgr-18-alpha"
  machine_type   = "n1-standard-2"
  zone           = "${var.gcp_zone_1}"
  can_ip_forward = true
  tags = ["no-nat-route", "allow-https", "allow-ssh"]

  disk {
    image = "pivotal-ops-manager-20160915t181006-100a670"
    size  = "120"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      // Ephemeral
    }
  }
}

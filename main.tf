terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.44.0" # 1.38.1
    }
  }
}

variable "hcloud_api_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_api_token
}

#################################
#### Server for Some-Service ####
#################################

resource "hcloud_server" "some_service" {
  name              = "some-service"
  server_type       = "cx11"
  image             = "debian-12"
  ssh_keys          = [ hcloud_ssh_key.maintainance_default.id ]
}

###################################
#### Firewall for Some-Service ####
###################################

resource "hcloud_firewall" "some_service" {
  name  = "some-service"

  # same bug with this code instead of `hcloud_firewall_attachment`
  # apply_to {
  #   server = hcloud_server.some_service.id
  # }

  rule {
    description = "A port for some service"
    direction   = "in"
    protocol    = "tcp"
    port        = 1337
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}

# resource "hcloud_firewall_attachment" "some_service" {
#   firewall_id = hcloud_firewall.some_service.id
#   server_ids  = [hcloud_server.some_service.id]
# }

####################
#### Workaround ####
####################

locals {
  some_service_firewall_ids = [
    hcloud_firewall.maintainance_dns.id,
    hcloud_firewall.maintainance_web.id,
    hcloud_firewall.maintainance_ssh.id,
    hcloud_firewall.some_service.id,
  ]
  some_service_firewall_ids_string = join(",", local.some_service_firewall_ids)
}

# count hack for "known after apply" values from https://stackoverflow.com/a/76692461/3206306
resource "hcloud_firewall_attachment" "some_service_all_firewalls" {
  count       = length(local.some_service_firewall_ids)
  firewall_id = split(",", local.some_service_firewall_ids_string)[count.index]
  server_ids  = [ hcloud_server.some_service.id ]
}

resource "null_resource" "some_service_server_setup" {
  depends_on = [ hcloud_server.some_service, hcloud_firewall_attachment.some_service_all_firewalls ]

  # this requires the maintainance-ssh firewall to be attached to the server
  connection {
    host        = "${hcloud_server.some_service.ipv4_address}"
    type        = "ssh"
    user        = "root"
    port        = 22
    private_key = tls_private_key.default.private_key_openssh
  }

  # install ansible on remote machine
  # this requires the maintainance-dns and maintainanace-web firewalls to be attached to the server
  provisioner "remote-exec" {
    inline = ["apt-get update -y && apt-get upgrade -y && apt-get install -y ansible"]
  }
}

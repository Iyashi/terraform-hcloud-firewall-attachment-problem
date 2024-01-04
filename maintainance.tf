##############################
#### Maintainance SSH-Key ####
##############################

# This simply creates an SSH-Key and works fine. I just added it for easy project setup.
# It has nothing to do with the actual problem.
# The problem only occures in the hcloud_server.some_service.firewall_ids list.

# Generate SSH-Private-Key
resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Write SSH-Private-Key to ~/.ssh/id_rsa.*.default
resource "local_sensitive_file" "ssh_key_private" {
  depends_on           = [ tls_private_key.default ]
  filename             = "id_rsa"
  file_permission      = "600"
  directory_permission = "700"
  content              = tls_private_key.default.private_key_openssh
}

# Generate SSH-Public-Key (from previously generated SSH-Private-Key)
data "tls_public_key" "default" {
  depends_on          = [ tls_private_key.default ]
  private_key_openssh = tls_private_key.default.private_key_openssh
}

# Write SSH-Public-Key to ~/.ssh/id_rsa.*.default.pub
resource "local_file" "ssh_key_public" {
  depends_on           = [ data.tls_public_key.default ]
  filename             = "id_rsa.pub"
  file_permission      = "644"
  directory_permission = "700"
  content              = data.tls_public_key.default.public_key_openssh
}

# Create SSH-Key Resource in Hetzner Cloud
resource "hcloud_ssh_key" "maintainance_default" {
  name       = "maintainance-default"
  public_key = tls_private_key.default.public_key_openssh
  labels     = { managed  = "terraform" }
}

##########################################
#### Resources: Mainainance Firewalls ####
##########################################

# This creates the maintainance firewalls and works fine.
# The problem only occures in the hcloud_server.some_service.firewall_ids list.

resource "hcloud_firewall" "maintainance_web" {
  name  = "maintainance-web"

  labels = {
    managed      = "terraform"
    category     = "maintainance"
    protocol     = "web"
  }

  rule {
    description      = "HTTP (tcp/out) - required to download packages (apt-get, ansible, docker)"
    direction        = "out"
    protocol         = "tcp"
    port             = 80
    destination_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description      = "HTTPS (tcp/out) - required to download packages (apt-get, ansible, docker)"
    direction        = "out"
    protocol         = "tcp"
    port             = 443
    destination_ips  = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "maintainance_dns" {
  name  = "maintainance-dns"

  labels = {
    managed      = "terraform"
    category     = "maintainance"
    protocol     = "dns"
  }

  rule {
    description      = "DNS (tcp/out) - required to resolve domains (apt-get, ansible, docker)"
    direction        = "out"
    protocol         = "tcp"
    port             = 53
    destination_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description      = "DNS (udp/out) - required to resolve domains (apt-get, ansible, docker)"
    direction        = "out"
    protocol         = "udp"
    port             = 53
    destination_ips  = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "maintainance_ssh" {
  name  = "maintainance-ssh"

  labels = {
    managed      = "terraform"
    category     = "maintainance"
    protocol     = "ssh"
  }

  rule {
    description = "SSH (tcp/in)"
    direction   = "in"
    protocol    = "tcp"
    port        = 22
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}

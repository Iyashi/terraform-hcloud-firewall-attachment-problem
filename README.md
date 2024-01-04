# terraform-hcloud-firewall-attachment-problem

Example terraform code to reproduce firewall attachment problem in HetznerCloud.

This repo was created for [hetznercloud/terraform-provider-hcloud/issues/828](https://github.com/hetznercloud/terraform-provider-hcloud/issues/828).

## Setup

1. Create new empty project in Hetzner Cloud
2. Create project API token and save it to `terraform.tfvars` (`hcloud_api_token = "<token>"`)
3. Initialize and apply (2x) terraform
   ```sh
   terraform init
   terraform apply # everything works, all firewalls attached
   terraform apply # some-service firewall gets detached again. why?
   ```

## What is the problem?

The first `terraform apply` works fine, everything is set up correctly, including firewalls.

But subsequent runs of `terraform apply` will detach the `some-service` firewall from the server.

As far as I understand, the server firewalls get reset to whatever was initially added to the server during server resource creation:

```sh
resource "hcloud_server" "some_service" {
  # ...
  firewall_ids = [
    hcloud_firewall.maintainance_dns.id,
    hcloud_firewall.maintainance_web.id,
    hcloud_firewall.maintainance_ssh.id
  ]
  # ...
}
```

This effectively ignores `hcloud_firewall_attachment.some_service`.

## Expected result

1. `maintainance-*` firewalls gets attached during server resource creation (works)
2. `some-service` firewall gets attached after server was created (works)
3. `some-service` firewall NOT being removed after second `terraform apply` (doesn't work)

terraform {
  required_version = ">= 1.9"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.42"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "openclaw" {
  name     = var.droplet_name
  region   = var.region
  size     = var.droplet_size
  image    = var.image
  vpc_uuid = digitalocean_vpc.openclaw.id
  ssh_keys = [var.ssh_key_id]
  tags     = var.tags

  user_data = templatefile("${path.module}/../cloud-init/user-data.yml.tmpl", {
    admin_username       = var.admin_username
    admin_ssh_public_key = var.admin_ssh_public_key
    tailscale_authkey    = var.tailscale_authkey
  })
}

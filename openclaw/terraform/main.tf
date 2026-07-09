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

  # user_data wiring deferred to Session 3: HCP Terraform's CLI-driven remote
  # runs only upload this working directory, so a templatefile() reference to
  # the sibling ../cloud-init/ path fails remotely even though it works
  # locally. Session 3 needs to either nest cloud-init under this directory
  # or otherwise restructure before wiring it in.
}

resource "digitalocean_vpc" "openclaw" {
  name     = "${var.droplet_name}-vpc"
  region   = var.region
  ip_range = var.vpc_ip_range
}

output "droplet_id" {
  value = digitalocean_droplet.openclaw.id
}

output "droplet_public_ip" {
  value = digitalocean_droplet.openclaw.ipv4_address
}

output "vpc_id" {
  value = digitalocean_vpc.openclaw.id
}

output "firewall_id" {
  value = digitalocean_firewall.openclaw.id
}

output "ssh_key_id" {
  value = digitalocean_ssh_key.admin.id
}

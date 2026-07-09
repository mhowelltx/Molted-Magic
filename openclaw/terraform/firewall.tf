# Inbound: SSH only, restricted to admin_ip_cidrs. Deliberately no inbound
# rule for the OpenClaw control UI port (or any other port) — that stays
# reachable only over Tailscale's private overlay network, never the public
# interface. See CLAUDE.md's "Infra safety" guardrail.
resource "digitalocean_firewall" "openclaw" {
  name        = "${var.droplet_name}-fw"
  droplet_ids = [digitalocean_droplet.openclaw.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.admin_ip_cidrs
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

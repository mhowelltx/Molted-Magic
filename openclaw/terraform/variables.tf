variable "do_token" {
  description = "DigitalOcean API token. Set via TF_VAR_do_token env var — never committed."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region slug, e.g. nyc3, sfo3."
  type        = string
}

variable "droplet_size" {
  description = "DigitalOcean droplet size slug, e.g. s-2vcpu-2gb."
  type        = string
}

variable "droplet_name" {
  description = "Name for the droplet and derived resource names (VPC, firewall)."
  type        = string
  default     = "openclaw"
}

variable "image" {
  description = "Droplet base image slug."
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "admin_username" {
  description = "Non-root admin username created by cloud-init on first boot."
  type        = string
  default     = "openclaw-admin"
}

variable "vpc_ip_range" {
  description = "CIDR range for the dedicated VPC."
  type        = string
  default     = "10.10.10.0/24"
}

variable "admin_ip_cidrs" {
  description = "CIDR blocks allowed to reach the droplet over SSH (your admin IP(s), or a Tailscale-assigned range)."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to the droplet."
  type        = list(string)
  default     = ["openclaw", "molted-magic"]
}

variable "admin_ssh_public_key" {
  description = "Public key content (e.g. the contents of an .pub file) — dual purpose: registered as a DigitalOcean account SSH key (digitalocean_ssh_key.admin) so the droplet trusts it at boot, AND granted to the non-root admin user by cloud-init. Not secret, but still a variable rather than hardcoded so it's easy to rotate."
  type        = string
}

variable "tailscale_authkey" {
  description = "Tailscale auth key used by cloud-init to join the tailnet on first boot. Set via TF_VAR_tailscale_authkey env var — never committed. Leave empty to skip joining Tailscale."
  type        = string
  sensitive   = true
  default     = ""
}

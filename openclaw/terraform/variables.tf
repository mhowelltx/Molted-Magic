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

variable "ssh_key_id" {
  description = "Fingerprint or ID of the SSH key already uploaded to the DigitalOcean account."
  type        = string
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

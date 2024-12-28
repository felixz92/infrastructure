variable "environment" {
  default = "staging"
  type = string
}

variable "base_domain" {
  type = string
  default = "staging-fzx-infra.dev"
}

variable "lets_encrypt_email" {
  type = string
  sensitive = true
}

variable "hcloud_token" {
  type = string
  sensitive = true
}

# Infra
variable "network_ipv4_cidr" {
  type = string
  default = "10.0.0.0/8" # do not change
}

variable "ssh_public_key" {
  type = string
  default = "~/.ssh/clusters/staging/id_ed25519.pub"
}

variable "ssh_private_key" {
  type = string
  default = "~/.ssh/clusters/staging/id_ed25519"
}

# Flux
variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
  default = "infrastructure"
}

variable "github_token" {
  type = string
  sensitive = true
}

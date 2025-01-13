variable "cluster_name" {
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
  default = "10.0.0.0/16" # do not change
}

# Flux
variable "github_owner" {
  type = string
  default = "FelixZ92"
}

variable "github_token" {
  type = string
  sensitive = true
}

variable "branch" {
  type = string
  default = "main"
}

variable "repository_name" {
  type = string
  default = "infrastructure"
}

variable "flux_version" {
  type = string
  default = "v2.4.0"
}

variable "doppler_token" {
  type = string
  sensitive = true
}

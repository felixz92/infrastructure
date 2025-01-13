variable "cluster_name" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "hcloud_token" {
  type = string
  sensitive = true
}

# Flux
variable "github_owner" {
  type = string
}

variable "github_token" {
  type = string
  sensitive = true
}

variable "branch" {
  type = string
}

variable "repository_name" {
  type = string
}

variable "flux_version" {
  type = string
}

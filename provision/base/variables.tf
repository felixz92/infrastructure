variable "cluster_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "base_domain" {
  type = string
}

# Flux
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

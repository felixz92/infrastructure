provider "github" {
  owner = var.github_owner
  token = var.github_token
}

data "github_repository" "main" {
  name = var.github_repo
}

locals {
  target_path = "flux/${var.environment}"
}

resource "tls_private_key" "main" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "github_repository_deploy_key" "main" {
  title      = "flux-${var.environment}"
  repository = data.github_repository.main.id
  key        = tls_private_key.main.public_key_openssh
  read_only  = false
}

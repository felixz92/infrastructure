provider "hcloud" {
  token = var.hcloud_token
}

terraform {
  required_version = ">= 1.3.3"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.49.1"
    }
    http = {
      source = "hashicorp/http"
      version = ">= 3.4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.4.0"
    }
  }
}

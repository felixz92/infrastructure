provider "hcloud" {
  token = var.hcloud_token
}

terraform {
  required_version = ">= 1.3.3"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.35.2"
    }
    http = {
      source = "hashicorp/http"
      version = ">= 3.4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.1.0"
    }
  }
}

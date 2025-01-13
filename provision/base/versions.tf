terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 4.5.2"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=3.1.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = ">=1.3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.49.1"
    }
  }
}
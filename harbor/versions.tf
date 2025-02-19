terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.49.1"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "2.3.5"
    }
    onepassword = {
      source = "1Password/onepassword"
      version = "2.1.2"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.0.0"
    }
    htpasswd = {
      source = "loafoe/htpasswd"
      version = "1.2.1"
    }
  }
}

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.60.1"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "2.3.7"
    }
    onepassword = {
      source = "1Password/onepassword"
      version = "3.3.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.18.0"
    }
    htpasswd = {
      source = "loafoe/htpasswd"
      version = "1.2.1"
    }
  }
}

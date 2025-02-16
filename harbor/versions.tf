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
  }
}

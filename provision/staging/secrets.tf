terraform {
  required_providers {
    onepassword = {
      source = "1Password/onepassword"
      version = "2.1.2"
    }
  }
}

provider "onepassword" {
  account = "my.1password.eu"
}

data "onepassword_vault" "vault" {
  name = "Personal"
}

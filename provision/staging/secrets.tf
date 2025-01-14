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

data "onepassword_item" "github_token" {
  vault = data.onepassword_vault.vault.uuid
  title = "development-github.com"
}

data "onepassword_item" "hcloud_token" {
  vault = data.onepassword_vault.vault.uuid
  title = "hcloud-token-staging"
}

provider "onepassword" {
  account = "my.1password.eu"
}

data "onepassword_vault" "vault" {
  name = "kubernetes-${var.environment}"
}

data "onepassword_item" "github_token" {
  vault = data.onepassword_vault.vault.uuid
  title = "flux-bootstrap"
}

data "onepassword_item" "hcloud_token" {
  vault = data.onepassword_vault.vault.uuid
  title = "hcloud-token"
}

data "onepassword_item" "op_credentials_json" {
  vault = data.onepassword_vault.vault.uuid
  title = "1password-automation"
}

data "onepassword_item" "op_connect_token" {
  vault = data.onepassword_vault.vault.uuid
  title = "op-connect-token"
}

data "onepassword_item" "zot_pull_user" {
  vault = data.onepassword_vault.vault.uuid
  title = "zot-pull-user"
}

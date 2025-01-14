module "cluster" {
  source = "../base"
  cluster_name = "staging"
  github_token = data.onepassword_item.github_token.section[0].field[0].value
  hcloud_token = data.onepassword_item.hcloud_token.password
  base_domain = "staging-fzx-infra.dev"
  github_owner = data.onepassword_item.github_token.username
  branch = "main"
  repository_name = "infrastructure"
  flux_version = "v2.4.0"
}

module "cluster" {
  source = "../base"
  cluster_name = "staging"
  github_token = ""
  hcloud_token = ""
  base_domain = "staging-fzx-infra.dev"
  github_owner = "FelixZ92"
  branch = "main"
  repository_name = "infrastructure"
  flux_version = "v2.4.0"
}

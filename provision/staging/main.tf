module "cluster" {
  source = "../base"
  cluster_name = "staging"
  base_domain = "staging-fzx-infra.dev"
  flux_version = "v2.4.0"
  environment = "staging"
}

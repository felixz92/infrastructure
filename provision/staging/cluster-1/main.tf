module "cluster" {
  source = "../../base"
  cluster_name = "staging"
  flux_version = "v2.4.0"
  environment = "staging"
}

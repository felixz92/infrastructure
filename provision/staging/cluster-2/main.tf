module "cluster" {
  source = "../../base"
  cluster_name = "cluster-2"
  flux_version = "v2.4.0"
  environment = "staging"
}

module "cluster" {
  source = "../../base"
  cluster_name = "cluster-2"
  flux_version = "v2.4.0"
  environment = "staging"
}

output "kubeconfig" {
  value = module.cluster.kubeconfig
  sensitive = true
}

output "talosconfig" {
  value = module.cluster.talosconfig
  sensitive = true
}

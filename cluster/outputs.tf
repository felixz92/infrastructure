output "kubeconfig_data" {
  sensitive = true
  depends_on = [module.kube-hetzner]
  value = module.kube-hetzner.kubeconfig_data
}

output "kubeconfig" {
  sensitive = true
  depends_on = [module.kube-hetzner]
  value = module.kube-hetzner.kubeconfig
}

output "loadbalancer_ipv4" {
  depends_on = [module.kube-hetzner]
  value = module.kube-hetzner.ingress_public_ipv4
}

output "loadbalancer_ipv6" {
  depends_on = [module.kube-hetzner]
  value = module.kube-hetzner.ingress_public_ipv6
}

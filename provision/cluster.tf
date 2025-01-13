module "kubernetes" {
  source  = "hcloud-k8s/kubernetes/hcloud"
  version = "0.14.1"

  talos_version = "v1.8.3"
  talos_ccm_version = "v1.8.1"
  kubernetes_version = "v1.30.5"
  hcloud_ccm_helm_version = "1.21.0"
  hcloud_csi_helm_version = "2.11.0"
  cilium_helm_version = "1.16.5"
  metrics_server_helm_version = "3.12.2"
  cert_manager_helm_version = "v1.15.4"
  prometheus_operator_crds_version = "v0.79.2"

  cluster_name = var.cluster_name
  hcloud_token = var.hcloud_token


  # Export configs for Talos and Kube API access
  cluster_kubeconfig_path  = "kubeconfig"
  cluster_talosconfig_path = "talosconfig"
  firewall_use_current_ipv6 = false
  cluster_delete_protection = false

  network_ipv4_cidr = var.network_ipv4_cidr
 // firewall_extra_rules = []

  control_plane_public_vip_ipv4_enabled = false

  # Optional Ingress Controller and Cert Manager
  cert_manager_enabled  = true
  ingress_nginx_enabled = false

  control_plane_nodepools = [
    { name = "control", type = "cax21", location = "fsn1", count = 1 }
  ]
  worker_nodepools = [
    { name = "worker-fsn", type = "cax21", location = "fsn1", count = 1 },
    { name = "worker-nbg", type = "cax21", location = "nbg1", count = 1 }
  ]
  cluster_autoscaler_nodepools = []

  control_plane_config_patches = [
    {"op": "replace", "path": "/cluster/allowSchedulingOnControlPlanes", "value": true}
  ]

  talos_image_extensions = []
  //talos_registries = {} // TODO

  //kube_api_hostname = "kube.${var.base_domain}"

  hcloud_load_balancer_location = "nbg1"

  //cilium_helm_values = {}
  cilium_service_monitor_enabled = true
  cilium_hubble_enabled = true
  cilium_hubble_relay_enabled = true
  cilium_hubble_ui_enabled = true

  metrics_server_schedule_on_control_plane = true
  metrics_server_replicas = 1

  cert_manager_helm_values = yamldecode(file("values/cert-manager.yaml"))
}

data "http" "kube_api_health" {
  url      = "${module.kubernetes.kubeconfig_data.server}/version"
  insecure = true

  retry {
    attempts     = 60
    min_delay_ms = 5000
    max_delay_ms = 5000
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 401
      error_message = "Status code invalid"
    }
  }

  depends_on = [module.kubernetes]
}
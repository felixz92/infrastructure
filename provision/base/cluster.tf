module "kubernetes" {
  source  = "hcloud-k8s/kubernetes/hcloud"
  version = "0.18.0"

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
  hcloud_token = data.onepassword_item.hcloud_token.password


  # Export configs for Talos and Kube API access
  cluster_kubeconfig_path  = "kubeconfig"
  cluster_talosconfig_path = "talosconfig"
  firewall_use_current_ipv6 = false
  cluster_delete_protection = false

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
  talos_registries = {
    mirrors = {
      "xpkg.upbound.io" = {
        endpoints = [
          "https://registry.fzx-infra.dev/v2/xpkg.upbound.io"
        ]
        overridePath= true
      }
      "docker.io" = {
        endpoints = [
          "https://registry.fzx-infra.dev/v2/docker.io"
        ]
        overridePath= true
      }
      "registry.k8s.io" = {
        endpoints = [
          "https://registry.fzx-infra.dev/v2/registry.k8s.io"
        ]
        overridePath= true
      }
      "ghcr.io" = {
        endpoints = [
          "https://registry.fzx-infra.dev/v2/ghcr.io"
        ]
        overridePath= true
      }
      "quay.io" = {
        endpoints = [
          "https://registry.fzx-infra.dev/v2/quay.io"
        ]
        overridePath= true
      }
    }
    config = {
      "registry.fzx-infra.dev" = {
        auth = {
          username = data.onepassword_item.zot_pull_user.username
          password = data.onepassword_item.zot_pull_user.password
        }
      }
    }
  }

  //kube_api_hostname = "kube.${var.base_domain}"

  hcloud_load_balancer_location = "nbg1"

  //cilium_helm_values = {}
  cilium_service_monitor_enabled = true
  cilium_hubble_enabled = true
  cilium_hubble_relay_enabled = true
  cilium_hubble_ui_enabled = true

  metrics_server_schedule_on_control_plane = true
  metrics_server_replicas = 1

  cert_manager_helm_values = yamldecode(file("${path.module}/values/cert-manager.yaml"))

  longhorn_enabled = true
  longhorn_helm_values = yamldecode(file("${path.module}/values/longhorn.yaml"))
  longhorn_helm_version = "v1.8.0"
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

output "kubeconfig" {
  value = module.kubernetes.kubeconfig
  sensitive = true
}

output "talosconfig" {
  value = module.kubernetes.talosconfig
  sensitive = true
}

# provider "github" {
#   owner = data.onepassword_item.github_token.username
#   token = data.onepassword_item.github_token.username
# }
#
provider "kubernetes" {
  host = module.kubernetes.kubeconfig_data.server
  client_certificate = module.kubernetes.kubeconfig_data.cert
  cluster_ca_certificate = module.kubernetes.kubeconfig_data.ca
  client_key = module.kubernetes.kubeconfig_data.key
}

provider "flux" {
  kubernetes = {
    host = module.kubernetes.kubeconfig_data.server
    client_certificate = module.kubernetes.kubeconfig_data.cert
    cluster_ca_certificate = module.kubernetes.kubeconfig_data.ca
    client_key = module.kubernetes.kubeconfig_data.key
  }

  git = {
    url  = "ssh://git@github.com/${data.github_repository.main.full_name}.git"
    branch = var.branch
    ssh = {
      username    = "git"
      private_key = tls_private_key.main.private_key_pem
    }
  }
}

data "github_repository" "main" {
  name = var.repository_name
}

locals {
  target_path = "clusters/${var.cluster_name}"
}

resource "tls_private_key" "main" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "github_repository_deploy_key" "main" {
  title      = "flux-${var.cluster_name}"
  repository = data.github_repository.main.id
  key        = tls_private_key.main.public_key_openssh
  read_only  = false
}

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository_deploy_key.main, data.http.kube_api_health]
  path = local.target_path
  version = var.flux_version
}

resource "kubernetes_namespace" "external_secrets" {
  depends_on = [flux_bootstrap_git.this]
  metadata {
    name = "external-secrets"
  }
}

resource "kubernetes_secret" "op_credentials" {
    depends_on = [kubernetes_namespace.external_secrets]
    metadata {
      name = "op-credentials"
      namespace = kubernetes_namespace.external_secrets.metadata.0.name
    }
    data = {
      "1password-credentials.json" = data.onepassword_item.op_credentials_json.file[0].content_base64
    }
}

resource "kubernetes_secret" "op_connect_token" {
    depends_on = [kubernetes_namespace.external_secrets]
    metadata {
      name = "op-connect-token"
      namespace = kubernetes_namespace.external_secrets.metadata.0.name
    }
    data = {
      "onepassword-connect-token" = data.onepassword_item.op_connect_token.password
    }
}

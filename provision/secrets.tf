provider "doppler"  {
  doppler_token = var.doppler_token
}

variable "doppler_tokens" {
  type = list(object({
    config = string
    namespaces = list(string)
    project = string
  }))
  default = [
    {
      config = "robusta"
      namespaces = ["robusta"]
      project = "infrastructure"
    },
    {
      config = "authentik"
      namespaces = ["authentik"]
      project = "infrastructure"
    },
#     {
#       config = "github-application"
#       namespaces = ["flux-system"]
#       project = "infrastructure"
#     },
#     {
#       config = "google-oauth"
#       namespaces = ["flux-system"]
#       project = "infrastructure"
#     },
    {
      config = "grafana-oauth"
      namespaces = ["observability"]
      project = "infrastructure"
    },
    {
      config = "wego"
      namespaces = ["weaveworks"]
      project = "infrastructure"
    },
#     {
#       config = "postgres"
#       namespaces = ["authentik", "postgres-operator"]
#       project = "infrastructure"
#     },
    {
      config = "ocis"
      namespaces = ["ocis"]
      project = "infrastructure"
    }
  ]
}

locals {
  tokens = flatten([
    for cfg in var.doppler_tokens : [
      for n in cfg.namespaces : {
        config = cfg.config
        name = "${cfg.config}_${n}"
        project = cfg.project
      }
    ]
  ])
}

resource "doppler_service_token" "service_token" {
  for_each = {
    for index, cfg in local.tokens:
      cfg.name => cfg
  }

  project = each.value.project
  config = "${var.environment}_${each.value.config}"
  name = each.key
  access = "read"
}

resource "kubernetes_secret" "doppler_monitoring_token" {
  for_each = {
    for index, n in doppler_service_token.service_token:
        n.name => {
          namespace = split("_", n.name)[1]
          cfg = split("_", n.name)[0]
          key = n.key
        }
  }

  metadata {
    name = "doppler-token-auth-api-${each.value.cfg}"
    namespace = each.value.namespace
  }
  data = {
    dopplerToken = each.value.key
  }

  depends_on = [flux_bootstrap_git.this]
}

locals {
  secrets = flatten([
    for key, obj in kubernetes_secret.doppler_monitoring_token: [
      for key, meta in obj.metadata: {
        name      = meta.name
        namespace = meta.namespace
      }
    ]
  ])
}

resource "kubernetes_manifest" "secret_store" {
  for_each = {
    for index, n in local.secrets:
      "${n.namespace}_${n.name}" =>  n
  }

  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "SecretStore"
    "metadata" = {
      "name" = each.value.name
      "namespace" = each.value.namespace
    }
    "spec" = {
      "provider" = {
        "doppler" = {
          "auth" = {
            "secretRef" = {
              "dopplerToken" = {
                "name" = each.value.name
                "key" = "dopplerToken"
              }
            }
          }
        }
      }
    }
  }
}

import k8s.apimachinery.pkg.apis.meta.v1
import crossplane_authentik.v1alpha1 as authentik
import json

# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_providerId = ocds[oxr.metadata.name + "-proxy"]?.Resource?.status?.atProvider?.id

outpost: authentik.Outpost = {
    metadata.name = oxr.metadata.name + "-outpost"
    spec = {
        forProvider = {
            name = oxr.metadata.name
            "type" = "proxy"
            serviceConnectionRef.name = "local"
            if _providerId:
                protocolProviders = [int(_providerId)]
            config = json.encode({
                "authentik_host": "http://authentik-server/"
                "authentik_host_insecure": bool("true")
                "authentik_host_browser": "https://authentik.staging-fzx-infra.dev/"
                "log_level": "info"
                "object_naming_template": "ak-outpost-%(name)s"
                "kubernetes_replicas": 1
                "kubernetes_namespace": "authentik"
                "kubernetes_service_type": "ClusterIP"
                "kubernetes_disabled_components": ["ingress","middleware"]
            })
        }
        providerConfigRef = {
            name = "authentik-provider"
        }
    }
}

items = [outpost]

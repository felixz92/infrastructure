import crossplane_authentik.provider.v1alpha1 as provider
import crossplane_authentik.policy.v1alpha1 as policy
import crossplane_authentik.v1alpha1 as authentik
import json

schema object:
    _name: str
    _manifest: any
    _readiness: str
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = {
        name = _name
    }
    spec = {
        deletionPolicy = "Delete"
        readiness.policy = _readiness
        forProvider.manifest = _manifest
        forProvider.manifest.metadata.name = _name
        forProvider.manifest.metadata.namespace = _namespace
    }

# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_claimName = oxr?.metadata?.labels?["crossplane.io/claim-name"]
_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

_resourceName = _claimName + "-" + _namespace

_providerId = ocds[_resourceName + "-proxy"]?.Resource?.status?.atProvider?.id
_appId = ocds[_resourceName + "-application"]?.Resource?.status?.atProvider?.uuid
_groupId = option("params").ctx["apiextensions.crossplane.io/extra-resources"]?.adminGroup[0]?.status?.atProvider?.id
_split = oxr.spec.externalHost.split(".")
_baseDomain = "${_split[1]}.${_split[2]}"

proxy: provider.Proxy = {
    metadata.name = _resourceName + "-proxy"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        forProvider = {
            name = _resourceName
            mode = "forward_single"
            accessTokenValidity = "hours=24"
            authorizationFlowRef = {
                name = "default-provider-authorization-implicit-consent"
            }
            invalidationFlowRef = {
                name = "default-provider-invalidation-flow"
            }
            externalHost = "https://" + oxr.spec.externalHost
        }
    }
}

application: authentik.Application = {
    metadata.name = _resourceName + "-application"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        forProvider = {
            name = _resourceName
            if _providerId:
                protocolProvider = int(_providerId)
            metaIcon = oxr.spec.icon
            metaDescription = oxr.spec.description
            metaLaunchUrl = "https://${oxr.spec.externalHost}/${oxr.spec.launchUrl}"
            metaPublisher = oxr.spec.publisher
        }
    }
}

outpost: authentik.Outpost = {
    metadata.name = _resourceName + "-outpost"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        forProvider = {
            name = _resourceName
            "type" = "proxy"
            serviceConnectionRef.name = "local"
            if _providerId:
                protocolProviders = [int(_providerId)]
            config = json.encode({
                "authentik_host": "http://authentik-server/"
                "authentik_host_insecure": True
                "authentik_host_browser": "https://authentik.${_baseDomain}/"
                "log_level": "info"
                "object_naming_template": "ak-outpost-%(name)s"
                "kubernetes_replicas": 1
                "kubernetes_namespace": "authentik"
                "kubernetes_service_type": "ClusterIP"
                "kubernetes_disabled_components": ["ingress", "middleware"]
            })
        }
    }
}

binding: policy.Binding {
    metadata.name = _resourceName + "-admin-binding"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec.forProvider = {
        target = _appId
        group = _groupId
        enabled = True
        order: 0
    }
}

middleware: object = {
    _name = _resourceName + "-middleware"
    _readiness = "SuccessfulCreate"
    _manifest = {
        apiVersion: "traefik.io/v1alpha1"
        kind: "Middleware"
        spec.forwardAuth = {
            trustForwardHeader = True
            address = "http://ak-outpost-{}.authentik:9000/outpost.goauthentik.io/auth/traefik".format(_claimName)
            authResponseHeaders = [
                "X-authentik-username"
                "X-authentik-groups"
                "X-authentik-entitlements"
                "X-authentik-email"
                "X-authentik-name"
                "X-authentik-uid"
                "X-authentik-jwt"
                "X-authentik-meta-jwks"
                "X-authentik-meta-outpost"
                "X-authentik-meta-provider"
                "X-authentik-meta-app"
                "X-authentik-meta-version"
            ]
        }
    }
}

ingress: object {
    _name = _resourceName + "-https"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion = "custom.fzx.dev/v1alpha1"
        kind = "HTTPSIngressClaim"
        spec = {
            externalHost = oxr.spec.externalHost
            backendService = {
                name = oxr.spec.backendService.name
                port = oxr.spec.backendService.port
            }
            clusterName = oxr.spec.clusterName
            middleware = [
                {
                    "type" = "ExtensionRef"
                    extensionRef = {
                        name = _resourceName + "-middleware"
                        group = "traefik.io"
                        kind = "Middleware"
                    }
                }
            ]
        }
    }
}

print("ingress: " + json.encode(ingress))

items = [proxy, application, outpost,binding, middleware, ingress]

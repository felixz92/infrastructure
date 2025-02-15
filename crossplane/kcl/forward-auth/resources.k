import k8s.apimachinery.pkg.apis.meta.v1
import crossplane_authentik.provider.v1alpha1 as provider
import crossplane_authentik.policy.v1alpha1 as policy
import crossplane_authentik.v1alpha1 as authentik
import json

# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_claimName = oxr?.metadata?.labels?["crossplane.io/claim-name"]

_providerId = ocds[_claimName + "-proxy"]?.Resource?.status?.atProvider?.id
_appId = ocds[_claimName + "-application"]?.Resource?.status?.atProvider?.uuid
_groupId = option("params").ctx["apiextensions.crossplane.io/extra-resources"]?.adminGroup[0]?.status?.atProvider?.id
_split = oxr.spec.externalHost.split(".")
_baseDomain = "${_split[1]}.${_split[2]}"

proxy: provider.Proxy = {
    metadata.name = _claimName + "-proxy"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        forProvider = {
            name = _claimName
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
    metadata.name = _claimName + "-application"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        forProvider = {
            name = _claimName
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
    metadata.name = _claimName + "-outpost"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        forProvider = {
            name = _claimName
            "type" = "proxy"
            serviceConnectionRef.name = "local"
            if _providerId:
                protocolProviders = [int(_providerId)]
            config = json.encode({
                "authentik_host": "http://authentik-server/"
                "authentik_host_insecure": True
                "authentik_host_browser": "https://authentik.${__baseDomain}/"
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
    metadata.name = _claimName + "-binding"
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

_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

middleware: object = {
    _name = _claimName + "-middleware"
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
    _name = oxr.metadata.name + "-ingress"
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
                        name = _claimName + "-middleware"
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

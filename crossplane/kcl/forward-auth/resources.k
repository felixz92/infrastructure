import k8s.apimachinery.pkg.apis.meta.v1
import crossplane_authentik.provider.v1alpha1 as provider
import crossplane_authentik.policy.v1alpha1 as policy
import crossplane_authentik.v1alpha1 as authentik
import json

# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_providerId = ocds[oxr.metadata.name + "-proxy"]?.Resource?.status?.atProvider?.id
_appId = ocds[oxr.metadata.name + "-application"]?.Resource?.status?.atProvider?.uuid
_groupId = option("params").ctx["apiextensions.crossplane.io/extra-resources"]?.adminGroup[0]?.status?.atProvider?.id

proxy: provider.Proxy = {
    metadata.name = oxr.metadata.name + "-proxy"
    spec = {
        forProvider = {
            name = oxr.metadata.name
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
        providerConfigRef = {
            name = "authentik-provider"
        }
    }
}

application: authentik.Application = {
    metadata.name = oxr.metadata.name + "-application"
    spec = {
        forProvider = {
            name = oxr.metadata.name
            if _providerId:
                protocolProvider = int(_providerId)
            metaIcon = oxr.spec.icon
            metaDescription = oxr.spec.description
            metaLaunchUrl = "https://" + oxr.spec.externalHost
            metaPublisher = oxr.spec.publisher
        }
        providerConfigRef = {
            name = "authentik-provider"
        }
    }
}

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
                "authentik_host_insecure": True
                "authentik_host_browser": "https://authentik.staging-fzx-infra.dev/"
                "log_level": "info"
                "object_naming_template": "ak-outpost-%(name)s"
                "kubernetes_replicas": 1
                "kubernetes_namespace": "authentik"
                "kubernetes_service_type": "ClusterIP"
                "kubernetes_disabled_components": ["ingress", "middleware"]
            })
        }
        providerConfigRef = {
            name = "authentik-provider"
        }
    }
}

binding: policy.Binding {
    metadata.name = oxr.metadata.name + "-binding"
    providerConfigRef.name = "authentik-provider"
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
        providerConfigRef.name = "kubernetes-provider"
        deletionPolicy = "Delete"
        readiness.policy = _readiness
        forProvider.manifest = _manifest
        forProvider.manifest.metadata.name = _name
        forProvider.manifest.metadata.namespace = _namespace
    }

_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

middleware: object = {
    _name = oxr.metadata.name + "-middleware"
    _readiness = "SuccessfulCreate"
    _manifest = {
        apiVersion: "traefik.io/v1alpha1"
        kind: "Middleware"
        spec.forwardAuth = {
            trustForwardHeader = True
            address = "http://ak-outpost-{}.authentik:9000/outpost.goauthentik.io/auth/traefik".format(oxr.metadata.name)
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

cert: object = {
    _name = oxr.metadata.name + "-ingress-cert"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion: "cert-manager.io/v1"
        kind: "Certificate"
        spec.secretName = oxr.metadata.name + "-ingress-cert"
        spec.dnsNames = [oxr.spec.externalHost]
        spec.issuerRef = {
            name = "dns-clusterissuer"
            kind = "ClusterIssuer"
        }
    }
}

gateway: object = {
    _name = oxr.metadata.name + "-gateway"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion = "gateway.networking.k8s.io/v1"
        kind = "Gateway"
        spec.gatewayClassName = "traefik"
        spec.listeners = [{
            name = "websecure"
            port = 8443
            "protocol" = "HTTPS"
            hostname = oxr.spec.externalHost
            tls.certificateRefs = [{
                name = oxr.metadata.name + "-ingress-cert"
            }]
        }]
    }
}

route: object = {
    _name = oxr.metadata.name + "-route"
    _readiness = "SuccessfulCreate"
    _manifest = {
        apiVersion = "gateway.networking.k8s.io/v1"
        kind = "HTTPRoute"
        spec.parentRefs = [{name = oxr.metadata.name + "-gateway"}]
        spec.hostnames = [oxr.spec.externalHost]
        spec.rules = [{
            matches = [{
                path = {"type" = "PathPrefix", value = "/"}
            }]
            backendRefs = [{
                name = oxr.spec.backendService.name
                port = oxr.spec.backendService.port
                weight = 1
            }]
            filters = [
                {
                    "type" = "ExtensionRef"
                    extensionRef = {
                        name = oxr.metadata.name + "-middleware"
                        group = "traefik.io"
                        kind = "Middleware"
                    }
                }
            ]
        }]
    }
}

items = [proxy, application, outpost, middleware, cert, gateway, route]

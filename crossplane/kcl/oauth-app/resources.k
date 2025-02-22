import crossplane_authentik.provider.v1alpha1 as provider
import crossplane_authentik.policy.v1alpha1 as policy
import crossplane_authentik.v1alpha1 as authentik

schema object:
    _name: str
    _manifest: any
    _readiness: str
    _references?: any
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = {
        name = _name
    }
    spec = {
        if _references:
            references = _references
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

_providerId = ocds[_resourceName + "-provider"]?.Resource?.status?.atProvider?.id
_appId = ocds[_resourceName + "-application"]?.Resource?.status?.atProvider?.uuid
_groupId = option("params").ctx["apiextensions.crossplane.io/extra-resources"]?.adminGroup[0]?.status?.atProvider?.id
_certId = ocds[_resourceName + "-cert-pair"]?.Resource?.status?.atProvider?.id

oauth: provider.OAuth2 = {
    metadata.name = _resourceName + "-provider"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        writeConnectionSecretToRef.name = _claimName + "-client-secret"
        writeConnectionSecretToRef.namespace = _namespace
        forProvider = {
            name = _claimName
            clientId = _claimName
            signingKey = _certId
            authorizationFlowRef.name = "default-provider-authorization-implicit-consent"
            invalidationFlowRef.name =  "default-provider-invalidation-flow"
            propertyMappingsRefs = [
                { name = "openid-email" }
                { name = "openid-openid" }
                { name = "openid-profile" }
            ]
            allowedRedirectUris = [
                {
                   "matching_mode" = "strict"
                   "url" = "https://" + oxr.spec.externalHost +  oxr.spec.redirectURL
                }
            ]
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
            name = _claimName
            if _providerId:
                protocolProvider = int(_providerId)
            metaIcon = oxr.spec.icon
            metaDescription = oxr.spec.description
            metaLaunchUrl = "https://" + oxr.spec.externalHost
            metaPublisher = oxr.spec.publisher
        }
    }
}

binding: policy.Binding {
    metadata.name = _resourceName + "-binding"
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

signingKey: object = {
    _name = _resourceName + "-signing-cert"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion: "cert-manager.io/v1"
        kind: "Certificate"
        spec.secretName = _claimName + "-signing-cert"
        spec.commonName = _claimName + "-signing"
        spec.usages = ["signing"]
        spec.privateKey = {
            algorithm = "ECDSA"
            size = 256
        }
        spec.issuerRef = {
            name = "cert-authority-issuer"
            kind = "ClusterIssuer"
        }
    }
}

certPair: authentik.CertificateKeyPair = {
    metadata.name = _resourceName + "-cert-pair"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec.forProvider.name = _claimName
    spec.forProvider.certificateDataSecretRef = {
        name = _claimName + "-signing-cert"
        key = "tls.crt"
        namespace= _namespace
    }
    spec.forProvider.keyDataSecretRef = {
        name = _claimName + "-signing-cert"
        key = "tls.key"
        namespace= _namespace
    }
}

ingress: object {
    _name = _resourceName + "-ingress"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion = "custom.fzx.dev/v1alpha1"
        kind = "HTTPSIngressClaim"
        spec = {
            clusterName = oxr.spec.clusterName
            externalHost = oxr.spec.externalHost
            backendService = {
                name = oxr.spec.backendService.name
                port = oxr.spec.backendService.port
            }
            if oxr.spec.headers.csp:
                middleware = [
                    {
                        "type" = "ResponseHeaderModifier"
                        responseHeaderModifier = {
                            add = [
                                {
                                    name = "Content-Security-Policy"
                                    value = oxr.spec.headers.csp
                                }
                            ]
                        }
                    }
                ]
        }
    }
}

_adminBinding = oxr.spec.adminBinding

items = [
    oauth,
    application,
    signingKey,
    certPair,
    ingress,
    if _adminBinding:
        binding
]

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
        providerConfigRef.name = "kubernetes-provider"
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
_providerId = ocds[_claimName + "-provider"]?.Resource?.status?.atProvider?.id
_appId = ocds[_claimName + "-application"]?.Resource?.status?.atProvider?.uuid
_groupId = option("params").ctx["apiextensions.crossplane.io/extra-resources"]?.adminGroup[0]?.status?.atProvider?.id
_certId = ocds[_claimName + "-cert-pair"]?.Resource?.status?.atProvider?.id

_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

oauth: provider.OAuth2 = {
    metadata.name = _claimName + "-provider"
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
        providerConfigRef = {
            name = "authentik-provider"
        }
    }
}

application: authentik.Application = {
    metadata.name = _claimName + "-application"
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
        providerConfigRef = {
            name = "authentik-provider"
        }
    }
}

binding: policy.Binding {
    metadata.name = oxr.metadata.name + "-binding"
    spec.providerConfigRef.name = "authentik-provider"
    spec.forProvider = {
        target = _appId
        group = _groupId
        enabled = True
        order: 0
    }
}

_signingKey: object = {
    _name = _claimName + "-signing-cert"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion: "cert-manager.io/v1"
        kind: "Certificate"
        spec.secretName = _claimName + "-signing-cert"
        spec.commonName = _claimName + "-signing"
        spec.usages = ["signing"]
        spec.privateKey = {
            algorithm = "EDCSA"
            size = 256
        }
        spec.issuerRef = {
            name = "cert-authority-issuer"
            kind = "ClusterIssuer"
        }
    }
}

certPair: authentik.CertificateKeyPair = {
    metadata.name = _claimName + "-cert-pair"
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


_adminBinding = oxr.spec.adminBinding

items = [
    oauth,
    application,
    if _adminBinding:
        binding
]

import crossplane_authentik.provider.v1alpha1 as provider
import crossplane_authentik.policy.v1alpha1 as policy
import crossplane_authentik.v1alpha1 as authentik

# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_claimName = oxr?.metadata?.labels?["crossplane.io/claim-name"]
_providerId = ocds[_claimName + "-provider"]?.Resource?.status?.atProvider?.id
_appId = ocds[_claimName + "-application"]?.Resource?.status?.atProvider?.uuid
_groupId = option("params").ctx["apiextensions.crossplane.io/extra-resources"]?.adminGroup[0]?.status?.atProvider?.id

_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

oauth: provider.OAuth2 = {
    metadata.name = _claimName + "-provider"
    spec = {
        writeConnectionSecretToRef.name = _claimName + "-client-secret"
        writeConnectionSecretToRef.namespace = _namespace
        forProvider = {
            name = _claimName
            clientId = _claimName
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

_adminBinding = oxr.spec.adminBinding

items = [
    oauth,
    application,
    if _adminBinding:
        binding
]

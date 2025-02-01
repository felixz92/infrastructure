import k8s.apimachinery.pkg.apis.meta.v1
import crossplane_authentik.v1alpha1 as authentik

# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_providerId = ocds[oxr.metadata.name + "-proxy"]?.Resource?.status?.atProvider?.id

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

items = [application]

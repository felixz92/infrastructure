import k8s.apimachinery.pkg.apis.meta.v1
import crossplane_authentik.provider.v1alpha1 as authentik

# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

proxy: authentik.Proxy = {
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

items = [proxy]

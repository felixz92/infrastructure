import crossplane.v1 as xpv1
import file
import manifests

forwardauthComposition = xpv1.Composition {
    metadata.name = "https-ingress"
    spec = {
        compositeTypeRef: {
            apiVersion = "custom.fzx.dev/v1alpha1"
            kind = "xHTTPSIngress"
        }
        mode: "Pipeline"
        pipeline: [
            {
                step = "provider"
                functionRef.name = "crossplane-contrib-function-kcl"
                input = {
                    apiVersion = "krm.kcl.dev/v1alpha1"
                    kind: "KCLInput"
                    spec.source = file.read("kcl/https-ingress/resources.k")
                    spec.dependencies = "\n".join([
                        'crossplane_authentik = { oci = "oci://ghcr.io/felixz92/crossplane-provider-authentik/crossplane-authetik", tag = "0.5.0", version = "0.5.0" }'
                        'crossplane_cloudflare = { oci = "oci://ghcr.io/felixz92/crossplane-provider-cloudflare/crossplane-cloudflare", tag = "0.1.0", version = "0.1.0" }'
                    ])
                }
            }
            {
                step = "automatically-detect-ready-composed-resources"
                functionRef.name = "crossplane-contrib-function-auto-ready"
            }
        ]
    }
}

items = [forwardauthComposition]
manifests.yaml_stream(items)
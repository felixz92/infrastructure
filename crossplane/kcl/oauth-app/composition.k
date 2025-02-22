import crossplane.v1 as xpv1
import file
import manifests

oauthComposition = xpv1.Composition {
    metadata.name = "oauth-application"
    spec = {
        compositeTypeRef: {
            apiVersion = "applications.authentik.crossplane.io/v1alpha1"
            kind = "OAuth"
        }
        mode: "Pipeline"
        pipeline: [
            {
                step = "pull-group"
                functionRef.name = "crossplane-contrib-function-extra-resources"
                input = {
                    apiVersion = "extra-resources.fn.crossplane.io/v1beta1"
                    kind: "Input"
                    spec = {
                        extraResources = [
                           {
                               apiVersion = "directory.authentik.crossplane.io/v1alpha1"
                               kind = "Group"
                               into: "adminGroup"
                               $type = "Reference"
                               ref.name = "cluster-admins"
                           }
                        ]
                    }
                }
            }
            {
                step = "provider"
                functionRef.name = "crossplane-contrib-function-kcl"
                input = {
                    apiVersion = "krm.kcl.dev/v1alpha1"
                    kind: "KCLInput"
                    spec.source = file.read("kcl/oauth-app/resources.k")
                    spec.dependencies = "\n".join([
                        'crossplane_authentik = { oci = "oci://ghcr.io/felixz92/crossplane-provider-authentik/crossplane-authetik", tag = "0.5.0", version = "0.5.0" }'
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

items = [oauthComposition]
manifests.yaml_stream(items)

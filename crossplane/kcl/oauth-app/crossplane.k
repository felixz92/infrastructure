import crossplane.v1 as xpv1
import file
import manifests

oauthDefinition = xpv1.CompositeResourceDefinition {
    metadata.name = "oauths.applications.authentik.crossplane.io"
    spec = {
        group: "applications.authentik.crossplane.io"
        names = {
            kind = "OAuth"
            plural = "oauths"
        }
        claimNames = {
            kind = "OAuthClaim"
            plural = "oauthclaims"
        }
        defaultCompositeDeletePolicy = "Foreground"
        versions = [
            {
                name = "v1alpha1"
                served = True
                referenceable = True
                $schema = {
                    openAPIV3Schema = {
                        $type = "object"
                        properties = {
                            spec = {
                                $type = "object"
                                properties = {
                                    externalHost = { $type = "string" }
                                    icon = { $type = "string" }
                                    description = { $type = "string" }
                                    publisher = { $type = "string" }
                                    redirectURL = { $type = "string" }
                                    adminBinding = {
                                        $type = "boolean"
                                        default = False
                                    }
                                }
                                required = ["externalHost", "redirectURL"]
                            }
                        }
                    }
                }
            }
        ]
    }
}

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
                    spec.source = file.read("crossplane/kcl/oauth-app/resources.k")
                    spec.dependencies = "\n".join([
                        'crossplane_authentik = { oci = "oci://ghcr.io/felixz92/crossplane-provider-authentik/crossplane-authetik", tag = "0.3.0", version = "0.3.0" }'
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

items = [oauthDefinition, oauthComposition]
manifests.yaml_stream(items)
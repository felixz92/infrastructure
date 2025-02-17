import crossplane.v1 as xpv1
import file
import manifests

forwardauthDefinition = xpv1.CompositeResourceDefinition {
    metadata.name = "forwardauths.applications.authentik.crossplane.io"
    spec = {
        group: "applications.authentik.crossplane.io"
        names = {
            kind = "ForwardAuth"
            plural = "forwardauths"
        }
        claimNames = {
            kind = "ForwardAuthClaim"
            plural = "forwardauthclaims"
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
                                    clusterName = { $type = "string" }
                                    launchUrl = { $type = "string" }
                                    backendService = {
                                        $type = "object"
                                        properties = {
                                            name = { $type = "string" }
                                            port = { $type = "integer" }
                                        }
                                    }
                                }
                                required = ["externalHost", "backendService", "clusterName"]
                            }
                        }
                    }
                }
            }
        ]
    }
}

forwardauthComposition = xpv1.Composition {
    metadata.name = "forward-auth-application"
    spec = {
        compositeTypeRef: {
            apiVersion = "applications.authentik.crossplane.io/v1alpha1"
            kind = "ForwardAuth"
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
                    spec.source = file.read("crossplane/kcl/forward-auth/resources.k")
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

items = [forwardauthDefinition, forwardauthComposition]
manifests.yaml_stream(items)
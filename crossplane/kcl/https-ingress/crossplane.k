import crossplane.v1 as xpv1
import file
import manifests

forwardauthDefinition = xpv1.CompositeResourceDefinition {
    metadata.name = "xhttpsingresses.custom.fzx.dev"
    spec = {
        group: "custom.fzx.dev"
        names = {
            kind = "xHTTPSIngress"
            plural = "xhttpsingresses"
        }
        claimNames = {
            kind = "HTTPSIngressClaim"
            plural = "httpsingressclaims"
        }
        defaultCompositeDeletePolicy = "Foreground"
        versions = [
            {
                additionalPrinterColumns = [
                    {
                        name = "host"
                        $type = "string"
                        jsonPath = ".spec.externalHost"
                    }
                    {
                        name = "service"
                        $type = "string"
                        jsonPath = ".spec.backendService.name"
                    }
                ]
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
                                    externalHosts = { $type = "array", items = { $type = "string" } }
                                    backendService = {
                                        $type = "object"
                                        properties = {
                                            name = { $type = "string" }
                                            port = { $type = "integer" }
                                        }
                                    }
                                    middleware = {
                                        $type = "object"
                                    }
                                }
                                required = ["externalHost", "backendService"]
                            }
                        }
                    }
                }
            }
        ]
    }
}

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
                    spec.source = file.read("crossplane/kcl/https-ingress/resources.k")
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
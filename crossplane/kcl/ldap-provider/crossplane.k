import crossplane.v1 as xpv1
import file
import manifests

oauthDefinition = xpv1.CompositeResourceDefinition {
    metadata.name = "ldapproviders.applications.authentik.crossplane.io"
    spec = {
        group: "applications.authentik.crossplane.io"
        names = {
            kind = "LDAPProvider"
            plural = "ldapproviders"
        }
        claimNames = {
            kind = "LDAPProviderClaim"
            plural = "ldapproviderclaims"
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
    metadata.name = "ldap-provider"
    spec = {
        compositeTypeRef: {
            apiVersion = "applications.authentik.crossplane.io/v1alpha1"
            kind = "LDAPProvider"
        }
        mode: "Pipeline"
        pipeline: [
            {
                step = "provider"
                functionRef.name = "crossplane-contrib-function-kcl"
                input = {
                    apiVersion = "krm.kcl.dev/v1alpha1"
                    kind: "KCLInput"
                    spec.source = file.read("crossplane/kcl/ldap-provider/resources.k")
                    spec.dependencies = "\n".join([
                        'crossplane_authentik = { oci = "oci://ghcr.io/felixz92/crossplane-provider-authentik/crossplane-authetik", tag = "0.4.1", version = "0.4.1" }'
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
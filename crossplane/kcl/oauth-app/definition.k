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
                                    clusterName = { $type = "string" }
                                    adminBinding = {
                                        $type = "boolean"
                                        default = False
                                    }
                                    headers = {
                                        $type = "object"
                                        properties = {
                                            csp = { $type = "string" }
                                        }
                                    }
                                    backendService = {
                                        $type = "object"
                                        properties = {
                                            name = { $type = "string" }
                                            port = { $type = "integer" }
                                        }
                                    }
                                }
                                required = ["externalHost", "redirectURL", "backendService", "clusterName"]
                            }
                        }
                    }
                }
            }
        ]
    }
}

items = [oauthDefinition]
manifests.yaml_stream(items)
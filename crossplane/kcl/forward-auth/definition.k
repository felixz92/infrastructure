import crossplane.v1 as xpv1
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

items = [forwardauthDefinition]
manifests.yaml_stream(items)

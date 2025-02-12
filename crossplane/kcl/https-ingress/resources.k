import crossplane_cloudflare.dns.v1alpha1 as dns
# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_claimName = oxr?.metadata?.labels?["crossplane.io/claim-name"]
_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

schema object:
    _name: str
    _manifest: any
    _readiness: str
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = {
        name = _name
    }
    spec = {
        providerConfigRef.name = "kubernetes-provider"
        deletionPolicy = "Delete"
        readiness.policy = _readiness
        forProvider.manifest = _manifest
        forProvider.manifest.metadata.name = _name
        forProvider.manifest.metadata.namespace = _namespace
    }

cert: object = {
    _name = oxr.metadata.name + "-ingress-cert"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion: "cert-manager.io/v1"
        kind: "Certificate"
        metadata.labels = {
            "velero.io/include" = "true"
        }
        spec.secretName = oxr.metadata.name + "-ingress-cert"
        spec.secretTemplate = {
            labels = {
                "velero.io/include" = "true"
            }
        }
        spec.dnsNames = map i,host in oxr.spec.externalHosts {
            host.name
        }
        spec.issuerRef = {
            name = "dns-clusterissuer"
            kind = "ClusterIssuer"
        }
    }
}

gateway: object = {
    _name = oxr.metadata.name + "-gateway"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion = "gateway.networking.k8s.io/v1"
        kind = "Gateway"
        spec.gatewayClassName = "traefik"
        spec.listeners = map i,host in oxr.spec.externalHosts {{
            name = "websecure-" + str(i)
            port = 8443
            $protocol = "HTTPS"
            hostname = host.name
            tls.certificateRefs = [{
                name = oxr.metadata.name + "-ingress-cert"
            }]
        }}
    }
}

route: object = {
    _name = oxr.metadata.name + "-route"
    _readiness = "SuccessfulCreate"
    _manifest = {
        apiVersion = "gateway.networking.k8s.io/v1"
        kind = "HTTPRoute"
        spec.parentRefs = [{name = oxr.metadata.name + "-gateway"}]
        spec.hostnames = oxr.spec.externalHosts
        spec.hostnames = map i,host in oxr.spec.externalHosts {
            host.name
        }
        spec.rules = [{
            matches = [{
                path = {"type" = "PathPrefix", value = "/"}
            }]
            backendRefs = [{
                name = oxr.spec.backendService.name
                port = oxr.spec.backendService.port
                weight = 1
            }]
            filters = oxr.spec.middleware
        }]
    }
}

dnsEntries: [dns.Record] = map i,host in oxr.spec.externalHosts {
     dns.Record {
        metadata.name = oxr.metadata.name + "-dns-" + str(i)
        spec.forProvider = {
            zoneIdRef.name = "root-domain"
            name = host.name
            $type = "CNAME"
            content = host.cname
        }
    }
}

items = [cert, gateway, route] + dnsEntries

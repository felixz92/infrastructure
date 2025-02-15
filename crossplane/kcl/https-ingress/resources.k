import crossplane_cloudflare.dns.v1alpha1 as dns
# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_claimName = oxr?.metadata?.labels?["crossplane.io/claim-name"]
_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]
_prefix = oxr.spec.externalHost.split(".")[0]
_baseDomain = oxr.spec.externalHost.split(".")[1]
_clusterName = oxr.spec.clusterName
print("prefix:" + _prefix)

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
        spec.dnsNames = [oxr.spec.externalHost, _prefix + ".cluster-1.${_baseDomain}", _prefix + ".cluster-2.${_baseDomain}"]
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
        # "${_prefix}.${_clusterName}.${_baseDomain}"
        spec.listeners =[
           {
                name = "websecure-0"
                port = 8443
                $protocol = "HTTPS"
                hostname = oxr.spec.externalHost
                tls.certificateRefs = [{
                    name = oxr.metadata.name + "-ingress-cert"
                }]
           },
           {
                name = "websecure-1"
                port = 8443
                $protocol = "HTTPS"
                hostname = _prefix+".${_clusterName}.${_baseDomain}"
                tls.certificateRefs = [{
                    name = oxr.metadata.name + "-ingress-cert"
                }]
           }
        ]
    }
}

route: object = {
    _name = oxr.metadata.name + "-route"
    _readiness = "SuccessfulCreate"
    _manifest = {
        apiVersion = "gateway.networking.k8s.io/v1"
        kind = "HTTPRoute"
        spec.parentRefs = [{name = oxr.metadata.name + "-gateway"}]
        spec.hostnames = [oxr.spec.externalHost, _prefix+".${_clusterName}.${_baseDomain}"]
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

cname : dns.Record = {
    metadata.name = oxr.metadata.name + "-dns"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec.forProvider = {
        zoneIdRef.name = "root-domain"
        name = oxr.spec.externalHost
        $type = "CNAME"
        content = "${_clusterName}.${_baseDomain}"
    }
}

dnsEntries: [dns.Record] = map i,n in ["cluster-1", "cluster-2"] {
     dns.Record {
        metadata.name = oxr.metadata.name + "-dns-" + n
        metadata.labels = {
            "velero.io/include" = "true"
        }
        spec.forProvider = {
            zoneIdRef.name = "root-domain"
            name = _prefix + "." + n + ".${_baseDomain}"
            $type = "CNAME"
            content = n + ".${_baseDomain}"
        }
    }
}

items = [cert, gateway, route, cname] + dnsEntries

import crossplane_cloudflare.dns.v1alpha1 as dns
# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_claimName = oxr?.metadata?.labels?["crossplane.io/claim-name"]
_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

_resourceName = _claimName + "-" + _namespace

_split = oxr.spec.externalHost.split(".")
_prefix = _split[0]
_baseDomain = "${_split[1]}.${_split[2]}"

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
    _name = _resourceName + "-ingress-cert"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion: "cert-manager.io/v1"
        kind: "Certificate"
        metadata.labels = {
            "velero.io/include" = "true"
        }
        spec.secretName = _resourceName + "-ingress-cert"
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
    _name = _resourceName + "-gateway"
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
                    name = _resourceName + "-ingress-cert"
                }]
           },
           {
                name = "websecure-1"
                port = 8443
                $protocol = "HTTPS"
                hostname = _prefix+".${_clusterName}.${_baseDomain}"
                tls.certificateRefs = [{
                    name = _resourceName + "-ingress-cert"
                }]
           }
        ]
    }
}

route: object = {
    _name = _resourceName + "-route"
    _readiness = "SuccessfulCreate"
    _manifest = {
        apiVersion = "gateway.networking.k8s.io/v1"
        kind = "HTTPRoute"
        spec.parentRefs = [{name = _resourceName + "-gateway"}]
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
    metadata.name = _resourceName + "-dns"
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
        metadata.name = _resourceName + "-dns-" + n
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

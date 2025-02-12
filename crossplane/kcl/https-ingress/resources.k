import crossplane_cloudflare.dns.v1alpha1 as dns
# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_claimName = oxr?.metadata?.labels?["crossplane.io/claim-name"]
_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]
_prefix = oxr.spec.externalHost.split(".")[0]

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
        spec.dnsNames = [oxr.spec.externalHost, "${_prefix}.cluster-1.${BASE_DOMAIN}", "${_prefix}.cluster-2.${BASE_DOMAIN}"]
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
        # "${_prefix}.${ACTUAL_CLUSTER}.${BASE_DOMAIN}"
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
                hostname = "${_prefix}.${ACTUAL_CLUSTER}.${BASE_DOMAIN}"
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
        spec.hostnames = [oxr.spec.externalHost, "${_prefix}.${ACTUAL_CLUSTER}.${BASE_DOMAIN}"]
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
        content = "${ACTUAL_CLUSTER}.${BASE_DOMAIN}"
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
            name = "${_prefix}.${n}.${BASE_DOMAIN}"
            $type = "CNAME"
            content = "${n}-${BASE_DOMAIN}"
        }
    }
}

items = [cert, gateway, route, cname] + dnsEntries

import crossplane_authentik.provider.v1alpha1 as provider
import crossplane_authentik.v1alpha1 as authentik
import json

schema object:
    _name: str
    _manifest: any
    _readiness: str
    _references?: any
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = {
        name = _name
    }
    spec = {
        if _references:
            references = _references
        providerConfigRef.name = "kubernetes-provider"
        deletionPolicy = "Delete"
        readiness.policy = _readiness
        forProvider.manifest = _manifest
        forProvider.manifest.metadata.name = _name
        forProvider.manifest.metadata.namespace = _namespace
    }

# Read the XR
oxr = option("params").oxr
ocds = option("params").ocds

_claimName = oxr?.metadata?.labels?["crossplane.io/claim-name"]
_providerId = ocds[_claimName + "-provider"]?.Resource?.status?.atProvider?.id
_certId = ocds[_claimName + "-cert-pair"]?.Resource?.status?.atProvider?.id

_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

cert: object = {
    _name = _claimName + "-ldap-cert"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion: "cert-manager.io/v1"
        kind: "Certificate"
        spec.secretName = _claimName + "-ldap-cert"
        spec.commonName = "ak-outpost-ldap-" + _claimName
        spec.dnsNames = [
            "ak-outpost-ldap-{}.authentik".format(_claimName),
            "ak-outpost-ldap-{}.authentik.svc".format(_claimName),
            "ak-outpost-ldap-{}.authentik.svc.cluster.local".format(_claimName)
        ]
        spec.subject.organisations = ["fzx"]
        spec.usages = ["key encipherment", "digital signature", "server auth"]
        spec.duration = "1440h"
        spec.privateKey = {
            algorithm = "ECDSA"
            size = 256
        }
        spec.issuerRef = {
            name = "cert-authority-issuer"
            kind = "ClusterIssuer"
        }
    }
}

ldap: provider.LDAP = {
    metadata.name = _claimName + "-provider"
    spec = {
        writeConnectionSecretToRef.name = _claimName + "-client-secret"
        writeConnectionSecretToRef.namespace = _namespace
        forProvider = {
            name = _claimName
            baseDn   = "DC=ldap,DC=goauthentik,DC=io"
            bindFlowRef.name = "default-authentication-flow"
            unbindFlowRef.name = "default-provider-invalidation-flow"
            name      = "ldap-ocis"
            searchMode = "direct"
            bindMode = "direct"
            certificate = _certId
            tlsServerName = "ak-outpost-ldap-ocis.authentik.svc.cluster.local"
        }
        providerConfigRef = {
            name = "authentik-provider"
        }
    }
}

certPair: authentik.CertificateKeyPair = {
    metadata.name = _claimName + "-cert-pair"
    spec.providerConfigRef.name = "authentik-provider"
    spec.forProvider.name = _claimName
    spec.forProvider.certificateDataSecretRef = {
        name = _claimName + "-ldap-cert"
        key = "tls.crt"
        namespace= _namespace
    }
    spec.forProvider.keyDataSecretRef = {
        name = _claimName + "-ldap-cert"
        key = "tls.key"
        namespace= _namespace
    }
}

outpost: authentik.Outpost = {
    metadata.name = _claimName + "-outpost"
    spec = {
        forProvider = {
            name = _claimName
            "type" = "ldap"
            serviceConnectionRef.name = "local"
            if _providerId:
                protocolProviders = [int(_providerId)]
            config = json.encode({
                "authentik_host": "http://authentik-server/"
                "authentik_host_insecure": True
                "authentik_host_browser": "https://authentik.${BASE_DOMAIN}/"
                "log_level": "info"
                "object_naming_template": "ak-outpost-%(name)s"
                "kubernetes_replicas": 1
                "kubernetes_namespace": "authentik"
                "kubernetes_service_type": "ClusterIP"
                "kubernetes_disabled_components": ["ingress", "middleware"]
            })
        }
        providerConfigRef = {
            name = "authentik-provider"
        }
    }
}

items = [
    ldap,
    cert,
    certPair,
    outpost
]

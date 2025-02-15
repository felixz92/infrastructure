import crossplane_authentik.provider.v1alpha1 as provider
import crossplane_authentik.v1alpha1 as authentik
import crossplane_authentik.directory.v1alpha1 as directory
import crossplane_authentik.rbac.v1alpha1 as rbac
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
_providerIdLdap = ocds[_claimName + "-provider-ldap"]?.Resource?.status?.atProvider?.id
_providerIdOauth = ocds[_claimName + "-provider-oauth"]?.Resource?.status?.atProvider?.id
_certId = ocds[_claimName + "-cert-pair"]?.Resource?.status?.atProvider?.id

_split = oxr.spec.externalHost.split(".")
_baseDomain = "${_split[1]}.${_split[2]}"
_namespace = oxr?.metadata?.labels?["crossplane.io/claim-namespace"]

cert: object = {
    _name = _claimName + "-ldap-cert"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion: "cert-manager.io/v1"
        kind: "Certificate"
        spec.secretName = _claimName + "-ldap-cert"
        spec.commonName = "ak-outpost-" + _claimName
        spec.dnsNames = [
            "ak-outpost-{}.authentik".format(_claimName),
            "ak-outpost-{}.authentik.svc".format(_claimName),
            "ak-outpost-{}.authentik.svc.cluster.local".format(_claimName)
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

user: directory.User = {
    metadata.name = _claimName + "-ldap-user"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec.forProvider = {
        username = "ldap-"+_claimName
        $type = "service_account"
        path = "goauthentik.io/serviceaccounts"
    }
}

token: directory.Token = {
    metadata.name = _claimName + "-ldap-token"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        writeConnectionSecretToRef.name = _claimName + "-ldap-token"
        writeConnectionSecretToRef.namespace = _namespace
        forProvider = {
            identifier = _claimName + "-ldap-token"
            description = "token to access ldap outpost"
            intent ="app_password"
            expiring = False
            userRef.name = _claimName + "-ldap-user"
            retrieveKey = True
        }
    }
}

permission:  rbac.UserPermission = {
    metadata.name = _claimName + "-ldap-permission"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec.forProvider = {
        userRef.name = _claimName + "-ldap-user"
        permission = "search_full_directory"
        model = "authentik_providers_ldap.ldapprovider"
        objectId = _providerIdLdap
    }
}

ldap: provider.LDAP = {
    metadata.name = _claimName + "-provider-ldap"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        writeConnectionSecretToRef.name = _claimName + "-ldap-secret"
        writeConnectionSecretToRef.namespace = _namespace
        forProvider = {
            name = "ldap-"+_claimName
            baseDn   = "DC=ldap,DC=goauthentik,DC=io"
            bindFlowRef.name = "default-authentication-flow"
            unbindFlowRef.name = "default-provider-invalidation-flow"
            searchMode = "direct"
            bindMode = "direct"
            certificate = _certId
            tlsServerName = "ak-outpost-ldap-ocis.authentik.svc.cluster.local"
        }
    }
}

oauth: provider.OAuth2 = {
    metadata.name = _claimName + "-provider-oauth"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        writeConnectionSecretToRef.name = _claimName + "-client-secret"
        writeConnectionSecretToRef.namespace = _namespace
        forProvider = {
            name = "oauth-"+_claimName
            clientId = _claimName
            signingKey = _certId
            clientType = "public"
            authorizationFlowRef.name = "default-provider-authorization-implicit-consent"
            invalidationFlowRef.name =  "default-provider-invalidation-flow"
            propertyMappingsRefs = [
                { name = "openid-email" }
                { name = "openid-openid" }
                { name = "openid-profile" }
            ]
            allowedRedirectUris = [
                {
                   "matching_mode" = "strict"
                   "url" = "https://" + oxr.spec.externalHost +  oxr.spec.redirectURL
                }
            ]
        }
    }
}

application: authentik.Application = {
    metadata.name = _claimName + "-application"
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        forProvider = {
            name = _claimName
            if _providerIdOauth:
                protocolProvider = int(_providerIdOauth)
            metaIcon = oxr.spec.icon
            metaDescription = oxr.spec.description
            metaLaunchUrl = "https://" + oxr.spec.externalHost
            metaPublisher = oxr.spec.publisher
            if _providerIdLdap:
                backchannelProviders =[int(_providerIdLdap)]
        }
    }
}

certPair: authentik.CertificateKeyPair = {
    metadata.name = _claimName + "-cert-pair"
    metadata.labels = {
        "velero.io/include" = "true"
    }
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
    metadata.labels = {
        "velero.io/include" = "true"
    }
    spec = {
        forProvider = {
            name = _claimName
            "type" = "ldap"
            serviceConnectionRef.name = "local"
            if _providerIdLdap:
                protocolProviders = [int(_providerIdLdap)]
            config = json.encode({
                "authentik_host": "http://authentik-server/"
                "authentik_host_insecure": True
                "authentik_host_browser": "https://authentik.${_baseDomain}/"
                "log_level": "debug"
                "object_naming_template": "ak-outpost-%(name)s"
                "kubernetes_replicas": 1
                "kubernetes_namespace": "authentik"
                "kubernetes_service_type": "ClusterIP"
                "kubernetes_disabled_components": ["ingress", "middleware"]
            })
        }
    }
}

ingress: object {
    _name = oxr.metadata.name + "-ingress"
    _readiness = "AllTrue"
    _manifest = {
        apiVersion = "custom.fzx.dev/v1alpha1"
        kind = "HTTPSIngressClaim"
        spec = {
            clusterName = oxr.spec.clusterName
            externalHost = oxr.spec.externalHost
            backendService = {
                name = oxr.spec.backendService.name
                port = oxr.spec.backendService.port
            }
        }
    }
}

items = [
    cert,
    certPair,
    user,
    token,
    ldap,
    permission,
    application,
    oauth,
    outpost,
    ingress
]

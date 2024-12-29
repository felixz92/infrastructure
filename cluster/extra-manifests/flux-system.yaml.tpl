---
apiVersion: v1
kind: Namespace
metadata:
  name: flux-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-env
  namespace: flux-system
data:
  ENVIRONMENT: ${environment}
  BASE_DOMAIN: ${base_domain}
  LETS_ENCRYPT_EMAIL: ${lets_encrypt_email}
---
apiVersion: v1
kind: Secret
metadata:
  name: flux-system
  namespace: flux-system
data:
    identity.pub: ${flux_public_key}
    identity: ${flux_private_key}
    known_hosts: ${flux_ssh_known_hosts}

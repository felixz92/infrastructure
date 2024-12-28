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

#!/usr/bin/env bash

# heredoc to generate secret and write to etcd.yaml
cat <<EOF > etcd.yaml
apiVersion: v1
kind: Secret
metadata:
  name: etcd-certs
  namespace: kube-system
data:
  etcd-ca.crt: $(talosctl get etcdrootsecret -o json | jq -r '.spec.etcdCA.crt')
  etcd-client.crt: $(talosctl get etcdsecret -o json | jq -r '.spec.etcd.crt')
  etcd-client-key.key: $(talosctl get etcdsecret -o json | jq -r '.spec.etcd.key')
EOF

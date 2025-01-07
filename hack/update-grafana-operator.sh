#!/usr/bin/env bash

set -eo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

VERSION="v5.15.1"
OUTPUT_DIR="${REPO_ROOT}/infrastructure/controllers/grafana-operator"

flux pull artifact "oci://ghcr.io/grafana/kustomize/grafana-operator:${VERSION}" --output "${OUTPUT_DIR}" \
  --creds "$(op read --no-newline op://Personal/development-github.com/username):$(op read --no-newline op://Personal/development-github.com/macos-pat)"

mv "${OUTPUT_DIR}/base/crds.yaml" "${REPO_ROOT}/crds/grafana-operator/"

(cd "${OUTPUT_DIR}/base" && kustomize edit remove resource crds.yaml)
(cd "${OUTPUT_DIR}/base" && kustomize edit remove resource namespace.yaml && rm namespace.yaml)
(
cd "${OUTPUT_DIR}/overlays/cluster_scoped"
kustomize edit set namespace grafana-operator
kustomize edit add patch --path seccomp.yaml --kind Deployment --group apps --version v1
)

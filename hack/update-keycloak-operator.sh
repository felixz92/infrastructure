#!/usr/bin/env bash

set -eo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

VERSION="26.1.0"
OUTPUT_DIR="${REPO_ROOT}/system/controllers/keycloak-operator/base"

curl -s -L --fail "https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${VERSION}/kubernetes/kubernetes.yml" -o "${OUTPUT_DIR}/operator.yaml"

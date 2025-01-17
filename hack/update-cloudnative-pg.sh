#!/usr/bin/env bash

set -eo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

VERSION="1.25.0"

url=https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v${VERSION}/cnpg-${VERSION}.yaml

CRD_OUTPUT_DIR="${REPO_ROOT}/system/crds/cloudnative-pg"
OUTPUT_DIR="${REPO_ROOT}/system/controllers/cloudnative-pg/base"

temp=$(mktemp -d)

curl -sL "${url}" -o "${temp}/cnpg.yaml"
(cd "${temp}" && yq -s '.kind +"-" + .metadata.name | downcase + ".yaml"' cnpg.yaml)

mv "${temp}/"customresourcedefinition*.yaml "${CRD_OUTPUT_DIR}/"

(cd "${CRD_OUTPUT_DIR}" ; rm kustomization.yaml ; kustomize init --autodetect)

#!/usr/bin/env bash

set -eo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

CRD_OUTPUT_DIR="${REPO_ROOT}/system/crds/velero"
OUTPUT_DIR="${REPO_ROOT}/system/controllers/velero/base"

BUCKET=fzx-staging-velero

temp=$(mktemp -d)

velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.11.1 \
    --bucket $BUCKET \
    --backup-location-config region=default \
    --snapshot-location-config region=default \
    --dry-run \
    --secret-file ./credentials-velero \
    -o yaml > "${temp}/velero.yaml"

echo $temp
(cd "${temp}" && yq '.items[]' velero.yaml -s '.kind +"-" + .metadata.name | downcase + ".yaml"' velero.yaml)
ls -la $temp
rm $temp/velero.yaml
ls  $temp | wc

mv "${temp}/"customresourcedefinition*.yaml "${CRD_OUTPUT_DIR}/"
(cd "${CRD_OUTPUT_DIR}" ; rm kustomization.yaml || true ; kustomize init --autodetect)
mv "${temp}/"*.yaml "${OUTPUT_DIR}/"
(cd "${OUTPUT_DIR}" ; rm kustomization.yaml || true ; kustomize init --autodetect)

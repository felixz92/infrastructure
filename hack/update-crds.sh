#!/usr/bin/env bash

set -eo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

for file in "${REPO_ROOT}"/system/crds/**/urls; do
  echo "Updating crds with file $file"
  dir="$(dirname "${file}")"
  if ls $dir/*.yaml; then
    rm $dir/*.yaml
  fi
  while read -r line;
  do
     crd="$(echo "$line" | grep -o '[^/]*$')"
     echo "$crd"
     curl -s -L --fail "$line" -o "$dir/$crd"
  done < "${file}"
  (cd "$dir" ; kustomize init --autodetect)
done

#!/usr/bin/env bash

set -eo pipefail

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
[ -d "$CURR_DIR" ] || {
  echo "FATAL: no current dir (maybe running in zsh?)"; exit 1
}

cd "$CURR_DIR/../cluster"

tmp_script=$(mktemp)
curl -sSL -o "${tmp_script}" https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/scripts/cleanup.sh
sed -i.bu 's/grep/ggrep/g' ${tmp_script}
chmod +x "${tmp_script}"
"${tmp_script}"
rm "${tmp_script}"
rm "${tmp_script}.bu"

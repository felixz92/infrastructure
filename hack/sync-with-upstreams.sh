#!/usr/bin/env bash

set -eo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

$REPO_ROOT/hack/update-crds.sh

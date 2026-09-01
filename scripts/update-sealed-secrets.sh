#!/bin/sh

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

# FIXME: Change this to use environments
op run --account my.1password.com --env-file="$REPO_ROOT/.env" -- ./scripts/populate-secrets-manifests.sh

git add manifests/**/sealed-secrets.yaml
git commit -m "Update sealed secrets" || echo "No changes to commit"
git push

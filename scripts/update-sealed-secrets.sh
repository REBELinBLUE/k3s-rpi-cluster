#!/bin/bash

set -euo pipefail

op run --environment jj5r3i2pf4cnxj6hak7jzhgtyy --account my.1password.com -- ./scripts/populate-secrets-manifests.sh

git add manifests/**/sealed-secrets.yaml
git commit -m "Update sealed secrets" || echo "No changes to commit"
git push

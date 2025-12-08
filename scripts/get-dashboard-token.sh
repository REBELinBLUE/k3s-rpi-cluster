#!/bin/sh

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n kubernetes-dashboard get secret admin-user -o jsonpath={".data.token"} | base64 -d

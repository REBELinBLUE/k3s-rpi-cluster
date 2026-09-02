#!/bin/sh

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

for node in $(kubectl --kubeconfig="$REPO_ROOT/k3s_config"  get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo "\n=== Node: $node ==="
  kubectl --kubeconfig="$REPO_ROOT/k3s_config" get pods -A --field-selector spec.nodeName=$node
done
#!/bin/bash

set -euo pipefail

for node in $(kubectl --context pi get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo ""
  echo "=== Node: $node ==="
  kubectl --context pi get pods -A --field-selector spec.nodeName=$node
done
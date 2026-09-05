#!/bin/bash

set -euo pipefail

for node in $(kubectl --context pi get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo ""
  echo "=== Node: $node ==="
  kubectl --context pi describe node $node | grep -A 5 "Allocated resources:" | grep -v -E "(Allocated resources:|overcommitted)"  | sed 's/^[ \t]*//'
done
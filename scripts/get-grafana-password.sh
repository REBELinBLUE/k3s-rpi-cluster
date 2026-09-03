#!/bin/bash

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

PWD=$(kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n monitoring get secrets vm-grafana -o jsonpath="{.data.admin-password}" | base64 -d)

echo "Grafana initial admin password: $PWD"
echo ""
echo "Forwarding Grafana server to http://localhost:8080"

kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n monitoring port-forward service/vm-grafana 8080:80
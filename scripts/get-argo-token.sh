#!/bin/sh

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

PWD=$(kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD initial admin password: $PWD"
echo ""
echo "Forwarding ArgoCD server to http://localhost:8090"

kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n argocd port-forward service/argocd-server 8090:80

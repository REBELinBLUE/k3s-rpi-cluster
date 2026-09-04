#!/bin/bash

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

until kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n argocd get deployment/argocd-server &>/dev/null; do
  echo "Waiting for argocd-server deployment to exist..."
  sleep 5
done

echo "Waiting for argocd-server to be available..."
kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n argocd rollout status deployment/argocd-server --timeout=300s

PWD=$(kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "ArgoCD initial admin password: $PWD"
echo ""
echo "Forwarding ArgoCD server to http://localhost:8090"

open http://localhost:8090

kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n argocd port-forward service/argocd-server 8090:80

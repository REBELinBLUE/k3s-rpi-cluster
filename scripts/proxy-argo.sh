#!/bin/bash

set -euo pipefail

until kubectl --context pi -n argocd get deployment/argocd-server &>/dev/null; do
  echo "Waiting for argocd-server deployment to exist..."
  sleep 5
done

echo "Waiting for argocd-server to be available..."
kubectl --context pi -n argocd rollout status deployment/argocd-server --timeout=300s

PWD=$(kubectl --context pi -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "ArgoCD initial admin password: $PWD"
echo ""
echo "Forwarding ArgoCD server to http://localhost:8090"

open http://localhost:8090

kubectl --context pi -n argocd port-forward service/argocd-server 8090:80

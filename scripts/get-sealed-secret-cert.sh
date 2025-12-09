#!/bin/sh

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

source ".env"

kubeseal --kubeconfig="$REPO_ROOT/k3s_config" --controller-namespace kube-system --controller-name sealed-secrets-controller --fetch-cert > pub-sealed-secrets.pem

kubectl --kubeconfig="$REPO_ROOT/k3s_config" create secret generic kured \
  --namespace=kube-system \
  --from-literal=KURED_SLACK_HOOK_URL=$SLACK_URL \
  --dry-run=client -o yaml | \
kubeseal --kubeconfig="$REPO_ROOT/k3s_config" -o yaml > $REPO_ROOT/manifests/infrastructure/manifests/kured/secrets.yaml


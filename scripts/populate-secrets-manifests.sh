#!/bin/bash

set -euo pipefail

# Ensure required environment variables are set
: "${SLACK_URL:?Environment variable SLACK_URL must be set}"
: "${GOOGLE_OAUTH_CLIENT_ID:?Environment variable GOOGLE_OAUTH_CLIENT_ID must be set}"
: "${GOOGLE_OAUTH_CLIENT_SECRET:?Environment variable GOOGLE_OAUTH_CLIENT_SECRET must be set}"
: "${GOOGLE_OAUTH_SECRET:?Environment variable GOOGLE_OAUTH_SECRET must be set}"
: "${LINODE_TOKEN:?Environment variable LINODE_TOKEN must be set}"

REPO_ROOT=$(git rev-parse --show-toplevel)

until kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n kube-system get deployment/sealed-secrets-controller &>/dev/null; do
  echo "Waiting for sealed-secrets-controller deployment to exist..."
  sleep 5
done

kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n kube-system rollout status deployment/sealed-secrets-controller --timeout=300s

kubeseal --kubeconfig="$REPO_ROOT/k3s_config" --fetch-cert > "$REPO_ROOT/pub-sealed-secrets.pem"

# Function to create and seal a secret
seal_secret() {
  local secret_name=$1
  local namespace=$2
  local output_file=$3
  shift 3
  local literals=("$@")

  # Build kubectl create secret generic command dynamically
  local cmd=(kubectl --kubeconfig="$REPO_ROOT/k3s_config" create secret generic "$secret_name" --namespace="$namespace" --dry-run=client -o yaml)

  for literal in "${literals[@]}"; do
    cmd+=(--from-literal="$literal")
  done

  # Execute and pipe to kubeseal
  "${cmd[@]}" | kubeseal --kubeconfig="$REPO_ROOT/k3s_config" -o yaml > "$output_file"
}

# Seal kured secret
# seal_secret "kured" "kube-system" \
#   "$REPO_ROOT/manifests/infrastructure/manifests/kured/sealed-secrets.yaml" \
#   "NOTIFY_URL=$SLACK_URL"

# Seal traefik-forward-auth secret
seal_secret "traefik-forward-auth" "ingress" \
  "$REPO_ROOT/manifests/infrastructure/manifests/traefik-forward-auth/sealed-secrets.yaml" \
  "CLIENT_ID=$GOOGLE_OAUTH_CLIENT_ID" \
  "CLIENT_SECRET=$GOOGLE_OAUTH_CLIENT_SECRET" \
  "SECRET=$GOOGLE_OAUTH_SECRET"

seal_secret "linode" "external-dns" \
  "$REPO_ROOT/manifests/infrastructure/manifests/external-dns/sealed-secrets.yaml" \
  "LINODE_TOKEN=$LINODE_TOKEN"
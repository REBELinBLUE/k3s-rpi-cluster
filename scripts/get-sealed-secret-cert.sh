#!/bin/sh

set -euo pipefail

kubectl --kubeconfig="$REPO_ROOT/k3s_config" --controller-namespace kube-system --controller-name sealed-secrets-controller --fetch-cert

#!/bin/sh

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

kubeseal --kubeconfig="$REPO_ROOT/k3s_config" --controller-namespace kube-system --controller-name sealed-secrets-controller --fetch-cert

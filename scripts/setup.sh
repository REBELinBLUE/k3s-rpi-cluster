#!/bin/bash

set -euo pipefail

echo "Installing Flux..."

flux bootstrap github --kubeconfig=k3s_config --owner=rebelinblue --repository=k3s-rpi-cluster --private=false --personal=true --branch=main --path=manifests/cluster/

#kubeseal --fetch-cert > pub-sealed-secrets.pem

FLUX_READY=1
while [ ${FLUX_READY} != 0 ]; do
    kubectl --kubeconfig=k3s_config -n flux-system wait --for condition=available deployment/flux
    FLUX_READY="$?"
    sleep 5
done

kubectl --kubeconfig=k3s_config -n flux-system get secrets flux-system -o json | jq -r '.data."identity.pub"' | base64 -d

#kubectl delete crd helmcharts.helm.cattle.io
#kubectl delete crd helmchartconfigs.helm.cattle.io
#kubectl delete crd addons.k3s.cattle.io
##kubectl delete apiservice v1beta1.metrics.k8s.io

#!/bin/bash

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/nodes.env"

message() {
    export CLI_MAGENTA=$(tput -Txterm-256color setaf 5)
    export CLI_BOLD=$(tput -Txterm-256color bold)
    export CLI_RESET=$(tput -Txterm-256color sgr0)

    printf "\n${CLI_BOLD}${CLI_MAGENTA}==========  %s  ==========${CLI_RESET}\n" "$@"
}

message "Labeling all nodes"
#kubectl taint nodes $K3S_MASTER node-role.kubernetes.io/master="":NoSchedule --overwrite
for node in $K3S_WORKERS_RPI; do
    kubectl label node $node node-role.kubernetes.io/worker="" --overwrite
done

kubectl create namespace vault
kubectl -n vault create secret generic vault-unseal-keys --from-literal="VAULT_UNSEAL_KEY_1=$VAULT_UNSEAL_KEY_1" \
                                                         --from-literal="VAULT_UNSEAL_KEY_2=$VAULT_UNSEAL_KEY_2" \
                                                         --from-literal="VAULT_UNSEAL_KEY_3=$VAULT_UNSEAL_KEY_3" \
                                                         --from-literal="VAULT_UNSEAL_KEY_4=$VAULT_UNSEAL_KEY_4" \
                                                         --from-literal="VAULT_UNSEAL_KEY_5=$VAULT_UNSEAL_KEY_5"

message "Installing Flux"
# kubectl create namespace flux
# helm repo add fluxcd https://charts.fluxcd.io
# helm repo add stable https://charts.helm.sh/stable
# helm upgrade --install flux --values $REPO_ROOT/deployments/flux/flux/flux-values.yaml --namespace flux fluxcd/flux
# helm upgrade --install helm-operator --values $REPO_ROOT/deployments/flux/helm-operator/helm-operator-values.yaml --namespace flux fluxcd/helm-operator

#kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml

GITHUB_TOKEN=.... flux bootstrap github --owner=rebelinblue --repository=k3s-on-raspbian --private=false --personal=true --branch=main --path=deployments/

#message "Installing NFS Provisioner"
#kubectl create namespace infra
#helm upgrade --install nfs-subdir-external-provisioner --values $REPO_ROOT/deployments/infra/nfs-subdir-external-provisioner.yaml --namespace infra nfs-subdir-external-provisioner/nfs-subdir-external-provisioner

# FLUX_READY=1
# while [ ${FLUX_READY} != 0 ]; do
#     echo "Waiting for flux pod to be fully ready..."
#     kubectl -n flux wait --for condition=available deployment/flux
#     FLUX_READY="$?"
#     sleep 5
# done

kubectl -n flux-system get secrets flux-system -o json | jq -r '.data."identity.pub"' | base64 -d

kubectl delete crd helmcharts.helm.cattle.io
kubectl delete crd helmchartconfigs.helm.cattle.io
kubectl delete crd addons.k3s.cattle.io
#kubectl delete apiservice v1beta1.metrics.k8s.io

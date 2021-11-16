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

echo "This is a destructive action which will delete everything and remove the kubernetes cluster served by $server"
while true; do
    read -p "Are you SURE you want to run this? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Attempt to delete all namespaces and pvcs prior to tearing-down the cluster. The reason for this is to allow the nfs-client provisioner a change to 'archive' the storage directories
message "Deleting all pods & pvcs"
for ns in $(kubectl get ns --field-selector="status.phase==Active" --no-headers -o "custom-columns=:metadata.name"); do
    kubectl delete namespace $ns --wait=false
done

kubectl -n default delete deployments,statefulsets,daemonsets --force --grace-period=0 --all
kubectl -n kube-system delete statefulsets,daemonsets --force --grace-period=0 --all

sleep 10

kubectl -n kube-system delete deployments --all

# raspberry pi4 worker nodes
for node in $K3S_WORKERS_RPI; do
    message "Tearing down $node"
    ssh -o "StrictHostKeyChecking=no" $node "k3s-agent-uninstall.sh"
done

# k3s master node
message "Tearing down $K3S_MASTER"
ssh -o "StrictHostKeyChecking=no" $K3S_MASTER "k3s-uninstall.sh"

message "All done - everything is removed!"

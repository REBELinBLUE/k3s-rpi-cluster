#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/nodes.env"

message() {
    export CLI_MAGENTA=$(tput -Txterm-256color setaf 5)
    export CLI_BOLD=$(tput -Txterm-256color bold)
    export CLI_RESET=$(tput -Txterm-256color sgr0)

    printf "\n${CLI_BOLD}${CLI_MAGENTA}==========  %s  ==========${CLI_RESET}\n" "$@"
}

# raspberry pi4 worker nodes
for node in $K3S_WORKERS_RPI; do
    message "Halting $node"
    ssh -o "StrictHostKeyChecking=no" $node "sudo halt"
done

# k3s master node
message "Halting $K3S_MASTER"
ssh -o "StrictHostKeyChecking=no" $K3S_MASTER "sudo halt"

message "All done - everything is shutting down!"

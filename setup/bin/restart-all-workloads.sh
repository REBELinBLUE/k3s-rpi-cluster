#!/bin/bash

set -e
set +x

namespaces=$(kubectl get namespaces -o json | jq -r '.items[] | .metadata.name')
for NS in $namespaces; do
    deployments=$(kubectl --namespace="$NS" get deployments -o json | jq -r '.items[] | .metadata.name')

    for DEPLOYMENT in $deployments; do
        echo "Restarting deployment $DEPLOYMENT in namespace $NS"
        kubectl --namespace="$NS" rollout restart deployment "$DEPLOYMENT"
    done

    demonsets=$(kubectl --namespace="$NS" get daemonsets -o json | jq -r '.items[] | .metadata.name')

    for DS in $demonsets; do
        echo "Restarting daemonset $DS in namespace $NS"
        kubectl --namespace="$NS" rollout restart daemonset "$DS"
    done

    # replicasets=$(kubectl --namespace="$NS" get replicasets -o json | jq -r '.items[] | .metadata.name')

    # for RS in replicasets; do
    #     echo "Restarting replicaset $RS in namespace $NS"
    #     kubectl --namespace="$NS" rollout restart replicaset "$RS"
    # done
done

kubectl -n monitoring delete pods --all --wait=0
kubectl -n infra delete pod -lapp=traefik
kubectl -n logging delete pod/loki-0
kubectl -n vault delete pod/vault-0
kubectl -n kube-system delete pods --all --wait=0

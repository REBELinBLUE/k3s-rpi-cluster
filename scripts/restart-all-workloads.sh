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

    statefulsets=$(kubectl --namespace="$NS" get statefulsets -o json | jq -r '.items[] | .metadata.name')

    for STS in $statefulsets; do
        echo "Restarting statefulset $STS in namespace $NS"
        kubectl --namespace="$NS" rollout restart statefulset "$STS"
    done
done


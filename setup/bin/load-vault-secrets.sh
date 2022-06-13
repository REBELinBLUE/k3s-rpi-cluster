#!/bin/bash

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/.env"

export VAULT_ADDR=$VAULT_ADDR
export VAULT_TOKEN=$VAULT_ROOT_TOKEN

kubectl -n vault port-forward svc/vault 8200:8200 >/dev/null 2>&1 &
VAULT_FWD_PID=$!
sleep 5

kpolicy() {
  VAULT_POLICY_NAME=$1

  VAULT_POLICY_FILE="$REPO_ROOT/deployments/vault/policies/${VAULT_POLICY_NAME}.hcl"

  if [[ "$(vault policy list | grep ${VAULT_POLICY_NAME})" != "${VAULT_POLICY_NAME}" ]]; then
      echo -e "[ INFO ] Create a policy ${VAULT_POLICY_NAME}"
  else
      echo -e "[ INFO ] Update a policy ${VAULT_POLICY_NAME}"
  fi

  vault policy write ${VAULT_POLICY_NAME} ${VAULT_POLICY_FILE} >/dev/null
  echo -e "[ INFO ] New policy created/updated: $(vault policy list | grep ${VAULT_POLICY_NAME})"
}

kapprole() {
  VAULT_POLICY_NAME=$1
  KUBERNETES_NAMESPACE=$2

  if [[ "$(vault list auth/approle/role | grep ${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME})" == "${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}" ]]; then
    echo -e "[ WARNING ] The AppRole ${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME} already exists. Abort"
    exit 0
  else
    echo -e "[ INFO ] Create an AppRole for ${VAULT_POLICY_NAME} in ${KUBERNETES_NAMESPACE}"
    vault write auth/approle/role/${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME} \
                policies=${VAULT_POLICY_NAME} \
                secret_id_ttl=0 \
                secret_id_num_uses=0 \
                token_num_uses=0 \
                token_ttl=1m \
                token_max_ttl=10m >/dev/null

    echo -e "[ INFO ] New AppRole created: $(vault list auth/approle/role | grep ${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME})"

    ROLE_ID=$(vault read auth/approle/role/${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}/role-id | xargs | awk '{ print $6 }')

    echo -e "[ INFO ] Role ID for ${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}: ${ROLE_ID} (base64: $(echo -n "${ROLE_ID}" | base64))"

    # Get secretid
    SECRET_ID=$(vault write -f auth/approle/role/${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}/secret-id | xargs | awk '{ print $6 }')

    echo -e "[ INFO ] Secret ID for ${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}: ${SECRET_ID} (base64: $(echo -n "${SECRET_ID}" | base64))"

    echo "[ INFO ] Create a Kubernetes secret"
    echo -e "---
apiVersion: v1
kind: Secret
metadata:
    name: ${VAULT_POLICY_NAME}-approle
    namespace: ${KUBERNETES_NAMESPACE}
    labels:
        app: ${VAULT_POLICY_NAME}
        role: approle
type: Opaque
data:
    role_id: $(echo -n "${ROLE_ID}" | base64)
    secret_id: $(echo -n "${SECRET_ID}" | base64)" > /tmp/${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}.yaml

    kubectl -n ${KUBERNETES_NAMESPACE} apply -f /tmp/${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}.yaml >/dev/null

    if [[ "$(kubectl -n ${KUBERNETES_NAMESPACE} get secrets | grep ${VAULT_POLICY_NAME}-approle | awk '{ print $1 }')" == "${VAULT_POLICY_NAME}-approle" ]]; then
        echo -e "[ INFO ] Secret created: ${VAULT_POLICY_NAME}-approle in ${KUBERNETES_NAMESPACE} namespace"
        rm -f /tmp/${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}.yaml
    else
        echo -e "[ WARNING ] Secret has not been created. One can create is manually: kubectl -n ${KUBERNETES_NAMESPACE} apply -f /tmp/${KUBERNETES_NAMESPACE}-${VAULT_POLICY_NAME}.yaml"
    fi
  fi
}


# kpolicy "linode-dynamic-dns"
# kapprole "linode-dynamic-dns" "infra"

# vault kv put apps/infra/linode-dynamic-dns token="$LINODE_TOKEN"

#kpolicy "fluxcloud"
#kapprole "fluxcloud" "flux-system"

kpolicy "alertmanager"
kapprole "alertmanager" "monitoring"

kpolicy "kured"
kapprole "kured" "kube-system"

vault kv put apps/shared/slack slack_url="$SLACK_URL"

kpolicy "minio"
kapprole "minio" "infra"

kpolicy "velero"
kapprole "velero" "velero"

vault kv put apps/shared/minio accesskey="$MINIO_ACCESS_KEY" \
                               secretkey="$MINIO_SECRET_KEY"

kpolicy "traefik-forward-auth"
kapprole "traefik-forward-auth" "infra"

vault kv put apps/infra/traefik-forward-auth CLIENT_ID="$OAUTH_CLIENT_ID" \
                                             CLIENT_SECRET="$OAUTH_CLIENT_SECRET" \
                                             SECRET="$OAUTH_SECRET"

#"${REPO_ROOT}/setup/bin/create-app-role.sh" test kuard
#
#vault kv put apps/test/kuard/example FOO="bar"

kill $VAULT_FWD_PID || true

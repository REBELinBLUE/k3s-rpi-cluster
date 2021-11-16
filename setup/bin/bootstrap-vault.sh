#!/bin/bash

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/.env"

message() {
    export CLI_MAGENTA=$(tput -Txterm-256color setaf 5)
    export CLI_BOLD=$(tput -Txterm-256color bold)
    export CLI_RESET=$(tput -Txterm-256color sgr0)

    printf "\n${CLI_BOLD}${CLI_MAGENTA}==========  %s  ==========${CLI_RESET}\n" "$@"
}

message "Initializing vault"
VAULT_READY=1
while [ $VAULT_READY != 0 ]; do
    kubectl -n vault wait --for condition=Initialized pod/vault-0 > /dev/null 2>&1
    VAULT_READY="$?"
    if [ $VAULT_READY != 0 ]; then
        echo "Waiting for vault pod to be somewhat ready..."
        sleep 10;
    fi
done
sleep 2

VAULT_READY=1
while [ $VAULT_READY != 0 ]; do
    init_status=$(kubectl -n vault exec "vault-0" -c vault  -- vault status -format=json 2>/dev/null | jq -r '.initialized')
    if [ "$init_status" == "false" ] || [ "$init_status" == "true" ]; then
        VAULT_READY=0
    else
        echo "Vault pod is almost ready, waiting for it to report status"
        sleep 5
    fi
done

sealed_status=$(kubectl -n vault exec "vault-0" -c vault -- vault status -format=json 2>/dev/null | jq -r '.sealed')
init_status=$(kubectl -n vault exec "vault-0" -c vault -- vault status -format=json 2>/dev/null | jq -r '.initialized')

if [ "$init_status" == "false" ]; then
    vault_init=$(kubectl -n vault exec "vault-0" -c vault -- vault operator init -format json -recovery-shares=5 -recovery-threshold=3) || exit 1

    export VAULT_UNSEAL_KEY_1=$(echo $vault_init | jq -r '.unseal_keys_b64[0]')
    export VAULT_UNSEAL_KEY_2=$(echo $vault_init | jq -r '.unseal_keys_b64[1]')
    export VAULT_UNSEAL_KEY_3=$(echo $vault_init | jq -r '.unseal_keys_b64[2]')
    export VAULT_UNSEAL_KEY_4=$(echo $vault_init | jq -r '.unseal_keys_b64[3]')
    export VAULT_UNSEAL_KEY_5=$(echo $vault_init | jq -r '.unseal_keys_b64[4]')
    export VAULT_ROOT_TOKEN=$(echo $vault_init | jq -r '.root_token')

    echo "VAULT_UNSEAL_KEY_1 is: $VAULT_UNSEAL_KEY_1"
    echo "VAULT_UNSEAL_KEY_2 is: $VAULT_UNSEAL_KEY_2"
    echo "VAULT_UNSEAL_KEY_3 is: $VAULT_UNSEAL_KEY_3"
    echo "VAULT_UNSEAL_KEY_4 is: $VAULT_UNSEAL_KEY_4"
    echo "VAULT_UNSEAL_KEY_5 is: $VAULT_UNSEAL_KEY_5"
    echo "VAULT_ROOT_TOKEN is: $VAULT_ROOT_TOKEN"

    sed -i "s~VAULT_ROOT_TOKEN=\".*\"~VAULT_ROOT_TOKEN=\"$VAULT_ROOT_TOKEN\"~" "$REPO_ROOT/setup/.env"
    sed -i "s~VAULT_UNSEAL_KEY_1=\".*\"~VAULT_UNSEAL_KEY_1=\"$VAULT_UNSEAL_KEY_1\"~" "$REPO_ROOT/setup/.env"
    sed -i "s~VAULT_UNSEAL_KEY_2=\".*\"~VAULT_UNSEAL_KEY_2=\"$VAULT_UNSEAL_KEY_2\"~" "$REPO_ROOT/setup/.env"
    sed -i "s~VAULT_UNSEAL_KEY_3=\".*\"~VAULT_UNSEAL_KEY_3=\"$VAULT_UNSEAL_KEY_3\"~" "$REPO_ROOT/setup/.env"
    sed -i "s~VAULT_UNSEAL_KEY_4=\".*\"~VAULT_UNSEAL_KEY_4=\"$VAULT_UNSEAL_KEY_4\"~" "$REPO_ROOT/setup/.env"
    sed -i "s~VAULT_UNSEAL_KEY_5=\".*\"~VAULT_UNSEAL_KEY_5=\"$VAULT_UNSEAL_KEY_5\"~" "$REPO_ROOT/setup/.env"

    kubectl -n vault delete secret vault-unseal-keys || true
    kubectl -n vault create secret generic vault-unseal-keys --from-literal="VAULT_UNSEAL_KEY_1=$VAULT_UNSEAL_KEY_1" \
                                                             --from-literal="VAULT_UNSEAL_KEY_2=$VAULT_UNSEAL_KEY_2" \
                                                             --from-literal="VAULT_UNSEAL_KEY_3=$VAULT_UNSEAL_KEY_3" \
                                                             --from-literal="VAULT_UNSEAL_KEY_4=$VAULT_UNSEAL_KEY_4" \
                                                             --from-literal="VAULT_UNSEAL_KEY_5=$VAULT_UNSEAL_KEY_5"
fi

if [ "$sealed_status" == "true" ]; then
    message "Unsealing vault"
    kubectl -n vault exec "vault-0" -c vault -- vault operator unseal "$VAULT_UNSEAL_KEY_1" || exit 1
    kubectl -n vault exec "vault-0" -c vault -- vault operator unseal "$VAULT_UNSEAL_KEY_2" || exit 1
    kubectl -n vault exec "vault-0" -c vault -- vault operator unseal "$VAULT_UNSEAL_KEY_3" || exit 1
fi

sleep 5

# Variables
export VAULT_ADDR=$VAULT_ADDR
export VAULT_TOKEN=$VAULT_ROOT_TOKEN
ADMIN_USERNAME=$VAULT_ADMIN_USERNAME
ADMIN_PASSWORD=$VAULT_ADMIN_PASSWORD

kubectl -n vault port-forward svc/vault 8200:8200 >/dev/null 2>&1 &
VAULT_FWD_PID=$!
sleep 5

message "Enabling approle, userpass and kv storage"

vault audit enable file file_path=stdout
vault secrets enable -path=apps kv
vault auth enable approle
vault auth enable userpass

message "Creating admin"

VAULT_ADMIN_POLICY_FILE="/tmp/vault-admin-policy.hcl"
VAULT_ADMIN_POLICY_NAME="admin"

cat >${VAULT_ADMIN_POLICY_FILE}<<EOF
path "*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOF

vault policy write $VAULT_ADMIN_POLICY_NAME $VAULT_ADMIN_POLICY_FILE >/dev/null

echo -e "[ INFO ] New policy created/updated: $(vault policy list | grep ${VAULT_ADMIN_POLICY_NAME})"

VAULT_METRICS_POLICY_FILE="/tmp/vault-metrics-policy.hcl"
VAULT_METRICS_POLICY_NAME="metrics"
cat >${VAULT_METRICS_POLICY_FILE}<<EOF
path "sys/metrics*" {
  capabilities = ["read", "list"]
}
EOF

vault policy write $VAULT_METRICS_POLICY_NAME $VAULT_METRICS_POLICY_FILE >/dev/null
echo -e "[ INFO ] New policy created/updated: $(vault policy list | grep ${VAULT_METRICS_POLICY_NAME})"

vault write auth/userpass/users/$ADMIN_USERNAME password="$ADMIN_PASSWORD" policies="admin"
vault token create -policy=metrics -display-name=prometheus -no-default-policy

rm -f $VAULT_ADMIN_POLICY_FILE >/dev/null
rm -f $VAULT_METRICS_POLICY_FILE >/dev/null

kill $VAULT_FWD_PID || true
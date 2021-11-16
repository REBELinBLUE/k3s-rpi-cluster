#!/bin/bash

set -e

if [[ $1 = "confd" ]]; then
    # Validate mandatory variables
    if [[ -z "${VAULT_ROLE_ID}" ]]; then
        echo -e "[ ERROR ] Vault RoleID must be provided explicitly. Exit.";
        exit 1;
    fi

    if [[ -z "${VAULT_SECRET_ID}" ]]; then
        echo -e "[ ERROR ] Vault SecretID must be provided explicitly. Exit.";
        exit 1;
    fi

    # Define default values
    export VAULT_HOST_ADDR=${VAULT_HOST_ADDR:-"vault.vault.svc.cluster.local"}
    export VAULT_TCP_PORT=${VAULT_TCP_PORT:-"8200"}
    export VAULT_SCHEME=${VAULT_SCHEME:-"http"}
    export CONFD_DIR=${CONFD_DIR:-"/etc/confd"}
    export CONFD_DEBUG_LEVEL=${CONFD_DEBUG_LEVEL:-"info"}
    export ANNOTATION_PREFIX=${ANNOTATION_PREFIX:-"SECRET_"}

    echo -e "[ INFO ] Checking Vault on ${VAULT_SCHEME}://${VAULT_HOST_ADDR}:${VAULT_TCP_PORT}"
    echo -e "[ INFO ] Check whether Vault is unsealed"

    if [[ $(curl --silent ${VAULT_SCHEME}://${VAULT_HOST_ADDR}:${VAULT_TCP_PORT}/v1/sys/seal-status | jq .sealed) == "true" ]]; then
        echo -e "[ ERROR ] Vault is sealed"
        exit 1
    fi

    echo -e "[ INFO ] Vault is unsealed"

    mkdir -p /etc/confd/conf.d /etc/confd/templates

    echo -e "[ INFO ] Parse annotations"
    if [[ -e /tmpfs/annotations ]]; then
        sed -e '/kubernetes.io/d' /tmpfs/annotations | grep "${ANNOTATION_PREFIX}" | sed -e "s/${ANNOTATION_PREFIX}//" > /secrets.lst;
    fi

    echo -e "[ INFO ] Parse secrets list into a confd template"
    sed -e 's/="/='\''{{getv "/' /secrets.lst | sed -e 's/"$/"}}"/g' | sed -e 's/^/export /' | sed -e 's/}}"/}}'\''/g' > /etc/confd/templates/secrets.tmpl

    echo -e "[ INFO ] Generate a confd TOML file"
    echo -e "[template]\nsrc = \"secrets.tmpl\"\ndest = \"/env/secrets\"\nkeys = [" > /etc/confd/conf.d/secrets.toml
    echo $(sed -n 's/.*="\/\(.*\)\/.*/\1/ip;T' secrets.lst | uniq | sed -e 's/^/"/' | sed -e 's/$/"/' | sed -e 's/$/,/' | sed ':a;N;$!ba;s/\n/ /g') | sed -e 's/,$//' | sed -e 's/^/    /' >> /etc/confd/conf.d/secrets.toml
    echo -e "]" >> /etc/confd/conf.d/secrets.toml

    JSON_STRING=$(jq -c -n \
                     --arg role_id $VAULT_ROLE_ID \
                     --arg secret_id $VAULT_SECRET_ID \
                     "{ role_id: \$role_id, secret_id: \$secret_id }")

    # Obtain the Vault client token
    RES=$(curl --silent \
               --data "${JSON_STRING}" \
               --request POST "${VAULT_SCHEME}://${VAULT_HOST_ADDR}:${VAULT_TCP_PORT}/v1/auth/approle/login")

    # Verify the token received
    if [ "$?" -eq 0 ]; then
        VAULT_TOKEN=$(echo $RES | jq -r .auth.client_token)
        if [ "$?" -eq 0 ] && [ "${VAULT_TOKEN}" != "null" ]; then
            echo -e "[ OK ] Vault client token has been successfully obtained\n[ INFO ] Render secrets"
            confd -onetime \
                  -log-level ${CONFD_DEBUG_LEVEL} \
                  -confdir ${CONFD_DIR} \
                  -backend vault \
                  -auth-type token \
                  -auth-token ${VAULT_TOKEN} \
                  -node ${VAULT_SCHEME}://${VAULT_HOST_ADDR}:${VAULT_TCP_PORT}

            if [ "$?" -eq 0 ] && [ -e /env/secrets ]; then
                echo -e "[ INFO ] Finished successfully"
            else
                echo -e "[ ERROR ] Environment variables file cannot be read"
                exit 1
            fi
        else
            echo -e "[ ERROR ] Could not obtain the Vault token:\n[ DEBUG ] Status code: $?\n[ DEBUG ] Response received: ${RES}"
            exit 1
        fi
    else
        echo -e "[ ERROR ] Could not obtain the Vault token:\n[ DEBUG ] Status code: $?\n[ DEBUG ] Response received: ${RES}"
        exit 1
    fi
else
    # shellcheck disable=SC2068
    exec $@
fi

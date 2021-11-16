#!/bin/bash

# Enable job control
set -m

# Define optional variables
export TIMEOUT=5
export VAULT_HOST=${VAULT_HOST:-"127.0.0.1"}
export VAULT_TCP_PORT=${VAULT_TCP_PORT:-"8200"}
export VAULT_SCHEME=${VAULT_SCHEME:-"http"}
export VAULT_ADDR="${VAULT_SCHEME}://${VAULT_HOST}:${VAULT_TCP_PORT}"
export VAULT_SKIP_VERIFY="true"

function unseal() {
    # Unseal Vault instance
    for key in "${keys[@]}"
    do
        key=$(echo $key | awk -F= '{ print $2 }')
        echo "[ INFO ] Unsealing using key ${key}"
        VAULT_ADDR="${VAULT_SCHEME}://${VAULT_HOST}:${VAULT_TCP_PORT}" vault operator unseal ${key} >/dev/null
        if [[ $(vault status | grep 'Sealed' | awk '{ print $2 }') == "false" ]]; then
            echo "[ INFO ] Vault is unsealed"
        else
            echo "[ WARNING ] Vault is sealed"
        fi
    done
}

echo "[ INFO ] Start Vault server in background"

vault server -config=/vault/config/vault.hcl >/dev/null &

if [ $? -ne 0 ]; then
  echo -e "[ ERROR ] Failed to start Vault server: $?"
  exit $?
fi

echo "[ INFO ] Wait for Vault on ${VAULT_HOST}:${VAULT_TCP_PORT}"
sleep ${TIMEOUT}

until ncat -z ${VAULT_HOST} ${VAULT_TCP_PORT}
do
    echo "Vault process is unreachable. Sleeping for ${TIMEOUT} seconds."
    sleep ${TIMEOUT}
done

echo -e "[ OK ] Vault is running"

# Get amount of keys needed to unseal Vault
KEYS_TRESHOLD=$(vault status | grep 'Threshold' | awk '{ print $2 }')
# echo ${KEYS_TRESHOLD}

# Get an array of unseal keys from environment variables
tmp=$(env | grep 'VAULT_UNSEAL_KEY_')
tmp2=$(echo $tmp)
IFS=' ' read -r -a keys <<< "$tmp2"
# echo "${keys[@]}"

# Get number of keys provided
KEYS_PROVIDED=$(echo "${#keys[@]}")
# echo "${KEYS_PROVIDED}"

# Verify if there is necessary amount of keys provided
if [ "${KEYS_TRESHOLD}" -gt "${KEYS_PROVIDED}" ]; then
    echo -e "[ WARNING ] Number of keys provided [${KEYS_PROVIDED}] is less than needed [${KEYS_TRESHOLD}]"
else
    # Check if Vault is initialized
    if [[ $(vault status | grep 'Initialized' | awk '{ print $2 }') == "false" ]]; then
        # Vault is not initialized
        echo "[ WARNING ] Vault has not been initialized. Please initialize Vault before unsealing"
    else
        # Vault is initialized
        echo "[ INFO ] Vault is initialized. Try to unseal..."
        unseal
    fi
fi

# Bring the Vault background process to foreground
fg
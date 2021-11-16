#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)
sed 's/=.*/=""/' $REPO_ROOT/setup/.env > $REPO_ROOT/setup/.env.sample
sed -i 's/VAULT_ADDR=""/VAULT_ADDR="http:\/\/localhost:8200"/' $REPO_ROOT/setup/.env.sample
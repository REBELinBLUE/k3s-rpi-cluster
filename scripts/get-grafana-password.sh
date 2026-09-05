#!/bin/bash

set -euo pipefail

PWD=$(kubectl --context pi -n monitoring get secrets vm-grafana -o jsonpath="{.data.admin-password}" | base64 -d)

echo "Grafana initial admin password: $PWD"
echo ""
echo "Forwarding Grafana server to http://localhost:8080"

kubectl --context pi -n monitoring port-forward service/vm-grafana 8080:80
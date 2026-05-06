#!/usr/bin/env bash
# Aplica os manifests k8s de todos os services contra o cluster EKS atual.
# Assume que infra/scripts/bootstrap.sh + infra/rds/create-instance.sh
# já rodaram, e que os ConfigMaps foram atualizados com o endpoint RDS.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

for svc in account-service auth-service product-service order-service exchange-service gateway-service; do
    if [ -d "$ROOT/api/$svc/k8s" ]; then
        echo "→ deploy $svc"
        kubectl apply -f "$ROOT/api/$svc/k8s/"
    fi
done

echo "✓ Manifests aplicados. Verifique:"
echo "  kubectl get pods -A"
echo "  kubectl get ingress"
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller"

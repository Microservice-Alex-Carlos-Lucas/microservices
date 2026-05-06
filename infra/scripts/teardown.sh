#!/usr/bin/env bash
# Desprovisiona TUDO. Roda após a demo para evitar cobrança.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/.env"

echo "Esse script vai destruir cluster EKS '$EKS_CLUSTER_NAME' e RDS '$DB_INSTANCE_ID'."
read -r -p "Continuar? (digite 'destroy' para confirmar) " confirm
[ "$confirm" = "destroy" ] || { echo "abortado."; exit 1; }

echo "[1/2] Deletando RDS (~5 min)..."
aws rds delete-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --skip-final-snapshot \
    --delete-automated-backups \
    --region "$AWS_REGION" 2>&1 | head -5 || true

echo "[2/2] Deletando cluster EKS (~10 min, inclui o LoadBalancer do nginx-ingress)..."
eksctl delete cluster --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" --wait

echo "✓ Tudo destruído. Confira no console AWS para garantir que não sobrou nada."
echo "  Especial atenção: ELBs orfãs custam mesmo sem cluster."

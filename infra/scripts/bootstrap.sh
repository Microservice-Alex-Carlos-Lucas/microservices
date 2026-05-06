#!/usr/bin/env bash
# Provisiona o cluster EKS + nginx-ingress + Redis.
# Postgres é provisionado separadamente via infra/rds/create-instance.sh.
#
# Pré-requisitos: AWS CLI, eksctl, kubectl, helm instalados.
# Custo: ~$0.20/h enquanto cluster + LoadBalancer estiverem up.
# Lembrar de rodar teardown.sh após a apresentação.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/.env"

echo "[1/5] Criando cluster EKS (~10 min)..."
eksctl create cluster -f "$ROOT/eks/cluster.yaml"

echo "[2/5] Configurando kubeconfig..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"

echo "[3/5] Instalando metrics-server (necessário para HPA)..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "[4/5] Instalando nginx-ingress controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx --create-namespace \
    -f "$ROOT/eks/nginx-ingress-values.yaml"

echo "[5/5] Subindo Redis (cache compartilhado)..."
kubectl apply -f "$ROOT/redis/"

echo "✓ Cluster pronto."
echo "Próximos passos:"
echo "  - infra/rds/create-instance.sh   (provisiona RDS, ~5 min)"
echo "  - infra/scripts/deploy-all.sh    (deploya os 6 services)"

#!/usr/bin/env bash
#
# Runbook de gravação do vídeo de apresentação (3-5 min).
# Roteiro segue docs/presentation.md.
#
# Pré-requisitos: cluster EKS up, infra/.env carregado, kubectl configurado.
# Stack local opcional (docker compose) usada APENAS pra demo de cache,
# já que a AwesomeAPI rate-limita o IP do node EKS (HTTP 429).
#
# Uso:
#   bash scripts/demo-video.sh setup      # carrega env + verifica cluster
#   bash scripts/demo-video.sh cache      # demo de cache (Docker compose local)
#   bash scripts/demo-video.sh hpa        # demo HPA (EKS) - 3 min ramp
#   bash scripts/demo-video.sh evidence   # tira prints de evidência

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/infra/.env"

NLB="a94cf70eecacd4522b386e8642429b43-b181d58fe02ec51d.elb.us-east-1.amazonaws.com"
LOCAL_GW="http://localhost:8080"
REMOTE_GW="http://$NLB"

load_env() {
  set -a; source "$ENV_FILE"; set +a
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME" >/dev/null 2>&1 || true
}

login() {
  local base="$1"
  curl -s -i -X POST "$base/auth/login" -H 'Content-Type: application/json' \
    -d '{"email":"demo@store.com","password":"demo123"}' \
    | grep -i "set-cookie" | grep -oE '__store_jwt_token=[^;]+' | head -1 | cut -d= -f2
}

ensure_demo_account() {
  local base="$1"
  curl -s -X POST "$base/auth/register" -H 'Content-Type: application/json' \
    -d '{"name":"demo","email":"demo@store.com","password":"demo123"}' >/dev/null || true
}

case "${1:-help}" in

  setup)
    load_env
    echo "=== Cluster ==="
    kubectl get nodes
    echo ""
    echo "=== Pods ==="
    kubectl get pods
    echo ""
    echo "=== HPA ==="
    kubectl get hpa
    echo ""
    echo "=== NLB ==="
    echo "http://$NLB"
    curl -s -o /dev/null -w "health: HTTP %{http_code}\n" "http://$NLB/health-check"
    ;;

  cache)
    echo ">>> Cache demo via Docker Compose (AwesomeAPI funciona localmente)"
    echo ""
    echo "Subindo stack local..."
    cd "$ROOT/api"
    docker compose up -d redis exchange product gateway auth account
    echo "Aguardando services..."
    sleep 25
    ensure_demo_account "$LOCAL_GW"
    TOKEN=$(login "$LOCAL_GW")
    echo "TOKEN: ${TOKEN:0:30}..."
    echo ""
    echo "=== Exchange USD/BRL — 1ª chamada (cache MISS) ==="
    curl -s --cookie "__store_jwt_token=$TOKEN" \
      -w "HTTP %{http_code} | latency=%{time_total}s\n" \
      "$LOCAL_GW/exchanges/USD/BRL"
    echo ""
    echo "=== Exchange USD/BRL — 2ª chamada (cache HIT) ==="
    curl -s --cookie "__store_jwt_token=$TOKEN" \
      -w "HTTP %{http_code} | latency=%{time_total}s\n" \
      "$LOCAL_GW/exchanges/USD/BRL"
    echo ""
    echo "=== Métricas Prometheus do exchange ==="
    docker compose exec -T exchange curl -s http://localhost:8000/metrics \
      | grep -E "(cache_hits|cache_misses|exchange_)" | head -5
    echo ""
    echo "=== Redis: chaves cacheadas ==="
    docker compose exec -T redis redis-cli KEYS '*'
    ;;

  hpa)
    load_env
    echo ">>> HPA + k6 stress demo"
    echo ""
    echo "Estado inicial:"
    kubectl get hpa gateway
    echo ""
    TOKEN=$(login "$REMOTE_GW")
    if [ -z "$TOKEN" ]; then
      echo "Login falhou. Tentando registrar..."
      ensure_demo_account "$REMOTE_GW"
      TOKEN=$(login "$REMOTE_GW")
    fi
    echo "TOKEN: ${TOKEN:0:30}..."
    echo ""
    echo "Em outro terminal, rode:"
    echo "  watch -n2 'kubectl get hpa,pods -l app=gateway'"
    echo ""
    echo "Pressione ENTER pra começar k6 (ramp 1→200 VUs em 2min)..."
    read -r
    BASE_URL="$REMOTE_GW" TOKEN="$TOKEN" k6 run "$ROOT/scripts/k6/gateway-stress.js"
    echo ""
    echo "Estado final:"
    kubectl get hpa gateway
    kubectl get pods -l app=gateway
    ;;

  evidence)
    load_env
    OUT="$ROOT/docs/evidence"
    mkdir -p "$OUT"
    echo "=== Capturando evidências em $OUT ==="
    kubectl get pods -A -o wide > "$OUT/pods.txt"
    kubectl get hpa -A > "$OUT/hpa.txt"
    kubectl get svc -A > "$OUT/services.txt"
    kubectl top pods 2>/dev/null > "$OUT/top-pods.txt" || true
    aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" \
      --query 'cluster.{name:name,status:status,version:version,createdAt:createdAt}' \
      > "$OUT/eks-cluster.json"
    aws rds describe-db-instances --region "$AWS_REGION" \
      --query 'DBInstances[?DBInstanceIdentifier==`store-db`].{id:DBInstanceIdentifier,status:DBInstanceStatus,engine:Engine,class:DBInstanceClass,endpoint:Endpoint.Address}' \
      > "$OUT/rds.json"
    echo "Evidências:"
    ls -la "$OUT"
    ;;

  help|*)
    cat <<HELP
Comandos:
  setup     - verifica cluster + pods + NLB
  cache     - demo de cache via docker compose (local)
  hpa       - demo de HPA com k6 stress (cluster EKS)
  evidence  - salva pods/hpa/rds/eks em docs/evidence/

Roteiro de gravação:
  1) bash $0 setup           # mostrar cluster up na tela
  2) abrir 2 terminais:
     - watch kubectl get hpa,pods -l app=gateway
     - bash $0 hpa            # roda k6, mostra escala
  3) (opcional) bash $0 cache # demo de cache localmente
  4) bash $0 evidence         # salva snapshots
HELP
    ;;
esac

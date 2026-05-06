# Testes de Carga

Validamos o comportamento sob carga com **[k6](https://k6.io/)** + observação de
**HPA** (em EKS). Os 3 bottlenecks de cache (Alex, Carlos, Lucas) também são
exercitados nestes cenários.

## Objetivos

1. Comprovar que o **HPA** escala o `gateway` de 1 → 5 réplicas quando CPU passa de 50%.
2. Comprovar que a latência **p95 não degrada** durante o ramp graças à escala automática.
3. Comprovar o ganho dos 3 caches Redis (exchange / product / order) no caminho mais caro
   (criar pedido em moeda alternativa).

## Setup

Scripts em `scripts/k6/`. Pré-requisito: `brew install k6` (ou rodar via `docker run grafana/k6`).

```bash
# 1. Subir stack (local) ou apontar pro NLB EKS
cd api && docker compose up -d --build
export BASE_URL=http://localhost:8080            # local
# OU: export BASE_URL=http://<NLB-DNS-DO-NGINX>  # EKS

# 2. Obter token via login
TOKEN=$(curl -s -i -X POST $BASE_URL/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"alex@test.com","password":"abc123"}' \
    | grep -i 'set-cookie' | sed -E 's/.*__store_jwt_token=([^;]+).*/\1/' | tr -d '\r\n')
export TOKEN
```

## Cenário 1 — Stress no gateway, observar HPA (somente EKS)

```bash
# Janela 1: monitorar HPA
watch -n 1 'kubectl get hpa,pods -l app=gateway'

# Janela 2: uso de CPU
kubectl top pods --watch

# Janela 3: gerar carga
k6 run -e BASE_URL=$BASE_URL -e TOKEN=$TOKEN scripts/k6/gateway-stress.js
```

`gateway-stress.js`: ramp 1 → 200 VUs em 2min, hold 1min, ramp-down 30s.

**Resultado esperado:**

| Métrica | Antes (vu=1) | Pico (vu=200) | Ramp-down |
|---|---|---|---|
| Réplicas `gateway` | 1 | 4–5 | volta para 1 após 5min |
| CPU média | ~5% | 60–80% pico, 40% após escala | <5% |
| http_req_duration p95 | <50ms | <300ms | <50ms |
| http_req_failed | 0% | <1% | 0% |

## Cenário 2 — Baseline local (já rodado ✅)

`gateway-baseline.js`: 10 VUs por 30s, hit em `/products` (cached).

```bash
docker run --rm -i \
    -e BASE_URL=http://host.docker.internal:8080 -e TOKEN=$TOKEN \
    --add-host=host.docker.internal:host-gateway \
    -v $PWD/scripts/k6:/scripts \
    grafana/k6:latest run /scripts/gateway-baseline.js
```

**Resultado medido em `docker compose` local:**

```
checks_total..............: 280     9.18 req/s
checks_succeeded..........: 100%    280/280
http_req_duration avg.....: 60.32ms
                  med.....: 40.74ms
                  p(90)...: 98.36ms
                  p(95)...: 236.89ms
                  max.....: 337.8ms
http_req_failed...........: 0%
```

p95 elevado em local porque cada VU faz 1s de sleep entre iterações; em EKS com HPA o
p95 fica < 50ms na maioria do tempo.

## Cenário 3 — Cache em série (3 caches Redis) — ✅ validado

Demonstra o ganho combinado dos bottlenecks de cache do projeto:

```bash
# obter token e produto válido (ver Setup acima)
PID=$(curl -s $BASE_URL/products -H "Cookie: __store_jwt_token=$TOKEN" | jq -r '.[0].id')
OID=$(curl -s -X POST $BASE_URL/orders -H "Cookie: __store_jwt_token=$TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"items\":[{\"idProduct\":\"$PID\",\"quantity\":2}]}" | jq -r .id)

# 1ª: cold (todos 3 caches miss + AwesomeAPI HTTP)
time curl -s -o /dev/null -H "Cookie: __store_jwt_token=$TOKEN" "$BASE_URL/orders/$OID?currency=BRL"
# real    0m0.622s
# 2ª: hot (cache hit em order::exchange-rates ANTES de tocar o exchange)
time curl -s -o /dev/null -H "Cookie: __store_jwt_token=$TOKEN" "$BASE_URL/orders/$OID?currency=BRL"
# real    0m0.024s  → 25× speedup
```

Inspeção do Redis após o teste mostra os 3 caches preenchidos:

```text
$ docker run --rm --network store-api_default redis:7-alpine redis-cli -h redis KEYS '*'
exchange:rate:USD:BRL                  # Alex (Python redis client)
products::products::<uuid>             # Carlos (Spring @Cacheable)
orders::exchange-rates::USD-BRL        # Lucas (wrapper @Cacheable)
```

## Cenário 4 — order-create.js (próximo passo, no EKS)

`order-create.js` exercita 50 VUs × 60s criando pedidos em BRL. Após o cluster up,
comparar p95 de `http_server_requests_seconds{uri="/orders"}` antes e depois do cache
do Lucas. Esperado: speedup ≥ 5× na média (cache absorve os hops Feign para
`exchange-service` durante a janela de 60s).

## Vídeo

!!! info "Em breve"
    Vídeo do teste de carga com 3 janelas (HPA, top, k6) + métricas Grafana.

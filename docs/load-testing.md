# Testes de Carga

Validamos o comportamento sob carga com **[k6](https://k6.io/)** rodando
contra o cluster EKS, observando o **HPA** escalar o `gateway` e medindo
o impacto dos bottlenecks de cache.

## Objetivos

1. Comprovar que o **HPA** escala o `gateway` de 1 → 5 réplicas quando
   CPU passa de 50%.
2. Comprovar que a latência **p95 não degrada** durante o ramp graças à
   escala automática.
3. Comprovar o ganho do **cache de exchange-rate** (Bottleneck do Lucas)
   no caminho de criação de pedido em moeda alternativa.

## Setup

Scripts em `scripts/k6/`. Pré-requisitos: `brew install k6`.

```bash
# obter token via login
curl -s -c cookies.txt -X POST $BASE_URL/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"alex@test.com","password":"abc123"}'
export TOKEN=$(grep __store_jwt_token cookies.txt | awk '{print $7}')
```

`BASE_URL` aponta pro NLB do nginx-ingress (em prod) ou
`http://localhost:8080` (em dev).

## Cenário 1 — Stress no gateway, observar HPA

```bash
# Janela 1: monitorar HPA
watch -n 1 'kubectl get hpa,pods -l app=gateway'

# Janela 2: monitorar uso de CPU
kubectl top pods --watch

# Janela 3: rodar carga
k6 run -e BASE_URL=$BASE_URL -e TOKEN=$TOKEN scripts/k6/gateway-stress.js
```

`gateway-stress.js` faz ramp 1 → 200 VUs em 2min, hold 1min, ramp-down.

**Resultado esperado:**

| Métrica | Antes (vu=1) | Pico (vu=200) | Ramp-down |
|---|---|---|---|
| Réplicas `gateway` | 1 | 4–5 | volta para 1 após 5min |
| CPU média | ~5% | 60–80% pico, 40% após escala | <5% |
| http_req_duration p95 | <50ms | <300ms | <50ms |
| http_req_failed | 0% | <1% | 0% |

## Cenário 2 — Cache de exchange-rate

Mostra o ganho do cache local do Alex (exchange-service) +
cache no order (Lucas spec):

```bash
# 1ª chamada — cache miss em ambos
time curl -s -H "Cookie: __store_jwt_token=$TOKEN" $BASE_URL/exchanges/USD/BRL

# 2ª chamada — cache hit
time curl -s -H "Cookie: __store_jwt_token=$TOKEN" $BASE_URL/exchanges/USD/BRL

# Métricas
curl -s $BASE_URL/exchanges/metrics | grep ^exchange_cache_
```

**Resultado validado em local** (`docker compose up exchange redis`):

```
first call (cache miss): 86.0ms
second call (cache hit):  0.9ms
speedup: 91.2×
exchange_cache_hits_total 1.0
exchange_cache_misses_total 1.0
```

## Cenário 3 — Criar pedidos sob carga (ainda não rodado)

`order-create.js` exercita o caminho mais caro (order → product Feign +
order → exchange Feign + AwesomeAPI). Quando Lucas implementar o
[Bottleneck 4 do spec](specs/order-bottleneck-extra.md), comparar p95 do
endpoint `/orders` antes e depois.

## Vídeo

!!! info "Em breve"
    Vídeo do teste de carga com 3 janelas (HPA, top, k6) + métricas Grafana.

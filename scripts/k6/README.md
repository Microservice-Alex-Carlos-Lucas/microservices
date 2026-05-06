# k6 load tests

Scripts para validar carga, observar HPA escalando, e demonstrar o efeito
dos bottlenecks (caching).

## Como rodar

```bash
brew install k6  # uma vez

# variáveis úteis pra apontar pro alvo
export BASE_URL=http://localhost:8080            # local (docker compose)
# ou
export BASE_URL=http://<NLB-DNS-DO-NGINX>        # EKS

# obter token (login → guarda cookie)
curl -s -c cookies.txt -X POST $BASE_URL/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"alex@test.com","password":"abc123"}'
export TOKEN=$(grep __store_jwt_token cookies.txt | awk '{print $7}')

# rodar
k6 run -e BASE_URL=$BASE_URL -e TOKEN=$TOKEN scripts/k6/gateway-stress.js
```

## Scripts

| Script | VUs / duração | Objetivo |
|---|---|---|
| `gateway-baseline.js` | 10 / 30s | warmup, métricas-base sem stress |
| `gateway-stress.js` | ramp 1→200 / 3min | dispara HPA (CPU > 50%) |
| `order-create.js` | 50 / 60s | exercita Feign+cache (order→product+exchange) |

## Demo HPA (3 janelas)

```bash
# janela 1
watch -n 1 'kubectl get hpa,pods -l app=gateway'

# janela 2
kubectl top pods --watch

# janela 3
k6 run -e BASE_URL=http://<NLB-DNS> -e TOKEN=$TOKEN scripts/k6/gateway-stress.js
```

Resultado esperado: `gateway` escala 1 → 5 réplicas durante o ramp, e
volta a 1 após 5 minutos sem carga.

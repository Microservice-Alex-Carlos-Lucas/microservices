# Exchange API

**Responsável:** Alex Chequer  
**Repositório:** [Microservice-Alex-Carlos-Lucas/exchange](https://github.com/Microservice-Alex-Carlos-Lucas/exchange)  
**Documentação individual:** [alexchequer.github.io/exchange](https://alexchequer.github.io/exchange)

---

## Descrição

API em Python (FastAPI) que retorna taxas de câmbio em tempo real entre duas moedas,
usando a [AwesomeAPI](https://docs.awesomeapi.com.br/api-de-moedas) como fonte.

## Endpoint

### `GET /exchanges/{from}/{to}`

!!! info "Autenticação obrigatória"
    Requer cookie `__store_jwt_token`. O gateway injeta `id-account` automaticamente.

**Resposta 200:**
```json
{
  "sell": 5.74,
  "buy":  5.73,
  "date": "2024-04-22 09:00:00",
  "id-account": "abc-123-def-456"
}
```

### `GET /exchanges/health-check`

Rota aberta. Retorna `{"status": "ok"}`.

## Stack

| Item | Detalhe |
|------|---------|
| Linguagem | Python 3.13 |
| Framework | FastAPI |
| Gerenciador | uv |
| Fonte de dados | AwesomeAPI (gratuita, sem chave) |
| Containerização | Docker (python:3.13-slim + uv) |

## Bottlenecks implementados

1. **Caching** — cache em memória com TTL de 60s por par de moedas, eliminando chamadas
   redundantes à AwesomeAPI sob carga
2. **Observabilidade** — `prometheus-fastapi-instrumentator` expõe `/metrics` com latência,
   throughput e erros HTTP para Prometheus/Grafana

Detalhes completos: [documentação individual](https://alexchequer.github.io/exchange/bottlenecks/)

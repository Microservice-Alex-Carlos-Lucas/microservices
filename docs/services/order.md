# Order API

**Responsável:** Lucas  
**Repositório:** [Microservice-Alex-Carlos-Lucas/order-service](https://github.com/Microservice-Alex-Carlos-Lucas/order-service)

---

## Descrição

API REST para gerenciamento de pedidos dos usuários autenticados. Integra-se com
product-service (via OpenFeign) para obter detalhes dos produtos, e com exchange-service
para conversão de moeda nos totais.

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/orders` | Criar pedido para o usuário autenticado |
| `GET` | `/orders` | Listar pedidos do usuário autenticado |
| `GET` | `/orders/{id}` | Detalhar pedido (aceita `?currency=BRL`) |

**POST /orders — request:**
```json
{
  "items": [
    { "idProduct": "0195abfb-7074-73a9-9d26-b4b9fbaab0a8", "quantity": 2 },
    { "idProduct": "0195abfe-e416-7052-be3b-27cdaf12a984", "quantity": 1 }
  ]
}
```

**GET /orders/{id}?currency=BRL — response:**
```json
{
  "id": "0195ac33-73e5-7cb3-90ca-7b5e7e549569",
  "date": "2025-09-01T12:30:00",
  "currency": "BRL",
  "items": [
    { "id": "...", "product": { "id": "..." }, "quantity": 2, "total": 116.28 }
  ],
  "total": 151.73
}
```

## Inter-service communication

| Serviço | Protocolo | Propósito |
|---------|-----------|-----------|
| product-service | OpenFeign | Obter nome/preço do produto |
| exchange-service | OpenFeign | Converter total de USD para a moeda solicitada |

## Stack

| Item | Detalhe |
|------|---------|
| Linguagem | Java 25 |
| Framework | Spring Boot 4.0.3 + Spring Cloud OpenFeign |
| Banco | PostgreSQL (schema: `orders`) — RDS em produção |
| Migrações | Flyway |
| Cache | Redis (wrapper `@Cacheable` no Feign do exchange-service, TTL 60s) |
| Métricas | Prometheus via Actuator |
| Orquestração | Kubernetes (EKS) com HPA (target 50% CPU, 1-5 réplicas) |
| CI/CD | Jenkins — Build → Push → Deploy to EKS |

## Status

- CRUD endpoints + integração com product/exchange via Feign: ✅
- Cache do `ExchangeClient` (bottleneck 1, 25× speedup no GET com moeda alternativa): ✅
- `@Timed` + counter `orders.created` (bottleneck 2): ✅
- k8s manifests + HPA: ✅
- Deploy em cluster EKS (`store-cluster`): ✅
- Pipeline Jenkins (Build → Push → Deploy to EKS): ✅

Documentação detalhada por bottleneck em
[microservice-alex-carlos-lucas.github.io/order-service](https://microservice-alex-carlos-lucas.github.io/order-service/).

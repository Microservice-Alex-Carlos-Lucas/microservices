# Product API

**Responsável:** Carlos  
**Repositório:** [Microservice-Alex-Carlos-Lucas/product-service](https://github.com/Microservice-Alex-Carlos-Lucas/product-service)

---

## Descrição

API REST para gerenciamento de produtos da loja. Permite criar, listar, buscar e deletar produtos.

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/products` | Criar produto |
| `GET` | `/products` | Listar todos os produtos |
| `GET` | `/products/{id}` | Buscar produto por ID |
| `DELETE` | `/products/{id}` | Deletar produto |

**POST /products — request:**
```json
{
  "name": "Tomato",
  "price": 10.12,
  "unit": "kg"
}
```

**GET /products — response:**
```json
[
  {
    "id": "0195abfb-7074-73a9-9d26-b4b9fbaab0a8",
    "name": "Tomato",
    "price": 10.12,
    "unit": "kg"
  }
]
```

## Stack

| Item | Detalhe |
|------|---------|
| Linguagem | Java 25 |
| Framework | Spring Boot 4.0.3 |
| Banco | PostgreSQL (schema: `products`) — RDS em produção |
| Migrações | Flyway |
| Cache | Redis (`@Cacheable` + `RedisCacheManager`, TTL 60s) |
| Métricas | Prometheus via Actuator |
| Orquestração | Kubernetes (EKS) com HPA (target 50% CPU, 1-5 réplicas) |
| CI/CD | Jenkins — Build → Push → Deploy to EKS |

## Status

- CRUD endpoints: ✅
- Cache Redis via `@Cacheable` (bottleneck 1, 3× speedup medido): ✅
- Métrica nativa de cache (Spring): ✅
- k8s manifests + HPA: ✅
- Deploy em cluster EKS (`store-cluster`): ✅
- Pipeline Jenkins (Build → Push → Deploy to EKS): ✅

Documentação detalhada por bottleneck em
[microservice-alex-carlos-lucas.github.io/product-service](https://microservice-alex-carlos-lucas.github.io/product-service/).

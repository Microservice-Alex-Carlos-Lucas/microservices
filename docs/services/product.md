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
| Banco | PostgreSQL (schema: `products`) |
| Migrações | Flyway |
| Métricas | Prometheus via Actuator |

!!! note "Status"
    Implementação em andamento. Scaffold disponível no repositório.

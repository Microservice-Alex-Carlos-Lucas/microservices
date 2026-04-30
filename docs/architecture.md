# Arquitetura

## Visão geral

A plataforma segue o padrão de **API Gateway + Trusted Layer**. Todo tráfego externo passa pelo gateway, que valida o JWT antes de encaminhar para os serviços internos.

```mermaid
graph LR
    internet([Internet]) -->|HTTP| gateway

    subgraph trusted[Trusted Layer]
        gateway -->|/accounts/**| account
        gateway -->|/auth/**| auth
        gateway -->|/products/**| product
        gateway -->|/orders/**| order
        gateway -->|/exchanges/**| exchange

        auth -->|valida JWT| gateway
        account --> db[(PostgreSQL\nschemas: accounts)]
        product --> db2[(PostgreSQL\nschemas: products)]
        order --> db3[(PostgreSQL\nschemas: orders)]
    end

    order -->|OpenFeign\n/products/{id}| product
    order -->|OpenFeign\n/exchanges/{from}/{to}| exchange
    exchange -->|HTTP| awesomeapi([AwesomeAPI])
```

## Fluxo de autenticação

```mermaid
sequenceDiagram
    actor User
    participant Gateway
    participant Auth
    participant Service

    User->>Gateway: POST /auth/login
    Gateway->>Auth: POST /auth/login (rota aberta)
    Auth-->>Gateway: Set-Cookie: __store_jwt_token
    Gateway-->>User: 200 OK + cookie

    User->>Gateway: GET /products (cookie JWT)
    Gateway->>Auth: POST /auth/solve
    Auth-->>Gateway: { idAccount }
    Gateway->>Service: GET /products (header: id-account)
    Service-->>Gateway: 200 OK
    Gateway-->>User: 200 OK
```

## Fluxo de criação de pedido com câmbio

```mermaid
sequenceDiagram
    actor User
    participant Gateway
    participant Order
    participant Product
    participant Exchange
    participant AwesomeAPI

    User->>Gateway: GET /orders/{id}?currency=BRL
    Gateway->>Order: GET /orders/{id}?currency=BRL
    Order->>Product: GET /products/{id}  (Feign)
    Product-->>Order: { id, name, price }
    Order->>Exchange: GET /exchanges/USD/BRL  (Feign)
    Exchange->>AwesomeAPI: GET /json/last/USD-BRL
    AwesomeAPI-->>Exchange: { bid, ask }
    Exchange-->>Order: { sell, buy, date }
    Order-->>Gateway: { id, date, currency: BRL, items, total }
    Gateway-->>User: 200 OK
```

## Stack técnica

| Serviço | Linguagem | Framework | Banco |
|---------|-----------|-----------|-------|
| gateway-service | Java 25 | Spring Cloud Gateway | — |
| auth-service | Java 25 | Spring Boot 4.0.3 | PostgreSQL |
| account-service | Java 25 | Spring Boot 4.0.3 | PostgreSQL |
| product-service | Java 25 | Spring Boot 4.0.3 | PostgreSQL |
| order-service | Java 25 | Spring Boot 4.0.3 | PostgreSQL |
| exchange | Python 3.13 | FastAPI | — (AwesomeAPI) |

## Infraestrutura

- **Orquestração:** Kubernetes (EKS na AWS)
- **CI/CD:** Jenkins + Docker Hub
- **Banco de dados:** PostgreSQL (RDS ou deployment k8s)
- **Observabilidade:** Prometheus + Grafana

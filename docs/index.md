# Store Platform

**Grupo:** Alex Chequer, Carlos, Lucas  
**Disciplina:** Plataformas, Microserviços, DevOps e APIs — Insper 2026.1  
**Instrutor:** Humberto Sandmann

---

## Sobre o projeto

Aplicação web de e-commerce com arquitetura de microserviços. Os usuários podem comprar e vender produtos em múltiplas moedas. A plataforma é composta por seis serviços independentes, orquestrados via Kubernetes (EKS) e integrados por um API Gateway.

## Membros e responsabilidades

| Membro | Microserviço | Repositório |
|--------|-------------|-------------|
| Alex Chequer | Exchange API (Python/FastAPI) | [exchange](https://github.com/Microservice-Alex-Carlos-Lucas/exchange) |
| Carlos | Product API (Java/Spring Boot) | [product-service](https://github.com/Microservice-Alex-Carlos-Lucas/product-service) |
| Lucas | Order API (Java/Spring Boot) | [order-service](https://github.com/Microservice-Alex-Carlos-Lucas/order-service) |

## Repositórios

| Serviço | Repositório |
|---------|-------------|
| Plataforma (raiz) | [microservices](https://github.com/Microservice-Alex-Carlos-Lucas/microservices) |
| Exchange API | [exchange](https://github.com/Microservice-Alex-Carlos-Lucas/exchange) |
| Product API | [product-service](https://github.com/Microservice-Alex-Carlos-Lucas/product-service) |
| Order API | [order-service](https://github.com/Microservice-Alex-Carlos-Lucas/order-service) |
| Account Service | [account-service](https://github.com/Microservice-Alex-Carlos-Lucas/account-service) |
| Auth Service | [auth-service](https://github.com/Microservice-Alex-Carlos-Lucas/auth-service) |
| Gateway Service | [gateway-service](https://github.com/Microservice-Alex-Carlos-Lucas/gateway-service) |

## Status de entrega

| Tarefa | Peso | Status |
|--------|------|--------|
| API Gateway | 5% | ✅ Concluído |
| Auth | 5% | ✅ Concluído |
| Account | 5% | ✅ Concluído |
| Exchange API | 5% | ✅ Concluído |
| Bottlenecks | 20% | 🔄 Em andamento |
| AWS | 5% | ⏳ Pendente |
| EKS | 10% | ⏳ Pendente |
| CI/CD (Jenkins) | 10% | 🔄 Em andamento |
| Load Testing | 15% | ⏳ Pendente |
| Custos & PaaS & SLA | 10% | ⏳ Pendente |
| MkDocs | 10% | 🔄 Em andamento |

## Arquitetura geral

```mermaid
graph LR
    internet([Internet]) -->|request| gateway

    subgraph trusted[Trusted Layer]
        gateway --> auth
        gateway --> account
        gateway --> product
        gateway --> order
        gateway --> exchange
        account --> db[(PostgreSQL)]
        product --> db
        order --> db
    end

    order -->|Feign| product
    order -->|Feign| exchange
    exchange -->|HTTP| awesomeapi([AwesomeAPI\n3rd-party])
```

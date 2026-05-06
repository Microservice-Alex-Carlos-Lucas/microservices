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
| Bottlenecks (todos os 6 implementados + medidos) | 20% | ✅ Concluído |
| AWS | 5% | 🔑 Aguarda credencial (infra pronta em `infra/`) |
| EKS | 10% | 🔑 Aguarda execução do `infra/scripts/bootstrap.sh` |
| CI/CD (Jenkins) | 10% | ✅ Pipelines com Build + Push + Deploy to EKS |
| Load Testing | 15% | ✅ k6 baseline rodado, scripts prontos para HPA demo |
| Custos & PaaS & SLA | 10% | ✅ Documentado |
| MkDocs | 10% | ✅ 4 sites publicados (parent + exchange + order + product) |

🔑 = bloqueado apenas pela falta de credencial AWS — todo o resto da
infraestrutura (manifests k8s, scripts eksctl, RDS, nginx-ingress, Redis)
está pronto pra rodar.

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

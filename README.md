# Store Platform

Aplicação web de e-commerce com arquitetura de microserviços. **Insper 2026.1** — Plataformas, Microserviços, DevOps e APIs (Humberto Sandmann).

**Grupo:** Alex Chequer · Carlos · Lucas

## Documentação

📖 **Site público:** publicado via GitHub Pages (`mkdocs gh-deploy`).
Estrutura completa em `docs/` (Architecture, Services, Infra/AWS-EKS-CICD, Bottlenecks, Custos, Load Testing).

## Repositórios

| Componente | Link |
|---|---|
| Plataforma (este) | [Microservice-Alex-Carlos-Lucas/microservices](https://github.com/Microservice-Alex-Carlos-Lucas/microservices) |
| Gateway Service | [gateway-service](https://github.com/Microservice-Alex-Carlos-Lucas/gateway-service) |
| Auth (interface) | [auth](https://github.com/Microservice-Alex-Carlos-Lucas/auth) |
| Auth Service | [auth-service](https://github.com/Microservice-Alex-Carlos-Lucas/auth-service) |
| Account Service | [account-service](https://github.com/Microservice-Alex-Carlos-Lucas/account-service) |
| Product API (Carlos) | [product-service](https://github.com/Microservice-Alex-Carlos-Lucas/product-service) |
| Order API (Lucas) | [order-service](https://github.com/Microservice-Alex-Carlos-Lucas/order-service) |
| Exchange API (Alex) | [exchange](https://github.com/Microservice-Alex-Carlos-Lucas/exchange) |

## Quick start (dev local)

```bash
git clone --recurse-submodules <repo>
cd microservices/api
docker compose up -d --build       # 6 services + Postgres + Redis
curl http://localhost:8080/health-check
```

## Quick start (produção EKS)

```bash
cp infra/.env.example infra/.env   # preencher AWS creds + DB password
infra/scripts/bootstrap.sh         # ~10 min: cria EKS + nginx-ingress + Redis
infra/rds/create-instance.sh       # ~5 min: cria RDS db.t3.micro
infra/scripts/deploy-all.sh        # aplica os 6 services
# após apresentação:
infra/scripts/teardown.sh          # destrói tudo
```

Detalhes em [`infra/README.md`](infra/README.md).

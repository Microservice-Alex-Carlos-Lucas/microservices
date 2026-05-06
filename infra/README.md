# Infrastructure

Manifests, scripts e specs para subir o cluster EKS + RDS Postgres +
nginx-ingress + Redis para a Store Platform.

## Quick start (apresentação)

```bash
cd infra
cp .env.example .env
$EDITOR .env  # preencher AWS_*, DB_PASSWORD

./scripts/bootstrap.sh        # ~10 min: cria EKS + nginx-ingress + Redis
./rds/create-instance.sh      # ~5 min: cria RDS db.t3.micro
# atualizar DATABASE_HOST nos ConfigMaps de account/product/order com o
# endpoint impresso no final do create-instance.sh
./scripts/deploy-all.sh       # aplica todos os k8s/ dos services

# após a demo:
./scripts/teardown.sh         # destrói tudo (~15 min)
```

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `eks/cluster.yaml` | spec do `eksctl` (2× t3.medium, us-east-1, OIDC) |
| `eks/nginx-ingress-values.yaml` | values do Helm chart `ingress-nginx/ingress-nginx` |
| `redis/{deployment,service}.yaml` | Redis 7 como pod (cache, sem PVC) |
| `rds/create-instance.sh` | provisiona RDS Postgres acessível pelo VPC do EKS |
| `rds/schema-init.md` | notas sobre Flyway, schemas e troubleshooting |
| `scripts/bootstrap.sh` | cria cluster + nginx-ingress + Redis |
| `scripts/deploy-all.sh` | `kubectl apply` em todos os `api/*/k8s/` |
| `scripts/teardown.sh` | destrói cluster + RDS (idempotente) |
| `.env.example` | template; copie para `.env` (gitignored) |

## Custo estimado

| Recurso | $/h | Notas |
|---|---|---|
| EKS Control Plane | 0.10 | flat rate |
| 2× t3.medium nodes | 0.083 | on-demand us-east-1 |
| NLB (nginx-ingress) | 0.025 | Network LB |
| RDS db.t3.micro | 0.017 | Single-AZ |
| **Total** | **~0.225/h** | ~$5 por dia se ficar 24/7 |

> Para o trabalho de aula, deixar tudo up só durante a apresentação
> (~30 min): custo final ~$0.10. Configurar AWS Budget Alert em $5
> como rede de segurança.

## Por que essas escolhas

- **EKS** vs ECS/auto-managed: EKS é PaaS gerenciado, encaixa no peso
  "Custos & PaaS" do projeto.
- **RDS** vs Postgres-pod: PaaS legítimo, justifica o doc de PaaS&SLA.
- **nginx-ingress** vs ALB Ingress Controller: chart Helm pronto,
  zero IAM extra, suporta L7 (rate-limit, gzip, paths) via annotations.
- **Redis pod** vs ElastiCache: cache é volátil, não vale o custo
  adicional de ElastiCache para uma demo de aula.
- **AWS keys via .env**: simplicidade. Em produção real, usaríamos IRSA
  para pods + IAM Roles para o Jenkins.

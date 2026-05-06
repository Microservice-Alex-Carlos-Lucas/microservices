# AWS

A plataforma roda em **AWS EKS + RDS + NLB**, provisionada via
`eksctl` + `aws cli`. Toda a configuração está versionada em
[`infra/`](https://github.com/Microservice-Alex-Carlos-Lucas/microservices/tree/main/infra).

## Conta e credenciais

- **Conta AWS:** ativada com cartão de crédito + Budget Alert em $5/mês para evitar surpresa.
- **IAM user `cluster-admin`:** Access Key gerada, policy `AdministratorAccess` (escopo de aula). Em produção real, policy mínima específica para EKS + RDS.
- **Region:** `us-east-1` — região com menor preço para EKS + maior disponibilidade de instâncias t3.

## Configuração local

Credenciais ficam em `infra/.env` (gitignored). Template em `infra/.env.example`:

```bash
cp infra/.env.example infra/.env
# preencher AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, DB_PASSWORD
```

Esse `.env` é montado no container do Jenkins (via `env_file:` em `jenkins/compose.yaml`)
para o stage `Deploy to EKS` autenticar.

## Serviços utilizados

| Serviço | Propósito | Custo |
|---|---|---|
| **EKS** | Kubernetes gerenciado (control plane) | $0.10/h |
| **EC2** (NodeGroup) | 2× t3.medium para os pods | $0.083/h total |
| **RDS Postgres** | DB gerenciado (db.t3.micro, single-AZ) | $0.017/h |
| **NLB** | Network LoadBalancer do nginx-ingress (entry point) | $0.025/h |
| **Docker Hub** | Registry das imagens (`cheqr/*`) | grátis |
| **GitHub Pages** | Hospedagem deste site MkDocs | grátis |

> Custo agregado durante demo: **~$0.225/h**. Apresentação de 30min ≈ $0.12.

## Estratégia de custo controlado

`infra/scripts/teardown.sh` roda imediatamente após a apresentação:
- `aws rds delete-db-instance --skip-final-snapshot`
- `eksctl delete cluster --wait` (deleta também o NLB do nginx-ingress)

Verificação via `aws ce get-cost-and-usage` no fim do mês para garantir que não sobrou nada.

## Diagrama

```mermaid
graph TB
    subgraph aws[AWS us-east-1]
        subgraph vpc[EKS VPC]
            subgraph cp[Control Plane (managed)]
                eks[EKS API]
            end
            subgraph nodes[NodeGroup 2× t3.medium]
                gw[gateway pods<br/>HPA 1-5]
                auth[auth pod]
                acc[account pod]
                prod[product pods]
                ord[order pods]
                exch[exchange pods]
                redis[redis pod]
                nginx[nginx-ingress pod]
            end
            rds[(RDS Postgres<br/>db.t3.micro)]
        end
        nlb[NLB<br/>internet-facing]
    end
    Internet --> nlb --> nginx --> gw
    gw --> auth & acc & prod & ord & exch
    acc & prod & ord --> rds
    exch & prod & ord --> redis
```

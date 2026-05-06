# Custos & PaaS

Os custos abaixo são reais para a configuração definida em `infra/eks/cluster.yaml`,
em `us-east-1`, durante o tempo em que o cluster fica de pé.

## Custo por hora (cluster up)

| Recurso | Configuração | $/h |
|---|---|---|
| EKS Control Plane | 1 cluster | 0.10 |
| EC2 NodeGroup | 2× t3.medium on-demand | 0.083 |
| NLB (nginx-ingress) | 1 Network Load Balancer | 0.025 |
| RDS Postgres | db.t3.micro single-AZ, 20GB | 0.017 |
| **Total** | | **~0.225/h** |

## Custo de demo

Para a apresentação de aula, o cluster fica up apenas durante a janela de
demo (~30 min). Custo estimado: **$0.12 por apresentação**.

`infra/scripts/teardown.sh` roda imediatamente depois pra desligar tudo.
AWS Budget Alert em $5/mês como rede de segurança.

## Custo se 24/7 (referencial)

| Cenário | Custo/mês |
|---|---|
| Sempre ligado (~$0.225/h × 730h) | ~$165 |
| Cluster + RDS Multi-AZ (HA produção) | ~$220 |
| Free tier não cobre EKS — só RDS db.t3.micro 750h/mês no 1º ano | — |

## Comparativo PaaS vs IaaS vs alternativas

| Plataforma | Custo equivalente | Trade-off |
|---|---|---|
| **AWS EKS + RDS** (atual) | ~$165/mês | mais flexível, mas mais ops |
| Heroku Eco + Postgres Mini | ~$30/mês (5 dynos) | mais simples, sem Kubernetes — não atende exigência didática |
| Render (Web Service + Postgres) | ~$50/mês | mais simples, sem HPA real |
| Fly.io (machines + Postgres) | ~$40/mês | distribuição global, escala manual por padrão |
| **EC2 self-managed** | ~$60/mês (1× t3.medium) | mais barato, mas perde "PaaS" — backup, patch, HA viram problema seu |

A escolha de EKS+RDS é deliberada: o **peso "Custos & PaaS & SLA" do projeto
exige PaaS legítimo**, e o custo adicional é justificável pelo que
abstrai (control plane, backup automático, failover potencial).

## PaaS utilizados

| Serviço | Tipo | Por que esse |
|---------|------|-----------|
| **AWS EKS** | PaaS — Kubernetes gerenciado | control plane sem manutenção; necessário pra exibir HPA + ingress |
| **AWS RDS** | PaaS — banco gerenciado | backups, patches e failover (Multi-AZ futuro) sem operação |
| **Docker Hub** | PaaS — registry | grátis; multi-arch via buildx funciona out-of-the-box |
| **GitHub Pages** | PaaS — hosting estático | deploy do MkDocs via `mkdocs gh-deploy` no CI |

## SLA esperado (publicado pela AWS)

| Componente | SLA AWS | Impacto |
|-----------|---------|---------|
| EKS Control Plane | [99.95%](https://aws.amazon.com/eks/sla/) | API server sempre disponível |
| RDS Single-AZ | [99.5%](https://aws.amazon.com/rds/sla/) | sem failover automático — risco assumido pra reduzir custo |
| RDS Multi-AZ | 99.95% | upgrade quando produção real |
| NLB | [99.99%](https://aws.amazon.com/elasticloadbalancing/sla/) | entry point altamente disponível |
| Compose de tudo (P × disponibilidade) | ~99.4% | aceitável pra MVP de aula |

## Otimizações possíveis (não aplicadas)

- **Spot Instances** para o NodeGroup: -60% no custo de EC2, com risco de
  preempção (não vale para demo curta — vale para staging persistente).
- **t4g.medium (Graviton)** ao invés de t3.medium: -10% e melhor perf/$
  para Java 25 (que tem suporte ARM nativo). Imagens Docker já são
  multi-arch (`--platform=linux/arm64,linux/amd64`).
- **ElastiCache Redis** ao invés de pod: maior disponibilidade, mas
  +$0.017/h. Não vale pro caso de aula.

# Custos & PaaS

!!! warning "Em andamento"
    Esta seção será preenchida após a configuração da AWS.

## Estimativa de custos (AWS Pricing Calculator)

| Serviço | Configuração | Custo estimado/mês |
|---------|-------------|-------------------|
| EKS Cluster | 1 cluster | ~$72 |
| EC2 Node Group | 2x t3.medium | ~$60 |
| RDS PostgreSQL | db.t3.micro, 20GB | ~$25 |
| Load Balancer | Application LB | ~$20 |
| **Total estimado** | | **~$177/mês** |

> Valores aproximados para região us-east-1. Consulte a
> [calculadora AWS](https://calculator.aws/pricing/2/home) para valores exatos.

## PaaS utilizado

| Serviço | Tipo | Descrição |
|---------|------|-----------|
| AWS EKS | PaaS | Kubernetes gerenciado — sem necessidade de gerenciar o plano de controle |
| AWS RDS | PaaS | Banco de dados gerenciado — backups, patches e alta disponibilidade automáticos |
| Docker Hub | PaaS | Registro de imagens Docker gerenciado |

### Por que PaaS?

O uso de EKS e RDS elimina a necessidade de gerenciar infraestrutura de baixo nível
(patches de SO, backups, alta disponibilidade), permitindo que o time foque no código de
negócio. O custo adicional é justificado pela redução de operação manual.

## SLA esperado

| Componente | SLA AWS | Impacto |
|-----------|---------|---------|
| EKS | 99.95% | Plano de controle sempre disponível |
| RDS Multi-AZ | 99.95% | Failover automático |
| Load Balancer | 99.99% | Entrada da plataforma |

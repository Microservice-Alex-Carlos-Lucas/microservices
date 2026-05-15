# PaaS

Esta seção justifica a escolha de **Platform-as-a-Service** para o projeto:
o que está sendo abstraído, por que esse modelo, e quais SLAs herdamos.

## O que é PaaS no nosso contexto

Em vez de provisionar máquinas e instalar tudo na mão (IaaS), usamos serviços
gerenciados que cuidam de control plane, patching, backup e disponibilidade.
O grupo entrega manifestos e código — o provedor entrega plataforma.

## Tecnologias PaaS utilizadas

### Amazon EKS — orquestração de containers

**Classificação:** PaaS (mais precisamente CaaS — *Container as a Service*).

Embora Kubernetes em si seja um orquestrador, ao usar **EKS** (Amazon Elastic
Kubernetes Service) na modalidade gerenciada, transferimos para a AWS toda a
responsabilidade do *control plane*:

- API server, scheduler e `etcd` rodando em alta disponibilidade gerenciada
- Patches de segurança aplicados pela AWS
- Atualizações de versão do Kubernetes sem downtime do plano de controle
- Multi-AZ para a control plane (mesmo no nosso cluster single-AZ pra data plane)

**O que nós ainda fazemos:** declarar `Deployment`, `Service`, `Ingress`,
`HPA` etc. via manifestos. A AWS cuida do resto.

### Amazon RDS — banco de dados gerenciado

**Classificação:** PaaS.

PostgreSQL `db.t3.micro` gerenciado pela AWS:

- Backups automáticos diários (retenção 7 dias por default)
- Snapshots manuais sob demanda
- Patches do PostgreSQL aplicados em janela de manutenção configurável
- Failover automático (em modo Multi-AZ — não habilitado aqui pra reduzir custo)
- Métricas (CPU, conexões, IOPS) expostas no CloudWatch sem instrumentação extra

**O que nós ainda fazemos:** versionar schema via **Flyway**, gerenciar
usuários da aplicação, definir parameter group.

### Docker Hub — registry de imagens

**Classificação:** PaaS (registry como serviço).

- Imagens `cheqr/<service>` publicadas pelo Jenkins
- Multi-arch (`linux/amd64`, `linux/arm64`) via `docker buildx`
- Gratuito para repositórios públicos, sem limite de pulls

### GitHub Pages — hospedagem do MkDocs

**Classificação:** PaaS (hosting estático).

- Site gerado por `mkdocs gh-deploy` rodando no GitHub Actions
- HTTPS automático com certificado renovado
- CDN global da Microsoft (Azure Front Door)

### Ferramentas que **não** são PaaS no projeto

| Tecnologia | Categoria | Por que não PaaS |
|---|---|---|
| **Docker** | Runtime/ferramenta | Empacota apps; é a base que roda *sobre* o PaaS, não é serviço |
| **Jenkins** | Auto-hospedado (IaaS-like) | Roda em container local (`jenkins/compose.yaml`) — operamos o servidor |
| **Redis** | Software (containerizado) | Roda como pod no cluster — componente da aplicação, não serviço externo gerenciado |
| **nginx-ingress** | Software (containerizado) | Roda como pod no cluster |

> Se quiséssemos elevar Jenkins/Redis pra PaaS legítimo, trocaríamos por:
> **AWS CodePipeline + CodeBuild** (CI/CD gerenciado) e **ElastiCache Redis**
> (Redis gerenciado). Decisão deliberada de manter self-managed pelo trade-off
> de custo num projeto de aula.

## Por que esse modelo (alinhamento com a disciplina)

O peso "Custos & PaaS & SLA" do projeto exige PaaS legítimo. A escolha de
EKS+RDS atende essa demanda *e* alinha com tópicos da disciplina:

- **DevOps + Cloud Computing.** Adotamos práticas de *NoOps* na camada base —
  o esforço do grupo concentra-se em CI/CD (Jenkins), bottlenecks (cache
  Redis nos 3 services) e qualidade do código, não em manter sistema operacional.
- **Microsserviços.** EKS permite isolar cada serviço em seu próprio
  Deployment com HPA independente — algo difícil de simular em PaaS mais
  simples como Heroku ou Render.
- **SLA herdado da AWS.** Confiando o control plane à AWS, herdamos o SLA
  publicado por eles (ver tabela em [Custos & SLA](costs.md)).

## Comparativo: por que não outras opções

Se o requisito fosse só "rodar a aplicação", várias plataformas seriam mais
baratas. Cada uma tem trade-offs incompatíveis com o escopo do projeto:

| Alternativa | Custo/mês | Por que não atende |
|---|---|---|
| **Heroku Eco + Postgres Mini** | ~$30 | Sem Kubernetes — não exibe HPA + manifests, requisitos didáticos |
| **Render** (Web Service + Postgres) | ~$50 | Sem HPA real configurável; ingress fixo |
| **Fly.io** (machines + Postgres) | ~$40 | Escala manual por padrão; sem Kubernetes nativo |
| **EC2 self-managed** (1× t3.medium) | ~$60 | Mais barato em $, mas perde a categoria PaaS — backup, patch e HA viram nossos |
| **AWS EKS + RDS** (atual) | ~$165 | **Atende todos os critérios da disciplina** |

A diferença de custo (~$100/mês para EKS+RDS vs alternativas) é o preço da
abstração PaaS que o projeto exige demonstrar.

## Resumo técnico

| Tecnologia | Classificação | Justificativa |
|---|---|---|
| **AWS EKS** | PaaS / CaaS | AWS gerencia hardware, SO e control plane do K8s — consumimos a API |
| **AWS RDS** | PaaS | DB gerenciado com backup automático e patches |
| **Docker Hub** | PaaS (registry) | Storage e distribuição de imagens — sem ops |
| **GitHub Pages** | PaaS (hosting) | Build + deploy do MkDocs sem servidor próprio |
| **Docker** | Ferramenta / runtime | Roda *sobre* o PaaS, não é PaaS |
| **Jenkins** | Self-managed | Hospedado em container local pelo grupo |
| **Redis** | Software (container) | Pod no cluster — componente da app, não serviço gerenciado |

Para os números de custo concreto e o detalhamento de SLA por componente,
ver [Custos & SLA](costs.md).

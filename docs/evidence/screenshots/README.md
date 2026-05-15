# Checklist de entrega — Microservicos Insper 2026.1

## ✅ JA FEITO

### Screenshots AWS / Infra
- [x] `kubernetes-overview.png` — EKS cluster Overview (Active, v1.30)
- [x] `kubernetes-node-groups.png` — Node group store-nodes (t3.medium, desired 2)
- [x] `kubernetes-nodes.png` — EC2 Instances: 2x t3.medium Running
- [x] `rds-config.png` — RDS store-db PostgreSQL (Configuration tab)
- [x] `load-balancer.png` — NLB do nginx-ingress (network, active, 2 listeners)

### CI/CD
- [x] `jenkins.png` — Jenkins dashboard: 8 jobs verdes
- [x] `jenkins-video.mov` — video do pipeline rodando do inicio ao fim (gitignored, 112 MB)
- [x] `docker-hub.png` — Docker Hub: 6 imagens (cheqr/*)

### Documentacao
- [x] MkDocs deployado em 4 URLs publicas (parent + exchange + order + product)
- [x] Mermaid renderizando em todos os sites (0 erros de parse — validado com mermaid-cli)
- [x] 7 screenshots embarcados em <figure> + <figcaption>
- [x] Pagina dedicada `docs/paas.md`
- [x] `docs/costs.md` com Cost Explorer real ($148.59 / $307.79)
- [x] Evidencia de terminal em `../*.txt` (pods, hpa, RDS schema, etc.)

---

## ⬜ FALTA FAZER

### 1. Video principal — STRESS TEST (OBRIGATORIO)

**Onde:** terminal local (macOS) gravando 2-3 janelas com Cmd+Shift+5.

**Setup (pre-gravacao, em 2 terminais separados):**

Terminal A (watch — deixar rodando antes de gravar):
```bash
cd "/Users/alexchequer/VSCode/Insper/5o semestre/Microservicos/microservices"
source infra/.env
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
watch -n2 'kubectl get hpa,pods -l app=gateway'
```

Terminal B (k6 — preparar mas nao rodar ainda):
```bash
cd "/Users/alexchequer/VSCode/Insper/5o semestre/Microservicos/microservices"
bash scripts/demo-video.sh hpa
# (vai pedir ENTER pra comecar)
```

**Gravar:** Cmd+Shift+5 -> Record Selected Portion -> selecionar area dos 2 terminais.
Apertar ENTER no Terminal B pro k6 comecar. Gravar ate ver REPLICAS subindo
para 5 no Terminal A (~3 min).

**Salvar como:** `stress-test.gif` (ou .mov) em `docs/evidence/screenshots/`.

**Apos salvar:** descomentar bloco `<figure>` em `docs/load-testing.md`
(procurar pelo HTML comment `Quando o GIF existir, descomente...`).

Roteiro completo em `docs/video-runbook.md`.

---

### 2. Print do AWS Cost Explorer (RECOMENDADO)

**Onde:** AWS Console -> Billing and Cost Management -> Cost Explorer.

**URL direto:** https://us-east-1.console.aws.amazon.com/cost-management/home?region=us-east-1#/cost-explorer

**O que mostrar no print:**
- Periodo: Last 30 days (default)
- Granularity: Monthly ou Daily
- Group by: **Service** (no painel direito)
- Deve aparecer: barras coloridas com EKS (Elastic Container Service for Kubernetes),
  EC2-Compute, EC2-Other, Tax, ELB, etc.
- Total visivel: ~$148.59 atual, projecao $307.79

**Salvar como:** `cost-explorer.png` em `docs/evidence/screenshots/`.

**Apos salvar:** descomentar bloco `<figure>` em `docs/costs.md`
(procurar pelo HTML comment `Quando o print existir, descomente...`).

---

### 3. Print Jenkins Stage View (OPCIONAL — ja tem admonicao explicando)

**Onde:** Jenkins local, na sua maquina.

**URL:** http://localhost:9080 -> clicar em qualquer job (ex: `exchange`)
-> menu lateral esquerdo "Stage View" (ou clicar no numero do ultimo build
e ver as 4 caixinhas coloridas).

**O que mostrar:** 4 estagios horizontais verdes em sequencia:
`Dependecies -> Build -> Build & Push Image -> Deploy to EKS`

**Salvar como:** `jenkins-stageview.png` em `docs/evidence/screenshots/`.

**Apos salvar:** transformar a admonicao em `docs/infra/cicd.md` em
`<figure markdown="span">` apontando pro arquivo.

---

### 4. Print Grafana p95 (OPCIONAL — so se tiver Grafana de pe)

**Onde:** so existe se voce tiver configurado Prometheus + Grafana no
cluster. Se nao tiver, pular este item — nao e obrigatorio.

**Se tiver:** abrir o painel com a query
`histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[1m]))`
durante a janela do stress test (proximo passo #1).

**Salvar como:** `grafana-p95.png` em `docs/evidence/screenshots/`.

---

## ⚠️ APOS A ENTREGA — TEARDOWN URGENTE

**O cluster esta rodando ha 7+ dias.** Custo acumulado ja em ~$150, projecao $307/mes.

```bash
bash infra/scripts/teardown.sh
# Verificar no console AWS depois que NADA sobrou:
#   - EKS: 0 clusters
#   - EC2: 0 instances
#   - RDS: 0 databases
#   - ELB: 0 load balancers
```

---

## 📎 Links a entregar (URLs publicas, nao precisam de print)

**MkDocs (GitHub Pages):**
- https://microservice-alex-carlos-lucas.github.io/microservices/
- https://microservice-alex-carlos-lucas.github.io/exchange/
- https://microservice-alex-carlos-lucas.github.io/order-service/
- https://microservice-alex-carlos-lucas.github.io/product-service/

**Repositorios:**
- https://github.com/Microservice-Alex-Carlos-Lucas

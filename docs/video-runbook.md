# Runbook do vídeo (3-5 min)

## Antes de gravar

- [ ] Cluster up: `bash scripts/demo-video.sh setup` mostra 7 pods Running + 3 HPAs
- [ ] Stack local docker compose pronta pra subir (cache demo)
- [ ] Conta demo criada via `/auth/register` (faz parte do script)
- [ ] Slides de arquitetura abertos numa janela (docs/architecture.md ou diagrama)
- [ ] Editor com 3 abas: `exchange-service/src/cache.py`, `product-service/.../CacheConfig.java`, `order-service/.../ExchangeRateService.java`
- [ ] Janelas: 4 terminais lado a lado (T1: cache demo, T2: k6, T3: kubectl watch, T4: evidence)

## Roteiro (segue [presentation.md](presentation.md))

### 0:00–0:30 — Abertura
"Alex, Carlos e Lucas. E-commerce multi-moeda em 6 microsserviços rodando em EKS+RDS, com 6 bottlenecks medidos."

### 0:30–1:30 — Arquitetura
Tela: diagrama em docs/architecture.md. Apontar o caminho:
- Internet → NLB AWS → nginx-ingress → gateway → 5 services
- AuthorizationFilter no gateway chama `/auth/solve` antes de cada request
- 3 caches Redis em camadas: exchange (cotação USD-BRL), product (produto por id), order (cotação via wrapper Feign)

### 1:30–3:00 — Demo ao vivo

**T1 — cache (compose local, AwesomeAPI funciona):**
```
bash scripts/demo-video.sh cache
```
Mostra 1ª chamada (~500ms, cache miss) → 2ª (~10ms, cache hit) → métricas Prometheus → Redis KEYS.

**T2 — k6 stress (EKS):**
```
bash scripts/demo-video.sh hpa
```
(Pressionar ENTER no script pra começar k6.)

**T3 — kubectl watch (EKS):**
```
watch -n2 'kubectl get hpa,pods -l app=gateway'
```
Mostra HPA escalando 1→5 réplicas conforme CPU passa de 50%.

### 3:00–4:00 — Bottlenecks (mostrar código no editor)
- **Alex (Exchange):** `api/exchange-service/src/cache.py` — Redis client + TTL 60s + Prometheus counters.
- **Carlos (Product):** `api/product-service/src/main/java/store/product/CacheConfig.java` — `@EnableCaching` + RedisCacheManager.
- **Lucas (Order):** `api/order-service/src/main/java/store/order/client/ExchangeRateService.java` — wrapper `@Cacheable` no Feign.

### 4:00–4:30 — Infra
- EKS via `eksctl` (mostrar `infra/eks/cluster.yaml`)
- RDS Postgres db.t3.micro
- nginx-ingress + NLB AWS
- Pipeline Jenkins: 8 jobs verdes (mostrar print do dashboard)
- Custo demo (~30min): **~$0.12**

### 4:30–5:00 — Encerramento
- Aprendizados: trade-offs PaaS vs IaaS, cache key fora do idAccount, fallback gracioso quando Redis cai.
- Próximos passos: AWS Secrets Manager, RDS Multi-AZ.

## Depois de gravar

```
bash scripts/demo-video.sh evidence    # salva pods/hpa/rds/eks em docs/evidence
bash infra/scripts/teardown.sh         # destrói cluster (~$0.25/h economizado)
```

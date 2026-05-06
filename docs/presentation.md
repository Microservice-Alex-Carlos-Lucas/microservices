# Apresentação

## Vídeo de apresentação

!!! info "Em breve"
    Vídeo de 3–5 minutos cobrindo o projeto e bottlenecks implementados.

<!-- [▶ Assistir](https://youtu.be/...) -->

---

## Roteiro detalhado (3–5 min)

### 0:00–0:30 — Abertura
- Quem somos: Alex, Carlos, Lucas
- O que entregamos: e-commerce multi-moeda em 6 microsserviços, sobre EKS+RDS,
  com 6 bottlenecks medidos.

### 0:30–1:30 — Arquitetura ([slide arquitetura](architecture.md))
- Mostrar diagrama: Internet → NLB → nginx-ingress → gateway → 5 services + Redis + RDS
- Destacar: AuthorizationFilter no gateway chama `/auth/solve` antes de cada request
- Order chama Product e Exchange via OpenFeign
- Os 3 caches Redis em série (exchange / product / order) — cada um cobre uma camada

### 1:30–3:00 — Demo ao vivo
**Janela 1** (terminal):
```bash
# stack up (já em pé antes da gravação)
curl -X POST http://$NLB/auth/login -d '...' # cookie obtido
curl http://$NLB/products/$PID         # 1ª: cache miss, ~30ms
curl http://$NLB/products/$PID         # 2ª: cache hit, ~12ms
curl http://$NLB/orders/$OID?currency=BRL  # 1ª: 622ms (chain Feign+HTTP)
curl http://$NLB/orders/$OID?currency=BRL  # 2ª: 24ms — 25× speedup
```

**Janela 2** (k6 + HPA):
```bash
k6 run scripts/k6/gateway-stress.js   # ramp 1→200 VUs em 2min
```

**Janela 3** (k8s):
```bash
watch kubectl get hpa,pods -l app=gateway   # mostrar escala 1→5 réplicas
```

### 3:00–4:00 — Bottlenecks (3 caches Redis)
- **Alex (Exchange):** Redis Python client + Prometheus instrumentator. 91× speedup medido.
- **Carlos (Product):** Spring `@Cacheable` + `RedisCacheManager`. 3 hits → 1 query no DB.
- **Lucas (Order):** wrapper `@Cacheable` ao redor do Feign. 25× speedup no caminho mais caro.
- Os 3 caches coexistem — `redis-cli KEYS '*'` mostra:
  ```
  exchange:rate:USD:BRL
  products::products::<uuid>
  orders::exchange-rates::USD-BRL
  ```

### 4:00–4:30 — Infra
- EKS provisionado via `eksctl` (`infra/eks/cluster.yaml`)
- RDS Postgres db.t3.micro (PaaS legítimo)
- nginx-ingress controller + NLB AWS automático
- Pipeline Jenkins: Build → Push Docker Hub → `kubectl set image`
- Custo total da demo (~30min cluster up): **~$0.12**

### 4:30–5:00 — Encerramento
- O que aprendemos: trade-offs PaaS vs IaaS, cuidado com cache key (não usar idAccount),
  importância de fallback gracioso quando Redis cai
- Próximos passos: trocar dev secrets por AWS Secrets Manager, RDS Multi-AZ em produção real

---

## Slides

!!! info "Em breve"
    Link para os slides será adicionado aqui.

## Checklist de entrega

- [x] Nome do aluno e grupo
- [x] Documentação das atividades realizadas
- [x] Código fonte das atividades realizadas
- [x] Documentação do projeto (este MkDocs)
- [x] Link para todos os repositórios
- [x] Destaques para os bottlenecks (≥2 por indivíduo) — **6/6 implementados e medidos**
- [ ] Apresentação do projeto
- [ ] Vídeo de apresentação (3–5 minutos)

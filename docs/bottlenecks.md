# Bottlenecks

O projeto implementa ao menos **2 bottlenecks por membro** (mínimo 6 no total).

## Alex — Exchange API

### Bottleneck 1: Caching de taxas de câmbio com Redis

**Problema:** Cada requisição a `/exchanges/{from}/{to}` faz uma chamada HTTP em tempo real
à AwesomeAPI, adicionando latência e risco de rate-limiting sob carga.

**Solução:** Cliente Redis com TTL de 60s por par de moedas (`exchange:rate:{FROM}:{TO}`).
Compartilhado entre réplicas via service `redis` no compose / pod no EKS. Falhas de Redis
caem para chamada direta à AwesomeAPI (resiliência > eficiência).

**Impacto medido:** cache miss 86ms → cache hit 0.9ms (**91× speedup**), confirmado em
`docker compose up -d --build exchange redis` + dois `curl` consecutivos. Provado também
por teste com `fakeredis` em `tests/test_service.py::test_cache_hit_skips_upstream_fetch`.

### Bottleneck 2: Observabilidade (Prometheus)

**Problema:** Sem métricas, impossível identificar degradação de performance ou acionar
autoscaling baseado em carga real.

**Solução:** `prometheus-fastapi-instrumentator` expõe `/metrics` com histogramas de latência,
contadores de requisições e erros por rota. Counters customizados
`exchange_cache_hits_total` / `exchange_cache_misses_total` evidenciam o efeito do cache.

**Métricas-chave:** `http_request_duration_seconds`, `http_requests_total`,
`http_requests_in_progress`, `exchange_cache_{hits,misses}_total`

Detalhes: [documentação individual de Alex](https://github.com/Microservice-Alex-Carlos-Lucas/exchange/blob/main/docs/bottlenecks.md)

---

## Carlos — Product API

!!! info "Em andamento"
    Bottlenecks do Carlos serão documentados aqui após a implementação.

---

## Lucas — Order API

!!! info "Em andamento"
    Bottlenecks do Lucas serão documentados aqui após a implementação.

---

## Referências

| Bottleneck | Ferramenta | Documentação |
|-----------|-----------|-------------|
| Caching | Redis / dict em memória | [Redis Docs](https://redis.io/docs) |
| Observabilidade | Prometheus + Grafana | [Spring Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html) |
| Messaging | RabbitMQ / Kafka | — |
| Load Balancing | Nginx / k8s Ingress | — |
| Vulnerability Scanning | OWASP ZAP / Snyk | — |

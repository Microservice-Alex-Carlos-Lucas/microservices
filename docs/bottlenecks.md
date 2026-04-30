# Bottlenecks

O projeto implementa ao menos **2 bottlenecks por membro** (mínimo 6 no total).

## Alex — Exchange API

### Bottleneck 1: Caching de taxas de câmbio

**Problema:** Cada requisição a `/exchanges/{from}/{to}` faz uma chamada HTTP em tempo real
à AwesomeAPI, adicionando latência e risco de rate-limiting sob carga.

**Solução:** Cache em memória com TTL de 60 segundos por par de moedas. Em produção, substituir
por Redis para compartilhar cache entre réplicas.

**Impacto:** Latência de cache hit < 5ms vs ~200ms de cache miss.

### Bottleneck 2: Observabilidade (Prometheus + Grafana)

**Problema:** Sem métricas, impossível identificar degradação de performance ou acionar
autoscaling baseado em carga real.

**Solução:** `prometheus-fastapi-instrumentator` expõe `/metrics` com histogramas de latência,
contadores de requisições e erros por rota.

**Métricas-chave:** `http_request_duration_seconds`, `http_requests_total`, `http_requests_in_progress`

Detalhes: [documentação individual de Alex](https://alexchequer.github.io/exchange/bottlenecks/)

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

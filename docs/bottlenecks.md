# Bottlenecks

O projeto implementa ao menos **2 bottlenecks por membro** (mínimo 6 no total). **Todos
foram implementados, instrumentados e validados end-to-end via `docker compose up`** —
três caches Redis em série (exchange / product / order) e instrumentação Prometheus.

| Membro | Bottleneck | Speedup medido |
|---|---|---|
| Alex (Exchange) | Cache Redis de taxas + métricas custom | **91×** (86ms → 0.9ms) |
| Alex (Exchange) | Observabilidade `prometheus-fastapi-instrumentator` | qualitativo |
| Carlos (Product) | Cache Redis em `@Cacheable` | **3×** (32ms → 12ms), 1 query DB para 3 hits |
| Carlos (Product) | Métrica nativa de cache (Spring) | qualitativo |
| Lucas (Order) | Cache wrapper do `ExchangeClient` Feign | **25×** (622ms → 25ms no GET de pedido em moeda alternativa) |
| Lucas (Order) | Counter `orders.created` + `@Timed` opcional | qualitativo |

> Todas as medições acima foram feitas em uma única sessão de
> `docker compose up -d --build` com 7 containers (gateway, auth,
> account, product, order, exchange, postgres, redis), via curl simples.
> Reproduzível em `~10s` na sua máquina seguindo os comandos abaixo.

---

## Alex — Exchange API

### Bottleneck 1: Caching de taxas de câmbio com Redis

**Problema:** Cada requisição a `/exchanges/{from}/{to}` faz uma chamada HTTP em tempo real
à AwesomeAPI, adicionando latência e risco de rate-limiting sob carga.

**Solução:** Cliente Redis (`api/exchange-service/src/cache.py`) com TTL de 60s por par de
moedas, chave `exchange:rate:{FROM}:{TO}`. Compartilhado entre réplicas via service `redis`
no compose / pod no EKS. Falhas de Redis caem para chamada direta à AwesomeAPI
(resiliência > eficiência).

**Verificação:**
```bash
cd api && docker compose up -d --build exchange redis
docker compose exec -T exchange python -c "import urllib.request, time
url='http://localhost:8000/exchanges/USD/BRL'
req=urllib.request.Request(url, headers={'id-account':'test'})
t0=time.time(); urllib.request.urlopen(req).read(); t1=time.time()
t2=time.time(); urllib.request.urlopen(req).read(); t3=time.time()
print(f'miss: {(t1-t0)*1000:.1f}ms, hit: {(t3-t2)*1000:.1f}ms')"
# miss: 86.0ms, hit: 0.9ms — speedup 91x
```

Provado também por teste com `fakeredis` em
`tests/test_service.py::test_cache_hit_skips_upstream_fetch`: duas chamadas consecutivas
ao mesmo par de moedas executam **só 1** chamada HTTP upstream.

### Bottleneck 2: Observabilidade (Prometheus)

**Problema:** Sem métricas, impossível identificar degradação de performance ou acionar
autoscaling baseado em carga real.

**Solução:** `prometheus-fastapi-instrumentator` expõe `/metrics` com histogramas de
latência, contadores de requisições e erros por rota. Counters customizados
`exchange_cache_hits_total` / `exchange_cache_misses_total` evidenciam o efeito do cache.

**Verificação:**
```bash
curl -s http://exchange:8000/metrics | grep ^exchange_cache
# exchange_cache_hits_total 1.0
# exchange_cache_misses_total 1.0
```

Detalhes: [documentação individual de Alex](https://microservice-alex-carlos-lucas.github.io/exchange/bottlenecks/)

---

## Carlos — Product API

### Bottleneck 1: Cache Redis em `@Cacheable`

**Problema:** O `order-service` chama `GET /products/{id}` via Feign para cada item de
cada pedido. Sob carga, cada hit derruba uma query no Postgres.

**Solução:** `spring-boot-starter-data-redis` + `spring-boot-starter-cache` com
`RedisCacheManager` (`api/product-service/src/main/java/store/product/CacheConfig.java`),
TTL 60s, prefixo `products::`. `ProductService.get(UUID id)` anotado com
`@Cacheable("products", key="#id")`; `create` com `@CachePut`; `delete` com `@CacheEvict`.

**Verificação:**
```bash
# 3 chamadas idênticas
for i in 1 2 3; do curl -s -o /dev/null -H "$COOKIE" $BASE/products/$PID; done

# Inspecionar key no Redis
docker run --rm --network store-api_default redis:7-alpine redis-cli -h redis KEYS '*'
# products::products::d84c4904-2295-4759-b122-abe4a4de625f

# Métrica do Spring Data Repository — só 1 findById foi executado
curl -s http://product:8080/actuator/prometheus | grep findById
# spring_data_repository_invocations_seconds_count{method="findById",repository="ProductRepository"} 1.0
```

**Latência:** 1ª chamada ~32ms (cache miss + DB), 2ª/3ª ~12ms (cache hit) — **3× speedup**
e elimina 2 das 3 queries no Postgres.

### Bottleneck 2: Métrica nativa de cache (Spring `@Cacheable` + Micrometer)

**Problema:** O ganho do Bottleneck 1 só é justificável se observável. Operação queremos
saber a hit ratio em produção.

**Solução:** `management.metrics.cache.instrument: true` + `RedisCacheManager` exposto
em `/actuator/caches`. Spring registra `cache_gets_total{result=hit|miss}` automaticamente
quando há tráfego, e o `/actuator/caches/products` traz o estado live do CacheWriter.

**Verificação:**
```bash
curl -s http://product:8080/actuator/caches/products
# {"cacheManager":"cacheManager","name":"products","target":"...DefaultRedisCacheWriter"}
```

---

## Lucas — Order API

### Bottleneck 1: Cache do `ExchangeClient` Feign via Redis (4º bottleneck individual)

**Problema:** `OrderService.create(...)` chama `ExchangeClient.getRate(from,to)` via Feign
para cada pedido em moeda alternativa. Hop HTTP order → exchange (~5–10ms na rede do EKS),
amplificado pela frequência de pedidos.

**Solução:** Wrapper `ExchangeRateService.java`
(`api/order-service/src/main/java/store/order/client/ExchangeRateService.java`) anotado
com `@Cacheable(value="exchange-rates", key="#from + '-' + #to")`. Feign não aceita
`@Cacheable` direto na interface — precisa da camada de indireção. A chave é
intencionalmente sem `idAccount` (a taxa não depende do usuário; cachear por usuário
particionaria o cache).

**Verificação:**
```bash
# Cria 1 pedido, recupera 2× em moeda alternativa (BRL)
T1=$(curl -s -o /dev/null -w '%{time_total}' -H "$COOKIE" "$BASE/orders/$OID?currency=BRL")
T2=$(curl -s -o /dev/null -w '%{time_total}' -H "$COOKIE" "$BASE/orders/$OID?currency=BRL")
echo "1st: $T1, 2nd: $T2"
# 1st: 0.622s (full path order→product+exchange→AwesomeAPI), 2nd: 0.024s — 25x speedup
```

Inspeção do Redis confirma os 3 caches em série:
```text
$ redis-cli KEYS '*'
exchange:rate:USD:BRL                          # Bottleneck 1 do Alex
products::products::<uuid>                     # Bottleneck 1 do Carlos
orders::exchange-rates::USD-BRL                # este bottleneck
```

### Bottleneck 2 (já existente no Order do Lucas): Observabilidade com `Counter` + `@Timed`

Counter `orders.created` registrado em `OrderService.java` via `MeterRegistry`. Detalhes
em `api/order-service/docs/individual/bottlenecks.md`.

---

## Referências

| Bottleneck | Ferramenta | Documentação |
|---|---|---|
| Caching distribuído | Redis 7 | [Redis Docs](https://redis.io/docs) |
| Observabilidade | Prometheus + Micrometer + `@Cacheable` metrics | [Spring Actuator](https://docs.spring.io/spring-boot/reference/actuator/metrics.html) |
| Cache em Feign | wrapper `@Cacheable` (Feign não suporta direto) | [Spring Cache](https://docs.spring.io/spring-framework/reference/integration/cache.html) |
| Resiliência | fallback gracioso quando Redis indisponível | [Resilience patterns](https://martinfowler.com/articles/microservice-trade-offs.html) |

# Bottleneck Spec — Product Service (Carlos)

> Plano de implementação dos **2 bottlenecks** exigidos pela disciplina,
> alinhado com o que o Alex implementou no exchange-service e seguindo o
> padrão PMA 26.1 do grupo. O Redis já está disponível em `redis:6379`
> via `api/compose.yaml`.

---

## Bottleneck 1 — Cache de produto via `@Cacheable` + Redis

**Categoria:** Latência · *read-heavy endpoint*

**Por que aqui:** `order-service` chama `ProductClient.getProduct(id)` via
Feign para **cada item** de cada pedido. Picos de leitura (catálogo, busca,
listagem na home) batem direto no Postgres. Cachear `GET /products/{id}`
reduz a latência percebida pelo order-service e tira pressão do RDS.

### Arquivos a tocar

| Arquivo | Mudança |
|---|---|
| `pom.xml` | adicionar `spring-boot-starter-data-redis` e `spring-boot-starter-cache` |
| `src/main/java/store/product/CacheConfig.java` | **criar** — `@EnableCaching`, `RedisCacheManager` com TTL 60s |
| `src/main/java/store/product/ProductService.java` | anotar `get(UUID id)` com `@Cacheable("products")`; `update`/`delete` com `@CacheEvict`; `create` com `@CachePut` |
| `src/main/resources/application.yaml` | configurar `spring.data.redis.host` e `spring.cache.type` |

### Snippets

**`pom.xml`** (dentro de `<dependencies>`):
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
```

**`CacheConfig.java`**:
```java
package store.product;

import java.time.Duration;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;

@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory cf) {
        RedisCacheConfiguration cfg = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofSeconds(60))
            .prefixCacheNameWith("products::")
            .disableCachingNullValues();
        return RedisCacheManager.builder(cf).cacheDefaults(cfg).build();
    }
}
```

**`ProductService.java`** (delta):
```java
@Cacheable(value = "products", key = "#id")
public ProductResponse get(UUID id) { ... }

@CachePut(value = "products", key = "#result.id()")
public ProductResponse update(UUID id, ProductRequest req) { ... }

@CacheEvict(value = "products", key = "#id")
public void delete(UUID id) { ... }
```

**`application.yaml`**:
```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
  cache:
    type: redis

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,caches
  metrics:
    cache:
      instrument: true
```

### Verificação (passo a passo)

```bash
cd api && docker compose up -d --build product redis

ID=$(curl -s -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -H "id-account: alex" \
  -d '{"name":"Laptop","price":3500.00}' | jq -r .id)

# 1ª chamada (cache miss)
time curl -s -H "id-account: alex" http://localhost:8080/products/$ID

# 2ª chamada (cache hit — deve ser >5x mais rápido)
time curl -s -H "id-account: alex" http://localhost:8080/products/$ID

# Métricas comprovando
curl -s http://localhost:8080/actuator/prometheus | grep cache_gets_total
```

**Output esperado:**
```
cache_gets_total{cache="products",result="hit"}  1.0
cache_gets_total{cache="products",result="miss"} 1.0
```

### Impacto esperado

- Cache miss (DB roundtrip + JPA hydrate): ~30–50ms
- Cache hit (Redis lookup): ~2–5ms
- Speedup ≥ 6×, compartilhado entre réplicas (não é Caffeine in-memory)

---

## Bottleneck 2 — Métrica nativa de cache (zero código extra)

**Categoria:** Identificação de gargalos · *capacity planning*

**Por que aqui:** o ganho do Bottleneck 1 só é justificável se for
**medido**. Spring Boot já entrega a métrica de graça quando habilitado.

### Arquivos a tocar

| Arquivo | Mudança |
|---|---|
| `src/main/resources/application.yaml` | já configurado no Bottleneck 1 (`management.metrics.cache.instrument: true`) |

### Verificação

```bash
curl -s http://localhost:8080/actuator/prometheus | grep -E "cache_(gets|puts|evictions)_total"
```

**Output esperado:**
```
cache_gets_total{cache="products",result="hit"} 42.0
cache_gets_total{cache="products",result="miss"} 7.0
cache_puts_total{cache="products"} 7.0
cache_size{cache="products"} 7.0
```

### O que isso desbloqueia

- Eficácia do cache visível em **Grafana** via query
  `rate(cache_gets_total{result="hit"}[1m]) / rate(cache_gets_total[1m])`
- **Alertas** quando hit ratio < 80% (TTL muito curto ou catálogo muito volátil)
- **HPA com métricas customizadas** via `prometheus-adapter`

### Arquivos relevantes

- `pom.xml`
- `src/main/java/store/product/CacheConfig.java` (criar)
- `src/main/java/store/product/ProductService.java`
- `src/main/resources/application.yaml`
- `docs/individual/bottlenecks.md` (criar — usar template do
  `api/order-service/docs/individual/bottlenecks.md` do Lucas)

---

## Como medir antes/depois (k6)

`scripts/k6/product-cache.js` — 200 VUs × 30s, loop em 5 IDs:

```javascript
import http from 'k6/http';
export const options = { vus: 200, duration: '30s' };
const ids = ['id1','id2','id3','id4','id5'];
export default () => {
    const id = ids[Math.floor(Math.random()*ids.length)];
    http.get(`http://localhost:8080/products/${id}`,
        { headers: { 'Cookie': `__store_jwt_token=${__ENV.TOKEN}` }});
};
```

Comparar p95 de `http_server_requests_seconds{uri="/products/{id}"}`
**antes** (sem cache, branch base) e **depois** (com cache).

---

## Estrutura do doc de entrega

Quando implementar, criar `docs/individual/bottlenecks.md` no formato
**Categoria → Problema → Solução → Verificação → O que isso desbloqueia
→ Arquivos relevantes**. Modelo: `api/order-service/docs/individual/bottlenecks.md` do Lucas.

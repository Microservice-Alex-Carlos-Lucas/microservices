# Bottleneck Spec — Order Service (Lucas) — Bottleneck Extra

> Você já implementou 3 bottlenecks (`Observabilidade`, `Rate Limiting`,
> `Validação`). Esse documento adiciona um **4º bottleneck** de alto
> impacto que se alinha com o cache que o Alex acabou de subir no
> exchange-service e que reduz drasticamente a latência do caminho
> mais caro do projeto: criação de pedido em moeda alternativa.

> Se preferir manter só os 3 que já estão entregues, ignore. Mas o
> bottleneck abaixo é o que mais salta numa demo de carga.

---

## Bottleneck 4 — Cache do `ExchangeClient` (Feign) via Redis

**Categoria:** Latência · *cross-service amplification*

**Por que aqui:** Hoje, `OrderService.create(...)` chama
`ExchangeClient.getRate(from,to)` para *cada pedido* em moeda
alternativa. Mesmo com cache no exchange-service, ainda há um hop HTTP
order→exchange (~5–10ms na rede do EKS). Cachear no order elimina esse
hop e protege o exchange de ser pingado N vezes pelo mesmo par no mesmo
segundo.

**Importante:** o cache **não deve usar `idAccount` na chave** — senão
cada usuário polui o cache. A taxa não depende do usuário, só do par.

### Arquivos a tocar

| Arquivo | Mudança |
|---|---|
| `pom.xml` | adicionar `spring-boot-starter-data-redis` e `spring-boot-starter-cache` |
| `src/main/java/store/order/CacheConfig.java` | **criar** — `@EnableCaching`, `RedisCacheManager` com TTL 60s |
| `src/main/java/store/order/client/ExchangeRateService.java` | **criar** — wrapper com `@Cacheable` que delega ao `ExchangeClient` |
| `src/main/java/store/order/OrderService.java` | substituir chamada direta ao `ExchangeClient` pelo `ExchangeRateService` |
| `src/main/resources/application.yaml` | configurar `spring.data.redis.host` e `spring.cache.type` |

### Snippets

**`pom.xml`**:
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
package store.order;

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
            .prefixCacheNameWith("orders::")
            .disableCachingNullValues();
        return RedisCacheManager.builder(cf).cacheDefaults(cfg).build();
    }
}
```

**`ExchangeRateService.java`** (wrapper porque `@Cacheable` em interface
Feign não funciona):
```java
package store.order.client;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class ExchangeRateService {

    private final ExchangeClient client;

    public ExchangeRateService(ExchangeClient client) {
        this.client = client;
    }

    @Cacheable(value = "exchange-rates", key = "#from + '-' + #to")
    public ExchangeResponse getRate(String from, String to, String idAccount) {
        // idAccount é só pass-through pro header; NÃO entra na chave do cache
        return client.getRate(from, to, idAccount);
    }
}
```

**`OrderService.java`** (delta):
```diff
- private final ExchangeClient exchangeClient;
+ private final ExchangeRateService exchangeRateService;

  // dentro de create(...)
- ExchangeResponse rate = exchangeClient.getRate(productCurrency, request.currency(), idAccount);
+ ExchangeResponse rate = exchangeRateService.getRate(productCurrency, request.currency(), idAccount);
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
  metrics:
    cache:
      instrument: true
```

### Verificação

```bash
cd api && docker compose up -d --build order redis exchange product

PID=$(curl -s -X POST http://localhost:8080/products -H "Content-Type: application/json" \
    -H "Cookie: __store_jwt_token=$TOKEN" \
    -d '{"name":"Phone","price":1000.00,"currency":"USD"}' | jq -r .id)

# 1ª order em BRL
time curl -s -X POST http://localhost:8080/orders -H "Content-Type: application/json" \
    -H "Cookie: __store_jwt_token=$TOKEN" \
    -d "{\"currency\":\"BRL\",\"items\":[{\"productId\":\"$PID\",\"quantity\":1}]}"

# 2ª order — taxa USD-BRL deve vir do cache
time curl -s -X POST http://localhost:8080/orders -H "Content-Type: application/json" \
    -H "Cookie: __store_jwt_token=$TOKEN" \
    -d "{\"currency\":\"BRL\",\"items\":[{\"productId\":\"$PID\",\"quantity\":1}]}"

curl -s http://localhost:8080/actuator/prometheus | grep -E 'cache_gets_total.*exchange-rates'
```

### Impacto esperado

- 1ª chamada: order persiste + Feign para product + Feign para exchange + AwesomeAPI HTTP = ~150–250ms
- 2ª chamada (mesmo par): order persiste + Feign para product + cache hit Redis = ~50–80ms
- Speedup do hop exchange: ~4–5×, e a AwesomeAPI nem é tocada (combinado com o cache do Alex)

### O que isso desbloqueia

- **Carga sustentável**: 1000 pedidos/min em USD-BRL fazem ~17 requests à AwesomeAPI (1 por TTL) em vez de 1000
- **Resiliência a falha do exchange-service** durante picos: order serve pedidos por 60s usando o último valor cacheado
- **HPA do order baseado em CPU pura** (cache absorve I/O bound)

### Arquivos relevantes

- `pom.xml`
- `src/main/java/store/order/CacheConfig.java` (criar)
- `src/main/java/store/order/client/ExchangeRateService.java` (criar)
- `src/main/java/store/order/OrderService.java`
- `src/main/resources/application.yaml`

---

## Como adicionar ao seu doc

Em `docs/individual/bottlenecks.md` que você já tem, agregar como
"Bottleneck 4 — Cache do ExchangeClient (Feign) via Redis", seguindo a
mesma estrutura dos seus 3 anteriores. Atualizar também
`docs/index.md` e `docs/exercicios/index.md` com o 4º bottleneck.

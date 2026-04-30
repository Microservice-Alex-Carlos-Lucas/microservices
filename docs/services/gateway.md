# Gateway Service

**Repositório:** [Microservice-Alex-Carlos-Lucas/gateway-service](https://github.com/Microservice-Alex-Carlos-Lucas/gateway-service)

---

## Descrição

Único ponto de entrada público da plataforma. Implementado com Spring Cloud Gateway (WebFlux).
Valida o cookie JWT em todas as rotas protegidas e injeta o `id-account` como header antes de
encaminhar a requisição ao serviço de destino.

## Tabela de rotas

| ID | Caminho | Destino |
|----|---------|---------|
| `insper` | `/insper/**` | `http://www.insper.edu.br` |
| `accounts` | `/accounts/**` | `http://account:8080` |
| `auth` | `/auth/**` | `http://auth:8080` |
| `products` | `/products/**` | `http://product:8080` |
| `orders` | `/orders/**` | `http://order:8080` |
| `exchanges` | `/exchanges/**` | `http://exchange:8000` |

## Rotas abertas (sem autenticação)

```java
"/auth/login"
"/auth/register"
"/auth/health-check"
"/accounts/health-check"
```

## Filtro de autorização

O `AuthorizationFilter` intercepta cada requisição a uma rota protegida:

1. Lê o cookie `__store_jwt_token`
2. Chama `POST http://auth:8080/auth/solve` com o token
3. Se válido, injeta `id-account` no header e encaminha
4. Se inválido ou ausente, retorna `401 Unauthorized`

## CORS

Configurado globalmente via `application.yaml`. Origens e credenciais são injetadas via variáveis
de ambiente (`CORS_ALLOWED_ORIGINS`, `CORS_ALLOWED_CREDENTIALS`).

## Porta pública

`:8080` (mapeada para o LoadBalancer no k8s)

# Auth Service

**Repositório:** [Microservice-Alex-Carlos-Lucas/auth-service](https://github.com/Microservice-Alex-Carlos-Lucas/auth-service)

---

## Descrição

Responsável por emissão e validação de tokens JWT. Usado pelo gateway no filtro de autorização.

## Endpoints-chave

| Rota | Descrição |
|------|-----------|
| `POST /auth/login` | Autentica usuário, retorna cookie `__store_jwt_token` |
| `POST /auth/register` | Cria conta de usuário |
| `POST /auth/solve` | Valida JWT e retorna `{ idAccount }` — chamado internamente pelo gateway |

!!! info "Rotas abertas"
    `/auth/login`, `/auth/register` e `/auth/health-check` não requerem autenticação prévia.

## Fluxo JWT

```mermaid
sequenceDiagram
    actor User
    participant Gateway
    participant Auth

    User->>Gateway: POST /auth/login { email, password }
    Gateway->>Auth: POST /auth/login (rota aberta)
    Auth-->>Gateway: 200 OK
    Gateway-->>User: Set-Cookie: __store_jwt_token=<jwt>

    User->>Gateway: GET /products (cookie)
    Gateway->>Auth: POST /auth/solve (header: <jwt>)
    Auth-->>Gateway: { idAccount: "uuid" }
    Gateway->>Product: GET /products (header: id-account: "uuid")
```

## Stack

| Item | Detalhe |
|------|---------|
| Linguagem | Java 25 |
| Framework | Spring Boot 4.0.3 |
| Token | JWT (cookie HTTP-only) |

# Account Service

**Repositório:** [Microservice-Alex-Carlos-Lucas/account-service](https://github.com/Microservice-Alex-Carlos-Lucas/account-service)

---

## Descrição

Gerencia contas de usuários (criação, consulta). Usado pelo auth-service para verificar
credenciais e pelo gateway para repassar o `id-account` nos headers das requisições autenticadas.

## Stack

| Item | Detalhe |
|------|---------|
| Linguagem | Java 25 |
| Framework | Spring Boot 4.0.3 |
| Banco | PostgreSQL (schema: `accounts`) |
| Migrações | Flyway |

## Docker Hub

`cheqr/account:latest`

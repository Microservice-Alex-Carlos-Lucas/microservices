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

## Endpoints

| Método | Path | Descrição |
|---|---|---|
| `POST` | `/accounts` | Cria conta. Recebe `{name, email, password}` (sem hash). Internamente armazena `password_sha256` e devolve `201 Created`. |
| `POST` | `/accounts/login` | Verifica credenciais. Recebe `{email, password}`, retorna `{idAccount, name, email}` em `200 OK` ou `401`. |
| `GET` | `/accounts/health-check` | Liveness/readiness (rota aberta no gateway). |

## Schema (Flyway)

| Migration | Conteúdo |
|---|---|
| `V2026.03.04.001__create_schema.sql` | `CREATE SCHEMA accounts` |
| `V2026.03.04.002__create_table.sql` | `accounts.accounts(id, name, email)` |
| `V2026.03.06.001__create_field_pass_sha256.sql` | adiciona `password_sha256 VARCHAR(64)` |
| `V2026.03.12.001_create_index.sql` | `idx_email_sha256` |
| `V2026.05.06.001__widen_id_column.sql` | `id` VARCHAR(32) → 36 (acomoda UUID v4 com hífens) |

## Docker Hub

`cheqr/account:latest` — pipeline Jenkins (`Jenkinsfile`) builda + push multi-arch + `kubectl set image`.

## k8s

Manifests em [`api/account-service/k8s/`](https://github.com/Microservice-Alex-Carlos-Lucas/account-service/tree/main/k8s):
- `deployment.yaml` (DATABASE_HOST do ConfigMap, USERNAME/PASSWORD do Secret)
- `service.yaml` ClusterIP
- `configmap.yaml` (DATABASE_HOST, DATABASE_PORT, DATABASE_DB)
- `secrets.yaml` (DATABASE_USERNAME, DATABASE_PASSWORD)

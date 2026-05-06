# Inicialização do RDS

Os 3 services Java (account, product, order) usam Flyway com schemas
separados (`accounts`, `products`, `orders`) no mesmo database.

A primeira vez que cada pod sobe contra o RDS, o Flyway aplica todas as
migrations automaticamente. Não há ação manual nesse caminho — desde que
o usuário do banco tenha permissão `CREATE SCHEMA`.

## Passo manual: criar usuários por service (opcional, mas recomendado)

```sql
-- conectar como master
psql -h $RDS_ENDPOINT -U store -d store

CREATE USER account_app WITH PASSWORD 'app-pass';
CREATE USER product_app WITH PASSWORD 'app-pass';
CREATE USER order_app   WITH PASSWORD 'app-pass';

CREATE SCHEMA accounts AUTHORIZATION account_app;
CREATE SCHEMA products AUTHORIZATION product_app;
CREATE SCHEMA orders   AUTHORIZATION order_app;
```

Depois ajustar `secrets.yaml` de cada service para usar o usuário
específico.

## Troubleshooting Flyway

Se houver checksum mismatch (raro, só acontece se uma migration foi
editada após ter rodado):

```bash
kubectl exec -it deployment/account -- /bin/sh
# dentro do pod, rodar via Flyway CLI ou simplesmente recriar DB
```

Para o trabalho de aula, a opção mais simples é rodar
`infra/scripts/teardown.sh` (que dropa o RDS) e recriar do zero.

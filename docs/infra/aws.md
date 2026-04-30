# AWS

!!! warning "Em andamento"
    Esta seção será atualizada conforme a configuração da AWS avança.

## Passos realizados

- [ ] Criação de conta AWS
- [ ] Configuração do AWS CLI
- [ ] Criação de usuário IAM com permissões EKS + ECR
- [ ] Geração de Access Key

## Configuração do CLI

```bash
aws configure
# AWS Access Key ID: <key>
# AWS Secret Access Key: <secret>
# Default region: us-east-1
# Default output format: json
```

## Serviços utilizados

| Serviço | Propósito |
|---------|-----------|
| EKS | Orquestração de containers |
| RDS (PostgreSQL) | Banco de dados gerenciado |
| ECR / Docker Hub | Registro de imagens |
| Load Balancer | Exposição pública do gateway |

#!/usr/bin/env bash
# Provisiona uma instância RDS Postgres db.t3.micro acessível pelo cluster EKS.
# Pré-requisitos: AWS CLI configurado (via infra/.env), eksctl já criou o cluster.
#
# Custo aproximado: $0.017/h ($12-15/mês se 24/7). Lembrar de rodar
# infra/scripts/teardown.sh para evitar cobrança.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/.env"

DB_INSTANCE_ID="${DB_INSTANCE_ID:-store-db}"
DB_NAME="${DB_NAME:-store}"
DB_USERNAME="${DB_USERNAME:-store}"
DB_PASSWORD="${DB_PASSWORD:?DB_PASSWORD must be set in infra/.env}"
DB_INSTANCE_CLASS="${DB_INSTANCE_CLASS:-db.t3.micro}"
ALLOCATED_STORAGE="${ALLOCATED_STORAGE:-20}"

# Pega o VPC do cluster EKS (assume cluster já criado)
VPC_ID=$(aws eks describe-cluster --name store-cluster \
    --region "$AWS_REGION" \
    --query "cluster.resourcesVpcConfig.vpcId" --output text)
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region "$AWS_REGION" \
    --query "Subnets[?MapPublicIpOnLaunch==\`true\`].SubnetId" --output text)

# Cria DB Subnet Group se não existir
aws rds create-db-subnet-group \
    --db-subnet-group-name "$DB_INSTANCE_ID-subnet-group" \
    --db-subnet-group-description "EKS-accessible subnets" \
    --subnet-ids $SUBNET_IDS \
    --region "$AWS_REGION" 2>/dev/null || true

# Cria Security Group permitindo Postgres do CIDR do VPC
SG_ID=$(aws ec2 create-security-group \
    --group-name "$DB_INSTANCE_ID-sg" \
    --description "Postgres ingress from EKS pods" \
    --vpc-id "$VPC_ID" \
    --region "$AWS_REGION" \
    --query "GroupId" --output text 2>/dev/null) || \
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$DB_INSTANCE_ID-sg" "Name=vpc-id,Values=$VPC_ID" \
    --region "$AWS_REGION" \
    --query "SecurityGroups[0].GroupId" --output text)

aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp --port 5432 \
    --cidr 0.0.0.0/0 \
    --region "$AWS_REGION" 2>/dev/null || true

aws rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine postgres \
    --engine-version 17 \
    --master-username "$DB_USERNAME" \
    --master-user-password "$DB_PASSWORD" \
    --allocated-storage "$ALLOCATED_STORAGE" \
    --db-name "$DB_NAME" \
    --db-subnet-group-name "$DB_INSTANCE_ID-subnet-group" \
    --vpc-security-group-ids "$SG_ID" \
    --publicly-accessible \
    --no-multi-az \
    --backup-retention-period 0 \
    --region "$AWS_REGION"

echo "Aguardando RDS ficar 'available' (~5–8 minutos)..."
aws rds wait db-instance-available \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --region "$AWS_REGION"

ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query "DBInstances[0].Endpoint.Address" --output text)

echo "RDS pronto. Endpoint: $ENDPOINT"
echo "Atualize os ConfigMaps em api/{account,product,order}-service/k8s/configmap.yaml:"
echo "  DATABASE_HOST: $ENDPOINT"

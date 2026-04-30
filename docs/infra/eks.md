# EKS

!!! warning "Em andamento"
    Esta seção será atualizada conforme o cluster EKS é criado.

## Passos planejados

1. Criar IAM Role para o cluster EKS
2. Criar VPC (ou usar a default)
3. Criar cluster EKS via console ou CLI
4. Criar Node Group
5. Configurar `kubectl` com `aws eks update-kubeconfig`

## Deploy dos serviços

Cada serviço tem manifestos k8s em `api/<service>/k8s/`:

```bash
# Aplicar todos os manifestos
kubectl apply -f api/postgres-service/k8s/
kubectl apply -f api/account-service/k8s/
kubectl apply -f api/auth-service/k8s/
kubectl apply -f api/gateway-service/k8s/
kubectl apply -f api/exchange-service/k8s/
kubectl apply -f api/product-service/k8s/
kubectl apply -f api/order-service/k8s/
```

## HPA (Horizontal Pod Autoscaler)

```bash
kubectl autoscale deployment gateway --cpu-percent=50 --min=1 --max=10
kubectl get hpa
```

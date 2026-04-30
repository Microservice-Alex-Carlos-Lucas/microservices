# Testes de Carga

!!! warning "Em andamento"
    Esta seção será preenchida após a configuração do EKS e HPA.

## Objetivo

Verificar o comportamento da plataforma sob carga e demonstrar o **HPA (Horizontal Pod Autoscaler)**
escalando os pods automaticamente com base no uso de CPU.

## Setup do HPA

```bash
# Criar HPA para o gateway
kubectl autoscale deployment gateway --cpu-percent=50 --min=1 --max=10

# Verificar status
kubectl get hpa
```

## Executando o teste

```bash
# Em um terminal — monitorar HPA
watch -n 1 'kubectl get hpa'

# Em outro terminal — gerar carga
kubectl run -i --tty load-generator --rm --image=busybox:1.28 \
  --restart=Never -- /bin/sh -c \
  "while sleep 0.01; do wget -q -O- http://<gateway-dns>/exchanges/health-check; done"
```

## Resultados esperados

| Métrica | Antes da carga | Durante a carga |
|---------|---------------|-----------------|
| Réplicas gateway | 1 | até 10 |
| CPU utilization | ~1% | >50% |
| Latência P95 | <100ms | <300ms |

## Vídeo

!!! info "Em breve"
    Vídeo do teste de carga em execução será adicionado aqui.

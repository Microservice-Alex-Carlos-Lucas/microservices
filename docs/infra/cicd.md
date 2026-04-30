# CI/CD

A plataforma usa **Jenkins** para CI/CD. Cada serviço tem seu próprio `Jenkinsfile` na raiz
do repositório, seguindo o mesmo padrão de pipeline.

## Pipeline padrão (Java/Spring Boot)

```groovy
pipeline {
    agent any
    environment {
        SERVICE = '<nome>'
        NAME    = "cheqr/${env.SERVICE}"
    }
    stages {
        stage('Build') {
            steps { sh 'mvn -B -DskipTests clean package' }
        }
        stage('Build & Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credential', ...)]) {
                    sh "docker buildx build --platform=linux/arm64,linux/amd64 --push ..."
                }
            }
        }
    }
}
```

## Pipeline Exchange (Python/FastAPI)

Sem etapa Maven — apenas build e push da imagem Docker:

```groovy
pipeline {
    agent any
    environment {
        SERVICE = 'exchange'
        NAME    = "cheqr/${env.SERVICE}"
    }
    stages {
        stage('Build & Push Image') { ... }
    }
}
```

## Serviços e imagens Docker Hub

| Serviço | Imagem Docker Hub |
|---------|------------------|
| account-service | `cheqr/account:latest` |
| auth-service | `cheqr/auth:latest` |
| gateway-service | `cheqr/gateway:latest` |
| exchange | `cheqr/exchange:latest` |
| product-service | `cheqr/product:latest` |
| order-service | `cheqr/order:latest` |

## Jenkins local

```bash
cd jenkins/
docker compose up -d
# Acesse http://localhost:8081
```

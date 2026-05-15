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
# Acesse http://localhost:9080
```

### Dashboard — 8 jobs verdes

Cada job representa um pipeline independente (8 no total: 6 services + 2
libs/interfaces `account` e `auth-interface`):

<figure markdown="span">
  ![Jenkins dashboard — 8 jobs com status verde](../evidence/screenshots/jenkins.png){ width="100%" }
  <figcaption>Figura 1 — Dashboard do Jenkins com os 8 jobs em estado verde (sucesso). Cada job mapeia 1 pra 1 com um repositório no GitHub.</figcaption>
</figure>

### Vídeo de um pipeline rodando do início ao fim

Pipeline completo do `exchange` (Build → Push Image → Deploy to EKS) — do
clone do repo até o `kubectl rollout status` confirmando o deploy em EKS.

<!-- TODO: substituir VIDEO_ID pelo ID do YouTube unlisted depois de subir o video -->
<div class="video-wrapper" markdown="span">
  <iframe width="100%" height="450"
    src="https://www.youtube.com/embed/VIDEO_ID"
    title="Jenkins pipeline rodando do inicio ao fim"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen>
  </iframe>
</div>

!!! tip "Upload do vídeo a fazer"
    Vídeo gravado em `docs/evidence/screenshots/jenkins-video.mov` (112 MB,
    gitignored). Subir para YouTube como **unlisted** (privacy → unlisted),
    pegar o video ID da URL (`youtube.com/watch?v=XXXXXXXXXXX`), e
    substituir `VIDEO_ID` no `<iframe>` acima.

## Docker Hub — imagens publicadas

Cada build do Jenkins publica `cheqr/<service>:latest` e `cheqr/<service>:<BUILD_ID>`
(multi-arch `linux/amd64,linux/arm64`):

<figure markdown="span">
  ![Docker Hub cheqr — 6 imagens dos services](../evidence/screenshots/docker-hub.png){ width="100%" }
  <figcaption>Figura 2 — Repositórios `cheqr/*` no Docker Hub: 6 imagens dos services (`account`, `auth`, `exchange`, `gateway`, `order`, `product`) com pushes recentes do Jenkins.</figcaption>
</figure>

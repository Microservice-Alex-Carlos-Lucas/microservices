/*
 * Cria a credencial 'dockerhub-credential' automaticamente quando Jenkins
 * inicia, lendo DOCKERHUB_USERNAME e DOCKERHUB_TOKEN do environment.
 * Esses env vars vêm do infra/.env via `env_file` em jenkins/compose.yaml.
 *
 * Os Jenkinsfiles de todos os 6 microsserviços referenciam essa credencial
 * por id no estágio "Build & Push Image" (`credentialsId: 'dockerhub-credential'`).
 */

import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import jenkins.model.Jenkins

def env = System.getenv()
def username = env['DOCKERHUB_USERNAME']
def token = env['DOCKERHUB_TOKEN']

if (!username || !token) {
    println("[init.groovy.d] ⚠️  DOCKERHUB_USERNAME or DOCKERHUB_TOKEN not set; skipping dockerhub-credential")
    return
}

def store = SystemCredentialsProvider.getInstance().getStore()
def existing = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    null
).find { it.id == 'dockerhub-credential' }

if (existing) {
    store.removeCredentials(Domain.global(), existing)
    println("[init.groovy.d] removed previous dockerhub-credential")
}

def cred = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    'dockerhub-credential',
    'Docker Hub deploy (auto-injected from infra/.env)',
    username,
    token
)
store.addCredentials(Domain.global(), cred)
println("[init.groovy.d] ✓ created credential 'dockerhub-credential' for user '${username}'")

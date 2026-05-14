---
name: Secrets Management
description: "Secure secrets management using Azure Key Vault, HashiCorp Vault, AWS Secrets Manager, or platform-native solutions. Use when storing credentials, managing API keys, handling certificates, configuring secret access in applications, infrastructure (Terraform/Ansible), Kubernetes, or CI/CD pipelines. Also covers secret rotation, scanning, ADO variable groups, workload identity, and least-privilege access patterns."
version: 1.0.0
tags: [secrets, vault, azure-key-vault, ado, aws-secrets-manager, kubernetes, terraform, security]
---

# Secrets Management

Secure secrets management across applications, infrastructure,
Kubernetes, and CI/CD — using Azure Key Vault, HashiCorp Vault,
AWS Secrets Manager, and platform-native solutions.

## When to Use

- Store or retrieve API keys, credentials, connection strings
- Manage database passwords or service account keys
- Handle TLS certificates and signing keys
- Configure secret access for applications (SDKs, env vars, config)
- Provision secret stores in Terraform or Ansible
- Inject secrets into Kubernetes workloads
- Integrate secrets into ADO, GitHub Actions, or GitLab pipelines
- Rotate secrets automatically
- Implement least-privilege access to secrets
- Set up secret scanning in repos or CI

## Azure Key Vault

### Create and Configure

```bash
az keyvault create \
  --name myapp-kv-prod \
  --resource-group myapp-rg \
  --location westeurope \
  --enable-rbac-authorization \
  --enable-purge-protection

az keyvault secret set \
  --vault-name myapp-kv-prod \
  --name DatabasePassword \
  --value "super-secret-password"

az keyvault certificate import \
  --vault-name myapp-kv-prod \
  --name tls-cert \
  --file cert.pfx \
  --password "pfx-password"

az keyvault secret show \
  --vault-name myapp-kv-prod \
  --name DatabasePassword \
  --query value -o tsv
```

### RBAC Roles (prefer over access policies)

| Role | Scope | Use Case |
|------|-------|----------|
| Key Vault Secrets User | Secret | Read secrets in apps and pipelines |
| Key Vault Secrets Officer | Vault | Manage secrets (create/rotate) |
| Key Vault Certificates Officer | Vault | Manage certificates |
| Key Vault Crypto User | Key | Sign/encrypt operations |
| Key Vault Administrator | Vault | Full control (break-glass only) |

```bash
# Assign to managed identity (app or pipeline)
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee <managed-identity-object-id> \
  --scope /subscriptions/<sub>/resourceGroups/myapp-rg/providers/Microsoft.KeyVault/vaults/myapp-kv-prod

# Scope to individual secret (least privilege)
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee <managed-identity-object-id> \
  --scope /subscriptions/<sub>/resourceGroups/myapp-rg/providers/Microsoft.KeyVault/vaults/myapp-kv-prod/secrets/DatabasePassword
```

### Networking

```bash
az keyvault update \
  --name myapp-kv-prod \
  --default-action Deny \
  --bypass AzureServices

az keyvault network-rule add \
  --name myapp-kv-prod \
  --subnet /subscriptions/<sub>/resourceGroups/myapp-rg/providers/Microsoft.Network/virtualNetworks/myapp-vnet/subnets/app-subnet
```

### Automatic Rotation

```bash
az keyvault secret rotation-policy update \
  --vault-name myapp-kv-prod \
  --name DatabasePassword \
  --value '{
    "lifetimeActions": [
      {"trigger": {"timeAfterCreate": "P90D"}, "action": {"type": "Rotate"}},
      {"trigger": {"timeBeforeExpiry": "P30D"}, "action": {"type": "Notify"}}
    ],
    "attributes": {"expiryTime": "P120D"}
  }'
```

```bash
# Event Grid subscription for custom rotation logic
az eventgrid event-subscription create \
  --name secret-rotation \
  --source-resource-id /subscriptions/<sub>/resourceGroups/myapp-rg/providers/Microsoft.KeyVault/vaults/myapp-kv-prod \
  --endpoint https://myapp-rotation-func.azurewebsites.net/api/rotate \
  --included-event-types Microsoft.KeyVault.SecretNearExpiry
```

## Application Integration

### Azure SDK (Go)

```go
import (
    "github.com/Azure/azure-sdk-for-go/sdk/azidentity"
    "github.com/Azure/azure-sdk-for-go/sdk/security/keyvault/azsecrets"
)

cred, _ := azidentity.NewDefaultAzureCredential(nil)
client, _ := azsecrets.NewClient("https://myapp-kv-prod.vault.azure.net", cred, nil)

resp, _ := client.GetSecret(ctx, "DatabasePassword", "", nil)
password := *resp.Value
```

### Azure SDK (Java / Spring Boot)

```xml
<!-- pom.xml -->
<dependency>
  <groupId>com.azure.spring</groupId>
  <artifactId>spring-cloud-azure-starter-keyvault-secrets</artifactId>
</dependency>
```

```yaml
# application.yml — secrets auto-mapped as Spring properties
spring:
  cloud:
    azure:
      keyvault:
        secret:
          property-sources:
            - name: myapp-kv-prod
              endpoint: https://myapp-kv-prod.vault.azure.net
```

```java
@Value("${DatabasePassword}")
private String dbPassword;
```

### Vault SDK (Go)

```go
import vault "github.com/hashicorp/vault/api"

client, _ := vault.NewClient(vault.DefaultConfig())
secret, _ := client.KVv2("secret").Get(ctx, "database/config")
password := secret.Data["password"].(string)
```

### Environment Variables (local dev)

```bash
# .envrc (direnv) — never commit this file
export DATABASE_URL="postgres://admin:localpass@localhost:5432/myapp"
export API_KEY="dev-key-only"
```

```bash
# 1Password CLI — fetch secrets without files on disk
export DB_PASSWORD=$(op read "op://Development/Database/password")
```

```gitignore
# .gitignore — always exclude secret files
.env
.env.*
.envrc
*.pem
*.key
credentials.json
```

### Azure App Configuration with Key Vault References

```bash
# Store a Key Vault reference in App Configuration
az appconfig kv set-keyvault \
  --name myapp-appconfig \
  --key "Settings:DatabasePassword" \
  --secret-identifier "https://myapp-kv-prod.vault.azure.net/secrets/DatabasePassword"
```

## Infrastructure

### Terraform — Azure Key Vault

```hcl
resource "azurerm_key_vault" "main" {
  name                       = "myapp-kv-prod"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "DatabasePassword"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"

  rotation_policy {
    automatic {
      time_after_creation = "P90D"
    }
    expire_after         = "P120D"
    notify_before_expiry = "P30D"
  }

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}

data "azurerm_key_vault_secret" "db_password" {
  name         = "DatabasePassword"
  key_vault_id = azurerm_key_vault.main.id
}
```

### Terraform — AWS Secrets Manager

```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "production/database/password"
}

resource "aws_db_instance" "main" {
  allocated_storage = 100
  engine            = "postgres"
  instance_class    = "db.t3.large"
  username          = "admin"
  password          = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

### Terraform State — Sensitive Values

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

output "connection_string" {
  value     = "postgres://admin:${var.db_password}@${azurerm_postgresql_server.main.fqdn}/mydb"
  sensitive = true
}
```

Never store secrets in `.tfvars` files committed to Git. Use
environment variables (`TF_VAR_db_password`), Vault provider,
or Key Vault data sources.

### Ansible Vault

```bash
# Encrypt a vars file
ansible-vault encrypt group_vars/production/secrets.yml

# Use in playbook — decrypted at runtime
ansible-playbook deploy.yml --ask-vault-pass

# Encrypt single string for embedding
ansible-vault encrypt_string 'super-secret' --name 'db_password'
```

```yaml
# group_vars/production/secrets.yml (encrypted at rest)
db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...
```

## Kubernetes

### External Secrets Operator — Azure Key Vault

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-kv-backend
  namespace: production
spec:
  provider:
    azurekv:
      vaultUrl: "https://myapp-kv-prod.vault.azure.net"
      authType: WorkloadIdentity
      serviceAccountRef:
        name: external-secrets-sa
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: azure-kv-backend
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: DatabasePassword
```

### External Secrets Operator — Vault

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: production
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "production"
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: database/config
        property: username
    - secretKey: password
      remoteRef:
        key: database/config
        property: password
```

### Azure Key Vault CSI Driver

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kv-secrets
  namespace: production
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "<managed-identity-client-id>"
    keyvaultName: "myapp-kv-prod"
    tenantId: "<tenant-id>"
    objects: |
      array:
        - |
          objectName: DatabasePassword
          objectType: secret
        - |
          objectName: tls-cert
          objectType: secret
  secretObjects:
    - secretName: db-credentials
      type: Opaque
      data:
        - objectName: DatabasePassword
          key: password
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: app
      volumeMounts:
        - name: secrets-store
          mountPath: "/mnt/secrets"
          readOnly: true
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
  volumes:
    - name: secrets-store
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: azure-kv-secrets
```

## CI/CD Integration

### ADO Pipelines — Variable Groups with Key Vault

```yaml
variables:
  - group: myapp-production-secrets   # linked to Key Vault

steps:
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: 'myapp-azure-connection'
      KeyVaultName: 'myapp-kv-prod'
      SecretsFilter: 'DatabasePassword,ApiKey'
      RunAsPreJob: true
    displayName: 'Fetch secrets from Key Vault'

  - script: |
      echo "Connecting as $(DatabasePassword)"
    displayName: 'Use secrets'
```

**ADO Library setup:**

1. Project Settings → Pipelines → Library → + Variable group
2. Toggle "Link secrets from an Azure key vault as variables"
3. Select service connection and Key Vault
4. Authorize specific secrets (never authorize all)
5. Restrict pipeline permissions to specific pipelines

### ADO — Workload Identity Federation

Prefer workload identity over service principal secrets:

```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: 'myapp-workload-identity'
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az keyvault secret show \
        --vault-name myapp-kv-prod \
        --name DatabasePassword \
        --query value -o tsv
```

**Setup:**

1. Create app registration in Entra ID
2. Add federated credential:
   issuer = `https://vstoken.dev.azure.com/<org-id>`,
   subject = `sc://<org>/<project>/<service-connection>`
3. Assign Key Vault RBAC to the app registration
4. Create ADO service connection with workload identity federation type

### ADO — Vault Integration

```yaml
steps:
  - script: |
      export VAULT_ADDR=https://vault.example.com:8200
      export VAULT_TOKEN=$(VaultToken)
      DB_PASSWORD=$(vault kv get -field=password secret/database/config)
      echo "##vso[task.setvariable variable=DB_PASSWORD;issecret=true]$DB_PASSWORD"
    displayName: 'Fetch secrets from Vault'
    env:
      VaultToken: $(VAULT_TOKEN)
```

### ADO Secret Hygiene

- **Variable groups**: Key Vault-linked, not manual secret variables
- **issecret=true**: `echo "##vso[task.setvariable variable=MY_SECRET;issecret=true]$value"`
- **SecretsFilter**: list specific secrets, never `*` in production
- **Pipeline permissions**: restrict variable group access per pipeline
- **Approval gates**: require approval on environments accessing production secrets
- **Audit**: ADO audit log tracks variable group access

### GitHub Actions

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/deploy
    aws-region: us-west-2

- name: Get secret
  run: |
    SECRET=$(aws secretsmanager get-secret-value \
      --secret-id production/database/password \
      --query SecretString --output text)
    echo "::add-mask::$SECRET"
    echo "DB_PASSWORD=$SECRET" >> $GITHUB_ENV
```

```yaml
- name: Import from Vault
  uses: hashicorp/vault-action@v2
  with:
    url: https://vault.example.com:8200
    token: ${{ secrets.VAULT_TOKEN }}
    secrets: |
      secret/data/database username | DB_USERNAME ;
      secret/data/database password | DB_PASSWORD
```

## Secret Scanning

### Pre-commit

```bash
#!/bin/bash
docker run --rm -v "$(pwd):/repo" \
  trufflesecurity/trufflehog:3.88 \
  filesystem --directory=/repo

if [ $? -ne 0 ]; then
  echo "Secret detected! Commit blocked."
  exit 1
fi
```

### CI Integration

```yaml
# ADO
- script: |
    docker run --rm -v $(Build.SourcesDirectory):/repo \
      trufflesecurity/trufflehog:3.88 filesystem --directory=/repo
  displayName: 'Secret scan'
  failOnStderr: true
```

```yaml
# GitHub Actions
- name: Secret scan
  uses: trufflesecurity/trufflehog@v3.88
  with:
    path: .
    extra_args: --only-verified
```

## HashiCorp Vault Reference

### Setup

```bash
vault server -dev
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'
vault secrets enable -path=secret kv-v2
vault kv put secret/database/config username=admin password=secret
```

### Policies (least privilege)

```hcl
# policy: app-readonly
path "secret/data/database/*" {
  capabilities = ["read"]
}

path "secret/data/api/*" {
  capabilities = ["read"]
}
```

```bash
vault policy write app-readonly app-readonly.hcl
vault token create -policy=app-readonly -ttl=1h
```

### Dynamic Secrets (database)

```bash
vault secrets enable database
vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@db:5432/myapp" \
  allowed_roles="readonly" \
  username="vault" \
  password="vault-password"

vault write database/roles/readonly \
  db_name=postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Application fetches short-lived credentials
vault read database/creds/readonly
```

### AWS Secrets Manager Reference

```bash
aws secretsmanager create-secret \
  --name production/database/password \
  --secret-string "super-secret-password"

aws secretsmanager get-secret-value \
  --secret-id production/database/password \
  --query SecretString --output text
```

## Best Practices

1. **Never commit secrets** to Git — use `.gitignore`, pre-commit hooks, and scanning
2. **Use different secrets per environment** — separate Key Vaults for prod/non-prod
3. **Rotate secrets regularly** — automate with Key Vault
   rotation policies or Vault dynamic secrets
4. **Scope access to individual secrets** — RBAC at secret
   level, not vault level
5. **Enable audit logging** — Key Vault diagnostics, Vault
   audit backend, CloudTrail
6. **Scan for secrets** in repos and CI
   (TruffleHog, GitGuardian, Trivy)
7. **Mask secrets in logs** — `issecret=true` (ADO),
   `::add-mask::` (GitHub), masked variables (GitLab)
8. **Prefer managed identity** — Azure Managed Identity,
   workload identity federation, AWS IAM Roles
9. **Use short-lived credentials** — dynamic secrets,
   federated tokens over long-lived keys
10. **Never store secrets in Terraform state unencrypted** —
    use remote backend with encryption, mark variables `sensitive`
11. **Document secret inventory** — what each secret is,
    who owns it, rotation schedule, consumers

## Related Skills

- `ado-standards` — ADO pipeline design, variable groups, service connections
- `ci-cd` — GitHub Actions security, code signing, supply chain protection
- `devsecops-expert` — Shift-left security, IaC scanning
- `security-auditing` — Code and infrastructure security review
- `talos-os-expert` — Kubernetes cluster security

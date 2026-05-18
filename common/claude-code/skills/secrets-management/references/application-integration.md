# Application Integration

## Azure SDK (Go)

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

## Azure SDK (Java / Spring Boot)

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

## Vault SDK (Go)

```go
import vault "github.com/hashicorp/vault/api"

client, _ := vault.NewClient(vault.DefaultConfig())
secret, _ := client.KVv2("secret").Get(ctx, "database/config")
password := secret.Data["password"].(string)
```

## Environment Variables (local dev)

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

## Azure App Configuration with Key Vault References

```bash
# Store a Key Vault reference in App Configuration
az appconfig kv set-keyvault \
  --name myapp-appconfig \
  --key "Settings:DatabasePassword" \
  --secret-identifier "https://myapp-kv-prod.vault.azure.net/secrets/DatabasePassword"
```

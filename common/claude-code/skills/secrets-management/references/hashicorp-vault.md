# HashiCorp Vault

## Setup

```bash
vault server -dev
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'
vault secrets enable -path=secret kv-v2
vault kv put secret/database/config username=admin password=secret
```

## Policies (least privilege)

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

## Dynamic Secrets (database)

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

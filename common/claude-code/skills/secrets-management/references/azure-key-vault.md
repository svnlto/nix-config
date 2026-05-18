# Azure Key Vault

## Create and Configure

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

## RBAC Roles (prefer over access policies)

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

## Networking

```bash
az keyvault update \
  --name myapp-kv-prod \
  --default-action Deny \
  --bypass AzureServices

az keyvault network-rule add \
  --name myapp-kv-prod \
  --subnet /subscriptions/<sub>/resourceGroups/myapp-rg/providers/Microsoft.Network/virtualNetworks/myapp-vnet/subnets/app-subnet
```

## Automatic Rotation

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

# Infrastructure

## Terraform — Azure Key Vault

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

## Terraform — AWS Secrets Manager

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

## Terraform State — Sensitive Values

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

## Ansible Vault

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

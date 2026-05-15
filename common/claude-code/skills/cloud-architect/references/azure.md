# Azure Architecture

Azure architecture patterns with both Terraform and CLI.
Each section provides IaC definitions and equivalent
az CLI commands for common cloud-architecture tasks.

## Networking

Virtual networks, subnets, network security groups,
NSG rules, and VNet peering.

### Terraform

```hcl
resource "azurerm_virtual_network" "main" {
  name                = "main-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = { environment = "production" }
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = [
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}

resource "azurerm_subnet" "data" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "app" {
  name                = "app-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# VNet peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}
```

### CLI

```bash
# Create VNet
az network vnet create \
  --resource-group main-rg \
  --name main-vnet \
  --address-prefix 10.0.0.0/16 \
  --location westeurope

# Create subnets
az network vnet subnet create \
  --resource-group main-rg \
  --vnet-name main-vnet \
  --name app-subnet \
  --address-prefix 10.0.1.0/24 \
  --service-endpoints Microsoft.Sql Microsoft.Storage

az network vnet subnet create \
  --resource-group main-rg \
  --vnet-name main-vnet \
  --name data-subnet \
  --address-prefix 10.0.2.0/24

# Create NSG
az network nsg create \
  --resource-group main-rg \
  --name app-nsg \
  --location westeurope

# Add NSG rule
az network nsg rule create \
  --resource-group main-rg \
  --nsg-name app-nsg \
  --name allow-https \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 443

# Associate NSG with subnet
az network vnet subnet update \
  --resource-group main-rg \
  --vnet-name main-vnet \
  --name app-subnet \
  --network-security-group app-nsg

# Create VNet peering
az network vnet peering create \
  --resource-group hub-rg \
  --name hub-to-spoke \
  --vnet-name hub-vnet \
  --remote-vnet spoke-vnet \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --allow-gateway-transit
```

## Identity & Access

Role assignments, managed identities, and workload
identity for AKS.

### Terraform

```hcl
# User-assigned managed identity
resource "azurerm_user_assigned_identity" "app" {
  name                = "app-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Least-privilege role assignment
resource "azurerm_role_assignment" "app_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# Custom role definition
resource "azurerm_role_definition" "app_custom" {
  name        = "app-custom-role"
  scope       = data.azurerm_subscription.current.id
  description = "Custom role for application workload"

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.KeyVault/vaults/secrets/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}

# Workload identity for AKS
resource "azurerm_federated_identity_credential" "app" {
  name                = "app-federated-cred"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.app.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:app:app-sa"
}
```

### CLI

```bash
# Create managed identity
az identity create \
  --resource-group main-rg \
  --name app-identity

# Assign role
az role assignment create \
  --assignee "<principal-id>" \
  --role "Reader" \
  --scope "/subscriptions/<sub-id>/resourceGroups/main-rg"

# Create custom role
az role definition create --role-definition '{
  "Name": "app-custom-role",
  "Description": "Custom role for application workload",
  "Actions": [
    "Microsoft.Storage/storageAccounts/read",
    "Microsoft.KeyVault/vaults/secrets/read"
  ],
  "AssignableScopes": ["/subscriptions/<sub-id>"]
}'

# Create federated identity credential (workload identity)
az identity federated-credential create \
  --identity-name app-identity \
  --resource-group main-rg \
  --name app-federated-cred \
  --issuer "https://oidc.prod-aks.azure.com/<id>" \
  --subject "system:serviceaccount:app:app-sa" \
  --audiences "api://AzureADTokenExchange"
```

## Compute

AKS clusters with node pools, App Service, and
Container Instances.

### Terraform

```hcl
# AKS cluster with system + user node pools
resource "azurerm_kubernetes_cluster" "main" {
  name                = "main-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "main-aks"
  kubernetes_version  = "1.30"

  default_node_pool {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    min_count           = 2
    max_count           = 5
    auto_scaling_enabled = true
    zones               = [1, 2, 3]
    os_disk_type        = "Ephemeral"
    os_disk_size_gb     = 100

    node_labels = { "nodepool-type" = "system" }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.aks.id
    ]
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin    = "azure"
    network_policy    = "cilium"
    load_balancer_sku = "standard"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "5m"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D8s_v5"
  min_count             = 2
  max_count             = 20
  auto_scaling_enabled  = true
  zones                 = [1, 2, 3]

  node_labels = { "nodepool-type" = "user" }
  node_taints = ["workload=user:NoSchedule"]
}

# App Service
resource "azurerm_service_plan" "main" {
  name                = "main-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "P1v3"
}

resource "azurerm_linux_web_app" "api" {
  name                = "api-webapp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = true

    application_stack {
      docker_image_name   = "myapp:latest"
      docker_registry_url = "https://myacr.azurecr.io"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }
}

# Container Instances
resource "azurerm_container_group" "worker" {
  name                = "worker-ci"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.app.id]

  container {
    name   = "worker"
    image  = "myacr.azurecr.io/worker:latest"
    cpu    = "2"
    memory = "4"

    ports {
      port     = 8080
      protocol = "TCP"
    }

    environment_variables = {
      ENV = "production"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }
}
```

### CLI

```bash
# Create AKS cluster
az aks create \
  --resource-group main-rg \
  --name main-aks \
  --kubernetes-version 1.30 \
  --node-count 3 \
  --node-vm-size Standard_D4s_v5 \
  --enable-managed-identity \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --network-plugin azure \
  --network-policy cilium \
  --zones 1 2 3

# Add user node pool
az aks nodepool add \
  --resource-group main-rg \
  --cluster-name main-aks \
  --name user \
  --node-vm-size Standard_D8s_v5 \
  --min-count 2 --max-count 20 \
  --enable-cluster-autoscaler \
  --zones 1 2 3

# Create App Service plan and web app
az appservice plan create \
  --resource-group main-rg \
  --name main-plan \
  --sku P1v3 --is-linux

az webapp create \
  --resource-group main-rg \
  --plan main-plan \
  --name api-webapp \
  --deployment-container-image-name myacr.azurecr.io/myapp:latest

# Create Container Instance
az container create \
  --resource-group main-rg \
  --name worker-ci \
  --image myacr.azurecr.io/worker:latest \
  --cpu 2 --memory 4 \
  --vnet main-vnet --subnet app-subnet \
  --ip-address Private
```

## Storage & Data

Storage accounts with encryption, Azure SQL, and
Key Vault.

### Terraform

```hcl
# Storage account with encryption and network rules
resource "azurerm_storage_account" "main" {
  name                     = "myappstorageacct"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
    bypass                     = ["AzureServices"]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = { environment = "production" }
}

# Azure SQL
resource "azurerm_mssql_server" "main" {
  name                         = "app-sql-server"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = "sql-admin-group"
    object_id      = data.azuread_group.sql_admins.object_id
  }
}

resource "azurerm_mssql_database" "app" {
  name      = "app-db"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "S1"

  zone_redundant = true

  short_term_retention_policy {
    retention_days = 14
  }

  long_term_retention_policy {
    weekly_retention  = "P4W"
    monthly_retention = "P12M"
    yearly_retention  = "P5Y"
    week_of_year      = 1
  }
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "app-keyvault"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  enable_rbac_authorization   = true

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
  }
}

resource "azurerm_role_assignment" "kv_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
```

### CLI

```bash
# Create storage account
az storage account create \
  --resource-group main-rg \
  --name myappstorageacct \
  --sku Standard_ZRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Add network rules
az storage account network-rule add \
  --resource-group main-rg \
  --account-name myappstorageacct \
  --vnet-name main-vnet \
  --subnet app-subnet

# Create SQL server and database
az sql server create \
  --resource-group main-rg \
  --name app-sql-server \
  --admin-user sqladmin \
  --admin-password "<from-key-vault>" \
  --minimal-tls-version 1.2

az sql db create \
  --resource-group main-rg \
  --server app-sql-server \
  --name app-db \
  --service-objective S1 \
  --zone-redundant true \
  --backup-storage-redundancy Zone

# Create Key Vault
az keyvault create \
  --resource-group main-rg \
  --name app-keyvault \
  --enable-rbac-authorization true \
  --enable-purge-protection true

# Grant secrets access
az role assignment create \
  --assignee "<principal-id>" \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/<sub>/resourceGroups/main-rg/providers/Microsoft.KeyVault/vaults/app-keyvault"
```

## High Availability

Availability zones, Traffic Manager, Azure Front Door,
paired regions, and zone-redundant resources.

### Terraform

```hcl
# Traffic Manager — DNS-based global load balancing
resource "azurerm_traffic_manager_profile" "app" {
  name                   = "app-tm"
  resource_group_name    = azurerm_resource_group.main.name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "app"
    ttl           = 60
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/health"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "primary" {
  name               = "primary"
  profile_id         = azurerm_traffic_manager_profile.app.id
  target_resource_id = azurerm_linux_web_app.primary.id
  priority           = 1
}

resource "azurerm_traffic_manager_azure_endpoint" "secondary" {
  name               = "secondary"
  profile_id         = azurerm_traffic_manager_profile.app.id
  target_resource_id = azurerm_linux_web_app.secondary.id
  priority           = 2
}

# Azure Front Door
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "app-frontdoor"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "app" {
  name                     = "app-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin_group" "app" {
  name                     = "app-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/health"
    protocol            = "Https"
    interval_in_seconds = 30
  }
}

resource "azurerm_cdn_frontdoor_origin" "primary" {
  name                           = "primary"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.app.id
  host_name                      = azurerm_linux_web_app.primary.default_hostname
  http_port                      = 80
  https_port                     = 443
  certificate_name_check_enabled = true
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_origin" "secondary" {
  name                           = "secondary"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.app.id
  host_name                      = azurerm_linux_web_app.secondary.default_hostname
  http_port                      = 80
  https_port                     = 443
  certificate_name_check_enabled = true
  priority                       = 2
  weight                         = 1000
}

# Zone-redundant resources — example: AKS with zones
resource "azurerm_kubernetes_cluster" "ha" {
  name                = "ha-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "ha-aks"

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_D4s_v5"
    min_count            = 3
    max_count            = 9
    auto_scaling_enabled = true
    zones                = [1, 2, 3]
  }

  identity {
    type = "SystemAssigned"
  }
}
```

### CLI

```bash
# Create Traffic Manager profile
az network traffic-manager profile create \
  --resource-group main-rg \
  --name app-tm \
  --routing-method Priority \
  --unique-dns-name app \
  --monitor-protocol HTTPS \
  --monitor-port 443 \
  --monitor-path /health

# Add endpoints
az network traffic-manager endpoint create \
  --resource-group main-rg \
  --profile-name app-tm \
  --name primary \
  --type azureEndpoints \
  --target-resource-id "<primary-webapp-id>" \
  --priority 1

az network traffic-manager endpoint create \
  --resource-group main-rg \
  --profile-name app-tm \
  --name secondary \
  --type azureEndpoints \
  --target-resource-id "<secondary-webapp-id>" \
  --priority 2

# Create Front Door profile
az afd profile create \
  --resource-group main-rg \
  --profile-name app-frontdoor \
  --sku Premium_AzureFrontDoor

# Create endpoint
az afd endpoint create \
  --resource-group main-rg \
  --profile-name app-frontdoor \
  --endpoint-name app-endpoint

# Create origin group with health probe
az afd origin-group create \
  --resource-group main-rg \
  --profile-name app-frontdoor \
  --origin-group-name app-origin-group \
  --probe-path /health \
  --probe-protocol Https \
  --probe-request-type HEAD \
  --probe-interval-in-seconds 30 \
  --sample-size 4 \
  --successful-samples-required 3
```

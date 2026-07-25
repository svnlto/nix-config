# Multi-Cloud Architecture

Patterns for operating across AWS and Azure.
Covers cross-cloud networking, identity federation,
data residency, disaster recovery, and abstraction
strategies.

## Cross-Cloud Networking

VPN connectivity between AWS VPC and Azure VNet,
transit gateway patterns, and DNS resolution across
clouds.

### VPN Between AWS and Azure

```hcl
# AWS side — VPN gateway
resource "aws_vpn_gateway" "main" {
  vpc_id          = aws_vpc.main.id
  amazon_side_asn = 64512

  tags = { Name = "aws-to-azure-vpn-gw" }
}

resource "aws_customer_gateway" "azure" {
  bgp_asn    = 65515
  ip_address = azurerm_public_ip.vpn_gw.ip_address
  type       = "ipsec.1"

  tags = { Name = "azure-customer-gw" }
}

resource "aws_vpn_connection" "to_azure" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.azure.id
  type                = "ipsec.1"
  static_routes_only  = false

  tags = { Name = "aws-to-azure-vpn" }
}

# Azure side — VNet gateway
resource "azurerm_public_ip" "vpn_gw" {
  name                = "vpn-gw-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "main" {
  name                = "azure-to-aws-vpn-gw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw2"
  active_active       = false
  enable_bgp          = true

  bgp_settings {
    asn = 65515
  }

  ip_configuration {
    name                          = "vnet-gw-config"
    public_ip_address_id          = azurerm_public_ip.vpn_gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

resource "azurerm_local_network_gateway" "aws" {
  name                = "aws-local-gw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  gateway_address     = aws_vpn_connection.to_azure.tunnel1_address

  bgp_settings {
    asn                 = 64512
    bgp_peering_address = aws_vpn_connection.to_azure.tunnel1_bgp_asn
  }
}

resource "azurerm_virtual_network_gateway_connection" "to_aws" {
  name                       = "azure-to-aws"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws.id
  shared_key                 = var.vpn_shared_key # From Key Vault

  enable_bgp = true
}
```

### DNS Resolution Across Clouds

```hcl
# AWS Route 53 — forward Azure DNS zone
resource "aws_route53_resolver_rule" "azure_forward" {
  domain_name          = "internal.azure.example.com"
  name                 = "forward-to-azure-dns"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip = "10.1.0.4" # Azure DNS resolver IP
  }
}

resource "aws_route53_resolver_rule_association" "main" {
  resolver_rule_id = aws_route53_resolver_rule.azure_forward.id
  vpc_id           = aws_vpc.main.id
}

# Azure DNS — conditional forwarding to Route 53
resource "azurerm_private_dns_resolver" "main" {
  name                = "dns-resolver"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  virtual_network_id  = azurerm_virtual_network.main.id
}

resource "azurerm_private_dns_resolver_forwarding_rule" "aws" {
  name                      = "forward-to-aws"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.main.id
  domain_name               = "internal.aws.example.com."

  target_dns_servers {
    ip_address = "10.0.0.2" # Route 53 resolver IP
    port       = 53
  }
}
```

### Transit Gateway Pattern (Hub-and-Spoke)

```bash
# AWS Transit Gateway — hub for multiple VPCs
aws ec2 create-transit-gateway \
  --description "multi-cloud-hub" \
  --options AmazonSideAsn=64512,AutoAcceptSharedAttachments=enable

# Attach VPC to transit gateway
aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-xxx \
  --vpc-id vpc-xxx \
  --subnet-ids subnet-a subnet-b

# Attach VPN to transit gateway
aws ec2 create-vpn-connection \
  --type ipsec.1 \
  --customer-gateway-id cgw-xxx \
  --transit-gateway-id tgw-xxx
```

## Identity Federation

Trust relationships between AWS IAM and Azure Entra
ID, OIDC federation, and Vault as an identity broker.

### AWS IAM + Azure Entra ID Trust

```hcl
# AWS: trust Azure Entra ID as OIDC provider
resource "aws_iam_openid_connect_provider" "azure_ad" {
  url             = "https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0"
  client_id_list  = [var.azure_app_client_id]
  thumbprint_list = [var.azure_ad_thumbprint]
}

# AWS: role assumable by Azure workloads
resource "aws_iam_role" "azure_federated" {
  name = "azure-federated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.azure_ad.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "login.microsoftonline.com/${var.azure_tenant_id}/v2.0:aud" = var.azure_app_client_id
          }
        }
      }
    ]
  })
}
```

### Azure: Trust AWS for Cross-Cloud Access

```hcl
# Azure: federated credential trusting AWS STS
resource "azurerm_user_assigned_identity" "aws_federated" {
  name                = "aws-federated-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_federated_identity_credential" "aws" {
  name                = "aws-oidc-trust"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.aws_federated.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:org/repo:environment:production"
}
```

### Vault as Identity Broker

```hcl
# Vault AWS secrets engine — dynamic credentials
resource "vault_aws_secret_backend" "aws" {
  path       = "aws"
  access_key = var.vault_aws_access_key
  secret_key = var.vault_aws_secret_key
  region     = "eu-west-1"

  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 7200
}

resource "vault_aws_secret_backend_role" "app" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "app-role"
  credential_type = "iam_user"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = ["arn:aws:s3:::my-bucket/*"]
      }
    ]
  })
}

# Vault Azure secrets engine — dynamic credentials
resource "vault_azure_secret_backend" "azure" {
  path            = "azure"
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
  client_id       = var.vault_azure_client_id
  client_secret   = var.vault_azure_client_secret
}

resource "vault_azure_secret_backend_role" "app" {
  backend = vault_azure_secret_backend.azure.path
  role    = "app-role"
  ttl     = 3600
  max_ttl = 7200

  azure_roles {
    role_name = "Reader"
    scope     = "/subscriptions/${var.azure_subscription_id}/resourceGroups/main-rg"
  }
}
```

## Data Residency

Region selection for compliance, data sovereignty,
cross-cloud replication, and encryption key management.

### Region Selection for Compliance

| Requirement | AWS Region | Azure Region |
|-------------|-----------|--------------|
| EU data residency | eu-west-1 (Ireland) | westeurope (Netherlands) |
| EU backup | eu-central-1 (Frankfurt) | northeurope (Ireland) |
| UK data residency | eu-west-2 (London) | uksouth (London) |
| US data residency | us-east-1 (Virginia) | eastus (Virginia) |

### Cross-Cloud Replication Pattern

```hcl
# S3 bucket in AWS (source)
resource "aws_s3_bucket" "primary" {
  bucket = "data-primary-aws"

  tags = {
    data-classification = "confidential"
    data-residency      = "eu"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration { status = "Enabled" }
}

# Azure Blob Storage (DR replica)
resource "azurerm_storage_account" "replica" {
  name                     = "datareplicaazure"
  resource_group_name      = azurerm_resource_group.dr.name
  location                 = "westeurope"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"

  tags = {
    data-classification = "confidential"
    data-residency      = "eu"
    replication-source  = "aws-eu-west-1"
  }
}

# Note: cross-cloud replication requires a sync
# process (e.g., AWS Lambda + Azure Function, or
# a dedicated replication service). Native S3-to-Blob
# replication does not exist.
```

### Encryption Key Management Per Cloud

```hcl
# AWS KMS — customer-managed key
resource "aws_kms_key" "data" {
  description             = "Data encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "KeyAdmins"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::123:role/key-admin" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })

  tags = { data-residency = "eu" }
}

# Azure Key Vault — customer-managed key
resource "azurerm_key_vault_key" "data" {
  name         = "data-encryption-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt", "encrypt",
    "wrapKey", "unwrapKey"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P365D"
    notify_before_expiry = "P30D"
  }
}
```

## Disaster Recovery

Active-active vs active-passive patterns, RTO/RPO
per service tier, failover automation, and Terraform
state management per cloud.

### Architecture Comparison

| Aspect | Active-Active | Active-Passive |
|--------|--------------|----------------|
| Cost | Higher (2x infra) | Lower (standby) |
| RTO | Near-zero | Minutes to hours |
| RPO | Near-zero (sync) | Seconds to minutes |
| Complexity | High | Medium |
| Data sync | Bidirectional | Unidirectional |
| Best for | Critical services | Standard services |

### RTO/RPO Per Service Tier

| Tier | RTO | RPO | Pattern |
|------|-----|-----|---------|
| Platinum | < 1 min | 0 (sync) | Active-active, multi-cloud |
| Gold | < 15 min | < 1 min | Active-passive, hot standby |
| Silver | < 1 hour | < 15 min | Warm standby, async replication |
| Bronze | < 4 hours | < 1 hour | Cold standby, backup restore |

### Failover Automation

```hcl
# AWS Route 53 health check — triggers failover
resource "aws_route53_health_check" "primary" {
  fqdn              = "api.primary.example.com"
  port               = 443
  type               = "HTTPS"
  resource_path      = "/health"
  request_interval   = 10
  failure_threshold  = 2

  tags = { Name = "primary-health-check" }
}

# Azure Traffic Manager — DNS failover
resource "azurerm_traffic_manager_profile" "dr" {
  name                   = "dr-traffic-manager"
  resource_group_name    = azurerm_resource_group.dr.name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "api"
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/health"
    interval_in_seconds          = 10
    timeout_in_seconds           = 5
    tolerated_number_of_failures = 2
  }
}
```

### Terraform State Per Cloud

Keep state backends separate per cloud provider
to avoid cross-cloud blast radius and enable
independent recovery.

```hcl
# AWS state backend
terraform {
  backend "s3" {
    bucket         = "terraform-state-aws"
    key            = "production/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# Azure state backend (separate Terraform root)
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateazure"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
```

## Abstraction Patterns

Terraform modules that abstract cloud-specific
resources. Know when to abstract vs use native APIs.

### When to Abstract

| Scenario | Abstract? | Reason |
|----------|-----------|--------|
| Compute (VM/instance) | Yes | Similar lifecycle |
| Networking (VPC/VNet) | Partially | Similar but nuanced |
| Managed K8s (EKS/AKS) | No | Too different |
| Secrets (KV/SM) | Yes | Simple CRUD |
| IAM (IAM/RBAC) | No | Fundamentally different |
| Storage (S3/Blob) | Partially | Similar basics |

### Abstracted Compute Module

```hcl
# modules/compute/main.tf
variable "cloud" {
  type = string
  validation {
    condition     = contains(["aws", "azure"], var.cloud)
    error_message = "Supported clouds: aws, azure."
  }
}

variable "name" { type = string }
variable "instance_size" { type = string }
variable "subnet_id" { type = string }

# AWS implementation
resource "aws_instance" "this" {
  count         = var.cloud == "aws" ? 1 : 0
  ami           = data.aws_ami.latest[0].id
  instance_type = var.instance_size
  subnet_id     = var.subnet_id

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = var.name }
}

# Azure implementation
resource "azurerm_linux_virtual_machine" "this" {
  count               = var.cloud == "azure" ? 1 : 0
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.instance_size
  admin_username      = "adminuser"

  network_interface_ids = [var.nic_id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

output "id" {
  value = var.cloud == "aws" ? (
    length(aws_instance.this) > 0 ? aws_instance.this[0].id : null
  ) : (
    length(azurerm_linux_virtual_machine.this) > 0 ? azurerm_linux_virtual_machine.this[0].id : null
  )
}
```

### Avoiding Lowest-Common-Denominator Trap

Do not abstract away cloud-specific strengths just to
achieve a uniform interface. Prefer native resources
when:

- The cloud service has unique features you need
  (e.g., EKS Pod Identity vs AKS Workload Identity)
- Performance characteristics differ significantly
- The abstraction hides important configuration
  (e.g., AZ placement, encryption options)
- You only run in one cloud for that workload

Use abstraction when:

- You genuinely deploy the same workload to both clouds
- The resources have nearly identical lifecycle
- The module simplifies onboarding for teams
- You have a platform team maintaining the modules

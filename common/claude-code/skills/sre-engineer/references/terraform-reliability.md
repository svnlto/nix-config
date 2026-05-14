# Terraform Reliability Patterns

Examples show raw Terraform resources;
wrap with Terragrunt for orchestration.

## Zero-Downtime Deploys

### Create Before Destroy (AWS Launch Template)

```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    app_version = var.app_version
  }))

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "app-${var.app_version}"
      Environment = var.environment
    }
  }
}
```

### Create Before Destroy (Azure Linux Web App)

```hcl
resource "azurerm_service_plan" "app" {
  name                = "plan-${var.app_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-${var.app_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app.id

  site_config {
    always_on = true

    application_stack {
      docker_registry_url = var.registry_url
      docker_image_name   = "${var.image_name}:${var.image_tag}"
    }

    health_check_path                 = "/healthz"
    health_check_eviction_time_in_min = 5
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

### Kubernetes Rolling Update

```hcl
resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace

    labels = {
      app     = var.app_name
      version = var.app_version
    }
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "0"
      }
    }

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app     = var.app_name
          version = var.app_version
        }

        annotations = {
          "config-hash" = sha256(jsonencode(var.app_config))
        }
      }

      spec {
        container {
          name  = var.app_name
          image = "${var.image}:${var.app_version}"

          port {
            container_port = var.container_port
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = var.container_port
            }

            initial_delay_seconds = 10
            period_seconds        = 5
            failure_threshold     = 3
            success_threshold     = 1
          }

          liveness_probe {
            http_get {
              path = "/livez"
              port = var.container_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }

            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }
        }

        termination_grace_period_seconds = 60
      }
    }
  }

  wait_for_rollout = true

  timeouts {
    create = "10m"
    update = "10m"
  }
}
```

### Helm Release with Safety Guards

```hcl
resource "helm_release" "app" {
  name       = var.release_name
  namespace  = var.namespace
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  wait          = true
  wait_for_jobs = true
  timeout       = 600
  atomic        = true

  values = [
    yamlencode({
      replicaCount = var.replicas

      image = {
        repository = var.image
        tag        = var.app_version
      }

      strategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxSurge       = "25%"
          maxUnavailable = 0
        }
      }

      readinessProbe = {
        httpGet = {
          path = "/healthz"
          port = "http"
        }
        initialDelaySeconds = 10
        periodSeconds       = 5
      }
    })
  ]

  set {
    name  = "podAnnotations.deploy-timestamp"
    value = timestamp()
  }
}
```

## Health Checks & Readiness

### AWS ALB Target Group Health Check

```hcl
resource "aws_lb_target_group" "app" {
  name                 = "${var.app_name}-${var.environment}"
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = false
    cookie_duration = 86400
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

### Azure Application Gateway Probe

```hcl
resource "azurerm_application_gateway" "app" {
  name                = "agw-${var.app_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = var.gateway_subnet_id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = var.public_ip_id
  }

  backend_address_pool {
    name = "${var.app_name}-pool"
  }

  probe {
    name                                      = "${var.app_name}-health"
    protocol                                  = "Http"
    path                                      = "/healthz"
    host                                      = var.app_hostname
    interval                                  = 10
    timeout                                   = 5
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
    minimum_servers                           = 0

    match {
      status_code = ["200"]
    }
  }

  backend_http_settings {
    name                  = "${var.app_name}-settings"
    cookie_based_affinity = "Disabled"
    port                  = var.container_port
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "${var.app_name}-health"

    connection_draining {
      enabled           = true
      drain_timeout_sec = 30
    }
  }

  http_listener {
    name                           = "${var.app_name}-listener"
    frontend_ip_configuration_name = "frontend"
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = var.ssl_cert_name
  }

  request_routing_rule {
    name                       = "${var.app_name}-rule"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "${var.app_name}-listener"
    backend_address_pool_name  = "${var.app_name}-pool"
    backend_http_settings_name = "${var.app_name}-settings"
  }
}
```

## Capacity Planning

### AWS Auto Scaling Group with Instance Refresh

```hcl
resource "aws_autoscaling_group" "app" {
  name                = "${var.app_name}-${var.environment}"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 120
      skip_matching          = true
    }
  }

  health_check_type         = "ELB"
  health_check_grace_period = 180
  wait_for_capacity_timeout = "10m"

  tag {
    key                 = "Name"
    value               = "${var.app_name}-${var.environment}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.app_name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = 70.0
    disable_scale_in = false
  }
}
```

### Kubernetes HPA v2

```hcl
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
  }

  spec {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.app.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"

      resource {
        name = "memory"

        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    behavior {
      scale_up {
        stabilization_window_seconds = 60
        select_policy                = "Max"

        policy {
          type           = "Percent"
          value          = 50
          period_seconds = 60
        }

        policy {
          type           = "Pods"
          value          = 4
          period_seconds = 60
        }
      }

      scale_down {
        stabilization_window_seconds = 300
        select_policy                = "Min"

        policy {
          type           = "Percent"
          value          = 10
          period_seconds = 60
        }
      }
    }
  }
}
```

### Kubernetes Resource Quotas

```hcl
resource "kubernetes_resource_quota_v1" "namespace" {
  metadata {
    name      = "${var.namespace}-quota"
    namespace = var.namespace
  }

  spec {
    hard = {
      "requests.cpu"    = var.quota_cpu_requests
      "requests.memory" = var.quota_memory_requests
      "limits.cpu"      = var.quota_cpu_limits
      "limits.memory"   = var.quota_memory_limits
      pods              = var.quota_max_pods
      services          = var.quota_max_services
    }
  }
}

resource "kubernetes_limit_range_v1" "namespace" {
  metadata {
    name      = "${var.namespace}-limits"
    namespace = var.namespace
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = "500m"
        memory = "512Mi"
      }

      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }

      max = {
        cpu    = "4"
        memory = "4Gi"
      }

      min = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
  }
}
```

## Drift Detection & State Safety

### Prevent Destroy on Critical Resources

```hcl
resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.app_name}-${var.environment}"
  engine             = "aurora-postgresql"
  engine_version     = var.aurora_version
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.master_password

  backup_retention_period      = 35
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  deletion_protection          = true
  skip_final_snapshot          = false
  final_snapshot_identifier    = "${var.app_name}-${var.environment}-final"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.app_name}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  lifecycle {
    prevent_destroy = true
  }
}
```

### Ignore Changes for Managed Fields

```hcl
resource "kubernetes_deployment_v1" "externally_managed" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["kubectl.kubernetes.io/last-applied-configuration"],
      metadata[0].annotations["deployment.kubernetes.io/revision"],
      metadata[0].labels["app.kubernetes.io/managed-by"],
    ]
  }

  # ... spec omitted for brevity
}

resource "helm_release" "managed_app" {
  name      = var.release_name
  namespace = var.namespace
  chart     = var.chart_name
  version   = var.chart_version

  lifecycle {
    ignore_changes = [
      metadata,
    ]
  }
}
```

## Secrets & Config

### Vault Dynamic Secrets to Kubernetes

```hcl
data "vault_generic_secret" "db_creds" {
  path = "database/creds/${var.vault_role}"
}

resource "kubernetes_secret_v1" "db_creds" {
  metadata {
    name      = "${var.app_name}-db-creds"
    namespace = var.namespace

    labels = {
      app                    = var.app_name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "Opaque"

  data = {
    username = data.vault_generic_secret.db_creds.data["username"]
    password = data.vault_generic_secret.db_creds.data["password"]
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
    ]
  }
}
```

### AWS SSM Parameter and Secrets Manager

```hcl
data "aws_ssm_parameter" "app_config" {
  for_each = toset(var.ssm_parameter_names)
  name     = "/app/${var.app_name}/${var.environment}/${each.key}"
}

data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = "app/${var.app_name}/${var.environment}/api-key"
}

resource "kubernetes_secret_v1" "app_secrets" {
  metadata {
    name      = "${var.app_name}-secrets"
    namespace = var.namespace
  }

  type = "Opaque"

  data = merge(
    {
      for name, param in data.aws_ssm_parameter.app_config :
      name => param.value
    },
    {
      api-key = data.aws_secretsmanager_secret_version.api_key.secret_string
    }
  )
}

resource "kubernetes_config_map_v1" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = var.namespace
  }

  data = {
    for name, param in data.aws_ssm_parameter.app_config :
    name => param.value
    if !contains(var.sensitive_params, name)
  }
}
```

## State Safety

### S3 Remote Backend with DynamoDB Locking

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-ACCOUNT_ID"
    key            = "app/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    kms_key_id     = "alias/terraform-state"
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

### Import Blocks for Existing Infrastructure

```hcl
import {
  to = aws_rds_cluster.main
  id = "existing-aurora-cluster-id"
}

import {
  to = azurerm_key_vault.main
  id = "/subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.KeyVault/vaults/VAULT_NAME"
}

# After import, run:
#   terraform plan -generate-config-out=generated.tf
# Review generated.tf, merge into your modules, then remove the import blocks.
```

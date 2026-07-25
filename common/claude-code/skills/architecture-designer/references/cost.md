# Cloud Cost Optimization

FinOps patterns for AWS and Azure with Terraform
and CLI. Covers tagging, right-sizing, reservations,
spot instances, and cost monitoring.

## Tagging Strategy

Consistent tagging is the foundation of cost allocation.
Enforce required tags via policy, not convention.

### Required Tags

| Tag | Purpose | Example |
|-----|---------|---------|
| `team` | Cost allocation to team | `platform` |
| `env` | Environment classification | `production` |
| `service` | Service or application name | `payment-api` |
| `cost-center` | Finance cost center code | `CC-4200` |

### Terraform — AWS Default Tags

```hcl
provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      team        = "platform"
      env         = "production"
      service     = "payment-api"
      cost-center = "CC-4200"
      managed-by  = "terraform"
    }
  }
}
```

### Terraform — Azure Provider Tags

```hcl
provider "azurerm" {
  features {}

  # No default_tags in azurerm — use a local
  # and spread it into every resource's tags block
}

locals {
  common_tags = {
    team        = "platform"
    env         = "production"
    service     = "payment-api"
    cost-center = "CC-4200"
    managed-by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "main-rg"
  location = "westeurope"
  tags     = local.common_tags
}
```

### Terraform — Azure Policy for Tag Enforcement

```hcl
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-cost-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require cost allocation tags"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "tags['team']"
          exists = "false"
        },
        {
          field  = "tags['env']"
          exists = "false"
        },
        {
          field  = "tags['service']"
          exists = "false"
        },
        {
          field  = "tags['cost-center']"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "require_tags" {
  name                 = "require-cost-tags"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  subscription_id      = data.azurerm_subscription.current.id
}
```

## Right-Sizing

Identify over-provisioned resources and resize to
match actual usage. Check recommendations regularly.

### AWS

```bash
# Get rightsizing recommendations from Cost Explorer
aws ce get-rightsizing-recommendation \
  --service AmazonEC2 \
  --configuration '{
    "RecommendationTarget": "SAME_INSTANCE_FAMILY",
    "BenefitsConsidered": true
  }'

# List underutilized instances via CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxx \
  --start-time 2026-05-07T00:00:00Z \
  --end-time 2026-05-14T00:00:00Z \
  --period 86400 \
  --statistics Average
```

### Azure

```bash
# Get cost optimization recommendations
az advisor recommendation list --category Cost

# List VM sizes available for resize
az vm list-sizes --location westeurope \
  --output table

# Resize a VM
az vm resize \
  --resource-group main-rg \
  --name app-vm \
  --size Standard_D2s_v5
```

### Terraform — Right-Sized Instance Types

```hcl
# Start small, scale up based on metrics
# t3.medium → t3.large → m6i.large → m6i.xlarge

variable "instance_type" {
  description = "EC2 instance type — review monthly"
  type        = string
  default     = "t3.medium"

  validation {
    condition = contains([
      "t3.medium", "t3.large",
      "m6i.large", "m6i.xlarge"
    ], var.instance_type)
    error_message = "Use an approved instance type."
  }
}
```

## Reserved & Savings Plans

Commit to usage for 1-year or 3-year terms to reduce
hourly costs. Only commit after 3+ months of stable
baseline usage.

### Break-Even Comparison

| Plan | Discount | Break-Even | Best For |
|------|----------|------------|----------|
| On-Demand | 0% | N/A | Variable, unpredictable |
| 1-Year RI / SP | ~30-40% | ~7-8 months | Stable baseline |
| 3-Year RI / SP | ~50-60% | ~14-16 months | Long-term commitments |

### When to Commit

- 3+ months of stable baseline usage observed
- Workload is not scheduled for decommission
- Coverage target: 60-80% of baseline (leave headroom)
- Review quarterly, adjust as usage changes

### AWS Savings Plans

```bash
# View Savings Plan recommendations
aws ce get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SAVINGS_PLANS \
  --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT \
  --lookback-period-in-days SIXTY_DAYS

# View current utilization
aws ce get-savings-plans-utilization \
  --time-period Start=2026-04-01,End=2026-05-01
```

### Azure Reservations

```bash
# List reservation recommendations
az consumption reservation recommendation list \
  --scope Shared \
  --look-back-period Last60Days

# View reservation utilization
az consumption reservation summary list \
  --reservation-order-id "<order-id>" \
  --grain monthly \
  --start-date 2026-04-01 \
  --end-date 2026-05-01
```

## Spot / Preemptible Instances

Use spot capacity for fault-tolerant, stateless
workloads. Always design for interruption.

### AWS Spot in Auto Scaling Group

```hcl
resource "aws_autoscaling_group" "spot_mixed" {
  name                = "app-spot-asg"
  min_size            = 2
  max_size            = 20
  desired_capacity    = 6
  vpc_zone_identifier = [for s in aws_subnet.private : s.id]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 2
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app.id
        version            = "$Latest"
      }

      override {
        instance_type = "m6i.large"
      }
      override {
        instance_type = "m5.large"
      }
      override {
        instance_type = "m5a.large"
      }
    }
  }
}
```

### Azure Spot VMs

```hcl
resource "azurerm_linux_virtual_machine" "spot_worker" {
  name                = "spot-worker"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D4s_v5"

  priority        = "Spot"
  eviction_policy = "Deallocate"
  max_bid_price   = -1 # Pay up to on-demand price

  admin_username = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.spot_worker.id
  ]
}
```

### Kubernetes Spot Node Pools

```hcl
# EKS spot node group
resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "spot-workers"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = [for s in aws_subnet.private : s.id]
  capacity_type   = "SPOT"
  instance_types  = ["m6i.large", "m5.large", "m5a.large"]

  scaling_config {
    desired_size = 3
    max_size     = 15
    min_size     = 0
  }

  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
}

# AKS spot node pool
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D4s_v5"
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1
  min_count             = 0
  max_count             = 15
  auto_scaling_enabled  = true

  node_labels = { "kubernetes.azure.com/scalesetpriority" = "spot" }
  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
}
```

### Interruption Handling

```bash
# AWS: monitor spot interruption notices (2-min warning)
# Use in a userdata script or sidecar
TOKEN=$(curl -s -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/spot/instance-action
```

## Cost Monitoring

Set budgets and anomaly alerts to catch unexpected
spending before it becomes a problem.

### AWS Budget — Terraform

```hcl
resource "aws_budgets_budget" "monthly" {
  name         = "monthly-total-budget"
  budget_type  = "COST"
  limit_amount = "10000"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = ["user:env$production"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["platform-team@example.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["platform-team@example.com"]
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }
}
```

### Azure Budget — Terraform

```hcl
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "monthly-total-budget"
  subscription_id = data.azurerm_subscription.current.id
  amount          = 10000
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-01-01T00:00:00Z"
    end_date   = "2027-01-01T00:00:00Z"
  }

  filter {
    tag {
      name   = "env"
      values = ["production"]
    }
  }

  notification {
    enabled        = true
    threshold      = 80
    threshold_type = "Forecasted"
    operator       = "GreaterThan"

    contact_emails = ["platform-team@example.com"]
  }

  notification {
    enabled        = true
    threshold      = 100
    threshold_type = "Actual"
    operator       = "GreaterThan"

    contact_emails = ["platform-team@example.com"]
    contact_groups = [azurerm_monitor_action_group.budget.id]
  }
}
```

### CLI — Budget Creation

```bash
# AWS: create budget
aws budgets create-budget --account-id 123456789012 \
  --budget '{
    "BudgetName": "monthly-total-budget",
    "BudgetLimit": {"Amount": "10000", "Unit": "USD"},
    "BudgetType": "COST",
    "TimeUnit": "MONTHLY"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "FORECASTED",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "platform-team@example.com"
    }]
  }]'

# Azure: create budget
az consumption budget create \
  --budget-name monthly-total-budget \
  --amount 10000 \
  --time-grain Monthly \
  --start-date 2026-01-01 \
  --end-date 2027-01-01 \
  --category Cost
```

### Anomaly Detection

```bash
# AWS: create cost anomaly monitor
aws ce create-anomaly-monitor \
  --anomaly-monitor '{
    "MonitorName": "service-anomaly",
    "MonitorType": "DIMENSIONAL",
    "MonitorDimension": "SERVICE"
  }'

# AWS: create anomaly subscription (alerts)
aws ce create-anomaly-subscription \
  --anomaly-subscription '{
    "SubscriptionName": "anomaly-alerts",
    "MonitorArnList": ["arn:aws:ce::123:anomalymonitor/xxx"],
    "Subscribers": [{
      "Address": "platform-team@example.com",
      "Type": "EMAIL"
    }],
    "Frequency": "DAILY",
    "ThresholdExpression": {
      "Dimensions": {
        "Key": "ANOMALY_TOTAL_IMPACT_ABSOLUTE",
        "Values": ["100"],
        "MatchOptions": ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }'

# Azure: cost anomalies via Advisor
az advisor recommendation list \
  --category Cost \
  --output table
```

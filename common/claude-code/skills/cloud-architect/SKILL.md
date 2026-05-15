---
name: cloud-architect
description: Cloud architecture design, migration, optimization, and disaster recovery across AWS and Azure. Use when designing VPCs/VNets, IAM/RBAC, compute/storage architectures, cost optimization, multi-cloud patterns, or planning migrations. Both Terraform and CLI approaches.
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "2.0.0"
  domain: cloud
  triggers: cloud architecture, AWS, Azure, VPC, VNet, IAM, RBAC, EKS, AKS, S3, migration, disaster recovery, multi-cloud, cost optimization, right-sizing
  role: specialist
  scope: implementation
  output-format: code
  related-skills: devops-engineer, sre-engineer, kubernetes-specialist
---

# Cloud Architect

## Core Workflow

1. **Discover** — assess current state, requirements, constraints
2. **Design** — multi-region topology with redundancy, HA patterns
3. **Secure** — zero-trust, IAM least privilege, encryption
4. **Cost** — model costs, tagging, reserved capacity
5. **Migrate** — 6Rs framework (rehost, replatform, refactor,
   repurchase, retire, retain)
6. **Operate** — monitoring, DR testing, continuous optimization

## Quick-Start Examples

### AWS VPC with Public/Private Subnets

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "main-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"

  tags = { Name = "private-subnet" }
}
```

```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications \
  'ResourceType=vpc,Tags=[{Key=Name,Value=main-vpc}]'
```

### Azure Least-Privilege Role Assignment

```hcl
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.example.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
```

```bash
az role assignment create \
  --assignee "<principal-id>" \
  --role "Reader" \
  --scope "/subscriptions/<sub-id>/resourceGroups/<rg>"
```

### Auto-Scaling Group

```hcl
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = 2
  max_size            = 10
  desired_capacity    = 3
  vpc_zone_identifier = [aws_subnet.private.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
}
```

```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name app-asg \
  --launch-template LaunchTemplateId=lt-0123456789abcdef0 \
  --min-size 2 --max-size 10 --desired-capacity 3 \
  --vpc-zone-identifier "subnet-abc123"
```

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| AWS | `references/aws.md` | VPC, IAM, EC2/ECS/EKS, S3, RDS |
| Azure | `references/azure.md` | VNet, RBAC, AKS, App Service, Key Vault |
| Cost | `references/cost.md` | Right-sizing, reservations, FinOps |
| Multi-Cloud | `references/multi-cloud.md` | Cross-cloud networking, federation, DR |

## Constraints

### MUST DO

- Define infrastructure as Terraform alongside CLI examples
- Use least-privilege IAM/RBAC everywhere
- Encrypt data at rest and in transit
- Tag all resources for cost allocation
- Design for high availability (99.9%+ targets)
- Define RTO/RPO for disaster recovery
- Plan for multi-AZ/multi-region

### MUST NOT DO

- Store credentials in code or environment variables
- Leave data unencrypted
- Create single points of failure
- Skip security testing
- Deploy without cost monitoring
- Design without understanding compliance requirements

# AWS Architecture

AWS architecture patterns with both Terraform and CLI.
Each section provides IaC definitions and equivalent
CLI commands for common cloud-architecture tasks.

## VPC & Networking

Multi-AZ VPC with public and private subnets, NAT
gateway, route tables, and security groups.

### Terraform

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "main-vpc" }
}

# Public subnets — one per AZ
resource "aws_subnet" "public" {
  for_each = {
    a = "10.0.1.0/24"
    b = "10.0.2.0/24"
    c = "10.0.3.0/24"
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = "eu-west-1${each.key}"
  map_public_ip_on_launch = true

  tags = { Name = "public-${each.key}" }
}

# Private subnets — one per AZ
resource "aws_subnet" "private" {
  for_each = {
    a = "10.0.10.0/24"
    b = "10.0.11.0/24"
    c = "10.0.12.0/24"
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "eu-west-1${each.key}"

  tags = { Name = "private-${each.key}" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "main-igw" }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["a"].id

  tags = { Name = "main-nat" }
}

# Public route table — routes to internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "public-rt" }
}

# Private route table — routes to NAT gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private-rt" }
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTPS inbound, all outbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web-sg" }
}
```

### CLI

```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications \
  'ResourceType=vpc,Tags=[{Key=Name,Value=main-vpc}]'

# Create subnets (public + private per AZ)
aws ec2 create-subnet --vpc-id vpc-xxx \
  --cidr-block 10.0.1.0/24 \
  --availability-zone eu-west-1a \
  --tag-specifications \
  'ResourceType=subnet,Tags=[{Key=Name,Value=public-a}]'

aws ec2 create-subnet --vpc-id vpc-xxx \
  --cidr-block 10.0.10.0/24 \
  --availability-zone eu-west-1a \
  --tag-specifications \
  'ResourceType=subnet,Tags=[{Key=Name,Value=private-a}]'

# Describe VPCs
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=main-vpc"

# Create internet gateway and attach
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway \
  --internet-gateway-id igw-xxx --vpc-id vpc-xxx

# Create NAT gateway
aws ec2 allocate-address --domain vpc
aws ec2 create-nat-gateway \
  --subnet-id subnet-public-a \
  --allocation-id eipalloc-xxx
```

## IAM

Least-privilege roles, policies, role attachments, and
OIDC provider for EKS workload identity.

### Terraform

```hcl
# Least-privilege IAM policy
resource "aws_iam_policy" "s3_read" {
  name        = "s3-read-only"
  description = "Read-only access to specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::my-bucket",
          "arn:aws:s3:::my-bucket/*"
        ]
      }
    ]
  })
}

# IAM role with trust policy
resource "aws_iam_role" "app" {
  name = "app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_s3" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.s3_read.arn
}

# OIDC provider for EKS workload identity
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}

# IAM role for EKS service account (IRSA)
resource "aws_iam_role" "eks_pod" {
  name = "eks-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:app:app-sa"
          }
        }
      }
    ]
  })
}
```

### CLI

```bash
# Create IAM role
aws iam create-role --role-name app-role \
  --assume-role-policy-document file://trust-policy.json

# Create and attach policy
aws iam create-policy --policy-name s3-read-only \
  --policy-document file://s3-read-policy.json

aws iam attach-role-policy --role-name app-role \
  --policy-arn arn:aws:iam::123456789012:policy/s3-read-only

# List policies attached to a role
aws iam list-attached-role-policies --role-name app-role

# Create OIDC provider for EKS
aws iam create-open-id-connect-provider \
  --url https://oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLE \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list abc123def456
```

## Compute

EC2 instances, EKS clusters with managed node groups,
and ECS services.

### Terraform

```hcl
# EC2 instance with launch template
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "app" }
  }
}

resource "aws_instance" "app" {
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  subnet_id = aws_subnet.private["a"].id

  tags = { Name = "app-instance" }
}

# EKS cluster
resource "aws_eks_cluster" "main" {
  name     = "main-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = [for s in aws_subnet.private : s.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "workers"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = [for s in aws_subnet.private : s.id]
  instance_types  = ["t3.large"]

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }
}

# ECS cluster and service
resource "aws_ecs_cluster" "main" {
  name = "main-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "app" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [for s in aws_subnet.private : s.id]
    security_groups = [aws_security_group.app.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8080
  }
}
```

### CLI

```bash
# Run EC2 instance
aws ec2 run-instances \
  --launch-template LaunchTemplateId=lt-xxx \
  --subnet-id subnet-xxx \
  --count 1

# Create EKS cluster
aws eks create-cluster --name main-cluster \
  --role-arn arn:aws:iam::123456789012:role/eks-cluster \
  --resources-vpc-config \
  subnetIds=subnet-a,subnet-b,subnet-c,\
endpointPublicAccess=false,endpointPrivateAccess=true

# Create managed node group
aws eks create-nodegroup --cluster-name main-cluster \
  --nodegroup-name workers \
  --node-role arn:aws:iam::123456789012:role/eks-node \
  --subnets subnet-a subnet-b subnet-c \
  --instance-types t3.large \
  --scaling-config minSize=2,maxSize=10,desiredSize=3

# Create ECS cluster
aws ecs create-cluster --cluster-name main-cluster \
  --settings name=containerInsights,value=enabled
```

## Storage & Data

S3 with versioning, encryption, and lifecycle; RDS
multi-AZ; and DynamoDB tables.

### Terraform

```hcl
# S3 bucket with security best practices
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data-bucket"

  tags = { Name = "app-data" }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "archive-old-objects"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# RDS multi-AZ
resource "aws_db_instance" "main" {
  identifier     = "app-db"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.r6g.large"

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  multi_az             = true
  db_subnet_group_name = aws_db_subnet_group.main.name

  backup_retention_period = 14
  deletion_protection     = true

  performance_insights_enabled = true
}

# DynamoDB table with on-demand billing
resource "aws_dynamodb_table" "sessions" {
  name         = "sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"
  range_key    = "created_at"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}
```

### CLI

```bash
# Create S3 bucket with encryption
aws s3api create-bucket --bucket my-app-data-bucket \
  --region eu-west-1 \
  --create-bucket-configuration \
  LocationConstraint=eu-west-1

aws s3api put-bucket-encryption --bucket my-app-data-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "arn:aws:kms:eu-west-1:123:key/xxx"
      },
      "BucketKeyEnabled": true
    }]
  }'

aws s3api put-bucket-versioning --bucket my-app-data-bucket \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block --bucket my-app-data-bucket \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,\
BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier app-db \
  --engine postgres --engine-version 16.4 \
  --db-instance-class db.r6g.large \
  --allocated-storage 100 \
  --multi-az --storage-encrypted \
  --backup-retention-period 14 \
  --deletion-protection

# Create DynamoDB table
aws dynamodb create-table \
  --table-name sessions \
  --attribute-definitions \
    AttributeName=session_id,AttributeType=S \
    AttributeName=created_at,AttributeType=N \
  --key-schema \
    AttributeName=session_id,KeyType=HASH \
    AttributeName=created_at,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
```

## High Availability

Multi-AZ patterns with ALB/NLB, auto-scaling groups,
and Route 53 health checks with failover routing.

### Terraform

```hcl
# Application Load Balancer
resource "aws_lb" "app" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in aws_subnet.public : s.id]

  enable_deletion_protection = true

  tags = { Name = "app-alb" }
}

resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  deregistration_delay = 30
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.app.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Auto-scaling group across AZs
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = 2
  max_size            = 10
  desired_capacity    = 3
  vpc_zone_identifier = [for s in aws_subnet.private : s.id]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 75
    }
  }

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

# Route 53 health check and failover
resource "aws_route53_health_check" "primary" {
  fqdn              = "app-primary.example.com"
  port               = 443
  type               = "HTTPS"
  resource_path      = "/health"
  request_interval   = 30
  failure_threshold  = 3

  tags = { Name = "primary-health-check" }
}

resource "aws_route53_record" "failover_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.app_secondary.dns_name
    zone_id                = aws_lb.app_secondary.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary"
}
```

### CLI

```bash
# Create ALB
aws elbv2 create-load-balancer --name app-alb \
  --type application \
  --subnets subnet-public-a subnet-public-b \
  --security-groups sg-xxx

# Create target group
aws elbv2 create-target-group --name app-tg \
  --protocol HTTP --port 8080 --vpc-id vpc-xxx \
  --health-check-path /health

# Create auto-scaling group
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name app-asg \
  --launch-template LaunchTemplateId=lt-xxx \
  --min-size 2 --max-size 10 --desired-capacity 3 \
  --vpc-zone-identifier "subnet-a,subnet-b,subnet-c" \
  --target-group-arns arn:aws:elasticloadbalancing:...

# Set scaling policy
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name app-asg \
  --policy-name cpu-target-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "TargetValue": 60.0
  }'

# Create Route 53 health check
aws route53 create-health-check --caller-reference app-hc \
  --health-check-config '{
    "FullyQualifiedDomainName": "app-primary.example.com",
    "Port": 443,
    "Type": "HTTPS",
    "ResourcePath": "/health",
    "RequestInterval": 30,
    "FailureThreshold": 3
  }'
```

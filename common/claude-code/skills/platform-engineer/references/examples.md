# Platform Engineering Examples

## Crossplane Composition: Self-Service PostgreSQL

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xpostgresqlinstances.platform.example.com
spec:
  group: platform.example.com
  names:
    kind: XPostgreSQLInstance
    plural: xpostgresqlinstances
  claimNames:
    kind: PostgreSQLInstance
    plural: postgresqlinstances
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                parameters:
                  type: object
                  properties:
                    size:
                      type: string
                      enum: ["small", "medium", "large"]
                      description: "Database size (small=db.t3.micro, medium=db.t3.medium, large=db.r5.large)"
                    version:
                      type: string
                      default: "15"
                    backupRetentionDays:
                      type: integer
                      default: 7
                  required:
                    - size
---
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: postgresql-aws
  labels:
    provider: aws
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XPostgreSQLInstance
  resources:
    - name: rds-instance
      base:
        apiVersion: rds.aws.crossplane.io/v1alpha1
        kind: DBInstance
        spec:
          forProvider:
            engine: postgres
            skipFinalSnapshot: false
            publiclyAccessible: false
            storageEncrypted: true
            autoMinorVersionUpgrade: true
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.version
          toFieldPath: spec.forProvider.engineVersion
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.size
          toFieldPath: spec.forProvider.dbInstanceClass
          transforms:
            - type: map
              map:
                small: db.t3.micro
                medium: db.t3.medium
                large: db.r5.large
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.backupRetentionDays
          toFieldPath: spec.forProvider.backupRetentionPeriod
```

Developer claims a database with:

```yaml
apiVersion: platform.example.com/v1alpha1
kind: PostgreSQLInstance
metadata:
  name: my-service-db
  namespace: my-team
spec:
  parameters:
    size: medium
    version: "15"
```

## Golden Path: GitHub Actions Pipeline Template

```yaml
# .github/workflows/golden-path.yml
name: Golden Path CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  id-token: write
  security-events: write

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: make build

      - name: Unit tests
        run: make test

      - name: Lint
        run: make lint

  security-scan:
    runs-on: ubuntu-latest
    needs: build-test
    steps:
      - uses: actions/checkout@v4

      - name: Container scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          severity: CRITICAL,HIGH
          exit-code: 1

      - name: SAST
        uses: github/codeql-action/analyze@v3

  deploy-staging:
    if: github.ref == 'refs/heads/main'
    needs: [build-test, security-scan]
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to staging
        run: make deploy ENV=staging

      - name: Smoke tests
        run: make smoke-test ENV=staging

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Deploy to production
        run: make deploy ENV=production

      - name: Verify SLOs
        run: make verify-slos ENV=production
```

## Platform Contract Template

```yaml
# platform-contract.yaml
apiVersion: platform.example.com/v1
kind: PlatformContract
metadata:
  name: compute-platform
  owner: platform-team
  version: "2.1"

capabilities:
  - name: container-hosting
    slo:
      availability: 99.9%
      provisioning_latency: "< 5 minutes"
      incident_response: "< 15 minutes (P1)"
    support:
      channels: ["#platform-help", "PagerDuty"]
      hours: "24/7 for P1, business hours for P2-P4"
    self_service: true
    documentation: "https://wiki.internal/compute/containers"

  - name: database-provisioning
    slo:
      availability: 99.95%
      provisioning_latency: "< 10 minutes"
    support:
      channels: ["#platform-help"]
      hours: "business hours"
    self_service: true
    documentation: "https://wiki.internal/data/databases"

deprecation_policy:
  notice_period: "90 days minimum"
  migration_support: "Platform team provides migration guide and office hours"
  eol_process: "Capability removed only after all consumers migrated"

feedback:
  survey: "quarterly, max 5 questions"
  office_hours: "bi-weekly Thursday 14:00-15:00"
  feature_requests: "https://github.com/org/platform/issues"
```

## Terraform: Self-Service Namespace Module

```hcl
variable "team_name" {
  type        = string
  description = "Team requesting the namespace"
}

variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "resource_quota" {
  type    = string
  default = "standard"
  validation {
    condition     = contains(["minimal", "standard", "large"], var.resource_quota)
    error_message = "Resource quota must be minimal, standard, or large."
  }
}

locals {
  quotas = {
    minimal  = { cpu = "2", memory = "4Gi", pods = "20" }
    standard = { cpu = "8", memory = "16Gi", pods = "50" }
    large    = { cpu = "32", memory = "64Gi", pods = "200" }
  }
}

resource "kubernetes_namespace" "team" {
  metadata {
    name = "${var.team_name}-${var.environment}"
    labels = {
      "platform.example.com/team"        = var.team_name
      "platform.example.com/environment" = var.environment
      "platform.example.com/managed-by"  = "platform-team"
    }
  }
}

resource "kubernetes_resource_quota" "team" {
  metadata {
    name      = "quota"
    namespace = kubernetes_namespace.team.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = local.quotas[var.resource_quota].cpu
      "requests.memory" = local.quotas[var.resource_quota].memory
      pods              = local.quotas[var.resource_quota].pods
    }
  }
}

resource "kubernetes_network_policy" "default_deny" {
  metadata {
    name      = "default-deny-ingress"
    namespace = kubernetes_namespace.team.metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}
```

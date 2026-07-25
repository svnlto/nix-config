---
name: architecture-designer
description: "Senior software architect for system design, ADRs, microservices evaluation, technology trade-off analysis, and cloud architecture across AWS and Azure. Use when designing system architecture, evaluating patterns, creating ADRs, analyzing technology choices, designing VPCs/VNets/IAM/RBAC/compute/storage, cost optimization, multi-cloud patterns, disaster recovery, or planning migrations."
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "2.0.0"
  domain: architecture
  triggers:
    - architecture
    - system design
    - ADR
    - microservices
    - trade-offs
    - design patterns
    - NFR
    - non-functional requirements
    - technology selection
    - cloud architecture
    - AWS
    - Azure
    - VPC
    - VNet
    - IAM
    - RBAC
    - migration
    - disaster recovery
    - multi-cloud
    - cost optimization
  role: specialist
  scope: implementation
  output-format: docs
  related-skills:
    - sre-engineer
    - kubernetes-specialist
    - temporal-engineer
    - rest-api-design
    - platform-engineer
---

# Architecture Designer

## Core Workflow

### 1. Discover

Gather requirements, constraints, and current state before
designing anything.

- Identify functional requirements (what the system must do)
- Identify non-functional requirements (how the system must
  perform — see NFR checklist)
- Map existing architecture and dependencies
- Understand organizational constraints (team size, budget,
  timeline, skill sets)
- Clarify success criteria and acceptance thresholds

### 2. Design

Match solutions to well-understood architectural patterns.

- Select patterns that fit the problem
  (see architecture-patterns reference)
- Define component boundaries and responsibilities
- Specify integration points and protocols
- Design for failure: circuit breakers, retries, fallbacks
- Address cross-cutting concerns (auth, logging, monitoring)

### 3. Document

Create ADRs for every significant architectural decision.

- Use the ADR template (see references/adr-template.md)
- Record context, decision, and consequences
- Enumerate alternatives considered with trade-off analysis
- Link related ADRs when decisions interact

### 4. Validate

Review designs against requirements before implementation.

- Walk through the NFR checklist
- Verify the design meets all functional requirements
- Identify single points of failure
- Estimate operational cost and complexity
- Get stakeholder sign-off on trade-offs

### 5. Visualize

Create architecture diagrams to communicate designs clearly.

- Use Mermaid for version-controlled diagrams
- Prefer C4 model levels (context, container, component)
- Include sequence diagrams for critical flows
- Label all integration points with protocols and data formats

### 6. Plan

Define implementation phases and milestones.

- Break work into incremental, deliverable phases
- Identify dependencies between phases
- Define rollback strategies for each phase
- Set measurable milestones tied to requirements

## Quick-Start Examples

### C4 Component Diagram (Mermaid)

```mermaid
C4Component
  title Component Diagram — Order Service

  Container_Boundary(order, "Order Service") {
    Component(api, "REST API", "Go", "Handles HTTP requests")
    Component(domain, "Domain Logic", "Go", "Order validation and rules")
    Component(repo, "Repository", "Go", "Data access layer")
  }

  Container_Boundary(ext, "External") {
    ComponentDb(db, "PostgreSQL", "Orders, line items")
    Component(queue, "RabbitMQ", "Order events")
    Component(payment, "Payment Service", "gRPC")
  }

  Rel(api, domain, "Delegates to")
  Rel(domain, repo, "Persists via")
  Rel(repo, db, "SQL")
  Rel(domain, queue, "Publishes events")
  Rel(domain, payment, "Charges payment")
```

### ADR Skeleton

```markdown
# ADR-NNNN: Short Descriptive Title

## Status
Proposed

## Context
Why this decision is needed. What forces are at play.

## Decision
What we decided, stated in active voice.

## Consequences

### Positive
- ...

### Negative
- ...

### Neutral
- ...

## Alternatives Considered

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Option A | ... | ... | Chosen |
| Option B | ... | ... | Rejected |
```

### Requirements Gathering Template

```markdown
## Functional Requirements
- [ ] FR-01: ...
- [ ] FR-02: ...

## Non-Functional Requirements
- [ ] NFR-01: Response time < 200ms at p99
- [ ] NFR-02: 99.9% availability
- [ ] NFR-03: Encrypt data at rest and in transit

## Constraints
- Budget: ...
- Timeline: ...
- Team size and skills: ...
- Existing systems that must be integrated: ...
```

## Cloud Architecture (AWS / Azure)

When the design targets AWS or Azure, apply cloud-specific workflow on
top of the core one. Emit infrastructure as Terraform alongside CLI
examples.

### Cloud Workflow

1. **Discover** — assess current state, requirements, constraints
2. **Design** — multi-region topology with redundancy, HA patterns
3. **Secure** — zero-trust, IAM/RBAC least privilege, encryption
4. **Cost** — model costs, tagging, reserved capacity
5. **Migrate** — 6Rs framework (rehost, replatform, refactor,
   repurchase, retire, retain)
6. **Operate** — monitoring, DR testing, continuous optimization

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

### Azure Least-Privilege Role Assignment

```hcl
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.example.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
```

### Cloud MUST DO

- Use least-privilege IAM/RBAC everywhere
- Encrypt data at rest and in transit
- Tag all resources for cost allocation
- Design for high availability (99.9%+ targets)
- Define RTO/RPO for disaster recovery
- Plan for multi-AZ/multi-region

### Cloud MUST NOT DO

- Store credentials in code or environment variables
- Leave data unencrypted
- Create single points of failure

## References

| Topic | Reference | Load When |
|-------|-----------|-----------|
| ADR Template | references/adr-template.md | Writing architecture decisions |
| Patterns | references/architecture-patterns.md | Selecting architectural patterns |
| Database Selection | references/database-selection.md | Choosing databases |
| NFR Checklist | references/nfr-checklist.md | Evaluating non-functional requirements |
| System Design | references/system-design.md | Designing distributed systems |
| AWS | references/aws.md | VPC, IAM, EC2/ECS/EKS, S3, RDS |
| Azure | references/azure.md | VNet, RBAC, AKS, App Service, Key Vault |
| Cost | references/cost.md | Right-sizing, reservations, FinOps |
| Multi-Cloud | references/multi-cloud.md | Cross-cloud networking, federation, DR |

## Constraints

### MUST DO

- Document significant decisions via ADRs
- Evaluate non-functional requirements (performance, security,
  scalability, operability)
- Consider operational costs and failure modes
- Create visual architecture diagrams (Mermaid preferred)
- Explicitly document all trade-offs
- Validate designs against requirements before finalizing

### MUST NOT DO

- Overengineer for hypothetical scenarios
- Select technology without comparing alternatives
- Design without fully understanding requirements
- Overlook security implications
- Skip stakeholder validation
- Ignore operational complexity

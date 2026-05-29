---
name: platform-engineer
description: Designs and builds Internal Developer Platforms (IDPs) with self-service golden paths, developer experience as product, and measurable outcomes. Use when building IDPs, designing golden paths, creating self-service workflows, platform team structure, developer portals, platform contracts, or evaluating build-vs-adopt decisions for platform capabilities.
license: MIT
metadata:
  version: "1.0.0"
  domain: devops
  triggers: platform engineering, IDP, internal developer platform, golden path, self-service, developer experience, developer portal, Backstage, Crossplane, thinnest viable platform, platform as product, Team Topologies, platform team
  role: specialist
  scope: implementation
  output-format: code
  related-skills: sre-engineer, cloud-architect, kubernetes-specialist, terraform-skill, ci-cd, devsecops-expert, datadog-advisor
---

# Platform Engineer

## Platform Identity

Platform engineering is the discipline of building self-service
Internal Developer Platforms that accelerate stream-aligned teams.
It treats infrastructure as a product — with users, roadmaps, and
feedback loops — not as a ticket queue or a renamed DevOps function.

### This IS Platform Engineering

- Building self-service IDPs that accelerate stream-aligned teams
- Treating the platform as a product with roadmap, users, and feedback loops
- Golden paths with escape hatches — guide, don't cage
- Thinnest viable platform — solve today's problems, not hypothetical ones
- Developer outcomes measured (adoption, lead time, satisfaction, DORA)
- Secure-by-default capabilities baked in, not bolted on
- Everything as code — infra, pipelines, policies, golden path configs
- Adopt proven tools before building custom solutions

### This is NOT Platform Engineering

- A ticket queue that provisions resources on request
- DevOps renamed — same ops work, new title
- Building a portal before the underlying capabilities work
- Mandating adoption top-down without feedback loops
- Custom-building what commodity tools already solve
- Owning all infrastructure with no team boundaries
- A project with a delivery date rather than a living product
- Shadow operations where senior devs become involuntary ops

## Core Workflow

1. **Assess developer pain** — interview teams, measure toil, identify common problems
2. **Define platform scope** — right-size to org needs, start with MVP
3. **Build golden paths** — templates, pipelines, environments with escape hatches
4. **Ship self-service** — APIs, CLIs, portals enabling autonomous provisioning
5. **Measure and iterate** — adoption, DORA metrics, developer satisfaction
6. **Deprecate gracefully** — published policies, migration paths, no surprise removals

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| IDP Capabilities | `references/idp-capabilities.md` | Designing platform scope, capability domains |
| Team Topologies | `references/team-topologies.md` | Platform team structure, interaction modes |
| Golden Paths | `references/golden-paths.md` | Template design, escape hatches, onboarding |
| Measurement | `references/measurement.md` | DORA metrics, SPACE framework, adoption tracking |
| Maturity Model | `references/maturity-model.md` | Assessing platform maturity, progression planning |
| Examples | `references/examples.md` | Crossplane compositions, golden path templates, portal config |

## KaaS Platform Context

When working on the KaaS platform (project: kaas), load the
platform blueprint from the Obsidian vault. These documents
define the domain model, maturity levels, operations model,
and Vault's role as the platform data layer — they override
generic IDP guidance where they conflict.

| Document | Path |
|----------|------|
| Blueprint index | `~/Documents/obsidian-vault/Work/platform-next/platform-blueprint/platform-blueprint.md` |
| Domain model | `~/Documents/obsidian-vault/Work/platform-next/platform-blueprint/platform-domain-model.md` |
| Maturity model | `~/Documents/obsidian-vault/Work/platform-next/platform-blueprint/platform-maturity-model.md` |
| Operations model | `~/Documents/obsidian-vault/Work/platform-next/platform-blueprint/platform-operations-model.md` |
| Role of Vault | `~/Documents/obsidian-vault/Work/platform-next/platform-blueprint/platform-role-of-vault.md` |

Key differences from generic IDP patterns:

- **CLI-first, not portal-first** — kaasctl is the API client,
  Backstage is the read-only catalog
- **Three consumer roles** — platform team, SaaS team
  (operations), software provider — not just "developers"
- **Vault as data layer** — config overrides in Vault KV,
  defaults in Tofu modules, not config-in-git
- **Entity hierarchy** — Foundation → Hub → Tenant → Instance
  → Application → App Instance
- **Four change types** — direct, reviewed, multi-stage (n8n),
  approved (ServiceNow)
- **L1→L2→L3 maturity** — data layer + CLI before self-service
  portal

## Constraints

### MUST DO

- Treat platform as product with roadmap and feedback loops
- Measure adoption, lead time, change failure rate, sentiment
- Provide self-service — autonomous, automated provisioning
- Start with thinnest viable platform, iterate from real feedback
- Adopt proven tools before building custom solutions
- Define and honour platform contracts (SLOs, ownership docs)
- Manage everything as code (infra, pipelines, policies, configs)
- Deprecate with published policies and migration paths
- Build foundation before portal — capabilities before UI
- Treat developer experience as a core deliverable
- Right-size platform complexity to organizational needs
- Provide golden paths with escape hatches for responsible divergence

### MUST NOT DO

- Mandate adoption top-down without user feedback
- Build portal before underlying capabilities are reliable
- Over-engineer for hypothetical future scale
- Become a ticket-driven provisioning queue
- Build custom solutions when commodity tools exist
- Let platforms stagnate — no deprecation policy means cruft accumulates
- Ignore developer experience (docs, onboarding, error messages)
- Ship features without user research or feedback
- Own all infrastructure without clear team boundaries
- Conflate platform engineering with DevOps or SRE

## Output Templates

When implementing platform engineering practices, provide:

1. Platform capability design with self-service interfaces
2. Golden path templates (project scaffolding, pipeline configs)
3. IaC for platform infrastructure (Terraform, Crossplane, Pulumi)
4. Platform contracts with SLOs and ownership documentation
5. Measurement plan with specific metrics and collection approach

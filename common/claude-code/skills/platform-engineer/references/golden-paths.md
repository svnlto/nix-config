# Golden Paths

Golden paths are opinionated, supported workflows that guide
developers toward production with security, compliance, and
best practices built in.

## Principles

1. **Guide, don't cage** — always provide escape hatches
2. **Opinionated defaults** — sensible choices pre-made, overridable
3. **Integrated capabilities** — security, observability, deployment wired in
4. **Self-service** — teams can adopt without filing tickets
5. **Maintained** — golden paths are products, not one-off scripts

## Anatomy of a Golden Path

A complete golden path includes:

```text
golden-path/
  template/              # Project scaffolding (cookiecutter, yeoman, etc.)
  pipeline/              # CI/CD config (GitHub Actions, ADO, Tekton)
  infra/                 # IaC for required resources (Terraform, Crossplane)
  observability/         # Dashboards, alerts, SLO definitions
  docs/                  # Onboarding guide, architecture decisions
  tests/                 # Smoke tests validating the path works end-to-end
```

## Categories

### Project Templates

Scaffold new services with everything wired in:

- Language/framework boilerplate
- CI/CD pipeline configuration
- Dockerfile with security scanning
- Observability instrumentation
- README with onboarding steps
- Pre-configured dev environment (devcontainer, nix flake)

### Environment Provisioning

Self-service creation of:

- Development/staging/production namespaces
- Database instances with backup policies
- Message queues with monitoring
- DNS entries and TLS certificates

### Deployment Workflows

Standardized paths from commit to production:

- Build, test, scan, deploy pipeline
- Progressive delivery (canary, blue-green)
- Automated rollback on SLO violation
- Environment promotion gates

## Escape Hatches

Every golden path must document:

1. **What's customizable** — which defaults can be overridden and how
2. **What's mandatory** — security/compliance requirements that can't be skipped
3. **How to diverge** — process for teams that need something the path doesn't cover
4. **Support boundaries** — what the platform team supports vs. what's on you

## Anti-Patterns

- **Golden cage**: no escape hatch, teams work around it instead of with it
- **Golden abandonware**: template created once, never updated
- **Golden sprawl**: too many paths, none well-maintained
- **Golden mandate**: forced adoption without feedback loops

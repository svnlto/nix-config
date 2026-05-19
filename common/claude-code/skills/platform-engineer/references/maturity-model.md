# Platform Maturity Model

Five levels of platform maturity. Most organizations should
target level 3 before investing in levels 4-5.

## Level 1: Provisional

- Ad-hoc scripts and runbooks shared informally
- Provisioning via tickets and manual processes
- No standard templates or golden paths
- Knowledge lives in people's heads

**Upgrade path**: document the top 3 most-requested workflows,
automate the single highest-toil provisioning task.

## Level 2: Operational

- On-demand provisioning of core capabilities (compute, storage, databases)
- Basic IaC for infrastructure (Terraform modules, Helm charts)
- Some documentation exists but is inconsistent
- Platform team exists but operates reactively

**Upgrade path**: introduce golden path templates for the most
common service type, add self-service for environment provisioning.

## Level 3: Scalable

- Self-service provisioning via APIs/CLIs for common capabilities
- Golden path templates for primary service types
- CI/CD pipelines standardized across teams
- Observability integrated into golden paths
- Platform contracts defined (SLOs, ownership)
- Measurement in place (adoption, lead time, satisfaction)

**Upgrade path**: add developer portal, expand golden paths to
cover more service types, introduce progressive delivery.

## Level 4: Optimizing

- Developer portal with service catalog, docs, and templates
- Environment templates for complete scenarios (web app, data pipeline, ML)
- Automatic instrumentation and standard dashboards
- Platform capabilities composable and optional
- Deprecation policies published and followed
- Regular feedback loops driving roadmap

**Upgrade path**: invest in developer experience polish, add
cost visibility, explore platform-managed preview environments.

## Level 5: Strategic

- Platform is a competitive advantage for engineering velocity
- Full self-service from idea to production
- Platform team has product management discipline
- Cost, security, and compliance transparent and automated
- Platform capabilities extend to external partners/customers
- Continuous measurement drives continuous improvement

## Assessment Questions

For each capability domain, ask:

1. How do teams currently get this capability? (ticket / self-service / DIY)
2. How long does it take? (minutes / hours / days / weeks)
3. How consistent is it across teams? (standard / varies / wild west)
4. Who supports it when it breaks? (platform / team / nobody)
5. Is it measured? (adoption / satisfaction / neither)

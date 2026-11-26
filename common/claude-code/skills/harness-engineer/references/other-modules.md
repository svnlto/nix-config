# Harness Modules Beyond CI/CD and IDP

## Naming map

Doc roots are under `https://developer.harness.io`.

| Name now | Earlier name | Doc root |
| --- | --- | --- |
| Security Testing Orchestration (STO) | unchanged | `/security-testing-orchestration/` |
| Feature Management & Experimentation (FME) | Feature Flags (FF), now "Feature Flags Classic" | `/feature-management-experimentation/` |
| Resilience Testing (Chaos, Load, DR) | Chaos Engineering (CE) | `/resilience-testing/` |
| Cloud & AI Cost Management (CACM) | Cloud Cost Management (CCM) | `/cloud-cost-management/` |
| AI DLC Insights (AIDI) | Software Engineering Insights (SEI); SEI 1.0 = "Engineering Insights Classic" | `/ai-dlc-insights/` |
| Code Repository (Harness Code) | unchanged | `/code-repository/2.0/` |
| Artifact Registry (AR) | unchanged | `/artifact-registry/` |
| Database DevOps | unchanged | `/database-devops/` |
| Supply Chain Security (SCS) | SSCA; URLs keep `software-supply-chain-assurance` | `/software-supply-chain-assurance/` |

## Security Testing Orchestration (STO)

Runs scanners in pipelines, deduplicates findings, and gates releases.

- Objects: `SecurityTests` stage, scan steps, targets, variants, baselines,
  exemptions.
- Modes: **orchestration** (scan and ingest in one step), **ingestion** (a
  Run step writes results to a shared folder, a scan step ingests them),
  **extraction** (pull from SaaS scanners such as SonarQube).
- Every scan step has `fail_on_severity`; exemptions keep known issues from
  failing it. A baseline (`main`, `latest`) separates new from common issues.

Doc: <https://developer.harness.io/security-testing-orchestration/new-to-sto/key-concepts/sto-workflows-overview>

## Feature Management & Experimentation (FME)

Split-based flags and experimentation; replaces Harness Feature Flags.

- Objects: projects, environments, flags, targeting rules, segments, traffic
  types, impressions, events, metrics.
- Flags live in a project; targeting rules and segments live per environment.
  SDKs evaluate locally in memory.
- Enable with **Start FME Free Plan**. FF is deprecated: free plans migrate by
  31 Dec 2026, paid plans by 30 Apr 2027.

Doc: <https://developer.harness.io/feature-flags-classic/new-to-feature-flags-classic/migrate-to-fme>

## Resilience Testing (Chaos Engineering)

Chaos Testing is one pillar of Resilience Testing, next to Load Testing and
Disaster Recovery Testing.

- Objects: experiments, faults, ChaosHubs (Enterprise ChaosHub has 200+
  faults), resilience probes, chaos infrastructure, services.
- Agentless (Delegate runs experiments on K8s, cloud, VMware) or agent-based
  (Linux, Windows hosts). Outbound 443 only.
- Build in Chaos Studio (YAML output); run from pipelines via the Chaos step.

Doc: <https://developer.harness.io/resilience-testing/new-to-resilience-testing/overview>

## Cloud & AI Cost Management (CACM)

One cost view across AWS, Azure, GCP, Kubernetes, AI providers, and external
spend.

- Objects: cloud, Kubernetes, and AI-provider connectors; Cost Explorer views
  (successor UI to Perspectives); Cost Categories; Budgets; Anomalies.
- Optimize: Recommendations, AutoStopping, Commitment Orchestration (AWS RIs
  and Savings Plans), Cluster Orchestrator (EKS).
- Govern: Asset Governance rules (policy as code), budget alerts.

Doc: <https://developer.harness.io/cloud-cost-management/new-to-cacm/navigating-cacm>

## AI DLC Insights (SEI successor)

DORA, productivity, and business-alignment metrics plus AI coding agent
adoption, spend, and impact.

- Objects: integrations, developers (CSV import), Org Trees, teams, profiles,
  dashboards. Org Tree leaves become teams; profiles pick the insights.
- No automated migration from Engineering Insights Classic; they run side by
  side until cutover.

Doc: <https://developer.harness.io/ai-dlc-insights/new-to-ai-dlc-insights/key-concepts>

## Code Repository (Harness Code)

Hosted Git with pull requests, rules, and native pipeline triggers.

- Objects: repositories (always in a project), branches, pull requests,
  rules, triggers on push events.
- Repository permissions: View, Review, Edit, Create, Delete, Push, Report
  Commit Check. Built-in role **Code Admin**.

Doc: <https://developer.harness.io/code-repository/2.0/new-to-harness-code/overview>

## Artifact Registry (AR)

Universal store: Docker, Helm (OCI, HTTP), Maven, npm, PyPI, NuGet, Go,
Debian, generic.

- Objects: registries (one format each), upstream proxies, packages,
  versions, lifecycle (cleanup, retention) rules, webhooks.
- Images scan via STO and SCS; failures are quarantined. OPA governs publish,
  promote, and delete.
- Registries hold no environments; tag with custom metadata instead.

Doc: <https://developer.harness.io/artifact-registry/new-to-artifact-registry/overview>

## Database DevOps

Pipeline orchestration on Liquibase or Flyway; not a data migration tool.

- Objects: DB Schema (Git repo plus changelog path), DB Instance (JDBC
  connection), steps `DBSchemaApply` and `DBSchemaRollback`.
- Steps run in a Custom stage's containerized step group; the Delegate starts
  `plugins/drone-liquibase` or `plugins/drone-flyway` pods.

Doc: <https://developer.harness.io/database-devops/new-to-database-devops/onboarding-guide>

## Supply Chain Security (SCS)

SBOMs, SLSA provenance, signing, open-source policy, repo posture.

- Objects: SBOMs (SPDX, CycloneDX), SLSA provenance, attestations (`.att`
  beside the image), keyless or key-based signing, allow/deny-list policies,
  remediation tracker.
- SBOM attestation covers container images only. Posture checks map to CIS
  benchmarks and the OWASP Top 10 CI/CD risks.

Doc: <https://developer.harness.io/software-supply-chain-assurance/new-to-scs/key-concepts>

## Not covered here

`/llms.txt` also lists AI SAST (`/sast-and-sca`), AI SCA (`/ai-sca`), API
Posture, AI Posture (`/ai-security`), Hardened Images, Incidents, AI Test
Automation, Release Orchestration, and AI Evals. Docs nav labels differ from
product names ("Feature Flags" = FME, "Engineering Efficiency" = AIDI, "AI &
Cloud Costs" = CACM). Open `llms.txt` before answering about any of them.

Doc: <https://developer.harness.io/llms.txt>

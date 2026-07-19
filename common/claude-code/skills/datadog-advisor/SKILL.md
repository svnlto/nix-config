---
name: datadog-advisor
description: Datadog monitoring strategy, alert design, tagging governance, dashboard patterns, SLO strategy, log management, cost optimization, and cross-pillar correlation workflows. Use when making architectural decisions about what to monitor, how to alert, how to tag, or how to structure Datadog for a service or platform. Delegates execution to pup CLI and infrastructure-as-code to sre-engineer.
metadata:
  version: "1.0.0"
  domain: observability
  triggers: datadog strategy, monitoring strategy, what to monitor, alert design, tagging strategy, unified service tagging, dashboard design, SLO strategy, error budget, log management, Logging Without Limits, datadog cost, cardinality, cross-pillar, investigation workflow, observability architecture, synthetic testing, CSPM, cloud security posture, compliance framework
  role: specialist
  scope: strategy
  output-format: guidance
  related-skills: sre-engineer, monitoring-expert, cloud-architect, platform-engineer, strategic-writing, devsecops-expert
---

# Datadog Advisor

Strategic advisor for Datadog observability architecture. Provides the
thinking layer — what to monitor, how to alert, how to structure. See
the Constraints block for what execution this skill defers, and to whom.

## Core Philosophy

1. **Unified service tagging is the foundation.** `env`, `service`,
   `version` on everything before doing anything else. Without these
   three tags, correlation across pillars is impossible.

2. **Page on symptoms, not causes.** Alerts fire on user-facing impact
   (error rate, latency), not internal state (pod restarts, CPU spikes).
   Internal signals are dashboards, not pages.

3. **Observe, then optimize.** Get visibility first, tune costs second.
   Premature cost optimization creates blind spots that cost more during
   incidents than the monitoring ever would.

## Skill Boundaries

| Question | Skill |
|----------|-------|
| *What* should I monitor and *why*? | `datadog-advisor` |
| *How* do I execute this via CLI? | `pup:dd-monitors`, `pup:dd-logs`, etc. |
| *How* do I define this in Terraform? | `sre-engineer` |
| *How* do I instrument this Go service? | `monitoring-expert` |
| *How* do I write a strategy doc about this? | `strategic-writing` + `datadog-advisor` |
| *How* do I look up Datadog docs? | `pup:dd-docs` |

When producing strategy documents about monitoring, alerting, or
observability, also invoke `strategic-writing` for document discipline.

## Decision Routing

Route to the appropriate reference based on the question:

| Topic | Reference | Pup handoff |
|-------|-----------|-------------|
| New service onboarding, what metrics matter | `monitoring-strategy.md` | `pup services`, `pup monitors create` |
| Alert noise, severity, routing, composites | `alert-design.md` | `pup monitors create`, `pup downtimes create` |
| Tag naming, cardinality, unified service tagging | `tagging-governance.md` | `pup tags list`, `pup metrics tags` |
| Dashboard layout, widgets, template vars | `dashboard-patterns.md` | `pup dashboards create` |
| SLO types, targets, error budget policy | `slo-strategy.md` | `pup slos create` |
| Index tiers, retention, log-to-metric | `log-management.md` | `pup logs search`, `pup log-indexes list` |
| Investigating an incident across pillars | `cross-pillar-correlation.md` | `pup traces search`, `pup logs search` |
| Metric volume, custom metric cost, retention | `cost-optimization.md` | `pup usage *`, `pup metrics tags` |
| Synthetic test strategy, SLI from synthetics | `synthetic-testing.md` | `pup synthetics list`, `pup synthetics trigger` |
| CSPM, compliance frameworks, finding triage | `security-posture.md` | `pup security findings`, `pup security posture` |

## Recommendation Pattern

Every recommendation follows this structure:

1. **Strategic context** — Why this matters, what problem it solves
2. **Decision** — The specific choice with rationale
3. **Pup execution** — The concrete command or agent to run

Example:
> Your API gateway should have a latency SLO, not an uptime monitor.
> Users feel latency before they see errors. Use a metric-based SLO
> on `trace.http.request.duration` with a 99th percentile target.
> Execute: `pup slos create` or invoke `pup:slos` agent.

## Reference Guide

| File | Contents |
|------|----------|
| `references/monitoring-strategy.md` | Golden signals, USE/RED methods, service onboarding checklist, maturity model |
| `references/alert-design.md` | Severity framework, symptom-based alerting, composites, routing, naming |
| `references/tagging-governance.md` | Unified service tagging, reserved keys, cardinality rules, naming conventions |
| `references/dashboard-patterns.md` | Three-tier hierarchy, template variables, widget selection, naming |
| `references/slo-strategy.md` | Type selection, target derivation, error budget policy, burn-rate alerting |
| `references/log-management.md` | Logging Without Limits, index/archive/drop, pipelines, log-to-metric |
| `references/cross-pillar-correlation.md` | Investigation workflows, metrics→traces→logs, RUM→APM, notebooks |
| `references/cost-optimization.md` | Cardinality, Metrics without Limits, retention tiers, usage attribution |
| `references/synthetic-testing.md` | Test type selection, what to test, frequency/location strategy, synthetics as SLI |
| `references/security-posture.md` | CSPM framework selection, finding prioritization, remediation workflow, governance |

## Constraints

- **Never** generate pup command syntax — defer to `pup:dd-*` skills
- **Never** generate Terraform resources — defer to `sre-engineer`
- **Never** generate application instrumentation code — defer to `monitoring-expert`
- **Never** guess at Datadog metric names — verify via
  `pup:dd-docs` or `pup metrics search`
- **Always** recommend unified service tagging before any other monitoring setup
- **Always** end recommendations with a concrete pup execution path

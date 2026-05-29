# Dashboard Patterns

## Three-Tier Hierarchy

Every team should have three levels of dashboards:

### Tier 1 — Overview

One dashboard per team showing golden signals across all services.
This is the "is anything broken?" view.

- **Audience:** On-call engineer, team lead
- **Layout:** Ordered (vertical flow)
- **Template variables:** `$env` (required), `$team` (if multi-team)
- **Refresh:** 5 min auto-refresh
- **Content:**
  - Group widget per service: request rate, error rate, p95 latency
  - SLO summary widget for all team SLOs
  - Recent deploys overlay (event timeline)
  - Change widget showing week-over-week trends

### Tier 2 — Service

One dashboard per service showing detailed operational metrics.
This is the "what's wrong with this service?" view.

- **Audience:** Service owner, on-call investigating an alert
- **Layout:** Ordered (vertical flow)
- **Template variables:** `$env`, `$version`, `$resource` (endpoint)
- **Refresh:** 1 min during incidents
- **Content:**
  - RED metrics: rate, errors, duration (p50, p95, p99)
  - Top errors by type (top list widget)
  - Dependency map (service map widget)
  - Resource utilization: CPU, memory, pods (if K8s)
  - Log error stream (log stream widget, filtered to ERROR+)
  - Recent traces with errors (trace list)

### Tier 3 — Debug

Focused dashboards for deep investigation of specific subsystems.
Created on-demand, often from notebook investigations.

- **Audience:** Developer debugging a specific issue
- **Layout:** Free (arrange widgets around the investigation)
- **Template variables:** `$env`, `$host`, `$container_id` as needed
- **Content:** Highly variable — database query stats, cache hit rates,
  queue depths, JVM/GC metrics, custom business metrics

## Template Variable Design

Standard template variables every dashboard should have:

| Variable | Source | Default | Purpose |
|----------|--------|---------|---------|
| `$env` | `tag:env` | `production` | Environment filter — every dashboard needs this |
| `$service` | `tag:service` | `*` | Service filter for overview dashboards |
| `$version` | `tag:version` | `*` | Deploy comparison |
| `$team` | `tag:team` | Team's value | Multi-team overviews |

**Tips:**

- Set sensible defaults (production, not staging)
- Use `*` as default for filters where you usually want "all"
- Link template variables across widgets so one dropdown filters everything
- Add `$timeframe` override only if the default 4h view is wrong for the use case

## Widget Selection Guide

| Question you're answering | Widget | Why |
|---------------------------|--------|-----|
| What's the current value? | **Query Value** | Single number, big and readable |
| How does it change over time? | **Timeseries** | Line chart, the workhorse |
| What changed since last period? | **Change** | Shows delta with color coding |
| What are the top N items? | **Top List** | Ranked list with values |
| What's the distribution? | **Distribution** | Histogram of values |
| What's the breakdown by group? | **Treemap** | Proportional area by tag value |
| Is the SLO healthy? | **SLO Summary** | Budget remaining, status |
| What happened recently? | **Event Timeline** | Deploys, alerts, incidents |
| What do the logs say? | **Log Stream** | Filtered live log tail |
| How do services connect? | **Service Map** | Dependency visualization |
| What's the geographic spread? | **Geomap** | Regional performance |
| Am I on track for the period? | **SLO List** | Multiple SLOs at a glance |

**Avoid:**

- Timeseries with more than 5 lines (use top list or split by group)
- Query value without context (add a timeseries below it)
- Free text widgets for documentation (use notebook links instead)

## Layout Principles

**Ordered layout** (default for Tier 1 and 2):

- Widgets flow top to bottom, left to right
- Group related widgets with group headers
- Most important signals at the top
- Investigation detail flows downward

**Free layout** (Tier 3 debug):

- Position widgets around the investigation narrative
- Place correlated metrics side by side for visual comparison
- Use smaller widgets to pack more data density

**General rules:**

- One idea per row — don't put error rate next to disk usage
- Wide timeseries (full width or half) for primary signals
- Narrow query values in a row for status-at-a-glance
- Group widgets with named sections: "Golden Signals," "Dependencies," "Resources"

## Dashboard Naming Convention

```text
[Team] Tier - Service/Topic
```

Examples:

- `[Platform] Overview - All Services`
- `[Payments] Service - Payment API`
- `[Payments] Service - Checkout Flow`
- `[Platform] Debug - PostgreSQL Performance`
- `[SRE] Overview - SLO Status`

## Dashboard as Code

Prefer defining dashboards in Terraform (via sre-engineer skill) for
production dashboards that multiple people use. Use the UI for
exploratory/debug dashboards that may be temporary.

Terraform-managed dashboards should have:

- `managed-by:terraform` tag
- Dashboard JSON stored in version control
- Template variables parameterized

## Pup Execution

| Task | Command |
|------|---------|
| List dashboards | `pup dashboards list` |
| Create a dashboard | `pup dashboards create` or invoke `pup:dashboards` |
| Export dashboard JSON | `pup dashboards get --id <id>` |
| Search dashboards | `pup dashboards list --query "team:platform"` |

# Tagging Governance

## Unified Service Tagging

The three non-negotiable tags that must exist on every piece of
telemetry before any other monitoring setup:

| Tag | Purpose | Example |
|-----|---------|---------|
| `env` | Separates environments | `env:production`, `env:staging` |
| `service` | Identifies the service | `service:payment-api` |
| `version` | Tracks deployed version | `version:1.4.2` |

These three tags are the correlation key across metrics, traces, logs,
and RUM. Without them, you cannot click from a metric to a trace to a
log. They are configured via environment variables:

```text
DD_ENV=production
DD_SERVICE=payment-api
DD_VERSION=1.4.2
```

Set these in your deployment manifests (Kubernetes labels, ECS task
definitions, Lambda environment), not in application code. The Datadog
Agent and tracing libraries read them automatically.

## Reserved Tag Keys

Datadog treats these keys specially — they enable automatic correlation
and filtering across the platform:

| Key | Effect | Source |
|-----|--------|--------|
| `host` | Groups all telemetry by host | Auto-detected by Agent |
| `device` | Disk/network device breakdown | Auto-detected by Agent |
| `source` | Log source identification | Log pipeline config |
| `service` | APM, logs, and metrics correlation | `DD_SERVICE` env var |
| `env` | Environment filtering everywhere | `DD_ENV` env var |
| `version` | Deployment tracking, error tracking | `DD_VERSION` env var |
| `team` | Ownership attribution | Custom (set in Service Catalog) |

Never use reserved keys for custom purposes. `service:database` means
a service named "database" to Datadog — not a tag category.

## Cardinality Rules

High-cardinality tags multiply your custom metric count. Each unique
tag combination creates a separate time series.

**Never use as tag values:**

- User IDs, session IDs, request IDs
- Timestamps, dates
- UUIDs, hashes
- IP addresses (use CIDR ranges or ASN if needed)
- Full URLs (use URL path templates: `/api/users/{id}`)
- Unbounded enums (error messages — use error categories)

**Acceptable high-cardinality contexts:**

- APM span tags (indexed spans, not custom metrics)
- Log attributes (free text, not aggregated)
- RUM session attributes

**Cardinality check:** Before adding a tag, ask: "How many unique
values will this have?" If the answer is "unbounded" or "more than
1,000," it should not be on a custom metric.

## Naming Conventions

| Rule | Example | Why |
|------|---------|-----|
| Lowercase only | `env:production` not `Env:Production` | Datadog normalizes to lowercase anyway; be explicit |
| Colon separator | `team:platform` not `team=platform` | Datadog's `key:value` format |
| Hyphens for multi-word | `cost-center:engineering` | Underscores also work, pick one and be consistent |
| No spaces | `region:us-east-1` not `region:us east 1` | Spaces break tag queries |
| Max 200 characters | Keep tag values short | Hard platform limit |
| Singular nouns for keys | `team:` not `teams:` | Consistency |

## Standard Organization Tags

Beyond unified service tagging, standardize these across the org:

| Tag | Purpose | Examples |
|-----|---------|---------|
| `team` | Ownership and routing | `team:platform`, `team:payments` |
| `cost-center` | Cost attribution | `cost-center:engineering` |
| `project` | Initiative tracking | `project:migration-v2` |
| `tier` | Service criticality | `tier:1`, `tier:2`, `tier:3` |
| `managed-by` | IaC source | `managed-by:terraform`, `managed-by:helm` |

Define these in your Service Catalog definitions. They propagate to
all telemetry associated with the service.

## Tag Inheritance

Tags flow downward through the stack:

```text
Host tags (Agent config, cloud provider)
  └─ Container tags (Docker labels, K8s labels)
       └─ Integration tags (auto-discovered)
            └─ Custom metric tags (application code)
                 └─ Trace span tags (tracing library)
                      └─ Log tags (log pipeline enrichment)
```

Host-level tags automatically appear on all metrics, logs, and traces
from that host. This means:

- Set `env` and `team` at the infrastructure level
- Set `service` and `version` at the application level
- Avoid duplicating tags that are already inherited

## Tag Audit Process

Periodically review tags for drift:

1. **Check for untagged resources** — `pup tags list` on hosts, look
   for missing `env`, `service`, or `team` tags
2. **Check cardinality** — `pup metrics tags list --metric <name>` to
   see tag keys and value counts on high-volume metrics
3. **Check naming consistency** — look for variants like `env:prod` vs
   `env:production` or `team:Platform` vs `team:platform`
4. **Check for stale tags** — tags referencing decommissioned services
   or deprecated cost centers

## Pup Execution

| Task | Command |
|------|---------|
| List host tags | `pup tags list` |
| Check metric tag keys | `pup metrics tags list --metric <name>` |
| View tag cardinality | `pup metrics tags list` or invoke `pup:metrics` |
| Search by tag | `pup infrastructure list --filter "tag:team:platform"` |

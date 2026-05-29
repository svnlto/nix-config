# Cross-Pillar Correlation

## The Correlation Chain

Datadog's value is not in any single pillar — it's in the connections
between them. The investigation workflow always follows the same chain:

```text
Alert → Metric → Trace → Log → Root Cause
  ↑                                  ↓
  └──────── Fix & Verify ←──────────┘
```

Unified service tagging (`env`, `service`, `version`) is the glue.
Without it, each pillar is an isolated silo.

## Investigation Workflow: Alert to Root Cause

### Step 1: Triage the alert

- Read the monitor message: what symptom, what service, what severity?
- Check the monitor's metric graph: is this a spike, a trend, or a step change?
- Check: was there a recent deploy? (`version` tag on the metric)

**Pup:** `pup monitors get --id <monitor_id>`

### Step 2: Assess impact scope

- Open the Service Map: is this service the origin, or is a dependency failing?
- Check SLO status: how much error budget has been consumed?
- Check other services that depend on this one: are they degraded too?

**Pup:** `pup services list`, `pup slos list`

### Step 3: Find representative traces

- Filter APM traces by `service:<name>` and `status:error` (or high latency)
- Look at the flamegraph: where is time being spent?
- Check span tags for error messages, HTTP status codes, database queries

**Pup:** `pup traces search --query "service:<name> status:error"`

### Step 4: Correlate with logs

- From the trace, click through to correlated logs (trace_id linkage)
- Or search logs directly: `service:<name> status:error` in the same time window
- Look for stack traces, error messages, connection failures

**Pup:** `pup logs search --query "service:<name> status:error" --from 15m`

### Step 5: Check infrastructure

- Is the host/pod/container healthy? CPU, memory, disk, network
- Are there Kubernetes events? (OOMKilled, Evicted, FailedScheduling)
- Is there resource contention from noisy neighbors?

**Pup:** `pup infrastructure list --filter "service:<name>"`, `pup metrics query`

### Step 6: Verify the fix

- Deploy the fix, watch the metric graph recover
- Confirm SLO burn rate returns to normal
- Verify traces show normal latency and success rate

## RUM to APM to Infrastructure

For user-facing issues reported through Real User Monitoring:

```text
RUM Session → Frontend Error/Slow Load
  → APM Trace (via trace_id in RUM event)
    → Backend Service Span (where time was spent)
      → Database Query / External Call (root cause)
        → Infrastructure Metrics (resource constraint)
```

### When to use this flow

- Users report slowness but backend metrics look normal
- Error tracking shows client-side errors with server correlation
- Performance regression after a frontend deploy

**Pup:** `pup rum search`, `pup traces search --query "trace_id:<id>"`

## Service Catalog as Entry Point

The Service Catalog should be the first place anyone looks when
investigating a service:

**What it should contain:**

- Service owner (team and individual)
- On-call rotation link
- Runbook links for common issues
- SLO links
- Dashboard links (Tier 1 and Tier 2)
- Repository link
- Dependencies (auto-discovered via APM)

When an alert fires, the Service Catalog answers: "Who owns this,
where do I look, and what do I do?"

**Pup:** `pup service-catalog list`, `pup service-catalog get --service <name>`

## Notebook Investigation Template

For incidents that need structured investigation, create a Datadog
Notebook with this template:

### Header

- **Incident:** Title and severity
- **Service:** Name with Service Catalog link
- **Timeline:** When detected, when acknowledged, when resolved
- **On-call:** Who responded

### Impact

- Metric graph of the symptom (error rate, latency)
- SLO budget impact
- User-facing description

### Investigation

- Timeline of key findings (cells with graphs at specific time ranges)
- Trace examples showing the failure
- Log excerpts with error details
- Infrastructure metrics during the incident

### Root Cause

- What broke and why
- Contributing factors

### Action Items

- Immediate fixes applied
- Follow-up work needed
- Monitoring improvements

Save investigation notebooks — they become the institutional memory
of how your team debugs issues.

**Pup:** `pup notebooks create` or invoke `pup:notebooks`

## Correlation Enablers Checklist

Without these in place, cross-pillar correlation won't work:

- [ ] **Unified service tagging** — `env`, `service`, `version` on all telemetry
- [ ] **Trace-log correlation** — `dd.trace_id` and `dd.span_id` injected into logs
- [ ] **Log pipeline enrichment** — service and env tags extracted and remapped
- [ ] **Service Catalog populated** — ownership, runbooks, dashboards linked
- [ ] **APM enabled** — automatic instrumentation on all
  services in the request path
- [ ] **RUM configured** — if there's a frontend, connect
  it to APM via trace propagation

## Pup Execution Summary

| Task | Command |
|------|---------|
| Search traces | `pup traces search` or invoke `pup:traces` |
| Search logs | `pup logs search` or invoke `pup:logs` |
| Query metrics | `pup metrics query` or invoke `pup:metrics` |
| List services | `pup services list` or invoke `pup:service-catalog` |
| RUM search | `pup rum search` or invoke `pup:rum` |
| Create notebook | `pup notebooks create` or invoke `pup:notebooks` |

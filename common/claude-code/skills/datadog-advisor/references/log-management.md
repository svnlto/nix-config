# Log Management

## Logging Without Limits

Datadog's model: ingest all logs, index selectively, archive cheaply.
The cost structure rewards this approach:

```text
Ingest (cheapest) → Pipeline processing → Decision point:
  ├─ Index (most expensive — pay per GB retained and queried)
  ├─ Archive (cheap — S3/GCS/Azure Blob for compliance)
  └─ Drop (free — exclusion filter, never stored)
```

The goal: index only what you'll actively query, archive what you need
for compliance, drop everything else.

## Index/Archive/Drop Decision Framework

| Log type | Decision | Rationale |
|----------|----------|-----------|
| Application errors (ERROR, FATAL) | **Index** | Active debugging, incident investigation |
| Request logs with latency data | **Index** (sampled) | Performance analysis, but high volume |
| Security/audit events | **Index** + **Archive** | Active alerting + compliance retention |
| Health check / heartbeat | **Drop** | High volume, zero diagnostic value |
| Debug logs from production | **Drop** | Should not be in production; if needed, enable temporarily |
| Kubernetes event logs | **Index** (short retention) | Useful during incidents, stale quickly |
| Load balancer access logs | **Archive** | Compliance/forensics, too high volume to index |
| CI/CD build logs | **Archive** | Useful for post-mortems, not daily queries |
| Verbose framework logging | **Drop** | Spring Boot startup, ORM queries — noise |

## Index Strategy

Use multiple indexes with different retention periods:

| Index | Retention | Contents | Purpose |
|-------|-----------|----------|---------|
| `main` | 15 days | Application errors, request logs | Day-to-day debugging |
| `security` | 90 days | Auth events, access logs, audit trail | Security investigations |
| `long-term` | 30 days | Infrastructure, deployment events | Trend analysis |

Each index has its own daily quota and exclusion filters. This lets
you control costs per log category independently.

**Index order matters.** Datadog evaluates indexes top to bottom.
A log matches the first index whose filter it satisfies. Put specific
indexes (security, compliance) above the general `main` index.

## Exclusion Filters

Apply exclusion filters on indexes to drop high-volume, low-value logs
after pipeline processing but before indexing:

**Common exclusion patterns:**

- Health checks: `source:nginx status:200 @http.url_details.path:/health*`
- Bot traffic: `@http.useragent:*bot* OR @http.useragent:*crawler*`
- Successful auth: `source:auth @evt.outcome:success` (keep failures)
- Verbose debug: `status:debug`
- Kubernetes probes: `@http.url_details.path:/ready* OR @http.url_details.path:/live*`

**Sampling exclusion:** Instead of dropping all matching logs, sample
at 1-10% for high-volume categories. This preserves visibility while
cutting cost by 90-99%.

## Standard Pipeline Design

Build log pipelines in this order:

### 1. Grok Parser

Extract structured fields from log messages.

```text
%{date("yyyy-MM-dd HH:mm:ss"):timestamp} %{word:level} %{data:message}
```

### 2. Status Remapper

Map the extracted `level` field to Datadog's standard `status` attribute.
This enables the log level filter in the UI.

### 3. Date Remapper

Use the extracted `timestamp` instead of ingestion time.
Critical for logs that arrive with delay.

### 4. Attribute Remapper

Normalize field names to Datadog conventions:

- `req_id` → `@http.request_id`
- `user_email` → `@usr.email`
- `response_time_ms` → `@duration`

### 5. Category Processor

Add computed categories for filtering:

- `@duration > 1000` → `@performance:slow`
- `@http.status_code:[500 TO 599]` → `@error_type:server`

### 6. Sensitive Data Scanner

Redact PII before indexing. Patterns:

- Email addresses
- Credit card numbers
- API keys / tokens
- SSNs / national IDs

Apply scanner rules at the pipeline level so data is scrubbed
regardless of which index the log lands in.

## Log-to-Metric Conversion

For high-volume log patterns where you need trends but not individual
events, generate a metric from logs:

**Good candidates:**

- Count of errors by service and error type
- Latency percentiles from request logs
- Count of specific business events (signups, purchases)
- Rate of specific log patterns (rate limiting, circuit breaker trips)

**How it works:**

1. Define a log-based metric with a query filter
2. Choose measure (count, gauge, or distribution)
3. Select group-by tags (keep cardinality low)
4. The metric is generated at ingest time — even if the log is excluded from indexing

This is the most powerful cost optimization: you get the metric
(cheap, long retention, fast queries) without paying to index the
underlying logs.

## Cost Optimization Checklist

1. **Audit exclusion filters** — Are health checks and bot traffic excluded?
2. **Review retention** — Does every index need 15+ days? Some need only 3.
3. **Check sampling** — High-volume success logs can be sampled at 1-10%.
4. **Convert to metrics** — Any log pattern queried only as counts/rates?
5. **Pipeline efficiency** — Are grok parsers failing on malformed logs?
   Failed parses still count as ingested.
6. **Archive unused** — Logs kept "just in case" should be archived, not indexed.

## Pup Execution

| Task | Command |
|------|---------|
| Search logs | `pup logs search` or invoke `pup:logs` |
| List indexes | `pup log-indexes list` or invoke `pup:log-configuration` |
| List pipelines | `pup log-pipelines list` or invoke `pup:log-configuration` |
| Check log volume | `pup usage logs` or invoke `pup:usage-metering` |

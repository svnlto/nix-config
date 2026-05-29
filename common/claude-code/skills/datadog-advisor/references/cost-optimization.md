# Cost Optimization

## Cost Hierarchy

Datadog costs scale with volume. The biggest cost drivers, in order:

1. **Custom metrics** — each unique tag combination is a time series.
   High cardinality = high cost. This is the most common surprise.
2. **Indexed logs** — pay per GB indexed and per GB scanned. Retention
   multiplies the cost.
3. **Indexed spans (APM)** — ingested spans are cheap, indexed spans
   are expensive. Control what you index.
4. **Synthetic tests** — per-test-run billing. Frequent tests on many
   locations add up.
5. **Infrastructure hosts** — per-host pricing. Usually predictable.

## Custom Metric Cardinality

### The problem

A metric with tags `env`, `service`, `endpoint`, `status_code` where:

- 3 environments × 20 services × 100 endpoints × 5 status codes
- = 30,000 time series from ONE metric name

Add `customer_id` (10,000 values) and it becomes 300,000,000 time series.

### Cardinality reduction

**Before emitting a metric, ask:**

1. Will I ever query by this tag? If no, don't add it.
2. How many unique values does this tag have? If > 100, reconsider.
3. Can I use a category instead? (`latency_bucket:fast|medium|slow`
   instead of raw milliseconds)

**Common high-cardinality culprits:**

- `endpoint` or `path` with unbounded route params → use route templates
- `status_code` as raw integer → group into `2xx`, `3xx`, `4xx`, `5xx`
- `customer_id` or `user_id` → never on custom metrics
- `request_id` → never on custom metrics
- `error_message` → use error categories

### Metrics without Limits

Datadog's Metrics without Limits lets you configure which tags are
queryable on a per-metric basis after ingestion:

1. Ingest the metric with all tags
2. Configure tag allowlist: only store time series for selected tag combinations
3. Aggregated data remains queryable; raw high-cardinality data is dropped

This lets you keep rich tags on individual traces/logs while controlling
metric costs.

**When to use:** Any custom metric where you added tags "just in case"
but only query by 2-3 of them.

**Pup:** `pup metrics tags configure` or invoke `pup:metrics`

## APM Span Indexing

### Ingested vs indexed spans

- **Ingested:** All spans received by Datadog. Cheap per GB. Retained
  for 15 minutes for live search.
- **Indexed:** Spans stored long-term for querying. Expensive per GB.
  Retained per your retention policy.

### Controlling indexed span volume

**Retention filters** determine what gets indexed. Default: all error
spans and a sample of everything else. Customize:

| Filter | Index? | Rationale |
|--------|--------|-----------|
| Error spans | Yes (100%) | Always index errors for debugging |
| High-latency spans (p99+) | Yes (100%) | Performance investigation |
| Critical service spans | Yes (10-25% sample) | Baseline visibility |
| Health check spans | No | Zero diagnostic value |
| Internal middleware spans | No | Noise — the parent span has the info |
| Low-traffic services | Yes (100%) | Low volume = low cost anyway |

**Pup:** `pup apm retention-filters list` or invoke `pup:apm-configuration`

## Log Cost Optimization

See `log-management.md` for the full framework. Key cost levers:

1. **Exclusion filters** — drop health checks, bot traffic, debug logs
2. **Multiple indexes** — shorter retention for operational logs, longer for compliance
3. **Log-to-metric conversion** — generate metrics from logs, then exclude the logs
4. **Sampling** — 1-10% sampling for high-volume success logs
5. **Archive** — move compliance logs to S3/GCS instead of indexing

## Synthetic Test Budget

Synthetic tests bill per execution. Control costs with:

| Strategy | Impact |
|----------|--------|
| Reduce check frequency | 5 min → 15 min saves 67% |
| Fewer locations | 5 → 2 locations saves 60% |
| Business hours only | Skip overnight checks for non-critical flows |
| Tiered frequency | Critical paths every 1 min, others every 15 min |

Keep high-frequency synthetics for:

- Core user journeys (login, checkout, search)
- API health checks used for SLOs
- Third-party dependency monitoring

## Usage Visibility

Before optimizing, understand where costs come from:

| What to check | Command |
|---------------|---------|
| Overall usage summary | `pup usage summary` |
| Billable hosts | `pup usage hosts` |
| Indexed log volume | `pup usage logs` |
| Custom metric count | `pup usage custom-metrics` |
| Indexed span volume | `pup usage indexed-spans` |
| Ingested span volume | `pup usage ingested-spans` |
| Synthetic test runs | `pup usage synthetics` |

**Cost attribution tags:** Configure `team` and `cost-center` tags
for cost attribution. This shows which team/service drives which costs.

**Pup:** `pup usage *` or invoke `pup:usage-metering`

## Optimization Prioritization

Work through these in order — each step has diminishing returns:

### Quick wins (do first)

1. Add exclusion filters for health checks and bot traffic in log indexes
2. Disable APM indexing for health check and internal middleware spans
3. Review custom metrics for unbounded cardinality tags

### Medium effort

1. Set up multiple log indexes with appropriate retention
2. Configure Metrics without Limits on top 10 highest-cardinality metrics
3. Convert high-volume log patterns to log-based metrics
4. Reduce synthetic test frequency for non-critical flows

### Ongoing governance

1. Alert on unexpected usage spikes (`pup usage` metrics)
2. Include cardinality review in code review for new metrics
3. Quarterly usage review per team using cost attribution

## Pup Execution Summary

| Task | Command |
|------|---------|
| Usage overview | `pup usage summary` or invoke `pup:usage-metering` |
| Custom metric count | `pup usage custom-metrics` |
| Metric tag config | `pup metrics tags configure` or invoke `pup:metrics` |
| Retention filters | `pup apm retention-filters list` or invoke `pup:apm-configuration` |
| Log index list | `pup log-indexes list` or invoke `pup:log-configuration` |

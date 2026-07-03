# Metrics Pipeline

Vector's event model has two shapes: **logs** and **metrics**.
The log-centric transforms (`remap`, `parse_*`, `route`) shape
logs; a separate set of components produces and reshapes metric
events. This file covers deriving metrics from logs, controlling
their cardinality, and rolling them up before shipping.

## Metric event model

A metric event is not a keyed object like a log — it carries a
`name`, a set of `tags` (the dimensions), and a typed value. The
value is one of six kinds:

- **counter** — a single monotonically increasing number (e.g.
  requests served).
- **gauge** — a single point-in-time value that can rise or fall
  (e.g. queue depth, memory in use).
- **distribution** — a stream of raw samples with weights, kept
  for later aggregation into histograms or summaries.
- **set** — a collection of unique values; its cardinality is the
  metric (e.g. distinct active users).
- **aggregated histogram** — pre-bucketed observations (bucket
  bounds plus counts), typical of Prometheus-style histograms.
- **summary** — pre-computed quantiles over observations.

Every metric also has a `kind`: **`incremental`** (a delta to add
to the running value, the natural output of `log_to_metric`
counters) or **`absolute`** (the value *is* the current reading,
as gauges usually are). Sinks and aggregation treat the two
differently — an incremental counter is summed, an absolute gauge
is replaced.

## Deriving metrics from logs (`log_to_metric`)

`log_to_metric` turns a stream of log events into metric events —
count errors, measure request durations, track status codes —
without touching an application. It takes a `metrics` list; each
entry names a metric to emit from every matching log. Per-entry
options: `type` (`counter`, `gauge`, or `histogram`), `field` (the
log field to read), `name`, optional `namespace`, and `tags` (a
map of dimension name to a `{{field}}` template pulling values
from the log). Counters default to +1 per event; set
`increment_by_value: true` to add the numeric `field` value
instead. Gauge values are absolute; histogram entries feed a
distribution of the `field`'s values.

```yaml
transforms:
  http_metrics:
    type: log_to_metric
    inputs:
      - parse_access_log
    metrics:
      # count responses, dimensioned by status and host
      - type: counter
        field: status
        name: response_total
        namespace: service
        tags:
          status: "{{status}}"
          host: "{{host}}"
      # observe request duration as a distribution
      - type: histogram
        field: duration_ms
        name: request_duration_ms
        tags:
          host: "{{host}}"
```

Wiring transforms into a topology (`inputs`, fan-out, named
outputs) is covered in `references/pipeline-config.md` and is not
repeated here.

## Controlling cardinality (`tag_cardinality_limit`)

Metric cost on backends like Datadog is driven by *unique tag
combinations* — every distinct set of tag values is a separate
custom metric time series and is billed as one. A single
high-cardinality tag (a raw `user_id`, a `request_id`, a
full URL path) can multiply one metric into millions of series
and dominate the bill. `tag_cardinality_limit` is the guardrail:
it caps how many distinct values a tag key may take and drops the
excess before they reach the sink.

Verified options:

- **`value_limit`** — max distinct values accepted for any tag
  key. Default `500`.
- **`limit_exceeded_action`** — what to do once a key exceeds the
  limit: `drop_tag` (strip the offending tag, keep the event) or
  `drop_event` (discard the whole event). Default `drop_tag`.
- **`mode`** — `exact` (precise tracking, more memory, guarantees
  no new value passes after the limit) or `probabilistic` (bounded
  memory via `cache_size_per_key`, may occasionally let a new
  value through).

```yaml
transforms:
  cap_tags:
    type: tag_cardinality_limit
    inputs:
      - http_metrics
    value_limit: 500
    limit_exceeded_action: drop_tag
    mode: exact
```

Place this before the metrics sink so unbounded dimensions are
capped at the aggregator, not paid for downstream. Prefer fixing
the source of high cardinality (drop the raw tag in
`log_to_metric`, or bucket the value in VRL first) over relying on
the limiter as the sole defence.

## Aggregating metrics (`aggregate`)

High-frequency metric streams (many events per second per series)
are wasteful to ship one-for-one. `aggregate` rolls incremental
metrics up over a time window, emitting one combined metric per
series per interval. The window is set by **`interval_ms`**
(milliseconds).

```yaml
transforms:
  rollup:
    type: aggregate
    inputs:
      - cap_tags
    interval_ms: 10000   # flush every 10s
```

This flattens flush frequency independent of source rate,
reducing the request volume and per-point cost at the sink.
Aggregation combines counters by summing and keeps the latest
absolute gauge within the window.

## Shipping

The `datadog_metrics` sink configuration — endpoint, API key via
environment interpolation, batching, and buffers — lives in
`references/datadog-integration.md`; do not duplicate it here.
Decisions about *what* metrics to keep, retention, and custom-
metric cost strategy are the domain of the `datadog-advisor`
skill.

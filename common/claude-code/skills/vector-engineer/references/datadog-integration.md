# Datadog Integration

Shipping logs and metrics from Vector to Datadog. This covers the
two Datadog sinks and their key options, keeping billing under
control before data leaves the pipeline, and where this skill's
responsibility ends and the `datadog-advisor` skill's begins.
Delivery-side concerns for these sinks — buffers, retries, acks,
health — live in `references/production-hardening.md`.

## Datadog sinks

Two sinks, one per data type. Both speak Datadog's intake API and
share the same credential and routing options.

- **`datadog_logs`** — ships log events to Datadog Logs.
- **`datadog_metrics`** — ships metric events to Datadog Metrics.

Verified key options (checked against
`vector.dev/docs/reference/configuration/sinks/datadog_logs` and
`.../datadog_metrics`):

- **`inputs`** — list of source/transform IDs feeding the sink.
- **`default_api_key`** — the Datadog API key. Never hardcode it;
  source it (see below).
- **`site`** — the Datadog site, matching the org's region:
  `datadoghq.com` (US1, default), `datadoghq.eu` (EU),
  `us3.datadoghq.com`, `us5.datadoghq.com`, `ap1.datadoghq.com`,
  or `ddog-gov.com`. Sending to the wrong site silently fails
  auth — match it to the org.
- **`endpoint`** — override the full intake URL. Only needed for a
  proxy or a private Datadog relay; leave unset to derive from
  `site`.
- **`compression`** (`datadog_logs`) — `zstd` (default), `gzip`,
  `snappy`, `zlib`, or `none`. Default `zstd` is the right choice;
  it trades a little CPU for a large egress reduction.
- **`default_namespace`** (`datadog_metrics`) — prefix applied to
  emitted metric names.
- **`series_api_version`** (`datadog_metrics`) — intake API
  version, `v2` on current Vector.

A minimal verified pair, keyed off internal telemetry as the input
example:

```yaml
sinks:
  dd_logs:
    type: datadog_logs
    inputs:
      - parsed_logs
    site: datadoghq.eu
    default_api_key: ${DATADOG_API_KEY}
    compression: zstd
  dd_metrics:
    type: datadog_metrics
    inputs:
      - app_metrics
    site: datadoghq.eu
    default_api_key: ${DATADOG_API_KEY}
```

**API key handling.** `default_api_key` is a secret and must not
appear in the config or in git. Two supported ways to supply it:

- **Environment variable** — reference it as
  `${DATADOG_API_KEY}` (shown above). Vector interpolates env
  vars at load; the value never lands in the config file. This is
  the simplest form and works everywhere.
- **Vector secret backend** — Vector can fetch secrets at startup
  from a configured `secret` backend (for example an `exec`
  backend that shells out to a secret store) and reference the
  resolved value in the sink. This keeps the key out of the pod
  environment entirely.

Where the key actually lives — Kubernetes Secret, Vault, a cloud
secret manager, or CI-injected env — and how it's rotated and
scoped is a secrets problem, not a Vector one. Use the
`secrets-management` skill for storage, rotation, and
least-privilege access; Vector only consumes the resolved value.

## Cost control

Datadog logs and metrics billing is volume-driven — indexed log
events and custom metric series both cost money per unit. Vector
sits directly in front of the intake, so the cheapest byte is the
one dropped before the Datadog sink. Reduce first, ship second.

The levers are ordinary pipeline transforms — `filter`, `sample`,
`route`, and `reduce`. Their syntax and wiring are covered in
`references/pipeline-config.md`; this section is about what to
apply, not how.

- **Drop low-value logs with `filter`.** Discard events that carry
  no investigative or compliance value: health-check and readiness
  probe lines, static-asset access logs, debug-level logs in
  production, chatty framework noise. This is the single largest
  saving and the safest — you never indexed them anyway.
- **Sample high-volume streams with `sample`.** For repetitive
  high-cardinality logs (per-request access logs, successful
  200s), ship a representative fraction rather than all of it. Keep
  errors and warnings at 100% and sample only the successful,
  low-signal majority so you retain the ability to investigate
  incidents while cutting the bulk.
- **Split by value with `route`.** Send full-fidelity streams
  (errors, audit, security) to Datadog and route the low-value
  remainder to cheaper storage (object storage, a data lake) or
  drop it. This avoids paying Datadog rates for data that only ever
  needs cold retention.
- **Aggregate metrics with `reduce`.** Pre-aggregate or roll up
  high-frequency metric series before the `datadog_metrics` sink to
  cut custom-metric cardinality, which is what Datadog bills on.
  Collapse redundant tags and short intervals where per-point
  granularity isn't needed.

Do the reduction as early in the topology as correctness allows —
ideally at the aggregator, before the egress sink — so the dropped
volume never occupies buffers or retry queues either.

## Division of responsibility

This skill and the `datadog-advisor` skill compose; they do not
overlap. Keep the boundary sharp.

- **Vector (this skill) owns the how — getting data there.**
  Collection, parsing, transformation, routing, sink configuration,
  compression, delivery guarantees, and volume reduction. Vector is
  the pipeline: it decides how events are shaped and moved and how
  reliably they reach Datadog.
- **`datadog-advisor` owns the what and the why — using the data
  once it lands.** What to monitor, how to tag for correlation and
  cost attribution, alert and monitor design, SLO definition,
  dashboard structure, and Datadog-side cost governance.

Practical seam: when a question is "how do I get these logs/metrics
into Datadog, cheaply and reliably?" it belongs here. When it's
"what should I alert on, how should I tag it, what's the SLO?" hand
off to `datadog-advisor`. Vector should emit clean, well-labeled,
right-sized data; the advisor decides what to do with it.

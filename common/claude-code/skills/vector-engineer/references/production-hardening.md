# Production Hardening

Turning a working pipeline into a reliable one. This covers the
sink-side controls that decide what happens under load, outages,
and restarts: buffers, concurrency, delivery guarantees, health,
and self-monitoring. Verify any key against `vector top` or the
per-sink docs before relying on it — options vary slightly by sink.

## Buffers

Every sink has a buffer that absorbs the gap between the rate
events arrive and the rate the destination accepts them. Two
types:

- **`memory`** (default) — fast, but lost on a crash or forced
  restart. Bounded by `max_events` (default `500`).
- **`disk`** — survives crashes and restarts (data is synced to
  disk every 500ms), at a throughput cost. Bounded by `max_size`
  in bytes, which must be at least ~256 MiB (`268435488`).

`references/kubernetes-deploy.md` covers the PVC wiring for disk
buffers on the aggregator StatefulSet — this section is about
choosing and sizing.

**Which type.** Use disk buffers where durability matters: the
aggregator's egress sinks, anything shipping to a paid or
compliance-relevant destination. Memory is fine for the thin
agent-to-aggregator hop, where the aggregator's own disk buffer is
the real durability line and losing a few in-flight events on a
node restart is acceptable.

**Sizing.** Size a disk buffer to cover the longest outage you
want to ride out without loss:

```text
buffer_bytes ≈ avg_event_bytes × events_per_sec × outage_seconds
```

Measure `avg_event_bytes` and throughput from the internal metrics
below rather than guessing. Add headroom for spikes. Then size the
PVC to hold the buffer plus that headroom. A buffer larger than
the volume just fails to write; a buffer far larger than any
realistic outage wastes disk.

**`when_full`.** This is the load-shedding policy and the most
consequential single choice:

- **`block`** (default) — wait for space, applying backpressure up
  the topology. No data is dropped; instead it piles up at the
  edge (on disk if buffered there). Correct default for durable
  paths.
- **`drop_newest`** — discard incoming events rather than wait.
  Sheds load to keep the pipeline moving. Use only where freshness
  beats completeness (high-volume, low-value telemetry) and you
  have alerting on the drop count.

Mixing them lets you protect a critical sink with `block` while a
best-effort sink on the same source uses `drop_newest`. Note that
one `block` sink applies backpressure to every sink sharing that
source — a slow durable sink can throttle a best-effort one.

## Concurrency & retries

Sinks that speak HTTP expose a `request` block controlling
outbound traffic.

**Adaptive concurrency.** `request.concurrency` accepts `adaptive`
(default), `none`, or a fixed positive integer. Prefer `adaptive`:
Vector's ARC algorithm watches round-trip latency and error rates
and continuously tunes in-flight request count, backing off when
the destination slows and ramping up when it recovers. A fixed
number is a guess that is either too low (wasted throughput) or too
high (you become the source of the overload you were trying to
avoid). Leave `request.adaptive_concurrency.*` at defaults unless
profiling says otherwise; `initial_concurrency` (default `1`) is
the one worth raising if ramp-up after restart is too slow — read
the current `adaptive_concurrency_limit` metric to pick a value.

**Retries.** Failed requests retry with exponential backoff:

- `request.retry_attempts` — max retries (default effectively
  unbounded).
- `request.retry_initial_backoff_secs` — first-retry delay
  (default `1`).
- `request.retry_max_duration_secs` — cap on total backoff wait
  (default `30` on the Datadog sinks).
- `request.retry_jitter_mode` — `Full` (default) or `None`;
  jitter spreads retries so a fleet doesn't hammer a recovering
  destination in lockstep.

**Rate limiting.** Cap outbound throughput independent of
concurrency with `request.rate_limit_num` requests per
`request.rate_limit_duration_secs` window (default window `1`
second). Use it to stay under a destination's documented quota;
it applies whether concurrency is adaptive or fixed.

## Delivery guarantees

End-to-end acknowledgements give at-least-once delivery. Set
`acknowledgements.enabled: true` on a sink: any connected source
that supports acks then holds each event until **all** connected
sinks confirm it, and only then acknowledges it back at the origin
(e.g. commits the Kafka offset, deletes the SQS message). The
sink-level setting overrides the global `acknowledgements` block.

Support is per-component — not every source and sink participates.
Sources with a real upstream cursor to hold (`kafka`, `aws_sqs`,
`kubernetes_logs`, the `vector` source) and sinks that can confirm
receipt implement it; others silently no-op. Check the specific
component's docs.

**Interaction with disk buffers.** Acks and disk buffers are
complementary, not redundant. A disk buffer makes the *hop from
buffer to destination* durable across a Vector restart;
acknowledgements make the *hop from origin to Vector* reliable so
the source doesn't advance its cursor until data is safely handled.
For genuine at-least-once from origin through to destination you
want both: acks enabled on the egress sink and a disk buffer in
front of it, so an event is neither lost on crash nor acked before
it is durably held.

## Health & shutdown

**Health checks.** Each sink runs a startup healthcheck by
default (`healthcheck.enabled: true`) — a probe of the
destination's reachability/credentials. Leave it on to fail fast on
misconfiguration. To make Vector refuse to start at all if any
sink is unhealthy, run with `--require-healthy`; without it, a
failing check is logged but Vector still starts and retries.

**Graceful shutdown.** On `SIGTERM` Vector stops accepting new
input, then flushes in-flight events through the topology and
drains buffers before exiting. A hung destination could block this
forever, so there is a bound: `--graceful-shutdown-limit-secs`
(default 60s) forces exit after the limit, dropping whatever
hasn't flushed; `--no-graceful-shutdown-limit` disables the cap
and waits indefinitely. On Kubernetes, set the pod
`terminationGracePeriodSeconds` comfortably above the shutdown
limit so the kubelet doesn't `SIGKILL` mid-flush — otherwise the
graceful window is meaningless. Disk buffers make a forced exit
survivable: un-flushed events are still on disk for the next start.

## Self-monitoring

Vector observes itself through two sources:

- **`internal_metrics`** — Vector's own telemetry as metric
  events.
- **`internal_logs`** — Vector's own log output as log events.

Route both into your observability backend like any other source.
Send them to a Datadog sink:

```yaml
sources:
  vector_metrics:
    type: internal_metrics
  vector_logs:
    type: internal_logs
sinks:
  dd_metrics:
    type: datadog_metrics
    inputs:
      - vector_metrics
  dd_logs:
    type: datadog_logs
    inputs:
      - vector_logs
```

Metrics worth alerting on (all carry `component_id`,
`component_kind`, `component_type` labels, so you can pinpoint the
offending component):

- **`component_errors_total`** — errors per component. A rising
  rate is the first sign of a failing sink or a broken transform.
- **`component_discarded_events_total`** — events dropped by a
  component. Should be zero on `block` paths; non-zero means data
  loss.
- **`buffer_size_bytes`** / **`buffer_size_events`** — current
  buffer occupancy. Sustained high utilization means the sink
  can't keep up and backpressure is imminent.
- **`buffer_discarded_events_total`** — events dropped by a
  non-blocking (`drop_newest`) buffer. This is your shed-load
  counter; alert if it's non-zero where you didn't intend it.
- **`buffer_received_events_total`** vs
  **`buffer_sent_events_total`** — a widening gap between in and
  out is a sink falling behind before the buffer is visibly full.

For SLO definitions, error-budget policy, and alert/monitor design
around these signals, use the sre-engineer skill. The Datadog sink
specifics — API key handling, `datadog_metrics` vs `datadog_logs`
config, tagging — live in `references/datadog-integration.md`.

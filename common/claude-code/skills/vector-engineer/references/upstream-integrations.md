# Upstream Integrations: Datadog Agent & Fluent Bit

Fronting Vector with an existing agent — the Datadog Agent or
Fluent Bit — instead of Vector's own `kubernetes_logs` agent.
Vector runs as the aggregator, receiving over the `datadog_agent`
or `fluent` source. The reliability question at this seam is the
same as anywhere in Vector (buffers, backpressure, acks) but the
upstream now owns half of it, so this file focuses on the handoff.
Verify any option against the current source docs before relying on
it — schemas drift across releases.

## When to use an upstream shipper

Prefer an upstream shipper over Vector's own agent when:

- **You already run an agent fleet.** A deployed Datadog Agent or
  Fluent Bit DaemonSet is doing host-level collection today.
  Pointing it at a Vector aggregator lets you add routing,
  sampling, and re-shaping centrally without ripping out the
  collection layer.
- **Gradual migration.** Insert Vector as an aggregator behind the
  existing shipper first, prove the pipeline, then optionally move
  collection to Vector later. Lower-risk than a big-bang swap.
- **Host-level collection you don't want to re-solve.** The DD
  Agent's integrations and Fluent Bit's low footprint are already
  tuned for the node; Vector adds the processing tier behind them.

If you have no existing agent, Vector's own agent role
(`references/kubernetes-deploy.md`) is simpler — one tool, one
protocol, native end-to-end acks over the `vector` source.

## Datadog Agent to Vector

Vector receives DD Agent logs, metrics, and traces on the
`datadog_agent` source. It listens on one HTTP `address` and
demultiplexes the three data types.

Vector side:

```yaml
sources:
  dd_agent_in:
    type: datadog_agent
    address: 0.0.0.0:8080
    multiple_outputs: true      # split into .logs / .metrics / .traces
    disable_traces: true        # accept logs + metrics only, drop traces
    store_api_key: true         # forward the Agent's API key downstream
    tls:
      enabled: true
      crt_file: /etc/vector/tls/server.crt
      key_file: /etc/vector/tls/server.key
```

With `multiple_outputs: true`, downstream components reference the
named outputs `dd_agent_in.logs`, `dd_agent_in.metrics`, and
`dd_agent_in.traces` (metrics is beta, traces is alpha). With it
`false` (default) all events arrive on the single default output.
`disable_logs` / `disable_metrics` / `disable_traces` (all default
`false`) turn off individual data types at the source.

Datadog Agent side — point `datadog.yaml` at the Vector endpoint
with the per-type `vector` block. `VECTOR_HOST:PORT` must be the
`datadog_agent` source `address`; use `https` when Vector TLS is
enabled:

```yaml
vector:
  logs.enabled: true
  logs.url: "https://vector-aggregator:8080"
  metrics.enabled: true
  metrics.url: "https://vector-aggregator:8080"
  traces.enabled: true
  traces.url: "https://vector-aggregator:8080"
```

Datadog's Observability Pipelines packaging uses the equivalent
`observability_pipelines_worker` block instead:

```yaml
observability_pipelines_worker:
  logs.enabled: true
  logs.url: "https://vector-aggregator:8080"
  metrics.enabled: true
  metrics.url: "https://vector-aggregator:8080"
```

The same settings map to `DD_VECTOR_LOGS_URL` /
`DD_OBSERVABILITY_PIPELINES_WORKER_LOGS_URL` style env vars for
containerized Agents.

**Acknowledgements.** The `datadog_agent` source supports
end-to-end acks: it holds the Agent's HTTP request open until every
connected sink confirms the events, then returns success so the
Agent can release them. Enable acks per sink
(`acknowledgements.enabled: true` on the egress sink) — the
source-level `acknowledgements` field is deprecated in favor of
the global/sink setting. See `references/production-hardening.md`
for the sink ack + disk-buffer pairing.

## Fluent Bit to Vector

Vector receives from Fluent Bit (or Fluentd) over the Fluent
Forward protocol on the `fluent` source.

Vector side:

```yaml
sources:
  fluent_in:
    type: fluent
    address: 0.0.0.0:24224     # 24224 is the conventional Forward port
    mode: tcp
    connection_limit: 1024     # cap concurrent inbound TCP connections
    tls:
      enabled: true
      crt_file: /etc/vector/tls/server.crt
      key_file: /etc/vector/tls/server.key
```

Options: `address` + `mode: tcp` for TCP (or `mode: unix` +
`path` for a Unix socket), `connection_limit`, `keepalive`,
`permit_origin` (CIDR allowlist), `receive_buffer_bytes`, and
`tls`. Note the `fluent` source supports TLS but **not** the
Forward protocol's shared-key / username-password auth, so Fluent
Bit's `secure_forward`-style shared-key auth is not compatible —
rely on TLS (and network controls) for the link.

Fluent Bit side — the `forward` output plugin pointed at the
Vector `fluent` source:

```ini
[OUTPUT]
    Name        forward
    Match       *
    Host        vector-aggregator
    Port        24224
    tls         on
    tls.verify  on
    Retry_Limit no_limits
```

`Host` / `Port` target the Vector source; `tls on` +
`tls.verify on` for a verified link in production. `Retry_Limit`
governs flush retries (default `1`; `no_limits` / `False` for
unbounded, `no_retries` to disable) — see buffering below.

**Acknowledgements.** As with `datadog_agent`, enable acks on the
Vector egress sink; the source-level `acknowledgements` field on
`fluent` is deprecated in favor of the global/sink setting. Note
Fluent Bit's `forward` output does not wait on downstream Vector
acks the way Vector's own source-to-sink acks do — its delivery
guarantee comes from its own retry + filesystem buffer, covered
next.

## Buffering & backpressure

This is the crux: when Vector slows or stops, where do events
queue, how is the pressure signalled back, and does the upstream
buffer survive the gap. Vector's own buffer/ack mechanics live in
`references/production-hardening.md`; here is how each upstream
reacts to Vector applying backpressure.

**How Vector signals backpressure.** With `when_full: block`
(default) on its egress sink buffers, a Vector slowdown or
downstream outage propagates back through the topology to the
`datadog_agent` / `fluent` source, which stops reading — for an
HTTP or TCP source that means it stops accepting / draining
inbound requests. The upstream shipper then sees a slow or
unavailable receiver and must absorb the events in its own buffer.
So the durability question splits: Vector's disk buffer covers the
buffer-to-destination hop; the upstream's buffer covers the
shipper-to-Vector hop while Vector is throttled or down.

**Datadog Agent side.** When Vector's `datadog_agent` source stops
draining, the Agent's HTTP submissions to `logs.url` slow or fail.
The Agent's logs pipeline retains undelivered payloads in its own
in-memory/on-disk logs buffer and retries; a prolonged Vector
outage eventually overflows that buffer and the Agent drops
oldest data. The Agent's logs buffer is comparatively small and
not sized for long outages, so:

- Give Vector's egress sink a disk buffer so a *downstream*
  outage is absorbed at Vector, not pushed back to the Agent.
- Keep the Agent-to-Vector hop short and highly available (local
  aggregator, multiple replicas behind a Service) so the Agent
  rarely has to buffer at all.
- Enable acks on the Vector egress sink so the source only
  returns HTTP success once events are durably held — the Agent
  then correctly retries anything not yet safe.

**Fluent Bit side.** Fluent Bit has a much stronger local buffer,
and it is the main lever for surviving a Vector outage. By default
inputs buffer in memory, bounded per input by `Mem_Buf_Limit`;
when that fills, Fluent Bit pauses the input (backpressure onto the
log source) until chunks flush. For durability across a Vector
restart, switch to filesystem buffering:

```ini
[SERVICE]
    storage.path              /var/log/flb-storage/
    storage.max_chunks_up     128
    storage.backlog.mem_limit 32M

[INPUT]
    Name        tail
    Path        /var/log/containers/*.log
    storage.type filesystem

[OUTPUT]
    Name        forward
    Match       *
    Host        vector-aggregator
    Port        24224
    storage.total_limit_size  5G
```

Key knobs for the handoff:

- **`storage.type filesystem`** (INPUT) — chunks are written to
  disk (under the SERVICE `storage.path`) so they survive a Fluent
  Bit or Vector restart, not just held in memory.
- **`storage.total_limit_size`** (OUTPUT) — caps on-disk chunks
  queued for *this* destination. This is the outage budget: when
  Vector is down, chunks accumulate here up to the limit, then the
  oldest are discarded. Size it to the longest Vector outage you
  want to ride out (see the sizing formula in
  `references/production-hardening.md`, applied to Fluent Bit's
  throughput).
- **`Mem_Buf_Limit`** (INPUT, memory mode) — per-input memory cap;
  when hit, the input pauses (backpressure to the source). With
  filesystem storage, `storage.max_chunks_up` (SERVICE) instead
  caps how many chunks stay mapped in memory, and
  `storage.pause_on_chunks_overlimit` (INPUT) decides whether the
  input pauses or keeps spilling to disk when that cap is reached.
- **`Retry_Limit`** (OUTPUT) — on flush failure to Vector, Fluent
  Bit retries with backoff. `no_limits` keeps retrying so buffered
  chunks aren't dropped for a transient Vector outage; the
  filesystem buffer holds them meanwhile.

Net: Fluent Bit's filesystem buffer + unlimited retries let it
tolerate a Vector outage up to `storage.total_limit_size`, then
apply backpressure to its inputs — no silent loss until the disk
budget is exhausted.

## Best practices

- **Acks end to end.** Enable `acknowledgements.enabled: true` on
  the Vector egress sink so the `datadog_agent` / `fluent` source
  only confirms receipt once events are durably held.
- **Disk buffers on both tiers.** Filesystem/disk buffer on the
  shipper (`storage.type filesystem` for Fluent Bit; the DD Agent's
  own logs buffer) *and* a Vector disk buffer on the egress sink —
  they cover different hops and are complementary, not redundant.
- **`when_full: block` for at-least-once.** Keep the default on
  durable paths so pressure propagates upstream instead of
  dropping; use `drop_newest` only where freshness beats
  completeness and you alert on the drop count.
- **Size for the longest expected downstream outage.** Set
  `storage.total_limit_size` (Fluent Bit) and Vector's disk
  buffer to survive the worst outage you want to ride out; a
  buffer smaller than the outage drops data, far larger wastes
  disk.
- **Secure the link with TLS.** Enable `tls` on both the Vector
  source and the shipper's output; verify certificates in
  production (`tls.verify on`). The `fluent` source has no shared
  -key auth, so TLS plus network controls are the boundary.
- **Monitor both buffers.** Watch Vector's `buffer_size_bytes` /
  `buffer_received_events_total` vs `buffer_sent_events_total`
  (see `references/production-hardening.md`) *and* the shipper's
  buffer metrics (Fluent Bit storage metrics; the DD Agent's log
  pipeline stats). A growing gap on either side is backpressure
  before it becomes loss.
- **One shipper role per host.** Run a single collection agent per
  node feeding one aggregator tier; don't stack multiple shippers
  competing for the same logs.

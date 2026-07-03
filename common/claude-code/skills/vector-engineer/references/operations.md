# Operations & Observing Vector

Running a pipeline is a different job from designing one. This
covers the live-inspection tooling for a Vector instance already in
production, how to reload it without dropping data, and the catalog
of Vector's own health metrics worth alerting on. All of the live
tools talk to Vector's GraphQL/gRPC API, so that comes first.

`references/production-hardening.md` covers the durability side —
buffers, `when_full`, acknowledgements, shutdown — and introduces
the `internal_metrics` / `internal_logs` sources. This file goes
deeper on the metric catalog and the live-debugging CLIs; it does
not repeat buffer or ack basics.

## The API (enable this first)

`vector top` and `vector tap` are clients of Vector's API — nothing
works until it is enabled. It is off by default. Turn it on in the
config:

```yaml
api:
  enabled: true
  address: "127.0.0.1:8686"
  playground: true
```

- **`api.enabled`** — boolean, default `false`. Must be `true`.
- **`api.address`** — bind address, default `127.0.0.1:8686`. Bind
  to loopback for local-only access. In a container set it to
  `0.0.0.0:8686` so `top`/`tap` can reach it from outside — but
  the API has **no authentication**, so never expose that port to
  an untrusted network. Keep it behind the pod/localhost boundary.
- **`api.playground`** — boolean, default `true`. Serves an
  interactive GraphQL playground at `/playground` for exploring the
  schema by hand.

The API exposes Vector's topology, per-component metrics, and
health over GraphQL. It is the single source the inspection tools
below query; `--url`/`-u` on those commands points at this address
when the instance is remote.

## Live inspection: `vector top`

`vector top` is a live TUI showing the running topology with
per-component event-in/event-out rates, error counts, and buffer
state, refreshed continuously. It is the fastest way to answer "is
data flowing, and where is it stuck." Use it as the first look when
a pipeline seems slow or a destination looks starved: a component
with high input and near-zero output is the bottleneck; a climbing
error column points at the failing component.

```bash
vector top --url http://127.0.0.1:8686/graphql
```

Useful flags (verified against the CLI reference):

- `--components, -c` — comma-separated component IDs / glob
  patterns to observe (default `*`).
- `--interval, -i` — metric sampling interval in ms (default
  `1000`).
- `--human-metrics, -H` — humanize numbers with suffixes (k, M).
- `--url, -u` — API endpoint for a remote instance.

`top` shows aggregates. When you need to see the actual events, use
`tap`.

## Tracing events: `vector tap`

`vector tap` streams the real events flowing into or out of a named
component on a running instance. This is the tool for "why is this
transform dropping / mangling events" — tap the transform's output
and watch what it actually emits, or tap its input to see what it
receives.

```bash
# Observe what a transform emits
vector tap --outputs-of my_transform

# Observe what a sink receives, as JSON
vector tap --inputs-of my_sink --format json
```

Flags and options (verified against the CLI reference):

- `--outputs-of` — components (sources, transforms) to observe on
  their **outputs**.
- `--inputs-of` — components (transforms, sinks) to observe on
  their **inputs**.
- positional `components` — glob pattern of source/transform
  outputs to tap (default `*`).
- `--format, -f` — event encoding: `json`, `logfmt`, or `yaml`.
- `--interval, -i` — sampling interval in ms (default `500`).
- `--limit, -l` — max events emitted per interval (default `100`).
- `--duration-ms, -d` — sample for a fixed duration, then exit.
- `--meta, -m` — annotate each event with its source
  `component_id`.
- `--quiet, -q` — print only the events, no framing.
- `--url, -u` — API endpoint for a remote instance.

Tap **samples** — with high throughput you see a slice, not every
event. That is fine for confirming shape and content; it is not a
substitute for the metric counters when you need exact totals.

## Config reload

Vector reloads its configuration without a full restart, keeping
unchanged components running.

- **SIGHUP** — signal the process to re-read its config:
  `killall -s SIGHUP vector` (or send `SIGHUP` to the PID).
- **`--watch-config` / `-w`** — start Vector so it auto-reloads
  when the config files change on disk. `--watch-config-method`
  selects `recommended` (filesystem events) or `poll`;
  `--watch-config-poll-interval-seconds` sets the poll cadence.

What reload handles gracefully: adding, removing, or editing
sources, transforms, and sinks — Vector diffs the topology and only
rebuilds what changed. What it cannot change on the fly: the data
directory and some process-level settings, which need a restart. A
config that fails validation is rejected and the previous topology
keeps running, so a bad reload does not take the pipeline down —
watch `internal_logs` to catch a rejected reload.

## Internal metrics to alert on

Enable the source, then route it to your backend (see the
self-monitoring section of `references/production-hardening.md` for
the full source + sink wiring):

```yaml
sources:
  vector_metrics:
    type: internal_metrics
```

Every metric below carries `component_id`, `component_kind`, and
`component_type` labels, so an alert can name the offending
component. Metric names verified against the Vector metrics
reference.

- **`component_errors_total`** (counter) — errors per component,
  labelled by `error_type` and `stage`. A rising rate is the
  earliest sign of a failing sink, a broken transform, or a sink's
  send stage failing to reach its destination. Sink send failures
  surface here (with the sending `stage`) rather than as a distinct
  metric. **Alert:** rate over any window > 0 on a component that
  should be clean; page if a critical egress sink's error rate is
  sustained.

- **`component_discarded_events_total`** (counter) — events dropped
  by a component, labelled `intentional` (`true` for a `filter`,
  `false` for an error). Non-intentional discards are data loss.
  **Alert:** any `intentional=false` discards; treat intentional
  ones as expected but chart them.

- **`component_sent_events_total`** vs
  **`component_received_events_total`** (counters) — events out of
  vs into a component. A widening gap across a transform is
  expected only where it filters; across the topology, egress
  lagging ingress means Vector is falling behind. **Alert:**
  sustained divergence between total received (at sources) and
  total sent (at sinks) beyond intended filtering.

- **`utilization`** (gauge, 0–1) — load on a component, updated
  every 5s; `0` is idle, `1` is never idle. A sink pinned near `1`
  is the throughput ceiling and the reason upstream buffers fill.
  **Alert:** warn on a sink or transform sustained near `1`.

- **`buffer_size_bytes`** / **`buffer_size_events`** (gauges) —
  current sink-buffer occupancy in bytes / events. Compare against
  the configured `max_size` / `max_events` (the buffer bound you
  set in config — Vector does not emit a separate max-size gauge).
  Sustained high occupancy means the sink can't keep up and
  backpressure is imminent. Note: `buffer_byte_size` and
  `buffer_events` are the old, **deprecated** names — use
  `buffer_size_*`. **Alert:** warn when occupancy exceeds a
  fraction (e.g. 80%) of the configured max.

- **`buffer_discarded_events_total`** (counter) — events dropped by
  a non-blocking (`drop_newest`) buffer. This is the shed-load
  counter. Zero on `block` paths by design. **Alert:** any value >
  0 where you did not intend load-shedding.

- **`buffer_received_events_total`** vs
  **`buffer_sent_events_total`** (counters) — into vs out of the
  buffer. A widening gap is a sink falling behind before the buffer
  is visibly full — an earlier signal than the occupancy gauges.
  **Alert:** growing divergence, as a leading indicator.

Routing these metrics to Datadog — the `datadog_metrics` sink, API
key handling, tagging — is covered in
`references/datadog-integration.md`. Turning these signals into
SLOs, error-budget policy, and monitor/alert definitions is the
domain of the sre-engineer and datadog-advisor skills; the intents
above are starting points, not finished monitors.

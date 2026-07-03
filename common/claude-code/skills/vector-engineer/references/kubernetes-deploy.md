# Kubernetes Deployment

Vector runs on Kubernetes in two distinct roles. Pick the role
per workload; a typical cluster runs both in an agent→aggregator
topology.

## Two roles

- **Agent** — a `DaemonSet`, one pod per node. Its job is
  collection: it runs the `kubernetes_logs` source to tail every
  container's logs off the node filesystem (plus node/pod
  metadata), does light enrichment at most, then forwards
  everything to an aggregator. Keep agent config thin — heavy
  transforms multiply across every node.
- **Aggregator** — a `StatefulSet`, a small fixed replica set.
  It receives from the agents (typically a `vector` source over
  the Vector protocol), then does the real work: parsing,
  routing, sampling, aggregation, and shipping to sinks. Central
  processing means one place to change transform logic and one
  place that holds the durable disk buffers.

The common topology is **agents fan in to aggregators**: each
node's agent ships to a `vector` sink pointed at the aggregator
Service, and the aggregator owns the expensive transforms and
sink connections. This isolates node-local collection from
cluster-wide processing, so you can scale, restart, or
reconfigure the aggregator without touching every node. For a
tiny cluster you can skip the aggregator and let agents ship
straight to sinks, but you lose the central buffer and
single-point-of-change benefits.

## Helm

The official `vector` Helm chart deploys either role. Add the
repo and install with a values file:

```bash
helm repo add vector https://helm.vector.dev
helm repo update
helm install vector vector/vector \
  --namespace vector --create-namespace \
  --values values.yaml
```

The `role` value selects the workload type — valid options are
`Agent` (DaemonSet), `Aggregator` (StatefulSet), and
`Stateless-Aggregator` (Deployment). Key `values.yaml` fields:

- **`role`** — `Agent` / `Aggregator` / `Stateless-Aggregator`.
- **`customConfig`** — inline Vector config (sources /
  transforms / sinks) as YAML. Overrides the chart's default
  config; when set, **all** options must be specified.
- **`resources`** — standard Kubernetes requests/limits.
- **`persistence`** — PVCs for the aggregator StatefulSet
  (`enabled`, `size`, and `storageClassName`, which applies to
  the Aggregator role only).

A minimal agent that collects pod logs and forwards to an
aggregator Service:

```yaml
role: Agent
customConfig:
  data_dir: /vector-data-dir
  sources:
    k8s:
      type: kubernetes_logs
  sinks:
    to_aggregator:
      type: vector
      inputs:
        - k8s
      address: vector-aggregator:6000
```

The matching aggregator receives on a `vector` source, processes,
and ships. `helm show values vector/vector` prints the full,
current value schema — check it before relying on any key.

## Buffers on PVC

The aggregator is where durability matters, so give its sinks
disk buffers backed by a PersistentVolume. A disk buffer survives
forced restarts and crashes (data is written periodically, synced
to disk on a short interval); a memory buffer does not. Configure
it per sink:

```yaml
sinks:
  ship:
    type: "..."
    inputs:
      - process
    buffer:
      type: disk
      max_size: 268435488  # bytes; disk buffers require this ~256 MB minimum
      when_full: block
```

`when_full: block` applies backpressure upstream rather than
dropping (see below); `drop_newest` sheds load instead. Disk
buffers write under Vector's `data_dir`, so the StatefulSet needs
a PersistentVolume mounted there — set `persistence.enabled: true`
and size the PVC (`persistence.size`) to hold the buffer plus
headroom. The chart default varies by version — check
`helm show values vector/vector` rather than assuming a fixed
size. Deep buffer tuning (overflow topologies,
sizing per throughput) lives in
`references/production-hardening.md`.

## Backpressure & sizing

Vector propagates backpressure end to end. When a sink slows —
a downstream outage, rate limit, or a full `when_full: block`
buffer — the pressure travels back up the topology: transforms
stall, the source stops accepting, and for the agent that means
it slows reading from the node. No data is silently dropped;
instead it piles up at the edge (on disk if buffered there). This
is the safe default, but it means a stuck sink can back up the
whole path, so alert on buffer fill and sink errors.

Rough sizing:

- **Agent** — modest and uniform; CPU scales with per-node log
  volume, memory stays small. Set requests generously enough to
  avoid throttling the log reader, but keep limits tight since it
  runs on every node.
- **Aggregator** — needs materially more CPU (all the transform
  work concentrates here) and more memory (in-flight events plus
  buffer bookkeeping), and it needs the PVC for disk buffers.
  Scale replicas for throughput and set requests to a realistic
  steady-state so backpressure doesn't trigger under normal load.

Set requests to steady-state and limits to a headroom multiple;
watch actual usage and adjust. Reliability targets, error-budget
thinking, and monitor design belong in
`references/production-hardening.md`.

## Related skills

For StatefulSet, DaemonSet, and general workload specifics
(volumes, affinity, PodDisruptionBudgets, Helm mechanics) use the
kubernetes-specialist skill. For reliability, SLOs, and alerting
around the pipeline use the sre-engineer skill.

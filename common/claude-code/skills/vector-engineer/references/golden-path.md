# Golden Path: Kubernetes Logs to Datadog + S3

A single worked example that ties the other references together:
collect every pod's logs, process them centrally, ship the
high-value stream to Datadog and everything else — plus anything
that fails to parse — to cheap S3 archive. Agents stay thin; the
aggregator does the real work.

The scenario is built up incrementally below, then shown as one
complete, consistent aggregator `customConfig`. Each component is
cross-referenced to the file that documents it in depth rather
than re-explained here.

## 1. Agents collect

The agent DaemonSet is deliberately minimal: a `kubernetes_logs`
source tailing every container off the node filesystem, forwarded
straight to the aggregator over the `vector` protocol. No parsing
or redaction on the node — that multiplies across every node and
belongs on the aggregator.

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

The agent-to-aggregator hop uses a memory buffer (the default) —
the aggregator's disk buffers are the real durability line. Helm
`role`/`customConfig` mechanics and PVC wiring live in
`references/kubernetes-deploy.md`; this file focuses on the
aggregator pipeline.

## 2. Aggregator pipeline

The aggregator runs as a StatefulSet with a `vector` source
listening on the same port the agents ship to. From there the
topology is: parse -> redact -> route -> two sinks, with a
dead-letter path for anything unparseable.

### Source

```yaml
sources:
  from_agents:
    type: vector
    address: 0.0.0.0:6000
```

The `vector` source supports end-to-end acknowledgements, so an
event isn't acked back to the agent until the aggregator's sinks
confirm it (see the delivery-guarantees section of
`references/production-hardening.md`).

### Parse, with a dead-letter path

`parse_json!` aborts on a malformed line; `reroute_dropped: true`
plus `drop_on_error: true` divert those aborted/errored events to
the transform's `.dropped` output instead of discarding them or
letting half-parsed events flow on. That `.dropped` output is
consumed by the S3 sink below — no failed event vanishes silently.
See the dead-letter section of
`references/production-hardening.md`.

```yaml
transforms:
  parse:
    type: remap
    inputs:
      - from_agents
    drop_on_error: true
    reroute_dropped: true
    source: |
      . = parse_json!(.message)
      .level = downcase(.level) ?? "info"
```

### Redact PII

Redact before any sink so raw PII never reaches a buffer, retry
queue, or disk. `redact` applied to the whole event walks every
string field; `filters` must be static (named filter + regex
literals). This mirrors the PII section of `references/vrl.md`.

```yaml
  redact_pii:
    type: remap
    inputs:
      - parse
    source: |
      . = redact(., filters: [
        "us_social_security_number",
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',   # email
      ])
```

### Route: high-value vs the low-value majority

Split the clean stream so full-fidelity logs go to Datadog and the
low-signal remainder goes to cheap storage — the cost-control
tiering from `references/datadog-integration.md`. `route`
conditions are VRL; reference a branch downstream as
`<route-id>.<branch>` (see `references/pipeline-config.md`).

```yaml
  by_value:
    type: route
    inputs:
      - redact_pii
    route:
      high_value: '.level == "error" || .level == "warn"'
      low_value:  '.level != "error" && .level != "warn"'
```

### High-value sink: `datadog_logs`

The high-value branch ships to Datadog with a disk buffer, acks,
and batching for durable at-least-once delivery. `default_api_key`
comes from the environment — never hardcoded (see
`references/datadog-integration.md`). Buffer minimum and
`when_full: block` per `references/kubernetes-deploy.md` and
`references/production-hardening.md`.

```yaml
sinks:
  dd_logs:
    type: datadog_logs
    inputs:
      - by_value.high_value
    site: datadoghq.eu
    default_api_key: ${DATADOG_API_KEY}
    compression: zstd
    acknowledgements:
      enabled: true
    buffer:
      type: disk
      max_size: 268435488   # ~256 MB disk-buffer minimum
      when_full: block
    batch:
      max_bytes: 1048576
      timeout_secs: 5
```

### Archive sink: `aws_s3` (low-value + dead-letter)

One `aws_s3` sink is the cheap home for two streams: the low-value
route branch and the `parse.dropped` dead-letter output.
Fan-in — both IDs sit in one `inputs` list. Options
(`bucket`, `region`, `key_prefix`, `compression`, `framing`,
`encoding`, `batch`) per `references/sources-and-sinks.md`; the
AWS credential chain (IRSA role) supplies auth, no keys in config.

```yaml
  archive:
    type: aws_s3
    inputs:
      - by_value.low_value
      - parse.dropped
    bucket: my-log-archive
    region: ${AWS_REGION}
    key_prefix: "date=%Y-%m-%d/"
    compression: gzip
    framing:
      method: newline_delimited
    encoding:
      codec: json
    batch:
      max_bytes: 10000000
```

## 3. Full aggregator config

The complete `customConfig` assembled from the pieces above, with
every `inputs` wired and the `.dropped` output consumed. This is
the Helm `customConfig` block for the Aggregator role; pair it with
`persistence.enabled: true` sized for the disk buffer (see
`references/kubernetes-deploy.md`).

```yaml
role: Aggregator
persistence:
  enabled: true
  size: 2Gi
customConfig:
  data_dir: /vector-data-dir
  api:
    enabled: true
    address: 0.0.0.0:8686

  sources:
    from_agents:
      type: vector
      address: 0.0.0.0:6000

  transforms:
    parse:
      type: remap
      inputs:
        - from_agents
      drop_on_error: true
      reroute_dropped: true
      source: |
        . = parse_json!(.message)
        .level = downcase(.level) ?? "info"

    redact_pii:
      type: remap
      inputs:
        - parse
      source: |
        . = redact(., filters: [
          "us_social_security_number",
          r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',   # email
        ])

    by_value:
      type: route
      inputs:
        - redact_pii
      route:
        high_value: '.level == "error" || .level == "warn"'
        low_value:  '.level != "error" && .level != "warn"'

  sinks:
    dd_logs:
      type: datadog_logs
      inputs:
        - by_value.high_value
      site: datadoghq.eu
      default_api_key: ${DATADOG_API_KEY}
      compression: zstd
      acknowledgements:
        enabled: true
      buffer:
        type: disk
        max_size: 268435488
        when_full: block
      batch:
        max_bytes: 1048576
        timeout_secs: 5

    archive:
      type: aws_s3
      inputs:
        - by_value.low_value
        - parse.dropped
      bucket: my-log-archive
      region: ${AWS_REGION}
      key_prefix: "date=%Y-%m-%d/"
      compression: gzip
      framing:
        method: newline_delimited
      encoding:
        codec: json
      batch:
        max_bytes: 10000000
```

Wiring check — every edge resolves within this block:

- `parse` <- `from_agents` (source)
- `redact_pii` <- `parse`
- `by_value` <- `redact_pii`
- `dd_logs` <- `by_value.high_value` (route branch)
- `archive` <- `by_value.low_value` (route branch) + `parse.dropped`
  (dead-letter output — consumed here)

No dangling inputs; the `.dropped` output has a home.

## 4. What to verify

Before rollout, confirm the config parses and behaves:

- **Validate** — parse, type-check, and healthcheck the topology
  in CI (`references/pipeline-config.md`):

  ```bash
  vector validate --config-yaml vector.yaml
  ```

- **Unit test** — a `tests:` stub asserting a debug line lands in
  the low-value branch and PII is masked. `insert_at` / `extract_from`
  and assertion VRL per `references/pipeline-config.md` and the
  testing section of `references/vrl.md`:

  ```yaml
  tests:
    - name: "debug log routes low-value and email is redacted"
      inputs:
        - type: log
          insert_at: parse
          log_fields:
            message: '{"level":"DEBUG","user":"a@b.com"}'
      outputs:
        - extract_from: by_value.low_value
          conditions:
            - type: vrl
              source: |
                assert_eq!(.level, "debug")
                assert_eq!(.user, "[REDACTED]")
  ```

- **Tap live** — watch the `route` outputs on a running instance to
  confirm events land on the branch you expect (needs the `api`
  block above; see `references/operations.md`):

  ```bash
  vector tap --outputs-of by_value.high_value --format json
  vector tap --outputs-of parse.dropped --format json
  ```

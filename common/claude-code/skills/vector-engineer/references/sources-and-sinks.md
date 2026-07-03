# Sources & Sinks

`kubernetes_logs` is the default agent source, but Vector
ingests from many places and ships to many destinations. This
is a quick-reference for the common non-Kubernetes sources and
for the archival/secondary sinks the cost-control section of
`references/datadog-integration.md` points at but never
configures. Verify every option key against Vector docs per
the skill's verify-first rule — component options change
between releases.

## Common sources

| Type | Ingests | Key required option(s) |
|------|---------|------------------------|
| `file` | Tails one or more log files (globbing) | `include` (list of paths/globs) |
| `journald` | The systemd journal | none beyond `type` |
| `http_server` | Events pushed over HTTP (formerly `http`) | `address` |
| `syslog` | Syslog over TCP/UDP/Unix socket | `address`, `mode` |
| `kafka` | A Kafka topic (consumer group) | `bootstrap_servers`, `group_id`, `topics` |
| `opentelemetry` | OTLP over gRPC/HTTP | `grpc.address` and/or `http.address` |

Notes:

- `http_server` was previously called the `http` source —
  update `type: http` to `type: http_server`.
- `file` also takes `read_from` (`beginning`/`end`),
  `exclude`, `ignore_older_secs`, and `data_dir` for
  checkpointing.
- `syslog` `mode` is one of `tcp`, `udp`, `unix`; `unix`
  additionally requires `path`.

Tail files on a host that is not running as a Kubernetes agent:

```yaml
sources:
  app_logs:
    type: file
    include:
      - /var/log/app/**/*.log
    read_from: beginning
```

Consume from a Kafka bus (aggregator ingesting an existing
stream):

```yaml
sources:
  bus:
    type: kafka
    bootstrap_servers: "${KAFKA_BOOTSTRAP}"   # host:port,host:port
    group_id: vector-aggregator
    topics:
      - app-logs
```

## Archival & secondary sinks

Not every event belongs in Datadog. Route low-value logs
(debug, health checks, high-volume access logs) to cheap
storage or a bus instead of paying per-ingest — this is the
concrete destination the cost-control tiering in
`references/datadog-integration.md` refers to. Pair these
sinks with a `route`/`filter` transform (see
`references/pipeline-config.md`) so only the high-value tier
reaches Datadog.

### `aws_s3` — cheap long-term archive

Writes batched, compressed objects to S3 (or any S3-compatible
store). Cheapest durable home for logs you must retain but
rarely query. Key options: `bucket`, `region`,
`key_prefix` (partitioning), `compression`, `framing`,
`encoding`, `batch`.

```yaml
sinks:
  archive:
    type: aws_s3
    inputs:
      - low_value            # e.g. a route branch, don't sample here
    bucket: my-log-archive
    region: "${AWS_REGION}"
    key_prefix: "date=%Y-%m-%d/"   # daily, hive-friendly partitions
    compression: gzip
    framing:
      method: newline_delimited
    encoding:
      codec: json
    batch:
      max_bytes: 10000000      # 10 MB uncompressed per object
```

Authentication: the sink uses the standard AWS credential
chain (instance/IRSA role, environment, or profile) — do not
hardcode keys in config. Use IAM roles where possible.

### `kafka` — fan-out to a bus

Publishes events to a Kafka topic so other consumers (SIEM,
another Vector aggregator, downstream analytics) can read the
same stream. Key options: `bootstrap_servers`, `topic`.

```yaml
sinks:
  bus_out:
    type: kafka
    inputs:
      - clean
    bootstrap_servers: "${KAFKA_BOOTSTRAP}"
    topic: processed-logs
```

## The long tail

Vector ships dozens more sources (cloud pull APIs, socket
listeners, other agents) and sinks (object stores, log/metric
backends, databases, message buses). This file covers the
common ones only. For anything else, look up the component's
page under `sources/` or `sinks/` in the Vector docs and
confirm its option keys there before use — do not assume an
option exists.

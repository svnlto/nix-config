# Monitoring Strategy

## Monitoring 101: Two Metric Types

Every system produces two kinds of metrics:

- **Work metrics** — throughput, success rate, error rate, latency.
  These measure what the system does for its users.
- **Resource metrics** — CPU, memory, disk, connections, queue depth.
  These measure what the system consumes internally.

Work metrics are alerts. Resource metrics are dashboards. Start with
work metrics; add resource metrics when you need to explain *why* a
work metric moved.

## The Four Golden Signals

Google SRE's four golden signals mapped to Datadog metric names:

| Signal | What it measures | Datadog metrics |
|--------|-----------------|-----------------|
| **Latency** | Time to serve a request | `trace.<service>.duration`, `trace.http.request.duration` |
| **Traffic** | Demand on the system | `trace.<service>.hits`, `aws.elb.request_count` |
| **Errors** | Failed request rate | `trace.<service>.errors`, `trace.http.request.errors` |
| **Saturation** | How full the system is | `system.cpu.user`, `system.mem.used`, `kubernetes.cpu.usage.total` |

For any service, if you can only have four graphs, use these four.

## USE Method (Infrastructure)

For every resource (CPU, memory, disk, network):

| Component | Utilization | Saturation | Errors |
|-----------|-------------|------------|--------|
| **CPU** | `system.cpu.user` + `system.cpu.system` | `system.load.1` / cores | `system.cpu.iowait` |
| **Memory** | `system.mem.pct_usable` | `system.swap.used` | OOM kill logs |
| **Disk** | `system.disk.in_use` | `system.io.await` | `system.disk.error` |
| **Network** | `system.net.bytes_sent/rcvd` | `system.net.packets_in.error` | `system.net.retrans_segs` |

USE works for infrastructure — physical or virtual resources with
hard limits. It does not work for services (use RED instead).

## RED Method (Services)

For every service in the request path:

| Signal | Metric | Meaning |
|--------|--------|---------|
| **Rate** | `trace.<service>.hits` | Requests per second |
| **Errors** | `trace.<service>.errors` / `trace.<service>.hits` | Error percentage |
| **Duration** | `trace.<service>.duration.by.resource_service.95p` | p95 latency |

RED works for request-driven services. It does not tell you *why*
something is slow — pair with USE on the underlying infrastructure.

## First 10 Monitors for a New Service

When onboarding a service to Datadog, create these monitors in order:

1. **Error rate** — `trace.<service>.errors / trace.<service>.hits > 5%`
   over 5 min. This is the single most important monitor.
2. **Latency p95** — `trace.<service>.duration.95p > threshold` over 5 min.
   Set threshold from baseline, not from wishful thinking.
3. **Throughput anomaly** — anomaly detection on `trace.<service>.hits`.
   Sudden drops in traffic are often worse than spikes.
4. **Apdex** — `trace.<service>.apdex` below acceptable threshold.
   User-perceived satisfaction score.
5. **Dependency error rate** — error rate on downstream service calls.
   Your service is only as healthy as its dependencies.
6. **Host/pod health** — `kubernetes.pods.running` or
   `system.cpu.user > 90%` sustained. Resource exhaustion signal.
7. **Log error spike** — log-based metric on ERROR/FATAL log lines.
   Catches errors that don't surface through APM traces.
8. **Disk/memory pressure** — `system.disk.in_use > 85%` or
   `system.mem.pct_usable < 15%`. Slow-burn resource exhaustion.
9. **Queue depth** — if the service uses queues, monitor consumer lag.
   `aws.sqs.approximate_number_of_messages_visible` or equivalent.
10. **SLO burn rate** — once the SLO is defined, alert on budget burn.
    See `slo-strategy.md` for burn-rate alerting patterns.

## Maturity Model

### Crawl — Infrastructure Basics

- Datadog Agent deployed on all hosts/containers
- Unified service tagging applied (`env`, `service`, `version`)
- Basic host monitors: CPU, memory, disk
- APM enabled with automatic instrumentation
- Logs flowing to Datadog with basic pipelines
- One overview dashboard per team

### Walk — Service Observability

- RED monitors on every service (error rate, latency, throughput)
- Service Map populated and dependencies visible
- Log pipelines parsing structured fields
- Custom dashboards per service with template variables
- Alert routing to correct Slack channels / PagerDuty services
- SLOs defined for customer-facing services

### Run — Proactive Operations

- SLO burn-rate alerting replacing threshold monitors where possible
- Error budget policies enforced (freeze deploys when budget exhausted)
- Cross-pillar correlation: click from metric → trace → log
- Synthetic tests covering critical user journeys
- Cost optimization: Metrics without Limits, log index tiers
- Notebook templates for incident investigation
- Service Catalog populated with ownership and runbooks

## Pup Execution

| Task | Command |
|------|---------|
| List services | `pup services list` |
| Create a monitor | `pup monitors create` or invoke `pup:monitoring-alerting` |
| Check existing monitors | `pup monitors list --query "service:<name>"` |
| View service dependencies | `pup apm dependencies` or invoke `pup:traces` |

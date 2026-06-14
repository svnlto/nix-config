# Operations & Production

## Worker Configuration (Go)

```go
w := worker.New(c, "my-queue", worker.Options{
    MaxConcurrentActivityExecutionSize:     200,   // activity slots
    MaxConcurrentWorkflowTaskExecutionSize: 200,   // workflow task slots
    MaxConcurrentLocalActivityExecutionSize: 200,  // local activity slots
    WorkerStopTimeout:                      30 * time.Second,
    DeadlockDetectionTimeout:              5 * time.Second,

    // Autoscaling pollers (recommended)
    WorkflowTaskPollerBehavior: worker.NewPollerBehaviorAutoscaling(
        worker.PollerBehaviorAutoscalingOptions{},
    ),
    ActivityTaskPollerBehavior: worker.NewPollerBehaviorAutoscaling(
        worker.PollerBehaviorAutoscalingOptions{},
    ),
})
```

**Tuning guidance:**

- Start with defaults, measure, then adjust
- Monitor `temporal_activity_schedule_to_start_latency` — high
  values mean not enough activity slots or workers
- Monitor `poll_success_rate` — low values mean too many pollers
  relative to work available
- Increase `MaxConcurrentActivityExecutionSize` for I/O-bound
  activities, decrease for CPU-bound
- `WorkerStopTimeout` gives in-flight activities time to complete
  on shutdown

## Graceful Shutdown

```go
w := worker.New(c, "my-queue", worker.Options{
    WorkerStopTimeout: 30 * time.Second,
})

// Start worker
go func() {
    if err := w.Run(worker.InterruptCh()); err != nil {
        log.Fatal(err)
    }
}()

// On SIGINT/SIGTERM: worker stops accepting new tasks,
// waits WorkerStopTimeout for in-flight tasks, then exits
```

Activities can detect shutdown via context:

```go
func LongActivity(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err() // clean exit on shutdown
        default:
            // do work, heartbeat
            activity.RecordHeartbeat(ctx, progress)
        }
    }
}
```

## CLI Operations

### Dev Server

```bash
# Persistent state, custom namespace, search attributes
temporal server start-dev \
    --db-filename /tmp/temporal.db \
    --namespace myapp \
    --search-attribute "Environment=Keyword" \
    --search-attribute "Priority=Int" \
    --dynamic-config-value "frontend.enableUpdateWorkflowExecution=true" \
    --log-level warn
# Web UI: http://localhost:8233
```

### Workflow Lifecycle

```bash
# Execute and wait for result
temporal workflow execute \
    --workflow-id order-123 \
    --type OrderWorkflow \
    --task-queue orders \
    --input '{"id": "123"}'

# Start (returns immediately)
temporal workflow start --workflow-id wf-1 --type MyWF --task-queue q

# Describe
temporal workflow describe --workflow-id wf-1

# Show event history
temporal workflow show --workflow-id wf-1
temporal workflow show --workflow-id wf-1 --output json > history.json

# List with query
temporal workflow list --query 'WorkflowType="OrderWorkflow" AND ExecutionStatus="Running"'

# Signal
temporal workflow signal --workflow-id wf-1 --name approve --input '{"by":"admin"}'

# Query
temporal workflow query --workflow-id wf-1 --name get-status

# Cancel (graceful) vs Terminate (immediate)
temporal workflow cancel --workflow-id wf-1
temporal workflow terminate --workflow-id wf-1 --reason "cleanup"

# Reset to a specific event
temporal workflow reset --workflow-id wf-1 --event-id 10 --reason "fix bug"
```

### Namespace & Search Attributes

```bash
temporal operator namespace create --namespace staging --retention 7d
temporal operator search-attribute create \
    --name CustomerId --type Int --namespace staging
```

### Schedules

```bash
temporal schedule create \
    --schedule-id daily-report \
    --cron "0 9 * * *" \
    --workflow-id report \
    --type ReportWorkflow \
    --task-queue reports
```

## Slot Suppliers

| Type | Use Case |
|------|----------|
| Fixed Size | Preset limits — recommended for most workloads |
| Resource-Based | Dynamic by CPU/memory targets (respects cgroups) |
| Custom | User-defined via `reserveSlot`/`releaseSlot` interface |

## Task Queue Design

- Define task queue names as **constants** shared between clients and workers
- Mismatches create duplicate queues without error
- Minimum 2 workers per task queue for resilience
- Scale task queues by adding partitions (default 4)
- Kubernetes: Use KEDA with `DescribeTaskQueueEnhanced` for autoscaling

## Observability

### Key Metrics (Prometheus)

| Metric | What It Tells You |
|--------|-------------------|
| `workflow_task_schedule_to_start_latency` | Workflow task queue backlog |
| `activity_task_schedule_to_start_latency` | Activity backlog — target <150ms |
| `temporal_activity_execution_latency` | Activity execution time |
| `temporal_sticky_cache_hit_total` | Cache hit rate |
| `temporal_sticky_cache_miss_total` | Cache misses — high = memory/history issue |
| `temporal_sticky_cache_total_forced_eviction_total` | Cache pressure |
| `temporal_worker_task_slots_available` | Available capacity |
| `temporal_worker_task_slots_used` | Current utilization |
| `temporal_request_failure` | Client-to-server errors |
| `temporal_request_latency` | Client-to-server latency |
| `temporal_long_request_failure` | Long poll failures |
| `workflow_task_replay_latency` | Replay time — large = big histories |
| `workflow_task_execution_latency` | >1-2s triggers deadlock detection |
| `poll_success_rate` | Poller efficiency — target ≥99% |

### Diagnostic Patterns

| Symptom | Diagnosis | Fix |
|---------|-----------|-----|
| High Schedule-to-Start + high CPU | Saturated workers | Scale horizontally |
| High Schedule-to-Start + low CPU | Insufficient pollers/slots | Increase config, check connectivity |
| Low Schedule-to-Start + low CPU | Over-provisioned | Scale down |
| High replay latency | Large histories, slow codecs, cache eviction | Continue-as-new, optimize payloads |

### Structured Logging

```go
logger := log.NewStructuredLogger(slog.Default())
c, err := client.Dial(client.Options{
    Logger: logger,
})
```

## Namespace Management

**Naming convention:** `<use-case>-<domain>-<environment>` (lowercase,
hyphens, max 39 chars on Cloud)

**When to split namespaces** (start with fewest possible):

- APS consumption threatens other workloads
- Different team access control requirements
- Production troubleshooting clarity needed
- Business-critical workload isolation
- Cross-namespace: use Nexus, not shared primitives

**Namespace limits (Temporal Cloud):**

- APS: 500 default (auto-scales on 7-day trailing)
- RPS: 2,000 default
- Custom search attributes: Bool/Datetime/Double/Int 20 each, Keyword 40

```bash
temporal operator namespace create --namespace staging --retention 7d
temporal operator search-attribute create \
    --name CustomerId --type Int --namespace staging
```

## Search Attributes

**Types:** Keyword (default choice), KeywordList, Text (prose), Bool,
Datetime, Double, Int

**Best practices:**

- Set at workflow start (0 Actions on Cloud)
- Batch `UpsertSearchAttributes` calls (1 Action regardless of count)
- Use Keyword type by default, not Text
- For filtering/querying only — not for business logic state
- NEVER include PII — stored unencrypted

## Scaling (Self-Hosted)

- Shard count is **immutable** after cluster creation — use 512 for
  production (default 4 is dev-only)
- Scaling sequence: Load → Measure → Scale → Repeat
- Database CPU at ~80% is the final bottleneck
- High shard lock latency (>5ms) → increase shard count

## Cost Optimization (Temporal Cloud)

- Every Activity = 1 Action; Child Workflow = 2 Actions;
  Heartbeat = 1 Action; Signal = 1 Action
- Search attributes at workflow start = 0 Actions
- Batch `UpsertSearchAttributes` = 1 Action (regardless of count)
- `SignalWithStart` = fewer Actions than Start + Signal
- Batch local activities = single billable Action
- Close workflows before extended sleep to move to retained storage

## Production Checklist

- [ ] Set explicit timeouts on all activities
- [ ] Heartbeat long-running activities (> 30s)
- [ ] Replay tests in CI for all workflow versions
- [ ] Monitor `schedule_to_start_latency` — alert at >150ms
- [ ] Monitor `poll_success_rate` — alert at <99%
- [ ] Configure `WorkerStopTimeout` for graceful shutdown
- [ ] Set namespace retention period (default: 30d Cloud, 72h OSS)
- [ ] Create custom search attributes for business queries
- [ ] Enable archival for compliance if needed
- [ ] Use payload codec for sensitive data
- [ ] Configure failure converter for PII in error messages
- [ ] Tune worker concurrency based on activity profile
- [ ] Minimum 2 workers per task queue
- [ ] Task queue names as shared constants
- [ ] Enable deletion protection on production namespaces

# Advanced Patterns

## Entity Workflow Pattern

Model each managed resource as one long-running workflow. Central
pattern for platform control planes, IDP automation, infrastructure
lifecycle.

```go
func ResourceWorkflow(ctx workflow.Context, state ResourceState) error {
    // Register handlers
    workflow.SetQueryHandler(ctx, "get-status", func() (ResourceState, error) {
        return state, nil
    })

    workflow.SetUpdateHandler(ctx, "configure",
        func(ctx workflow.Context, cfg Config) (ResourceState, error) {
            state.PendingConfig = &cfg
            return state, nil
        },
        workflow.UpdateHandlerOptions{
            Validator: func(cfg Config) error {
                if cfg.Name == "" { return fmt.Errorf("name required") }
                return nil
            },
        },
    )

    signalChan := workflow.GetSignalChannel(ctx, "delete")

    for !state.Deleted {
        // Check continue-as-new
        if workflow.GetInfo(ctx).GetCurrentHistoryLength() > 5000 {
            if workflow.AllHandlersFinished(ctx) {
                return workflow.NewContinueAsNewError(ctx, ResourceWorkflow, state)
            }
        }

        // Main loop — serializes all mutations
        selector := workflow.NewSelector(ctx)

        selector.AddReceive(signalChan, func(c workflow.ReceiveChannel, more bool) {
            c.Receive(ctx, nil)
            state.Deleted = true
        })

        // Process pending config via activity
        if state.PendingConfig != nil {
            cfg := *state.PendingConfig
            state.PendingConfig = nil
            future := workflow.ExecuteActivity(ctx, ApplyConfig, state.ResourceID, cfg)
            selector.AddFuture(future, func(f workflow.Future) {
                if err := f.Get(ctx, nil); err != nil {
                    state.LastError = err.Error()
                } else {
                    state.Config = cfg
                    state.Status = "configured"
                }
            })
        }

        selector.Select(ctx)
    }

    // Cleanup
    return workflow.ExecuteActivity(ctx, DestroyResource, state.ResourceID).Get(ctx, nil)
}
```

**Key principles:**

- Deterministic Workflow ID: `fmt.Sprintf("resource/%s", resourceID)`
- Compact state: control-plane facts only, bounded operation cache
- No workflow retry policy — retries belong on activities
- Continue-as-new from day one — check history length each iteration
- Wait for `AllHandlersFinished()` before continue-as-new

## Async Activity Completion

Activity returns immediately; external system completes it later.
Use for human-in-the-loop approvals, webhook callbacks.

```go
func ApprovalActivity(ctx context.Context, req ApprovalRequest) (string, error) {
    taskToken := activity.GetInfo(ctx).TaskToken

    // Send task token to external system (Slack, email, webhook)
    sendForApproval(req, taskToken)

    // Signal Temporal: "don't time out yet, result comes later"
    return "", activity.ErrResultPending
}

// External system calls this when approval arrives:
// client.CompleteActivity(ctx, taskToken, "approved", nil)
```

Set `StartToCloseTimeout` to cover the entire wait period (e.g.,
one week for human review).

## Local Activities

Execute in the same worker process — no separate task scheduling.
Lower latency, single billable Action for batch.

**Use ONLY when:**

- Same binary as the workflow
- Completes in seconds (not minutes)
- No global rate limiting needed
- No routing to specific workers needed

**Gotchas:**

- If execution exceeds 80% of Workflow Task Timeout (10s default),
  triggers heartbeating adding 3 events per heartbeat
- Multiple local activities fail/retry as a unit
- Heartbeating from local activities does nothing
- Signals/Updates delay until next heartbeat cycle during execution

```go
lao := workflow.LocalActivityOptions{
    ScheduleToCloseTimeout: 5 * time.Second,
}
ctx = workflow.WithLocalActivityOptions(ctx, lao)
err := workflow.ExecuteLocalActivity(ctx, QuickLookup, key).Get(ctx, &result)
```

## Schedules

### Overlap Policies

| Policy | Behavior |
|--------|----------|
| `Skip` (default) | Skip if previous still running |
| `BufferOne` | Queue one, start when previous completes |
| `BufferAll` | Unlimited queue, sequential |
| `CancelOther` | Cancel current, start new |
| `TerminateOther` | Terminate current immediately, start new |
| `AllowAll` | Unlimited concurrent |

### Schedule Features

- **Jitter:** Random offset (0 to max) to spread load
- **Exclusions:** Calendar expressions for holidays
- **Backfill:** Execute missed actions for a past period
- **Pause-on-failure:** Auto-pause if workflow completes with failure
- **Catchup window:** Which missed actions execute on recovery (default 1y)
- **LastCompletionResult:** Subsequent executions access last success's result
- **Start Delay:** For one-time future triggers, use Start Delay, not Schedules

```bash
temporal schedule create \
    --schedule-id daily-report \
    --cron "0 9 * * *" \
    --overlap-policy BufferOne \
    --workflow-id report \
    --type ReportWorkflow \
    --task-queue reports
```

## Multi-Tenant Patterns

| Pattern | Best For | Scale |
|---------|----------|-------|
| Task Queues per tenant | Most apps | 1000+ tenants |
| Single queue + Fairness Keys | Tiered SaaS, dynamic weights | 1000+ tenants |
| Shared WF + separate Activity queues | CPU-intensive activities | 1000+ tenants |
| Namespace per tenant | High-value, strict compliance | <50 tenants |

**Noisy neighbor mitigation:**

- Per-tenant rate limiting in application layer
- Tenant ID as search attribute for filtering
- Dedicated workers for problematic tenants
- Aggressive timeout policies

## Nexus (Cross-Namespace Communication)

Peer-to-peer service mesh for cross-namespace workflow calls.
Workers poll a Nexus task queue — no custom service deployment.

**Operation types:**

- **Synchronous:** Must complete within 10s handler deadline
- **Asynchronous:** Up to 60 days, backed by workflows

**Built-in features:**

- At-least-once semantics (handlers must be idempotent)
- Automatic retries with exponential backoff
- Circuit breaking: 5 consecutive errors → open → half-open after 60s

**Cancellation vs Termination:**

- Cancellation propagates to handler workflows (preferred)
- Termination abandons operations WITHOUT notifying handler

**Versioning:** Use distinct service names + task queues per version.

## Workflow ID Management

| Policy | Behavior |
|--------|---------|
| **Reuse: AllowDuplicate** | Closed workflow → same ID reusable |
| **Reuse: RejectDuplicate** | No reuse within retention period |
| **Conflict: Fail** (default) | Error if open workflow with same ID |
| **Conflict: UseExisting** | Returns existing run ID |
| **Conflict: TerminateExisting** | Terminates then spawns new |

`SignalWithStart` — atomically signals or starts a workflow (saves
an Action vs separate Start + Signal).

## Standalone Activities (Preview)

Top-level activity executions started by client, no workflow required.
Fewer billable Actions and lower latency. Same activity code works
for both standalone and workflow-initiated.

Requires Server v1.31.0+. Available in Go and Python SDKs.

## Platform Engineering Use Cases

Temporal as the durable execution layer under platform control planes:

- **Infrastructure lifecycle:** Entity workflow per resource, saga
  compensation for multi-step provisioning
- **Certificate rotation:** Scheduled workflows with overlap policies
- **CI/CD orchestration:** Fan-out/fan-in across build/test/deploy
- **Approval gates:** Signal-based pause → notification → wait for
  approval signal
- **Self-service IDP:** Encapsulate provisioning (GitHub + Terraform +
  Vault + DNS) in single durable workflow
- **Environment-specific routing:** Push workers into environments,
  route via task queues

Temporal orchestrates *around* Terraform/Pulumi — it adds durable
execution (approvals, retries, compensation, scheduling) that IaC
tools were not designed to provide.

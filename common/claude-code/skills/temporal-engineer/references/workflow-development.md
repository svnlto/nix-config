# Workflow & Activity Development

## Workflow Definition (Go)

```go
func OrderWorkflow(ctx workflow.Context, order Order) (OrderResult, error) {
    logger := workflow.GetLogger(ctx)
    logger.Info("Order workflow started", "orderID", order.ID)

    ao := workflow.ActivityOptions{
        StartToCloseTimeout: 30 * time.Second,
        RetryPolicy: &temporal.RetryPolicy{
            InitialInterval:    time.Second,
            BackoffCoefficient: 2.0,
            MaximumInterval:    time.Minute,
            MaximumAttempts:    5,
        },
    }
    ctx = workflow.WithActivityOptions(ctx, ao)

    var validated ValidatedOrder
    err := workflow.ExecuteActivity(ctx, ValidateOrder, order).Get(ctx, &validated)
    if err != nil {
        return OrderResult{}, err
    }

    var charged ChargeResult
    err = workflow.ExecuteActivity(ctx, ChargePayment, validated).Get(ctx, &charged)
    if err != nil {
        return OrderResult{}, err
    }

    return OrderResult{Status: "completed", ChargeID: charged.ID}, nil
}
```

## Activity Definition (Go)

```go
func ChargePayment(ctx context.Context, order ValidatedOrder) (ChargeResult, error) {
    // Heartbeat for long operations
    activity.RecordHeartbeat(ctx, "charging")

    // Check cancellation
    if ctx.Err() != nil {
        return ChargeResult{}, ctx.Err()
    }

    // Actual I/O happens here — HTTP calls, DB writes, etc.
    result, err := paymentGateway.Charge(order.Amount, order.PaymentMethod)
    if err != nil {
        return ChargeResult{}, err
    }

    return ChargeResult{ID: result.ID}, nil
}
```

## Timeout Types

| Timeout | Measures | When to Set |
|---------|----------|-------------|
| `ScheduleToCloseTimeout` | Total time from scheduled to completed (includes retries) | Always set — upper bound on total activity time |
| `StartToCloseTimeout` | Single attempt execution time | Set for per-attempt limits |
| `ScheduleToStartTimeout` | Queue wait time before worker picks up | Rarely needed — detects worker starvation |
| `HeartbeatTimeout` | Max gap between heartbeats | Set for activities > 30s |
| `WorkflowExecutionTimeout` | Total workflow lifetime | Set for workflows that must complete within a bound |
| `WorkflowRunTimeout` | Single run (before continue-as-new) | Set when using continue-as-new |

**Rule:** Always set at least one of `StartToCloseTimeout` or
`ScheduleToCloseTimeout`. Prefer `StartToCloseTimeout` when using
retries so each attempt has a bounded duration.

## Retry Policy

```go
retryPolicy := &temporal.RetryPolicy{
    InitialInterval:        time.Second,       // first retry delay
    BackoffCoefficient:     2.0,               // exponential multiplier
    MaximumInterval:        5 * time.Minute,   // cap on retry delay
    MaximumAttempts:        0,                 // 0 = unlimited (use timeout)
    NonRetryableErrorTypes: []string{"InvalidInput", "Forbidden"},
}
```

**Defaults:** Temporal retries activities indefinitely with
exponential backoff unless `MaximumAttempts` or a
`ScheduleToCloseTimeout` limits them. Non-retryable error types
short-circuit retries for known-unrecoverable failures.

## Continue-As-New

Workflows with unbounded iterations must use continue-as-new to avoid
history size limits (51,200 events / 50 MB).

```go
func ProcessorWorkflow(ctx workflow.Context, state ProcessorState) error {
    for {
        // Prefer SDK-provided check over hardcoded iteration count
        if workflow.GetInfo(ctx).GetCurrentHistoryLength() > 5000 {
            // CRITICAL: wait for all handlers to finish first
            if workflow.AllHandlersFinished(ctx) {
                return workflow.NewContinueAsNewError(ctx, ProcessorWorkflow, state)
            }
        }

        err := workflow.ExecuteActivity(ctx, ProcessBatch, state.Cursor).Get(ctx, &state.Cursor)
        if err != nil {
            return err
        }
        if state.Cursor == "" {
            return nil
        }
    }
}
```

**Rules:**

- NEVER call continue-as-new from signal/update handlers — only from
  the main workflow method
- Children do NOT carry over — parent's new instance loses ongoing children
- `LastCompletionResult` becomes inaccessible after continue-as-new
- Search attribute keys carry forward; values persist only for active executions
- Close before extended sleep/wait to move history to cheaper retained storage

## Determinism Constraints

Workflow code replays from history on recovery. Every replay must
produce the same sequence of commands. Violations cause
`NonDeterministicError`.

**Safe in workflows:**

- `workflow.ExecuteActivity()`, `workflow.ExecuteChildWorkflow()`
- `workflow.Sleep()`, `workflow.Now()`
- `workflow.Go()`, `workflow.NewSelector()`, `workflow.NewMutex()`
- `workflow.SideEffect()` — for random/UUID/time (cached on first run)
- `workflow.GetVersion()` — for branching on code changes

**Forbidden in workflows:**

- Network/file I/O — use activities
- `time.Now()`, `time.Sleep()` — use `workflow.Now()`, `workflow.Sleep()`
- `go func()` — use `workflow.Go()`
- `select` — use `workflow.NewSelector()`
- `sync.Mutex` — use `workflow.NewMutex()`
- `rand`, `uuid.New()` — use `workflow.SideEffect()`
- Global mutable state — use workflow-local variables
- Map iteration for commands — order not guaranteed

## Cancellation Handling

```go
func MyWorkflow(ctx workflow.Context) error {
    ao := workflow.ActivityOptions{
        StartToCloseTimeout:    time.Minute,
        WaitForCancellation:    true, // wait for activity to handle cancellation
    }
    ctx = workflow.WithActivityOptions(ctx, ao)

    // Use disconnected context for cleanup activities
    err := workflow.ExecuteActivity(ctx, MainWork).Get(ctx, nil)
    if errors.Is(ctx.Err(), workflow.ErrCanceled) {
        newCtx, _ := workflow.NewDisconnectedContext(ctx)
        return workflow.ExecuteActivity(newCtx, Cleanup).Get(newCtx, nil)
    }
    return err
}
```

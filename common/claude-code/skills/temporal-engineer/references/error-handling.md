# Error Handling & Compensation

## Failure Type Hierarchy

| Type | Source | Effect |
|------|--------|--------|
| `ApplicationFailure` | User code | Workflows: execution failure. Activities: auto-wrapped |
| `ActivityFailure` | Activity errors | Wraps activity error; `cause` has the real error |
| `ChildWorkflowFailure` | Child workflow | Wraps child error; `cause` has the real error |
| `TimeoutFailure` | Timeout exceeded | Contains last heartbeat details |
| `CancelledFailure` | Cancellation | Workflow/activity was cancelled |
| `TerminatedFailure` | Termination | Workflow was force-terminated |
| `ServerFailure` | Temporal Service | Infrastructure errors |
| `NexusOperationFailure` | Nexus | Includes endpoint/service/operation metadata |

## Critical Distinction: Task Failure vs Execution Failure

**Workflow Task Failure** — non-Application errors in workflows (panics
in Go). Retried indefinitely, trapping the workflow. Visible as
repeated task failures in the UI.

**Workflow Execution Failure** — only `ApplicationError` causes this.
Workflow is marked failed, retries stop.

In Go: returned errors behave like Application Failures. Panics
behave like non-Application Failures (task retried forever).

## Non-Retryable Errors

```go
// Activity-level: mark error as non-retryable
return temporal.NewNonRetryableApplicationError("invalid input", "InvalidInput", nil)

// Caller-level: configure in retry policy
retryPolicy := &temporal.RetryPolicy{
    NonRetryableErrorTypes: []string{"InvalidInput", "Forbidden", "NotFound"},
}
```

**Rule of thumb:** 4xx HTTP equivalents should be non-retryable.
5xx equivalents should retry with backoff.

## next_retry_delay Override

Override retry policy timing for the next attempt — useful for
respecting rate-limit headers (HTTP 429 Retry-After):

```go
return temporal.NewApplicationErrorWithOptions("rate limited",
    temporal.ApplicationErrorOptions{
        NextRetryDelay: 30 * time.Second,
    },
)
```

## Saga Compensation Pattern

Maintain an ordered list of compensating activities. Execute in
reverse on failure. Log compensation failures but continue remaining
rollbacks.

```go
func ProvisionWorkflow(ctx workflow.Context, req ProvisionRequest) error {
    var compensations []func(workflow.Context) error

    // Step 1: Create database
    var dbID string
    err := workflow.ExecuteActivity(ctx, CreateDatabase, req).Get(ctx, &dbID)
    if err != nil {
        return err
    }
    compensations = append(compensations, func(ctx workflow.Context) error {
        return workflow.ExecuteActivity(ctx, DeleteDatabase, dbID).Get(ctx, nil)
    })

    // Step 2: Create user
    err = workflow.ExecuteActivity(ctx, CreateUser, dbID, req.User).Get(ctx, nil)
    if err != nil {
        return compensate(ctx, compensations)
    }
    compensations = append(compensations, func(ctx workflow.Context) error {
        return workflow.ExecuteActivity(ctx, DeleteUser, dbID, req.User).Get(ctx, nil)
    })

    // Step 3: Configure DNS
    err = workflow.ExecuteActivity(ctx, ConfigureDNS, req.Domain, dbID).Get(ctx, nil)
    if err != nil {
        return compensate(ctx, compensations)
    }

    return nil
}

func compensate(ctx workflow.Context, compensations []func(workflow.Context) error) error {
    // Disconnected context — immune to parent cancellation
    ctx, _ = workflow.NewDisconnectedContext(ctx)
    // Reverse order
    for i := len(compensations) - 1; i >= 0; i-- {
        if err := compensations[i](ctx); err != nil {
            workflow.GetLogger(ctx).Error("compensation failed", "step", i, "error", err)
            // Continue remaining compensations
        }
    }
    return fmt.Errorf("provisioning failed, compensations executed")
}
```

## Failure Converter for Sensitive Data

Default behavior copies error messages and stack traces as plain text.
For PII/financial data, configure a custom Failure Converter to
encrypt `message` and `stack_trace` fields before they reach the
Temporal Service.

## Cancellation Patterns

**Activities only receive cancellation if they heartbeat AND have a
HeartbeatTimeout set.** Without heartbeats, the activity cannot detect
the cancellation request.

```go
func LongActivity(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err() // clean exit
        default:
            activity.RecordHeartbeat(ctx, progress)
            // do work
        }
    }
}
```

**Workflow cancellation cleanup:**

```go
err := workflow.ExecuteActivity(ctx, MainWork).Get(ctx, nil)
if errors.Is(ctx.Err(), workflow.ErrCanceled) {
    newCtx, _ := workflow.NewDisconnectedContext(ctx)
    return workflow.ExecuteActivity(newCtx, Cleanup).Get(newCtx, nil)
}
```

**If ALL activities handle cancellation gracefully, workflow status =
Complete (not Cancelled).**

# Message Passing & Child Workflows

## Signals

Signals deliver data to a running workflow asynchronously. The sender
does not wait for the workflow to process the signal.

```go
// Receive a signal (blocking)
var approval ApprovalInput
workflow.GetSignalChannel(ctx, "approve").Receive(ctx, &approval)
```

```go
// Receive signals concurrently with workflow.Go
func OrderWorkflow(ctx workflow.Context, order Order) error {
    var cancelRequested bool
    signalChan := workflow.GetSignalChannel(ctx, "cancel-order")

    workflow.Go(ctx, func(gCtx workflow.Context) {
        signalChan.Receive(gCtx, nil)
        cancelRequested = true
    })

    // Main workflow continues — checks cancelRequested as needed
    // ...
}
```

## Queries

Queries read workflow state synchronously. They must not mutate state
or perform I/O.

```go
err := workflow.SetQueryHandler(ctx, "get-status", func() (string, error) {
    return currentStatus, nil
})
```

```go
// Query from outside (client or CLI)
// temporal workflow query --workflow-id my-wf --name get-status
resp, err := client.QueryWorkflow(ctx, workflowID, "", "get-status")
```

## Updates

Updates combine signal + query: send data, run a handler, get a
return value. Supports validators for rejecting invalid updates.

```go
err := workflow.SetUpdateHandler(ctx, "update-address",
    func(ctx workflow.Context, addr Address) (Address, error) {
        currentAddress = addr
        return currentAddress, nil
    },
    workflow.UpdateHandlerOptions{
        Validator: func(addr Address) error {
            if addr.Zip == "" {
                return fmt.Errorf("zip required")
            }
            return nil
        },
    },
)
```

**Enable updates on dev server:**

```bash
temporal server start-dev \
    --dynamic-config-value "frontend.enableUpdateWorkflowExecution=true"
```

## Selectors (Multiplexing)

Selectors let you wait on multiple futures and channels
simultaneously — Temporal's replacement for Go's `select`.

```go
selector := workflow.NewSelector(ctx)

// Wait on activity result
future := workflow.ExecuteActivity(ctx, FetchData, id)
selector.AddFuture(future, func(f workflow.Future) {
    err := f.Get(ctx, &result)
    // handle result
})

// Wait on signal
ch := workflow.GetSignalChannel(ctx, "cancel")
selector.AddReceive(ch, func(c workflow.ReceiveChannel, more bool) {
    c.Receive(ctx, &signal)
    // handle signal
})

// Block until one fires
selector.Select(ctx)
```

## Child Workflows

Use child workflows to decompose complex workflows, enforce separate
retry/timeout policies, or run in different namespaces.

```go
cwo := workflow.ChildWorkflowOptions{
    WorkflowID:          "child-" + parentID,
    TaskQueue:           "child-queue",
    WorkflowRunTimeout:  time.Hour,
    ParentClosePolicy:   enums.PARENT_CLOSE_POLICY_TERMINATE,
}
ctx = workflow.WithChildOptions(ctx, cwo)

var result ChildResult
err := workflow.ExecuteChildWorkflow(ctx, ChildWorkflow, input).Get(ctx, &result)
```

**Parent Close Policy options:**

- `TERMINATE` — child terminated when parent completes (default)
- `ABANDON` — child continues independently
- `REQUEST_CANCEL` — cancellation sent to child

## Handler Best Practices

**Initialization ordering:** Initialize state BEFORE registering
handlers. Handlers may execute before the main workflow method
(Signal-with-Start, worker delays, continue-as-new). In Go: register
handlers only after initialization completes.

**Concurrency:** Handlers run single-threaded but interleave with the
main workflow when they block. Make handlers reentrant; use
`workflow.NewMutex(ctx)` for async handlers that share state.

**Work injection pattern:** Queue commands in handlers, process in the
main workflow event loop. Keeps all mutations serialized.

**Handler completion:** Ensure handlers finish before workflow
completion or continue-as-new. Use `workflow.AllHandlersFinished(ctx)`
to check. Set Handler Unfinished Policy to Abandon if completion is
not required.

**Signal errors in Go:** Errors in signal handlers behave like
Application Failures — the entire workflow fails. Only return errors
for truly unrecoverable conditions.

**Update deduplication:** Server-side by Update ID per-run. After
continue-as-new, implement application-level dedup (server dedup is
per-run only).

## When to Use Each Pattern

| Need | Pattern |
|------|---------|
| Fire-and-forget data to workflow | Signal |
| Read current workflow state | Query |
| Send data + get response | Update |
| Wait on multiple async operations | Selector |
| Decompose into sub-workflows | Child Workflow |
| Long-lived event-driven workflow | Signal + Selector loop |
| Request-response from external | Signal in + Signal out (or Update) |
| Atomic start + signal | `SignalWithStart` (saves an Action) |

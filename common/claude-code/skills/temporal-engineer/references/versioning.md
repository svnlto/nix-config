# Versioning Workflows

## The Problem

Workflow code changes while executions are in-flight. Replay must
produce the same commands as the original execution. Changing the
command sequence without versioning causes `NonDeterministicError`.

## Strategy 1: Patching with GetVersion (Go)

Use `workflow.GetVersion()` to branch code paths. Existing workflows
replay the old path; new workflows take the new path.

### Step 1 — Add versioned branch

```go
v := workflow.GetVersion(ctx, "ChangeNotification", workflow.DefaultVersion, 1)
if v == workflow.DefaultVersion {
    // Old path — existing workflows replay this
    err = workflow.ExecuteActivity(ctx, SendEmail, data).Get(ctx, nil)
} else {
    // New path — new workflows run this
    err = workflow.ExecuteActivity(ctx, SendSlackNotification, data).Get(ctx, nil)
}
```

### Step 2 — After all old executions complete, remove old path

```go
v := workflow.GetVersion(ctx, "ChangeNotification", 1, 1)
// Only new path remains
err = workflow.ExecuteActivity(ctx, SendSlackNotification, data).Get(ctx, nil)
```

### Step 3 — Eventually remove GetVersion entirely

```go
// All traces of versioning removed once no v1 executions exist
err = workflow.ExecuteActivity(ctx, SendSlackNotification, data).Get(ctx, nil)
```

### Multi-step versioning

```go
v := workflow.GetVersion(ctx, "Step1", workflow.DefaultVersion, 2)
switch {
case v == workflow.DefaultVersion:
    // original code
case v == 1:
    // first change
case v == 2:
    // latest change
}
```

## Strategy 2: Worker Versioning (Build ID)

Assign Build IDs to workers. Temporal routes workflow tasks to workers
with compatible Build IDs.

```bash
# Register a build ID as the default for a task queue
temporal task-queue versioning insert-assignment-rule \
    --task-queue my-queue \
    --build-id "v2.0" \
    --percentage 100

# Existing workflows keep running on old workers
# New workflows start on v2.0 workers
```

**Worker code:**

```go
w := worker.New(c, "my-queue", worker.Options{
    BuildID:                 "v2.0",
    UseBuildIDForVersioning: true,
})
```

**When to prefer worker versioning:**

- Major refactors that touch many activities
- Multiple teams deploying independently
- Blue-green deployment patterns
- When patching becomes unwieldy

## Combining Both Strategies

Use worker versioning for major changes, patching for minor changes
within a build.

## Safe Deployment Checklist

1. **Export replay histories** from production workflows before
   changing code
2. **Add replay tests** to CI for each active version
3. **Use `GetVersion`** for any change that alters the command
   sequence (new/removed/reordered activities, changed timers)
4. **Deploy new workers alongside old** — both must run until all
   old-version executions complete
5. **Monitor for `NonDeterministicError`** in worker logs/metrics
6. **Clean up old branches** only after confirming zero in-flight
   executions using that version

## What Requires Versioning

| Change | Versioning Needed? |
|--------|-------------------|
| Add/remove/reorder activity calls | Yes |
| Change timer duration | Yes |
| Add/remove signal handler registration | Yes |
| Change activity input/output types | Yes (or use data converter) |
| Change activity retry policy | No (not replayed) |
| Change activity timeout | No (not replayed) |
| Add new query handler | No (queries are side-effect-free) |
| Change activity implementation (not signature) | No (activity code is not replayed) |
| Add logging in workflow | No (logging is side-effect-free) |

# Testing Temporal Workflows

## Unit Testing with Test Suite (Go)

The SDK's `testsuite` package provides a simulated environment that
runs workflows without a server.

```go
type OrderWorkflowSuite struct {
    suite.Suite
    testsuite.WorkflowTestSuite
    env *testsuite.TestWorkflowEnvironment
}

func (s *OrderWorkflowSuite) SetupTest() {
    s.env = s.NewTestWorkflowEnvironment()
}

func (s *OrderWorkflowSuite) AfterTest(suiteName, testName string) {
    s.env.AssertExpectations(s.T())
}

func (s *OrderWorkflowSuite) Test_Success() {
    s.env.ExecuteWorkflow(OrderWorkflow, testOrder)
    s.True(s.env.IsWorkflowCompleted())
    s.NoError(s.env.GetWorkflowError())

    var result OrderResult
    s.NoError(s.env.GetWorkflowResult(&result))
    s.Equal("completed", result.Status)
}

func TestOrderWorkflow(t *testing.T) {
    suite.Run(t, new(OrderWorkflowSuite))
}
```

## Mocking Activities

```go
func (s *OrderWorkflowSuite) Test_PaymentFailure() {
    // Mock specific activity to return error
    s.env.OnActivity(ChargePayment, mock.Anything, mock.Anything).
        Return(ChargeResult{}, errors.New("payment declined"))

    s.env.ExecuteWorkflow(OrderWorkflow, testOrder)

    s.True(s.env.IsWorkflowCompleted())
    err := s.env.GetWorkflowError()
    s.Error(err)
}

func (s *OrderWorkflowSuite) Test_ActivityParamValidation() {
    // Intercept activity to validate params
    s.env.OnActivity(ValidateOrder, mock.Anything, mock.Anything).
        Return(func(ctx context.Context, order Order) (ValidatedOrder, error) {
            s.Equal("test-123", order.ID) // assert param
            return ValidatedOrder{ID: order.ID}, nil
        })

    s.env.ExecuteWorkflow(OrderWorkflow, Order{ID: "test-123"})
    s.True(s.env.IsWorkflowCompleted())
    s.NoError(s.env.GetWorkflowError())
}
```

## Testing Signals and Timers

```go
func (s *OrderWorkflowSuite) Test_ApprovalTimeout() {
    // Register delayed callback to send signal
    s.env.RegisterDelayedCallback(func() {
        s.env.SignalWorkflow("approve", ApprovalInput{Name: "admin"})
    }, time.Minute*5)

    s.env.ExecuteWorkflow(ApprovalWorkflow, input)
    s.True(s.env.IsWorkflowCompleted())
}

func (s *OrderWorkflowSuite) Test_TimerFires() {
    // Time is auto-skipped — workflow.Sleep(ctx, 24*time.Hour)
    // completes instantly in tests
    s.env.ExecuteWorkflow(DailyWorkflow)
    s.True(s.env.IsWorkflowCompleted())
}
```

## Replay Testing

Replay tests catch non-determinism errors by replaying recorded
history against current workflow code. Run these in CI on every code
change.

```go
func TestReplayWorkflowHistory(t *testing.T) {
    replayer := worker.NewWorkflowReplayer()
    replayer.RegisterWorkflow(OrderWorkflow)

    // Replay from JSON history file
    err := replayer.ReplayWorkflowHistoryFromJSONFile(nil, "testdata/order_workflow_history.json")
    require.NoError(t, err)
}
```

**Export history for replay tests:**

```bash
temporal workflow show \
    --workflow-id my-wf-123 \
    --output json > testdata/order_workflow_history.json
```

**When to add replay tests:**

- Before any workflow code change
- For each workflow version in production
- In CI — blocks deploy if replay fails

## Integration Testing with Dev Server

For end-to-end tests, start a local dev server:

```go
func TestIntegration_OrderWorkflow(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }

    c, err := client.Dial(client.Options{HostPort: "localhost:7233"})
    require.NoError(t, err)
    defer c.Close()

    w := worker.New(c, "test-queue", worker.Options{})
    w.RegisterWorkflow(OrderWorkflow)
    w.RegisterActivity(ValidateOrder)
    w.RegisterActivity(ChargePayment)
    go w.Run(worker.InterruptCh())
    defer w.Stop()

    we, err := c.ExecuteWorkflow(context.Background(),
        client.StartWorkflowOptions{
            ID:        "test-" + uuid.New(),
            TaskQueue: "test-queue",
        },
        OrderWorkflow,
        testOrder,
    )
    require.NoError(t, err)

    var result OrderResult
    require.NoError(t, we.Get(context.Background(), &result))
    assert.Equal(t, "completed", result.Status)
}
```

## Disabling Workflow Cache for Tests

Force full replay on every workflow task (useful for side effect
testing):

```go
worker.SetStickyWorkflowCacheSize(0)
w := worker.New(c, "task-queue", worker.Options{})
```

## Failure Injection Testing

Run these before production to validate resilience:

**Worker shutdown test:**

1. Kill all workers to create task backlog
2. Restart workers
3. Validate: idempotency holds, replay integrity, backlog drains

**Worker restart churn:**

1. Restart workers frequently in a loop
2. Validate: sticky cache invalidation, replay latency under churn

**Network connectivity loss:**

1. Use NetworkPolicy, ToxiProxy, or Chaos Mesh to sever connections
2. Validate: CPU behavior during reconnection storms

**Downstream saturation:**

1. Launch more workflows than downstream services can handle
2. Validate: rate limiting produces increased latency, not lost work

## Load Testing

- Establish baseline metrics BEFORE testing
- Define success criteria in business terms, not just throughput
- Build reusable test harnesses with start/stop/cleanup
- One variable at a time; record start/stop times
- Post-test: identify metric gaps, update retry/timeout/versioning

## Deployment Verification

Two-phase deployment for safe code changes:

1. **Verify mode:** Replay 10 hours of recent production histories
   against new code using Temporal's Replayer
2. **Run mode:** Deploy if replay passes

```go
// Build worker with verify/run mode
if mode == "verify" {
    replayer := worker.NewWorkflowReplayer()
    replayer.RegisterWorkflow(MyWorkflow)
    // Replay recent histories from production
} else {
    w := worker.New(c, "my-queue", worker.Options{})
    // Normal worker startup
}
```

**Note:** Encrypted payloads may be undecryptable for replay testing —
plan codec server access accordingly.

## Test Strategy Summary

| Test Type | Speed | Catches | When to Run |
|-----------|-------|---------|-------------|
| Unit (test suite) | Fast | Logic errors, activity interactions | Every commit |
| Replay | Fast | Non-determinism from code changes | Every commit (CI) |
| Integration (dev server) | Slow | End-to-end, real timing, retries | Pre-merge, nightly |
| Failure injection | Slow | Resilience, idempotency, backlog recovery | Pre-production |
| Load | Slow | Throughput, downstream capacity, rate limiting | Pre-production |

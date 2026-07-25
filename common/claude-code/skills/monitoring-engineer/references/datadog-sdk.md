# Datadog Go SDK

Datadog APM and custom metrics for Go services via
`dd-trace-go` and `datadog-go`.

## 1. Tracer Setup

Initialize the tracer once in `main()` with unified
service tags. The tracer connects to the Datadog Agent
over localhost or a cluster-local address:

```go
package main

import (
	"log"
	"net/http"

	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

func main() {
	tracer.Start(
		tracer.WithService("api"),
		tracer.WithEnv("production"),
		tracer.WithServiceVersion("1.0.0"),
		tracer.WithAgentAddr("datadog-agent:8126"),
	)
	defer tracer.Stop()

	mux := http.NewServeMux()
	mux.HandleFunc("/api/health", handleHealth)

	log.Println("server listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}

func handleHealth(
	w http.ResponseWriter, r *http.Request,
) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}
```

`tracer.Stop()` flushes any remaining spans to the agent
before the process exits. Always defer it immediately
after `tracer.Start()`.

## 2. HTTP/gRPC Instrumentation

### HTTP

Wrap an existing `http.ServeMux` to automatically trace
every incoming request:

```go
package main

import (
	"log"
	"net/http"

	httptrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/net/http"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

func main() {
	tracer.Start(
		tracer.WithService("api"),
		tracer.WithEnv("production"),
		tracer.WithServiceVersion("1.0.0"),
	)
	defer tracer.Stop()

	// Option A: wrap an existing handler.
	mux := http.NewServeMux()
	mux.HandleFunc("/api/orders", handleOrders)
	wrapped := httptrace.WrapHandler(
		mux, "api", "/",
	)

	log.Fatal(http.ListenAndServe(":8080", wrapped))
}

func mainAlternative() {
	tracer.Start(
		tracer.WithService("api"),
		tracer.WithEnv("production"),
		tracer.WithServiceVersion("1.0.0"),
	)
	defer tracer.Stop()

	// Option B: use a traced mux that instruments all
	// registered routes automatically.
	mux := httptrace.NewServeMux()
	mux.HandleFunc("/api/orders", handleOrders)

	log.Fatal(http.ListenAndServe(":8080", mux))
}

func handleOrders(
	w http.ResponseWriter, r *http.Request,
) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"orders":[]}`))
}
```

### gRPC

Use interceptors for both server and client-side tracing:

```go
package main

import (
	"log"
	"net"

	grpctrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/google.golang.org/grpc"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
	"google.golang.org/grpc"
)

func main() {
	tracer.Start(
		tracer.WithService("api"),
		tracer.WithEnv("production"),
		tracer.WithServiceVersion("1.0.0"),
	)
	defer tracer.Stop()

	// Server with tracing interceptor.
	server := grpc.NewServer(
		grpc.UnaryInterceptor(
			grpctrace.UnaryServerInterceptor(
				grpctrace.WithServiceName("api"),
			),
		),
		grpc.StreamInterceptor(
			grpctrace.StreamServerInterceptor(
				grpctrace.WithServiceName("api"),
			),
		),
	)

	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	log.Fatal(server.Serve(lis))
}

func newClientConn(addr string) (*grpc.ClientConn, error) {
	// Client with tracing interceptor. Trace context
	// propagates automatically across service boundaries.
	return grpc.Dial(
		addr,
		grpc.WithUnaryInterceptor(
			grpctrace.UnaryClientInterceptor(),
		),
		grpc.WithStreamInterceptor(
			grpctrace.StreamClientInterceptor(),
		),
		grpc.WithInsecure(),
	)
}
```

## 3. Custom Spans

Create spans to trace specific operations. Child spans
inherit the trace ID from the parent context, forming a
tree visible in the Datadog trace view:

```go
package processing

import (
	"context"
	"fmt"

	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/ext"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

// ProcessOrder creates a parent span and delegates to
// child operations, each with their own nested span.
func ProcessOrder(
	ctx context.Context, orderID string,
) error {
	span, ctx := tracer.StartSpanFromContext(
		ctx, "order.process",
	)
	defer span.Finish()

	span.SetTag("order.id", orderID)
	span.SetTag(ext.ResourceName, "ProcessOrder")

	if err := validateOrder(ctx, orderID); err != nil {
		span.Finish(tracer.WithError(err))
		return fmt.Errorf("validation failed: %w", err)
	}

	if err := chargePayment(ctx, orderID); err != nil {
		span.Finish(tracer.WithError(err))
		return fmt.Errorf("payment failed: %w", err)
	}

	return nil
}

// validateOrder is a child span nested under the parent.
func validateOrder(
	ctx context.Context, orderID string,
) error {
	span, _ := tracer.StartSpanFromContext(
		ctx, "order.validate",
	)
	defer span.Finish()

	span.SetTag("order.id", orderID)
	span.SetTag(ext.ResourceName, "ValidateOrder")

	// Validation logic here.
	return nil
}

// chargePayment is another child span at the same level
// as validateOrder, both children of order.process.
func chargePayment(
	ctx context.Context, orderID string,
) error {
	span, _ := tracer.StartSpanFromContext(
		ctx, "payment.charge",
	)
	defer span.Finish()

	span.SetTag("order.id", orderID)
	span.SetTag(ext.ResourceName, "ChargePayment")
	span.SetTag("payment.provider", "stripe")

	// Payment logic here.
	return nil
}
```

The resulting trace tree:

```text
order.process (parent)
├── order.validate (child)
└── payment.charge (child)
```

When an error occurs, `span.Finish(tracer.WithError(err))`
sets the `error` tag and `error.msg` on the span, making
it appear red in the Datadog trace flamegraph.

## 4. DogStatsD Custom Metrics

Use the `datadog-go` client to emit custom metrics to the
Datadog Agent over DogStatsD (UDP port 8125):

```go
package metrics

import (
	"log"
	"time"

	"github.com/DataDog/datadog-go/v5/statsd"
)

// Client is the package-level DogStatsD client.
var Client *statsd.Client

// Init creates a buffered DogStatsD client. Call once
// at startup.
func Init() {
	var err error
	Client, err = statsd.New(
		"datadog-agent:8125",
		statsd.WithBufferPoolSize(10),
		statsd.WithMaxMessagesPerPayload(100),
	)
	if err != nil {
		log.Fatalf(
			"failed to create statsd client: %v", err,
		)
	}
}

// RecordOrderProcessed increments the order counter
// with status and service tags.
func RecordOrderProcessed(status string) {
	Client.Incr(
		"orders.processed",
		[]string{
			"status:" + status,
			"service:api",
		},
		1,
	)
}

// RecordProcessingTime sends a histogram observation
// for order processing duration.
func RecordProcessingTime(
	elapsed time.Duration, orderType string,
) {
	Client.Histogram(
		"order.processing_time",
		elapsed.Seconds(),
		[]string{
			"order_type:" + orderType,
			"service:api",
		},
		1,
	)
}

// RecordQueueDepth sets the current queue depth gauge.
func RecordQueueDepth(depth int) {
	Client.Gauge(
		"queue.depth",
		float64(depth),
		[]string{"service:api"},
		1,
	)
}

// RecordRequestSize sends a distribution metric for
// HTTP request body size. Distributions are aggregated
// server-side, giving globally accurate percentiles.
func RecordRequestSize(size int) {
	Client.Distribution(
		"http.request.size",
		float64(size),
		[]string{"service:api"},
		1,
	)
}
```

**Histogram vs Distribution:** Histograms are aggregated
on the agent before shipping. Distributions are aggregated
server-side by Datadog, giving globally accurate
percentiles across all hosts. Prefer Distribution for
latency and size metrics.

## 5. Unified Service Tagging

Unified service tagging correlates traces, metrics, and
logs by requiring three tags on every telemetry signal:
`service`, `env`, and `version`.

### Environment Variables

Set these on the application process. The tracer, metrics
client, and log integrations pick them up automatically:

```bash
DD_SERVICE=api
DD_ENV=production
DD_VERSION=1.0.0
```

### Kubernetes Labels and Annotations

Apply standard labels to pod templates so the Datadog
Agent can inject tags into all telemetry it collects:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    tags.datadoghq.com/service: api
    tags.datadoghq.com/env: production
    tags.datadoghq.com/version: "1.0.0"
spec:
  template:
    metadata:
      labels:
        tags.datadoghq.com/service: api
        tags.datadoghq.com/env: production
        tags.datadoghq.com/version: "1.0.0"
      annotations:
        # Log source and service for log pipeline
        # correlation.
        ad.datadoghq.com/api.logs: >-
          [{"source":"go","service":"api"}]
    spec:
      containers:
        - name: api
          image: registry.example.com/api:1.0.0
          env:
            - name: DD_SERVICE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/service']
            - name: DD_ENV
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/env']
            - name: DD_VERSION
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/version']
            - name: DD_AGENT_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
```

The `tags.datadoghq.com/*` labels on the pod are read by
the Datadog Admission Controller, which can also inject
the `DD_*` environment variables automatically when the
controller is enabled.

## 6. Runtime Metrics

Enable Go runtime metrics to get goroutine counts, GC
stats, and memory allocation data without custom code:

```go
package main

import (
	"log"
	"net/http"

	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

func main() {
	tracer.Start(
		tracer.WithService("api"),
		tracer.WithEnv("production"),
		tracer.WithServiceVersion("1.0.0"),
		tracer.WithRuntimeMetrics(),
		tracer.WithProfilerCodeHotspots(true),
		tracer.WithProfilerEndpoints(true),
	)
	defer tracer.Stop()

	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### Metrics Emitted

| Metric                               | Description                  |
|---------------------------------------|------------------------------|
| `runtime.go.num_goroutine`           | Active goroutines            |
| `runtime.go.num_gc`                  | Total GC cycles              |
| `runtime.go.mem_stats.heap_alloc`    | Bytes allocated on heap      |
| `runtime.go.mem_stats.heap_sys`      | Bytes obtained from OS       |
| `runtime.go.mem_stats.heap_idle`     | Idle heap bytes              |
| `runtime.go.mem_stats.heap_inuse`    | In-use heap bytes            |
| `runtime.go.mem_stats.heap_released` | Bytes released to OS         |
| `runtime.go.num_cpu`                 | Available logical CPUs       |
| `runtime.go.mem_stats.gc_pause`      | GC pause duration            |

### Profiler Integration

- `WithProfilerCodeHotspots(true)` links traces to the
  continuous profiler, showing which code paths consume
  CPU and memory within a traced request.
- `WithProfilerEndpoints(true)` aggregates profiling data
  per endpoint, letting you see which routes are the most
  resource-intensive.

### When to Use Runtime vs Custom Metrics

**Runtime metrics** answer infrastructure questions:

- Is the service leaking goroutines?
- Is GC pressure increasing after the last deploy?
- How much heap is allocated under load?

**Custom metrics** (DogStatsD) answer business questions:

- How many orders were processed per minute?
- What is the p99 payment processing latency?
- How deep is the work queue right now?

Use both. Runtime metrics are free once enabled. Custom
metrics require code changes but provide domain-specific
observability that runtime metrics cannot.

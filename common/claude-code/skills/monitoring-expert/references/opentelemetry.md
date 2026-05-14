# OpenTelemetry (Go)

Go OpenTelemetry SDK patterns for distributed tracing
and metrics in production services.

## 1. SDK Bootstrap

Initialize `TracerProvider` and `MeterProvider` with OTLP
exporters and semantic resource attributes. Return a single
shutdown function the caller defers:

```go
package telemetry

import (
	"context"
	"errors"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

// initTelemetry sets up tracing and metrics providers.
// The returned shutdown function flushes and closes both
// providers. Always defer it in main.
func initTelemetry(
	ctx context.Context,
) (shutdown func(context.Context) error, err error) {
	var shutdownFuncs []func(context.Context) error

	shutdown = func(ctx context.Context) error {
		var errs []error
		for _, fn := range shutdownFuncs {
			errs = append(errs, fn(ctx))
		}
		return errors.Join(errs...)
	}

	// Build a resource describing this service.
	res, err := resource.Merge(
		resource.Default(),
		resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName("my-service"),
			semconv.ServiceVersion("1.2.0"),
			semconv.DeploymentEnvironmentName("production"),
		),
	)
	if err != nil {
		return shutdown, err
	}

	// Trace exporter — OTLP over HTTP.
	traceExporter, err := otlptracehttp.New(ctx)
	if err != nil {
		return shutdown, err
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(traceExporter,
			sdktrace.WithBatchTimeout(5*time.Second),
		),
		sdktrace.WithResource(res),
		sdktrace.WithSampler(
			sdktrace.ParentBased(
				sdktrace.TraceIDRatioBased(0.1),
			),
		),
	)
	shutdownFuncs = append(shutdownFuncs, tp.Shutdown)
	otel.SetTracerProvider(tp)

	// Metric exporter — OTLP over HTTP.
	metricExporter, err := otlpmetrichttp.New(ctx)
	if err != nil {
		return shutdown, err
	}

	mp := metric.NewMeterProvider(
		metric.WithReader(
			metric.NewPeriodicReader(metricExporter,
				metric.WithInterval(30*time.Second),
			),
		),
		metric.WithResource(res),
	)
	shutdownFuncs = append(shutdownFuncs, mp.Shutdown)
	otel.SetMeterProvider(mp)

	// Set W3C TraceContext propagator globally.
	otel.SetTextMapPropagator(
		propagation.TraceContext{},
	)

	return shutdown, nil
}
```

Usage in `main`:

```go
func main() {
	ctx := context.Background()

	shutdown, err := initTelemetry(ctx)
	if err != nil {
		log.Fatalf("init telemetry: %v", err)
	}
	defer func() {
		// Give in-flight spans 5s to flush.
		ctx, cancel := context.WithTimeout(
			context.Background(), 5*time.Second,
		)
		defer cancel()
		if err := shutdown(ctx); err != nil {
			log.Printf("telemetry shutdown: %v", err)
		}
	}()

	// ... start server
}
```

For gRPC export, replace `otlptracehttp` with
`otlptracegrpc` and `otlpmetrichttp` with
`otlpmetricgrpc`. The provider setup is identical.

## 2. Manual Spans

Create spans manually for business logic that is not
covered by auto-instrumentation. Always pass the child
context returned by `Start` to downstream calls:

```go
package order

import (
	"context"
	"fmt"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

var tracer = otel.Tracer("order-service")

// ProcessOrder demonstrates parent/child spans with
// attributes, events, and error recording.
func ProcessOrder(
	ctx context.Context, orderID string, amount float64,
) error {
	// Parent span — covers the full operation.
	ctx, span := tracer.Start(ctx, "order.process",
		trace.WithAttributes(
			attribute.String("order.id", orderID),
			attribute.Float64("order.amount", amount),
		),
	)
	defer span.End()

	span.AddEvent("validation.started")

	if err := validateOrder(ctx, orderID); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return fmt.Errorf("validate order: %w", err)
	}

	span.AddEvent("validation.passed",
		trace.WithAttributes(
			attribute.String("order.id", orderID),
		),
	)

	if err := chargePayment(ctx, orderID, amount); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return fmt.Errorf("charge payment: %w", err)
	}

	span.SetStatus(codes.Ok, "order processed")
	return nil
}

// validateOrder creates a child span by receiving the
// parent context from ProcessOrder.
func validateOrder(
	ctx context.Context, orderID string,
) error {
	ctx, span := tracer.Start(ctx, "order.validate")
	defer span.End()

	span.SetAttributes(
		attribute.String("order.id", orderID),
	)

	// ... validation logic
	return nil
}

// chargePayment is another child span nested under the
// parent ProcessOrder span.
func chargePayment(
	ctx context.Context, orderID string, amount float64,
) error {
	_, span := tracer.Start(ctx, "order.charge_payment")
	defer span.End()

	span.SetAttributes(
		attribute.String("order.id", orderID),
		attribute.Float64("payment.amount", amount),
		attribute.String("payment.currency", "USD"),
	)

	// ... payment logic
	return nil
}
```

The resulting trace tree:

```text
order.process
  +-- order.validate
  +-- order.charge_payment
```

Key rules:

- **Always defer `span.End()`** immediately after `Start`.
- **Always pass the child context** returned by `Start` to
  downstream functions so child spans are linked.
- **Call `RecordError` before `SetStatus`** so the error
  event appears inside the span before it is marked failed.
- **Use `codes.Ok` explicitly** only when the success
  status carries meaning. Spans without a status default
  to `Unset`, which backends treat as success.

## 3. Context Propagation

W3C TraceContext propagation ensures trace IDs survive
across service boundaries and goroutines.

### Global propagator setup

Set this once during bootstrap (already done in section 1):

```go
otel.SetTextMapPropagator(propagation.TraceContext{})
```

### Incoming HTTP requests

When using `otelhttp` (section 4), trace context is
extracted from the `traceparent` header automatically.
For manual extraction:

```go
package server

import (
	"net/http"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"
)

func handler(w http.ResponseWriter, r *http.Request) {
	// Extract trace context from incoming headers.
	propagator := otel.GetTextMapPropagator()
	ctx := propagator.Extract(
		r.Context(),
		propagation.HeaderCarrier(r.Header),
	)

	// ctx now carries the remote trace/span IDs.
	// Any spans started with this ctx are children of
	// the upstream span.
	ctx, span := tracer.Start(ctx, "handle.request")
	defer span.End()

	// ... handle request using ctx
}
```

### Outgoing HTTP requests

Inject trace context into outgoing requests so the
downstream service continues the same trace:

```go
func callDownstream(
	ctx context.Context, url string,
) (*http.Response, error) {
	req, err := http.NewRequestWithContext(
		ctx, http.MethodGet, url, nil,
	)
	if err != nil {
		return nil, err
	}

	// Inject traceparent header.
	otel.GetTextMapPropagator().Inject(
		ctx, propagation.HeaderCarrier(req.Header),
	)

	return http.DefaultClient.Do(req)
}
```

Or use `otelhttp.NewTransport` (section 4) which handles
injection automatically.

### Goroutine propagation

Always pass the context explicitly. Goroutines that
capture a context variable by closure risk using a stale
or cancelled context:

```go
func processItems(
	ctx context.Context, items []Item,
) {
	ctx, span := tracer.Start(ctx, "process.items")
	defer span.End()

	for _, item := range items {
		item := item // capture loop variable

		// Pass ctx as a function argument, not via closure.
		go func(ctx context.Context, it Item) {
			_, span := tracer.Start(
				ctx, "process.single_item",
			)
			defer span.End()

			span.SetAttributes(
				attribute.String("item.id", it.ID),
			)

			// ... process item
		}(ctx, item)
	}
}
```

## 4. HTTP/gRPC Instrumentation

### HTTP server

Wrap your `http.Handler` with `otelhttp.NewHandler` to
get automatic span creation, status code recording, and
request/response size metrics:

```go
package main

import (
	"net/http"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/orders", handleOrders)
	mux.HandleFunc("/api/health", handleHealth)

	// Wrap the entire mux. Each request gets a span
	// named after the route.
	handler := otelhttp.NewHandler(mux, "http-server",
		otelhttp.WithMessageEvents(
			otelhttp.ReadEvents,
			otelhttp.WriteEvents,
		),
	)

	http.ListenAndServe(":8080", handler)
}

func handleOrders(w http.ResponseWriter, r *http.Request) {
	// r.Context() already carries the span created by
	// otelhttp. Child spans inherit it automatically.
	ctx := r.Context()

	result, err := processOrder(ctx)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(result)
}
```

### HTTP client

Wrap the transport so outgoing requests automatically
create client spans and inject `traceparent` headers:

```go
package client

import (
	"context"
	"net/http"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

// NewHTTPClient returns an *http.Client with automatic
// tracing on every outbound request.
func NewHTTPClient() *http.Client {
	return &http.Client{
		Transport: otelhttp.NewTransport(
			http.DefaultTransport,
		),
	}
}

func fetchUpstream(
	ctx context.Context, url string,
) (*http.Response, error) {
	client := NewHTTPClient()

	req, err := http.NewRequestWithContext(
		ctx, http.MethodGet, url, nil,
	)
	if err != nil {
		return nil, err
	}

	// The transport injects traceparent and creates a
	// client span automatically.
	return client.Do(req)
}
```

### gRPC server

Use interceptors from `otelgrpc` for automatic span
creation on every RPC:

```go
package main

import (
	"net"

	"google.golang.org/grpc"
	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"

	pb "example.com/api/v1"
)

func main() {
	lis, _ := net.Listen("tcp", ":50051")

	srv := grpc.NewServer(
		grpc.StatsHandler(otelgrpc.NewServerHandler()),
	)

	pb.RegisterOrderServiceServer(srv, &orderServer{})
	srv.Serve(lis)
}
```

### gRPC client

```go
package main

import (
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"

	pb "example.com/api/v1"
)

func newOrderClient() (pb.OrderServiceClient, error) {
	conn, err := grpc.NewClient(
		"order-service:50051",
		grpc.WithTransportCredentials(
			insecure.NewCredentials(),
		),
		grpc.WithStatsHandler(
			otelgrpc.NewClientHandler(),
		),
	)
	if err != nil {
		return nil, err
	}

	return pb.NewOrderServiceClient(conn), nil
}
```

**Note:** The `otelgrpc` library now recommends
`StatsHandler` over the older `UnaryServerInterceptor` /
`StreamServerInterceptor` approach. Use `StatsHandler`
for new code. The interceptor API still works but is
considered legacy.

## 5. Span-to-Log Correlation

Extract trace and span IDs from the context and inject
them into structured logs so you can jump from a log line
to the corresponding trace in your backend.

### Manual injection with slog

```go
package logging

import (
	"context"
	"log/slog"

	"go.opentelemetry.io/otel/trace"
)

// LoggerWithTrace returns a child logger with trace_id
// and span_id fields if the context carries an active
// span.
func LoggerWithTrace(
	ctx context.Context, logger *slog.Logger,
) *slog.Logger {
	span := trace.SpanFromContext(ctx)
	if !span.SpanContext().IsValid() {
		return logger
	}

	return logger.With(
		slog.String(
			"trace_id",
			span.SpanContext().TraceID().String(),
		),
		slog.String(
			"span_id",
			span.SpanContext().SpanID().String(),
		),
	)
}
```

Usage:

```go
func handleRequest(
	ctx context.Context, orderID string,
) {
	logger := LoggerWithTrace(ctx, slog.Default())

	logger.InfoContext(ctx, "processing order",
		slog.String("order_id", orderID),
	)
	// Output includes trace_id and span_id automatically.
}
```

### Automatic injection via custom slog.Handler

A handler wrapper that extracts trace context from the
Go context on every log call, so callers never need to
think about it:

```go
package logging

import (
	"context"
	"log/slog"

	"go.opentelemetry.io/otel/trace"
)

// TraceHandler wraps any slog.Handler and automatically
// adds trace_id and span_id from the context to every
// log record that has an active span.
type TraceHandler struct {
	inner slog.Handler
}

// NewTraceHandler wraps an existing handler.
func NewTraceHandler(h slog.Handler) *TraceHandler {
	return &TraceHandler{inner: h}
}

func (h *TraceHandler) Enabled(
	ctx context.Context, level slog.Level,
) bool {
	return h.inner.Enabled(ctx, level)
}

func (h *TraceHandler) Handle(
	ctx context.Context, r slog.Record,
) error {
	span := trace.SpanFromContext(ctx)
	if span.SpanContext().IsValid() {
		r.AddAttrs(
			slog.String(
				"trace_id",
				span.SpanContext().TraceID().String(),
			),
			slog.String(
				"span_id",
				span.SpanContext().SpanID().String(),
			),
		)
	}
	return h.inner.Handle(ctx, r)
}

func (h *TraceHandler) WithAttrs(
	attrs []slog.Attr,
) slog.Handler {
	return &TraceHandler{
		inner: h.inner.WithAttrs(attrs),
	}
}

func (h *TraceHandler) WithGroup(
	name string,
) slog.Handler {
	return &TraceHandler{
		inner: h.inner.WithGroup(name),
	}
}
```

Wire it up during init:

```go
func initLogger() {
	jsonHandler := slog.NewJSONHandler(os.Stdout,
		&slog.HandlerOptions{Level: slog.LevelInfo},
	)
	traceHandler := NewTraceHandler(jsonHandler)
	slog.SetDefault(slog.New(traceHandler))
}
```

Correlated output:

```json
{
  "time": "2026-05-14T10:23:01Z",
  "level": "INFO",
  "msg": "processing order",
  "order_id": "ord_abc123",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7"
}
```

With this handler in place, every `slog.InfoContext(ctx,
...)` call automatically gets trace correlation without
any manual `logger.With(...)` calls.

## 6. Sampling

Sampling controls what fraction of traces are recorded
and exported. Choosing the right strategy balances
observability cost against visibility.

### Head-based sampling (at span creation)

The decision is made when the root span starts, before
any downstream work. All child spans inherit the parent
decision.

```go
package telemetry

import (
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

// ProductionSampler samples 10% of new traces but always
// respects the parent decision for child spans that
// arrive from upstream services.
func ProductionSampler() sdktrace.Sampler {
	return sdktrace.ParentBased(
		sdktrace.TraceIDRatioBased(0.1),
	)
}

// DevelopmentSampler records every trace. Use in dev and
// staging where volume is low.
func DevelopmentSampler() sdktrace.Sampler {
	return sdktrace.AlwaysSample()
}

// LoadTestSampler drops all traces. Use during load tests
// where tracing overhead skews latency measurements.
func LoadTestSampler() sdktrace.Sampler {
	return sdktrace.NeverSample()
}
```

Apply a sampler to the TracerProvider:

```go
tp := sdktrace.NewTracerProvider(
	sdktrace.WithSampler(ProductionSampler()),
	sdktrace.WithBatcher(exporter),
	sdktrace.WithResource(res),
)
```

### ParentBased behavior

`ParentBased` is a composite sampler that delegates
based on whether the incoming span has a parent:

| Scenario                     | Decision              |
|------------------------------|-----------------------|
| No parent (root span)       | Uses the inner sampler (e.g. 10% ratio) |
| Parent is sampled            | Always sample         |
| Parent is not sampled        | Never sample          |
| Remote parent, sampled       | Always sample         |
| Remote parent, not sampled   | Never sample          |

This ensures consistent sampling across a distributed
trace. If the root service decides to sample, every
downstream service records its spans too.

### Head-based vs tail-based sampling

**Head-based** (decided at span creation):

- Simple, no extra infrastructure.
- Low overhead — unsampled spans are never created.
- Blind to outcome: you might drop an error trace.
- Use when: cost control matters more than catching
  every error, or volume is manageable.

**Tail-based** (decided after the trace completes):

- Requires a trace collector (e.g. OpenTelemetry
  Collector with `tailsamplingprocessor`).
- Can keep all error traces and drop boring ones.
- Higher memory cost: must buffer complete traces.
- Use when: you need guaranteed visibility into errors
  and slow requests regardless of sample rate.

A common production pattern combines both:

```text
Services: head-based at 100% (send everything)
    |
    v
OTel Collector: tail-based sampling
    - Keep all traces with errors
    - Keep all traces > 2s duration
    - Sample 10% of remaining traces
    |
    v
Backend (Jaeger / Tempo / Datadog)
```

### Configuring tail-based sampling in OTel Collector

This is configured in the Collector, not in Go code:

```yaml
processors:
  tail_sampling:
    decision_wait: 10s
    num_traces: 100000
    policies:
      - name: errors
        type: status_code
        status_code:
          status_codes:
            - ERROR
      - name: slow-requests
        type: latency
        latency:
          threshold_ms: 2000
      - name: percentage
        type: probabilistic
        probabilistic:
          sampling_percentage: 10
```

### Choosing a sampling rate

| Environment | Sampler                    | Rate |
|-------------|----------------------------|------|
| Development | `AlwaysSample()`           | 100% |
| Staging     | `AlwaysSample()`           | 100% |
| Production  | `TraceIDRatioBased(0.1)`   | 10%  |
| Load test   | `NeverSample()`            | 0%   |

Adjust the production rate based on traffic volume and
backend cost. At 10,000 RPS, even 1% sampling produces
~8.6 million traces per day.

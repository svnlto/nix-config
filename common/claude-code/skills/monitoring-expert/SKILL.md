---
name: monitoring-expert
description: >-
  Implements application observability in Go: structured logging
  with slog, Prometheus metrics instrumentation, OpenTelemetry
  distributed tracing, Datadog APM with dd-trace-go, application
  profiling with pprof, and load testing with k6. Use when
  instrumenting Go services, adding structured logging, emitting
  Prometheus metrics, setting up distributed tracing, profiling
  CPU/memory, running load tests, or deploying monitoring
  infrastructure with Terraform.
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "2.0.0"
  domain: devops
  triggers: >-
    monitoring, observability, logging, slog, metrics, tracing,
    OpenTelemetry, Prometheus, pprof, profiling, Datadog APM,
    dd-trace-go, DogStatsD, k6, load testing, benchmarks
  role: specialist
  scope: implementation
  output-format: code
  related-skills: devops-engineer, debugging-wizard, architecture-designer
---

# Monitoring Expert

Application observability specialist for Go services:
structured logging, metrics instrumentation, distributed tracing,
profiling, and performance testing.

## Core Workflow

1. **Assess** — Identify what needs monitoring (SLIs, critical
   paths, business metrics)
2. **Instrument** — Add logging, metrics, and traces to the
   application
3. **Collect** — Configure aggregation and storage (Prometheus
   scrape, OTLP endpoint, Datadog agent); verify data arrives
   before proceeding
4. **Visualize** — Build dashboards using RED
   (Rate/Errors/Duration) or USE
   (Utilization/Saturation/Errors) methods
5. **Alert** — Define threshold and anomaly alerts on critical
   paths; validate no false-positive flood before shipping

## Scope

This skill covers **application-side** instrumentation and
testing. For platform-level Datadog monitors, SLOs, dashboards,
error budgets, and Terraform observability resources, use the
`sre-engineer` skill.

## Quick-Start Examples

### Structured Logging (Go slog)

```go
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/google/uuid"
)

type ctxKey string

const requestIDKey ctxKey = "request_id"

func newLogger() *slog.Logger {
	return slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level:     slog.LevelInfo,
		AddSource: true,
	}))
}

func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Request-ID")
		if id == "" {
			id = uuid.NewString()
		}
		ctx := context.WithValue(r.Context(), requestIDKey, id)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func logFromContext(ctx context.Context, logger *slog.Logger) *slog.Logger {
	if id, ok := ctx.Value(requestIDKey).(string); ok {
		return logger.With("request_id", id)
	}
	return logger
}
```

### Prometheus Metrics (Go)

```go
package main

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequests = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "http_requests_total",
		Help: "Total HTTP requests",
	}, []string{"method", "route", "status"})

	httpDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "http_request_duration_seconds",
		Help:    "HTTP request latency",
		Buckets: []float64{0.05, 0.1, 0.3, 0.5, 1, 2, 5},
	}, []string{"method", "route"})
)

func metricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		timer := prometheus.NewTimer(
			httpDuration.WithLabelValues(r.Method, r.URL.Path),
		)
		defer timer.ObserveDuration()

		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		next.ServeHTTP(rw, r)

		httpRequests.WithLabelValues(
			r.Method, r.URL.Path, http.StatusText(rw.statusCode),
		).Inc()
	})
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

func main() {
	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.Handler())
	// register app routes...
	http.ListenAndServe(":8080", metricsMiddleware(mux))
}
```

### OpenTelemetry Tracing (Go)

```go
package main

import (
	"context"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
)

func initTracer(ctx context.Context) (*sdktrace.TracerProvider, error) {
	exporter, err := otlptracehttp.New(ctx,
		otlptracehttp.WithEndpointURL("http://otel-collector:4318"),
	)
	if err != nil {
		return nil, err
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName("order-service"),
			semconv.ServiceVersion("1.0.0"),
			semconv.DeploymentEnvironment("production"),
		)),
	)
	otel.SetTracerProvider(tp)
	return tp, nil
}

var tracer = otel.Tracer("order-service")

func processOrder(ctx context.Context, orderID string) error {
	ctx, span := tracer.Start(ctx, "order.process")
	defer span.End()

	span.SetAttributes(attribute.String("order.id", orderID))

	if err := saveOrder(ctx, orderID); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return err
	}

	span.SetStatus(codes.Ok, "")
	return nil
}
```

### Prometheus Alerting Rule

```yaml
groups:
  - name: api.rules
    rules:
      - alert: HighErrorRate
        expr: |
          rate(http_requests_total{status=~"5.."}[5m])
          / rate(http_requests_total[5m]) > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: >-
            Error rate above 5% on {{ $labels.route }}
```

### k6 Load Test

```js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '5m', target: 50 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('https://api.example.com/orders');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(1);
}
```

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Logging | `references/structured-logging.md` | Go slog, JSON logging, correlation |
| Metrics | `references/prometheus-metrics.md` | Go promhttp, counters, histograms |
| Tracing | `references/opentelemetry.md` | Go OTel SDK, spans, OTLP |
| Datadog APM | `references/datadog-sdk.md` | dd-trace-go, DogStatsD, custom metrics |
| Performance Testing | `references/performance-testing.md` | k6 load tests, Go benchmarks |
| Profiling | `references/application-profiling.md` | Go pprof, CPU/memory profiling |
| Monitoring Infra | `references/terraform-monitoring-infra.md` | Datadog agent, OTel collector, Terraform |

## Constraints

### MUST DO

- Use structured logging (JSON) via `slog`
- Include request IDs for correlation
- Set up alerts for critical paths
- Monitor business metrics, not just technical
- Use appropriate metric types (counter/gauge/histogram)
- Implement health check endpoints
- Use `slog` for structured logging (not `log` or `logrus`)

### MUST NOT DO

- Log sensitive data (passwords, tokens, PII)
- Alert on every error (alert fatigue)
- Use string interpolation in logs (use structured fields)
- Skip correlation IDs in distributed systems
- Duplicate platform-level monitoring covered by sre-engineer

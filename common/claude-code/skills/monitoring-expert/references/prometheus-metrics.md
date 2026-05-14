# Prometheus Metrics (Go)

Go Prometheus client instrumentation patterns using
`github.com/prometheus/client_golang`.

## 1. Metric Types

Use the right metric type for the right signal:

| Type      | Behavior               | Use For                        |
|-----------|------------------------|--------------------------------|
| Counter   | Monotonically increases | Requests, errors, bytes sent  |
| Gauge     | Goes up and down       | In-flight, queue depth, temp   |
| Histogram | Bucketized distribution | Latency, response size         |
| Summary   | Client-side quantiles  | Avoid — can't aggregate        |

**Avoid Summary.** Quantiles computed on individual
instances cannot be aggregated across instances. Use
Histogram with `histogram_quantile()` in PromQL instead.

```go
package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// Counter: total HTTP requests received.
var httpRequestsTotal = promauto.NewCounter(
	prometheus.CounterOpts{
		Name: "http_requests_total",
		Help: "Total number of HTTP requests received.",
	},
)

// Gauge: currently in-flight requests.
var httpRequestsInFlight = promauto.NewGauge(
	prometheus.GaugeOpts{
		Name: "http_requests_in_flight",
		Help: "Number of HTTP requests currently being processed.",
	},
)

// Histogram: request duration with custom buckets tuned
// for a typical web service (5ms to 10s).
var httpRequestDuration = promauto.NewHistogram(
	prometheus.HistogramOpts{
		Name: "http_request_duration_seconds",
		Help: "Duration of HTTP requests in seconds.",
		Buckets: []float64{
			0.005, 0.01, 0.025, 0.05, 0.1,
			0.25, 0.5, 1.0, 2.5, 5.0, 10.0,
		},
	},
)
```

## 2. HTTP Middleware

Use `promhttp` instrument wrappers for automatic RED
metrics (Rate, Errors, Duration) without manual code:

```go
package main

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	requestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Duration of HTTP requests in seconds.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"code", "method"},
	)

	requestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests.",
		},
		[]string{"code", "method"},
	)

	requestsInFlight = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "http_requests_in_flight",
			Help: "Number of in-flight HTTP requests.",
		},
	)
)

// InstrumentHandler wraps an http.Handler with automatic
// RED metrics: duration, count, and in-flight tracking.
func InstrumentHandler(
	handler http.Handler,
) http.Handler {
	// Order matters: outermost wrapper runs first.
	// InFlight -> Duration -> Counter -> handler
	return promhttp.InstrumentHandlerInFlight(
		requestsInFlight,
		promhttp.InstrumentHandlerDuration(
			requestDuration,
			promhttp.InstrumentHandlerCounter(
				requestsTotal,
				handler,
			),
		),
	)
}

func main() {
	app := http.NewServeMux()
	app.HandleFunc("/api/orders", handleOrders)

	// Wrap the entire mux with metrics instrumentation.
	instrumented := InstrumentHandler(app)

	http.ListenAndServe(":8080", instrumented)
}

func handleOrders(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}
```

This gives you three metrics automatically:

- `http_request_duration_seconds` (histogram)
- `http_requests_total` (counter, by code + method)
- `http_requests_in_flight` (gauge)

## 3. Custom Business Metrics

Track domain-specific signals alongside infrastructure
metrics:

```go
package metrics

import (
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// CounterVec: orders by processing result.
var ordersProcessedTotal = promauto.NewCounterVec(
	prometheus.CounterOpts{
		Name: "orders_processed_total",
		Help: "Total orders processed, partitioned by status.",
	},
	[]string{"status"},
)

// GaugeFunc: queue depth pulled from an external source.
// The function is called on every scrape — keep it cheap.
var orderQueueDepth = promauto.NewGaugeFunc(
	prometheus.GaugeOpts{
		Name: "order_queue_depth",
		Help: "Current number of orders waiting in the queue.",
	},
	func() float64 {
		return float64(orderQueue.Len())
	},
)

// HistogramVec: processing duration by order type.
var orderProcessingDuration = promauto.NewHistogramVec(
	prometheus.HistogramOpts{
		Name: "order_processing_duration_seconds",
		Help: "Time spent processing an order.",
		Buckets: []float64{
			0.01, 0.05, 0.1, 0.5, 1.0, 5.0, 30.0,
		},
	},
	[]string{"order_type"},
)

// ProcessOrder demonstrates incrementing and observing
// business metrics in application code.
func ProcessOrder(order Order) error {
	start := time.Now()

	err := doProcessOrder(order)

	// Always record duration, even on failure.
	orderProcessingDuration.
		WithLabelValues(order.Type).
		Observe(time.Since(start).Seconds())

	if err != nil {
		ordersProcessedTotal.
			WithLabelValues("failure").Inc()
		return err
	}

	ordersProcessedTotal.
		WithLabelValues("success").Inc()
	return nil
}
```

## 4. Label Cardinality

Labels multiply the number of time series a single metric
creates. Unbounded labels cause cardinality explosions that
crash Prometheus.

**Good labels** (bounded, small set of values):

| Label         | Example Values         | Cardinality |
|---------------|------------------------|-------------|
| `method`      | GET, POST, PUT, DELETE | ~5          |
| `status_code` | 200, 201, 400, 404, 500 | ~10       |
| `service`     | orders, payments, auth | ~10         |
| `endpoint`    | /api/v1/orders, /health | ~20        |

**Bad labels** (unbounded, grows with traffic/users):

| Label        | Why It Is Bad                       |
|--------------|-------------------------------------|
| `user_id`    | Grows with every new user           |
| `request_id` | Unique per request — infinite       |
| `email`      | PII and unbounded                   |
| `full_url`   | Query params make it infinite       |

**Cardinality explosion example:**

```text
1,000 users x 10 endpoints x 5 methods = 50,000 time series

That is 50,000 series from ONE metric. With a 15s scrape
interval and 30-day retention, that is ~250 billion samples
for a single metric.
```

**Rule of thumb:** if a label can have more than ~100
distinct values, do not use it as a metric label. Use
structured logging instead and query it in your log
aggregator.

## 5. Scrape Endpoint

Expose metrics on a separate port to keep them off the
public-facing API. Use a custom registry for testability
and to avoid global state pollution:

```go
package main

import (
	"log"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// Custom registry — no default process/go collectors.
	// Add them explicitly if you want them.
	registry := prometheus.NewRegistry()
	registry.MustRegister(prometheus.NewProcessCollector(
		prometheus.ProcessCollectorOpts{},
	))
	registry.MustRegister(prometheus.NewGoCollector())

	// Register application metrics against custom registry.
	factory := promauto.With(registry)

	requestsTotal := factory.NewCounter(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total HTTP requests.",
		},
	)

	// Application server on :8080.
	appMux := http.NewServeMux()
	appMux.HandleFunc("/api/health", func(
		w http.ResponseWriter, r *http.Request,
	) {
		requestsTotal.Inc()
		w.WriteHeader(http.StatusOK)
	})

	// Metrics server on :9090 — not exposed publicly.
	metricsMux := http.NewServeMux()
	metricsMux.Handle("/metrics", promhttp.HandlerFor(
		registry,
		promhttp.HandlerOpts{
			ErrorHandling: promhttp.HTTPErrorOnError,
		},
	))

	// Start both servers.
	go func() {
		log.Println("metrics server listening on :9090")
		log.Fatal(http.ListenAndServe(
			":9090", metricsMux,
		))
	}()

	log.Println("app server listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", appMux))
}
```

Benefits of a custom registry:

- **Testability**: create a fresh registry per test, no
  global state leaking between tests.
- **No surprise collectors**: only metrics you register
  appear at `/metrics`.
- **Separate port**: metrics stay off the public API,
  reducing attack surface and avoiding accidental exposure
  behind a load balancer.

## 6. Naming Conventions

### Suffixes

| Suffix     | Metric Type | Example                         |
|------------|-------------|---------------------------------|
| `_total`   | Counter     | `http_requests_total`           |
| `_seconds` | Histogram   | `http_request_duration_seconds` |
| `_bytes`   | Histogram   | `http_response_size_bytes`      |
| `_info`    | Gauge (1)   | `build_info`                    |
| `_ratio`   | Gauge       | `cache_hit_ratio`               |

### Rules

- **Always use base units.** Seconds not milliseconds,
  bytes not kilobytes. Prometheus convention and PromQL
  functions expect base units.
- **Prefix with subsystem.** This namespaces metrics and
  prevents collisions across services.
- **Use snake_case.** No camelCase, no dots, no hyphens.

### Common Metrics Mapped to Correct Names

| What You Measure         | Correct Name                         |
|--------------------------|--------------------------------------|
| HTTP request count       | `http_requests_total`                |
| HTTP request latency     | `http_request_duration_seconds`      |
| HTTP response body size  | `http_response_size_bytes`           |
| DB query latency         | `db_query_duration_seconds`          |
| DB connection pool size  | `db_connections_in_use`              |
| Cache hit count          | `cache_hits_total`                   |
| Cache miss count         | `cache_misses_total`                 |
| Queue depth              | `queue_depth`                        |
| Order processing time    | `order_processing_duration_seconds`  |
| Build/version metadata   | `build_info`                         |
| Error count by type      | `errors_total`                       |
| Bytes received           | `network_receive_bytes_total`        |

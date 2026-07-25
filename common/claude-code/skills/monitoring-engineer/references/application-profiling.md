# Application Profiling (Go)

Go pprof and Datadog continuous profiler for production
performance analysis and bottleneck identification.

## 1. `net/http/pprof` Setup

The blank import registers all pprof handlers on
`DefaultServeMux`:

```go
import _ "net/http/pprof"
```

Run pprof on a separate port so it never shares the
application listener:

```go
go func() {
    http.ListenAndServe(":6060", nil)
}()
```

In production, never expose pprof on a public interface.
Use a separate mux bound to localhost with basic auth:

```go
package debug

import (
	"crypto/subtle"
	"net/http"
	"net/http/pprof"
	"os"
)

// NewPprofServer returns an HTTP server that serves pprof
// endpoints on localhost only, protected by basic auth.
func NewPprofServer(addr string) *http.Server {
	mux := http.NewServeMux()

	mux.HandleFunc("/debug/pprof/", pprof.Index)
	mux.HandleFunc("/debug/pprof/cmdline", pprof.Cmdline)
	mux.HandleFunc("/debug/pprof/profile", pprof.Profile)
	mux.HandleFunc("/debug/pprof/symbol", pprof.Symbol)
	mux.HandleFunc("/debug/pprof/trace", pprof.Trace)

	return &http.Server{
		Addr:    addr,
		Handler: basicAuth(mux),
	}
}

func basicAuth(next http.Handler) http.Handler {
	user := os.Getenv("PPROF_USER")
	pass := os.Getenv("PPROF_PASS")

	return http.HandlerFunc(func(
		w http.ResponseWriter, r *http.Request,
	) {
		u, p, ok := r.BasicAuth()
		if !ok ||
			subtle.ConstantTimeCompare(
				[]byte(u), []byte(user),
			) != 1 ||
			subtle.ConstantTimeCompare(
				[]byte(p), []byte(pass),
			) != 1 {
			w.Header().Set(
				"WWW-Authenticate",
				`Basic realm="pprof"`,
			)
			http.Error(
				w, "Unauthorized",
				http.StatusUnauthorized,
			)
			return
		}
		next.ServeHTTP(w, r)
	})
}
```

Usage in `main.go`:

```go
pprofSrv := debug.NewPprofServer("127.0.0.1:6060")
go func() {
    if err := pprofSrv.ListenAndServe(); err != nil {
        slog.Error("pprof server failed",
            slog.Any("error", err),
        )
    }
}()
```

## 2. CPU Profiling

Capture a 30-second CPU profile:

```bash
curl -o cpu.prof \
  http://localhost:6060/debug/pprof/profile?seconds=30
```

Open in the web UI (interactive flame graph):

```bash
go tool pprof -http=:8081 cpu.prof
```

Interactive CLI analysis:

```bash
go tool pprof cpu.prof
```

Useful commands inside the CLI:

```text
(pprof) top 20
(pprof) top 20 -cum
(pprof) list funcName
(pprof) web
```

`top 20` ranks functions by flat time (time spent in the
function itself). `top 20 -cum` ranks by cumulative time
(including callees). `list funcName` shows annotated
source with per-line CPU cost.

### Flame graph interpretation

- **Wide bars** indicate functions where the most CPU time
  is spent. Start optimization here.
- **Tall stacks** indicate deep call chains. Look for
  unnecessary abstraction layers.
- The x-axis is **not** time; it is alphabetical or stack
  depth. Width is what matters.

### What to look for

- Unexpected functions in the top 10 (e.g., JSON
  marshaling dominating a compute service).
- Regex compilation (`regexp.Compile`) in hot paths.
  Pre-compile to a package-level `*regexp.Regexp`.
- Reflection-heavy serialization. Consider code
  generation or hand-written marshalers.
- Excessive `runtime.mallocgc` — points to allocation
  pressure (see Memory Profiling).

## 3. Memory Profiling

Capture a heap profile:

```bash
curl -o heap.prof \
  http://localhost:6060/debug/pprof/heap
```

Analyze **currently held** memory (find leaks):

```bash
go tool pprof -inuse_space heap.prof
```

Analyze **cumulative allocations** (find GC pressure):

```bash
go tool pprof -alloc_space heap.prof
```

Open either in the web UI:

```bash
go tool pprof -http=:8081 -inuse_space heap.prof
go tool pprof -http=:8081 -alloc_space heap.prof
```

### Key `runtime.MemStats` fields

| Field          | Meaning                              |
|----------------|--------------------------------------|
| `HeapAlloc`    | Bytes in live heap objects            |
| `HeapInuse`    | Bytes in spans with live objects      |
| `NumGC`        | Total GC cycles completed            |
| `PauseTotalNs` | Cumulative GC stop-the-world pause   |

Expose via an endpoint or emit as metrics:

```go
var m runtime.MemStats
runtime.ReadMemStats(&m)
slog.Info("memstats",
    slog.Uint64("heap_alloc", m.HeapAlloc),
    slog.Uint64("heap_inuse", m.HeapInuse),
    slog.Uint64("num_gc", uint64(m.NumGC)),
    slog.Uint64("pause_total_ns", m.PauseTotalNs),
)
```

### What to look for

- `[]byte` allocations in serialization hot paths.
  Reuse buffers with `sync.Pool`.
- String concatenation with `+` in loops. Use
  `strings.Builder`.
- Interface boxing of small values causing heap escapes.
  Check with `go build -gcflags='-m'`.
- Growing `HeapInuse` over time without corresponding
  traffic increase indicates a memory leak.

## 4. Goroutine Profiling

Human-readable goroutine dump (shows full stack traces
with goroutine state):

```bash
curl http://localhost:6060/debug/pprof/goroutine?debug=2
```

Machine-readable format for `go tool pprof`:

```bash
curl -o goroutine.prof \
  http://localhost:6060/debug/pprof/goroutine
go tool pprof -http=:8081 goroutine.prof
```

### Detecting goroutine leaks

- Goroutine count growing over time with stable traffic.
- Goroutines blocked on channel send/receive forever
  (missing cancellation or timeout).
- Monitor count via `runtime.NumGoroutine()` or the
  `/debug/pprof/goroutine?debug=0` count header.

### Blocking profile

Enable the blocking profiler, then capture:

```go
runtime.SetBlockProfileRate(1) // sample every block event
```

```bash
curl -o block.prof \
  http://localhost:6060/debug/pprof/block
go tool pprof -http=:8081 block.prof
```

This shows where goroutines spend time waiting on
channel operations, `select`, or `sync.Cond`.

### Mutex contention profile

Enable mutex profiling, then capture:

```go
runtime.SetMutexProfileFraction(5) // sample 1/5 of events
```

```bash
curl -o mutex.prof \
  http://localhost:6060/debug/pprof/mutex
go tool pprof -http=:8081 mutex.prof
```

In the pprof UI, look for high contention on:

- `sync.Mutex` / `sync.RWMutex` in hot paths.
- Global locks protecting shared maps (consider
  `sync.Map` or sharding).
- Database connection pool mutexes (tune pool size).

**Production note**: `SetBlockProfileRate(1)` and low
`SetMutexProfileFraction` values add overhead. Use
selectively or with higher sampling fractions in
production.

## 5. Datadog Continuous Profiler

Import and start the profiler at application startup:

```go
package main

import (
	"log/slog"

	"gopkg.in/DataDog/dd-trace-go.v1/profiler"
)

func initProfiler() {
	err := profiler.Start(
		profiler.WithService("api"),
		profiler.WithEnv("production"),
		profiler.WithVersion("1.0.0"),
		profiler.WithProfileTypes(
			profiler.CPUProfile,
			profiler.HeapProfile,
			profiler.GoroutineProfile,
			profiler.BlockProfile,
			profiler.MutexProfile,
		),
	)
	if err != nil {
		slog.Error("failed to start profiler",
			slog.Any("error", err),
		)
	}
}

func main() {
	initProfiler()
	defer profiler.Stop()

	// ... application code
}
```

### Comparing profiles across deploys

The `WithVersion` tag lets you compare profiles between
releases in the Datadog UI:

1. Open **APM > Profiling**.
2. Select your service and filter by `version`.
3. Use **Compare** to see flame graph diffs between the
   old and new version side by side.

This surfaces regressions introduced by a specific
deploy before they trigger alerts.

### When to enable in production

| Profile Type | Always On? | Overhead  |
|-------------|------------|-----------|
| CPU         | Yes        | ~1%       |
| Heap        | Yes        | ~1%       |
| Goroutine   | Yes        | Negligible |
| Block       | Selective  | Variable  |
| Mutex       | Selective  | Variable  |

CPU and heap profiles are safe to run continuously.
Enable block and mutex profiles when investigating
specific contention issues, then disable them.

## 6. Trace-to-Profile Correlation

Enable code hotspots and endpoint profiling when
starting the Datadog tracer:

```go
package main

import (
	"log/slog"

	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
	"gopkg.in/DataDog/dd-trace-go.v1/profiler"
)

func initObservability() {
	// Start profiler first.
	err := profiler.Start(
		profiler.WithService("api"),
		profiler.WithEnv("production"),
		profiler.WithVersion("1.0.0"),
		profiler.WithProfileTypes(
			profiler.CPUProfile,
			profiler.HeapProfile,
		),
	)
	if err != nil {
		slog.Error("failed to start profiler",
			slog.Any("error", err),
		)
	}

	// Start tracer with profiler correlation.
	tracer.Start(
		tracer.WithService("api"),
		tracer.WithEnv("production"),
		tracer.WithServiceVersion("1.0.0"),
		tracer.WithProfilerCodeHotspots(true),
		tracer.WithProfilerEndpoints(true),
	)
}

func main() {
	initObservability()
	defer tracer.Stop()
	defer profiler.Stop()

	// ... application code
}
```

### How it works

When both the tracer and profiler are running with
code hotspots enabled, the Datadog agent correlates
active CPU profile samples with the trace span that
was executing at that moment. This links a slow APM
trace span directly to the CPU profile that was active
during that span's execution.

### Navigation flow

1. Open **APM > Traces** and find a slow trace.
2. Click into the slow span.
3. Select the **Code Hotspots** tab.
4. See which functions consumed the most CPU during
   that specific request, ranked by percentage.
5. Click a function to jump to its flame graph position
   in the profiler.

With endpoint profiling enabled, you can also:

1. Open **APM > Profiling**.
2. Filter by endpoint (e.g., `GET /api/v1/orders`).
3. See aggregated CPU/memory profiles for all requests
   to that endpoint.

### When this is most valuable

- **Latency spikes under load**: a trace shows P99
  latency jumped, but the code path looks normal.
  Code hotspots reveal that a shared mutex or GC pause
  dominated wall time during that request.
- **Intermittent slow queries**: endpoint profiling
  aggregates profiles across many requests, surfacing
  patterns that a single trace cannot show.
- **Post-deploy regression**: compare endpoint profiles
  before and after a release to pinpoint which function
  got slower.

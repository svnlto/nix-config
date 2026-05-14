# Structured Logging (Go slog)

Production-ready structured logging patterns using Go's
stdlib `log/slog` package.

## 1. JSON Handler Setup

Configure a JSON handler with source location and custom
attribute formatting:

```go
package main

import (
	"log/slog"
	"os"
	"time"
)

func initLogger() *slog.Logger {
	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level:     slog.LevelInfo,
		AddSource: true,
		ReplaceAttr: func(
			groups []string, a slog.Attr,
		) slog.Attr {
			// Use RFC3339 for timestamps.
			if a.Key == slog.TimeKey {
				a.Value = slog.StringValue(
					a.Value.Time().Format(time.RFC3339),
				)
			}
			// Rename "msg" to "message" for ELK compat.
			if a.Key == slog.MessageKey {
				a.Key = "message"
			}
			return a
		},
	})

	logger := slog.New(handler)
	slog.SetDefault(logger)
	return logger
}
```

Output:

```json
{
  "time": "2026-05-14T10:23:01Z",
  "level": "INFO",
  "source": {
    "function": "main.main",
    "file": "main.go",
    "line": 42
  },
  "message": "server started",
  "port": 8080
}
```

## 2. Context-Based Correlation

Inject request ID, trace ID, and user ID into context so
every log line carries correlation fields automatically:

```go
package logging

import (
	"context"
	"log/slog"

	"github.com/google/uuid"
)

type ctxKey string

const (
	keyRequestID ctxKey = "request_id"
	keyTraceID   ctxKey = "trace_id"
	keyUserID    ctxKey = "user_id"
)

// WithRequestID stores a request ID in the context.
// Generates a new UUID if id is empty.
func WithRequestID(ctx context.Context, id string) context.Context {
	if id == "" {
		id = uuid.NewString()
	}
	return context.WithValue(ctx, keyRequestID, id)
}

// RequestIDFromContext retrieves the request ID.
func RequestIDFromContext(ctx context.Context) string {
	if v, ok := ctx.Value(keyRequestID).(string); ok {
		return v
	}
	return ""
}

// WithTraceID stores a trace ID in the context.
func WithTraceID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, keyTraceID, id)
}

// WithUserID stores a user ID in the context.
func WithUserID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, keyUserID, id)
}

// LoggerFromContext returns a child logger with all
// correlation fields attached from the context.
func LoggerFromContext(
	ctx context.Context, base *slog.Logger,
) *slog.Logger {
	if base == nil {
		base = slog.Default()
	}

	var attrs []slog.Attr

	if v := ctx.Value(keyRequestID); v != nil {
		attrs = append(attrs,
			slog.String("request_id", v.(string)))
	}
	if v := ctx.Value(keyTraceID); v != nil {
		attrs = append(attrs,
			slog.String("trace_id", v.(string)))
	}
	if v := ctx.Value(keyUserID); v != nil {
		attrs = append(attrs,
			slog.String("user_id", v.(string)))
	}

	if len(attrs) == 0 {
		return base
	}

	args := make([]any, len(attrs))
	for i, a := range attrs {
		args[i] = a
	}
	return base.With(args...)
}
```

## 3. Middleware Pattern

HTTP middleware that generates or extracts a request ID,
creates a scoped logger, and logs request lifecycle:

```go
package middleware

import (
	"context"
	"log/slog"
	"net/http"
	"time"

	"github.com/google/uuid"
)

type ctxKey string

const ctxLogger ctxKey = "logger"

// responseWriter wraps http.ResponseWriter to capture
// the status code for logging.
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// RequestLogging returns middleware that instruments each
// request with a scoped logger and duration tracking.
func RequestLogging(base *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()

			// Extract or generate request ID.
			requestID := r.Header.Get("X-Request-ID")
			if requestID == "" {
				requestID = uuid.NewString()
			}

			// Build child logger with request-scoped fields.
			logger := base.With(
				slog.String("request_id", requestID),
				slog.String("method", r.Method),
				slog.String("path", r.URL.Path),
				slog.String("remote_addr", r.RemoteAddr),
			)

			// Store logger in context.
			ctx := context.WithValue(
				r.Context(), ctxLogger, logger,
			)

			logger.InfoContext(ctx, "request started")

			// Wrap response writer to capture status.
			wrapped := &responseWriter{
				ResponseWriter: w,
				statusCode:     http.StatusOK,
			}
			wrapped.Header().Set("X-Request-ID", requestID)

			next.ServeHTTP(wrapped, r.WithContext(ctx))

			logger.InfoContext(ctx, "request completed",
				slog.Int("status", wrapped.statusCode),
				slog.Duration("duration", time.Since(start)),
			)
		})
	}
}

// LoggerFrom extracts the request-scoped logger from the
// context. Falls back to slog.Default() if not present.
func LoggerFrom(ctx context.Context) *slog.Logger {
	if l, ok := ctx.Value(ctxLogger).(*slog.Logger); ok {
		return l
	}
	return slog.Default()
}
```

## 4. Log Levels

| Level   | Use For                              | Example                           |
|---------|--------------------------------------|-----------------------------------|
| `Debug` | Internal state, dev-only diagnostics | Cache hit/miss, SQL query text    |
| `Info`  | Business events, state changes       | Order placed, user signed in      |
| `Warn`  | Degraded but functional              | Retry succeeded, pool exhausted   |
| `Error` | Failures needing attention           | DB unreachable, payment declined  |

```go
// Debug: internal state, never in production logs.
slog.Debug("cache lookup",
	slog.String("key", cacheKey),
	slog.Bool("hit", hit),
)

// Info: business event worth recording.
slog.Info("order created",
	slog.String("order_id", order.ID),
	slog.Int("item_count", len(order.Items)),
	slog.String("customer_id", order.CustomerID),
)

// Warn: degraded but the system recovered.
slog.Warn("upstream retry succeeded",
	slog.String("service", "payments"),
	slog.Int("attempt", 3),
	slog.Duration("backoff", 2*time.Second),
)

// Error: something broke and needs attention.
// Always use slog.Any("error", err) to preserve the
// error type and any wrapped context — never err.Error().
slog.Error("database connection failed",
	slog.String("host", dbHost),
	slog.Int("port", dbPort),
	slog.Any("error", err),
)
```

**Never use `err.Error()`** as a string value. Using
`slog.Any("error", err)` preserves the full error chain,
lets handlers serialize wrapped errors, and keeps the
structured representation intact for log aggregators.

## 5. Sensitive Data Redaction

Implement `slog.LogValuer` to control what gets logged
for types that contain sensitive data:

```go
package model

import "log/slog"

// User contains PII that must not appear in logs.
type User struct {
	ID    string
	Email string
	Token string
	Name  string
}

// LogValue implements slog.LogValuer. It controls the
// structured representation of User in log output.
func (u User) LogValue() slog.Value {
	return slog.GroupValue(
		slog.String("id", u.ID),
		slog.String("name", u.Name),
		slog.String("email", maskEmail(u.Email)),
		// Token is deliberately omitted.
	)
}

// maskEmail shows only the first character and domain.
// "alice@example.com" -> "a***@example.com"
func maskEmail(email string) string {
	at := -1
	for i, c := range email {
		if c == '@' {
			at = i
			break
		}
	}
	if at <= 0 {
		return "***"
	}
	return string(email[0]) + "***" + email[at:]
}
```

Usage:

```go
user := model.User{
	ID:    "usr_123",
	Email: "alice@example.com",
	Token: "sk-secret-token",
	Name:  "Alice",
}

slog.Info("user authenticated", slog.Any("user", user))
```

Output:

```json
{
  "level": "INFO",
  "message": "user authenticated",
  "user": {
    "id": "usr_123",
    "name": "Alice",
    "email": "a***@example.com"
  }
}
```

**Never log**: passwords, bearer tokens, API keys, session
IDs, PII beyond what is strictly necessary, or full HTTP
request/response bodies.

## 6. Performance

### Pre-allocated attributes on hot paths

Use `LogAttrs` with pre-built `[]slog.Attr` slices to
avoid allocations from variadic `any` arguments:

```go
func handleRequest(
	ctx context.Context,
	logger *slog.Logger,
	method, path string,
	status int,
	dur time.Duration,
) {
	logger.LogAttrs(ctx, slog.LevelInfo, "request handled",
		slog.String("method", method),
		slog.String("path", path),
		slog.Int("status", status),
		slog.Duration("duration", dur),
	)
}
```

### Level guards for expensive construction

Check `Enabled` before building attributes that are costly
to compute:

```go
if logger.Enabled(ctx, slog.LevelDebug) {
	dump := expensiveDebugDump(state)
	logger.DebugContext(ctx, "state snapshot",
		slog.String("dump", dump),
	)
}
```

### Grouped fields without extra allocations

Use `slog.Group` to namespace related fields in a single
call:

```go
slog.Info("upstream response",
	slog.Group("http",
		slog.String("method", "GET"),
		slog.String("url", url),
		slog.Int("status", resp.StatusCode),
		slog.Duration("latency", elapsed),
	),
)
```

Output:

```json
{
  "level": "INFO",
  "message": "upstream response",
  "http": {
    "method": "GET",
    "url": "https://api.example.com/v1/items",
    "status": 200,
    "latency": "42ms"
  }
}
```

### Benchmarking

Measure allocations with:

```bash
go test -bench=BenchmarkLog -benchmem -count=5
```

A well-tuned handler should show 0 allocs/op for
`LogAttrs` calls at disabled levels and minimal
allocations at enabled levels.

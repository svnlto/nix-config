# Performance Testing

Load testing with k6 and Go benchmarks for validating
service performance under realistic conditions.

## 1. k6 Patterns

Staged load profile with thresholds, checks, groups,
and custom metrics in a single test script.

```js
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

// Custom metrics for business-level tracking.
const orderErrors = new Counter('order_errors');
const orderDuration = new Trend('order_duration_ms');

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // ramp up
    { duration: '5m', target: 50 },   // sustain
    { duration: '1m', target: 0 },    // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // p95 < 500ms
    http_req_failed: ['rate<0.01'],    // error rate < 1%
    order_errors: ['count<10'],        // custom threshold
    order_duration_ms: ['p(95)<800'],  // business metric
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  group('list orders', () => {
    const listRes = http.get(`${BASE_URL}/api/orders`);
    check(listRes, {
      'list status is 200': (r) => r.status === 200,
      'list returns array': (r) => {
        const body = JSON.parse(r.body);
        return Array.isArray(body);
      },
    });
  });

  group('create order', () => {
    const payload = JSON.stringify({
      product: 'widget',
      quantity: 1,
    });
    const params = {
      headers: { 'Content-Type': 'application/json' },
    };

    const start = Date.now();
    const createRes = http.post(
      `${BASE_URL}/api/orders`,
      payload,
      params,
    );
    orderDuration.add(Date.now() - start);

    const ok = check(createRes, {
      'create status is 201': (r) => r.status === 201,
      'create returns id': (r) => {
        const body = JSON.parse(r.body);
        return body.id !== undefined;
      },
    });

    if (!ok) {
      orderErrors.add(1);
    }
  });

  sleep(1);
}
```

Run with environment variable override:

```bash
k6 run --env BASE_URL=https://staging.example.com \
  performance-test.js
```

## 2. k6 Scenarios

Each scenario type targets a different load shape.
Define them under `options.scenarios`.

### Ramping VUs (Standard Load Test)

```js
export const options = {
  scenarios: {
    standard_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
};
```

### Constant Arrival Rate (Stress Test)

Fixed 100 requests per second regardless of response
time. Pre-allocates VUs to absorb slowdowns.

```js
export const options = {
  scenarios: {
    stress_test: {
      executor: 'constant-arrival-rate',
      rate: 100,
      timeUnit: '1s',
      duration: '5m',
      preAllocatedVUs: 50,
      maxVUs: 200,
    },
  },
};
```

### Shared Iterations (One-Shot Processing)

Distribute 1000 iterations across 10 VUs. Each
iteration runs exactly once.

```js
export const options = {
  scenarios: {
    data_processing: {
      executor: 'shared-iterations',
      vus: 10,
      iterations: 1000,
      maxDuration: '10m',
    },
  },
};
```

### Per-VU Iterations (User Journey)

Each VU runs the full scenario 5 times, simulating
individual user sessions.

```js
export const options = {
  scenarios: {
    user_journey: {
      executor: 'per-vu-iterations',
      vus: 20,
      iterations: 5,
      maxDuration: '10m',
    },
  },
};
```

### Combined Scenarios

Run multiple scenarios in a single test. Each gets
its own executor and schedule.

```js
export const options = {
  scenarios: {
    browse: {
      executor: 'constant-arrival-rate',
      rate: 50,
      timeUnit: '1s',
      duration: '5m',
      preAllocatedVUs: 20,
      maxVUs: 100,
      exec: 'browseProducts',
    },
    checkout: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 10 },
        { duration: '3m', target: 10 },
      ],
      exec: 'checkoutFlow',
    },
  },
};

export function browseProducts() {
  http.get(`${BASE_URL}/api/products`);
  sleep(1);
}

export function checkoutFlow() {
  http.post(`${BASE_URL}/api/checkout`, payload);
  sleep(2);
}
```

## 3. Go Benchmarks

### Basic Benchmark with Setup

```go
func BenchmarkProcessOrder(b *testing.B) {
    svc := NewOrderService(setupTestDB(b))
    order := Order{Product: "widget", Qty: 1}

    b.ResetTimer() // exclude setup from measurement

    for b.Loop() {
        if _, err := svc.Process(order); err != nil {
            b.Fatal(err)
        }
    }
}
```

### Allocation Tracking

```go
func BenchmarkSerialize(b *testing.B) {
    b.ReportAllocs()

    data := generateTestPayload()
    for b.Loop() {
        if _, err := json.Marshal(data); err != nil {
            b.Fatal(err)
        }
    }
}
```

### Concurrent Benchmark

```go
func BenchmarkConcurrentLookup(b *testing.B) {
    cache := NewCache()
    cache.Warm(testData)

    b.ResetTimer()
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            _ = cache.Get("hot-key")
        }
    })
}
```

### Sub-Benchmarks

```go
func BenchmarkHash(b *testing.B) {
    b.Run("md5", func(b *testing.B) {
        for b.Loop() {
            md5.Sum(testData)
        }
    })

    b.Run("sha256", func(b *testing.B) {
        for b.Loop() {
            sha256.Sum256(testData)
        }
    })
}
```

### Table-Driven Benchmarks

```go
func BenchmarkSort(b *testing.B) {
    sizes := []struct {
        name string
        n    int
    }{
        {"10", 10},
        {"100", 100},
        {"1000", 1000},
        {"10000", 10000},
    }

    for _, s := range sizes {
        b.Run(s.name, func(b *testing.B) {
            for b.Loop() {
                data := generateSlice(s.n)
                sort.Ints(data)
            }
        })
    }
}
```

### Running Benchmarks

```bash
# All benchmarks with memory stats, 5 iterations.
go test -bench=. -benchmem -count=5 ./...

# Specific benchmark with CPU profile output.
go test -bench=BenchmarkProcessOrder -benchmem \
  -cpuprofile=cpu.prof -memprofile=mem.prof ./...

# Compare results with benchstat.
go test -bench=. -count=10 ./... > old.txt
# ... make changes ...
go test -bench=. -count=10 ./... > new.txt
benchstat old.txt new.txt
```

## 4. Profiling Under Load

Capture Go profiles while k6 drives realistic traffic.
The service must import `net/http/pprof` and expose
port 6060.

### Service Setup

```go
import _ "net/http/pprof"

func main() {
    // pprof on a separate port so it is never
    // exposed through the public listener.
    go func() {
        log.Println(http.ListenAndServe(
            "localhost:6060", nil,
        ))
    }()

    // ... start main server on :8080
}
```

### Manual Profile Capture

```bash
# CPU profile (30-second sample during peak load).
curl -o cpu.prof \
  'http://localhost:6060/debug/pprof/profile?seconds=30'

# Heap profile at peak.
curl -o heap.prof \
  'http://localhost:6060/debug/pprof/heap'

# Goroutine dump.
curl -o goroutine.prof \
  'http://localhost:6060/debug/pprof/goroutine'
```

### Analyze with pprof

```bash
# Interactive web UI.
go tool pprof -http=:8081 cpu.prof

# Top functions by cumulative CPU time.
go tool pprof -top cpu.prof

# Flamegraph of allocations.
go tool pprof -http=:8081 heap.prof
```

### Automated Load + Profile Script

Run k6 and capture profiles simultaneously. The
script starts profiling, kicks off k6, then collects
heap at peak.

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE_URL="${SERVICE_URL:-http://localhost:8080}"
PPROF_URL="${PPROF_URL:-http://localhost:6060}"
K6_SCRIPT="${1:?Usage: $0 <k6-script.js>}"
OUT_DIR="profiles/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$OUT_DIR"

echo "==> Starting 30s CPU profile..."
curl -so "$OUT_DIR/cpu.prof" \
  "$PPROF_URL/debug/pprof/profile?seconds=30" &
CURL_PID=$!

echo "==> Running k6 load test..."
k6 run \
  --env BASE_URL="$SERVICE_URL" \
  --summary-export="$OUT_DIR/k6-results.json" \
  "$K6_SCRIPT" &
K6_PID=$!

# Wait for CPU profile to finish (30s), then grab
# a heap snapshot while load is still running.
wait "$CURL_PID"
echo "==> Capturing heap profile at peak..."
curl -so "$OUT_DIR/heap.prof" \
  "$PPROF_URL/debug/pprof/heap"

# Wait for k6 to complete.
wait "$K6_PID"
K6_EXIT=$?

echo "==> Capturing goroutine dump..."
curl -so "$OUT_DIR/goroutine.prof" \
  "$PPROF_URL/debug/pprof/goroutine"

echo "==> Profiles saved to $OUT_DIR/"
ls -lh "$OUT_DIR"

exit "$K6_EXIT"
```

## 5. CI Integration

### Thresholds as Quality Gate

k6 exits with code 99 when any threshold breaches.
Use this as a pipeline gate without extra logic.

```js
export const options = {
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};
```

### Azure DevOps Pipeline

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UseDotNet@2
    displayName: 'Install k6'
    inputs:
      command: 'custom'
      custom: |
        curl -sL https://github.com/grafana/k6/releases/download/v0.50.0/k6-v0.50.0-linux-amd64.tar.gz \
          | tar xz --strip-components=1
        mv k6 $(Pipeline.Workspace)/k6
        chmod +x $(Pipeline.Workspace)/k6

  - script: |
      $(Pipeline.Workspace)/k6 run \
        --env BASE_URL=$(SERVICE_URL) \
        --summary-export=$(Build.ArtifactStagingDirectory)/k6-results.json \
        tests/load/performance-test.js
    displayName: 'Run k6 load test'
    continueOnError: false

  - task: PublishBuildArtifacts@1
    displayName: 'Publish k6 results'
    condition: always()
    inputs:
      PathtoPublish: '$(Build.ArtifactStagingDirectory)/k6-results.json'
      ArtifactName: 'k6-results'
```

### GitHub Actions Workflow

```yaml
name: Performance Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  load-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install k6
        run: |
          curl -sL https://github.com/grafana/k6/releases/download/v0.50.0/k6-v0.50.0-linux-amd64.tar.gz \
            | tar xz --strip-components=1
          sudo mv k6 /usr/local/bin/

      - name: Start service
        run: |
          docker compose up -d
          sleep 5

      - name: Run k6 load test
        run: |
          k6 run \
            --env BASE_URL=http://localhost:8080 \
            --summary-export=k6-results.json \
            tests/load/performance-test.js

      - name: Upload k6 results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: k6-results
          path: k6-results.json

      - name: Stop service
        if: always()
        run: docker compose down
```

### Go Benchmarks in CI

Track benchmark regressions across commits using
`benchstat`. Fails if any benchmark regresses by
more than 10%.

```yaml
# GitHub Actions step
- name: Run Go benchmarks
  run: |
    go test -bench=. -benchmem -count=5 \
      ./... > bench-new.txt

- name: Compare benchmarks
  run: |
    go install golang.org/x/perf/cmd/benchstat@latest
    benchstat bench-baseline.txt bench-new.txt

- name: Upload benchmark results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: benchmark-results
    path: bench-new.txt
```

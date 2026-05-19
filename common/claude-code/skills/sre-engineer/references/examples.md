# SRE Concrete Examples

## SLO Definition & Error Budget Calculation

```text
# 99.9% availability SLO over a 30-day window
# Allowed downtime: (1 - 0.999) * 30 * 24 * 60 = 43.2 minutes/month
# Error budget (request-based): 0.001 * total_requests

# Example: 10M requests/month → 10,000 error budget requests
# If 5,000 errors consumed in week 1 → 50% budget burned in 25% of window
# → Trigger error budget policy: freeze non-critical releases
```

## Prometheus SLO Alerting Rule (Multiwindow Burn Rate)

```yaml
groups:
  - name: slo_availability
    rules:
      # Fast burn: 2% budget in 1h (14.4x burn rate)
      - alert: HighErrorBudgetBurn
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[1h]))
            /
            sum(rate(http_requests_total[1h]))
          ) > 0.014400
          and
          (
            sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          ) > 0.014400
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High error budget burn rate detected"
          runbook: "https://wiki.internal/runbooks/high-error-burn"

      # Slow burn: 5% budget in 6h (1x burn rate sustained)
      - alert: SlowErrorBudgetBurn
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[6h]))
            /
            sum(rate(http_requests_total[6h]))
          ) > 0.001
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Sustained error budget consumption"
          runbook: "https://wiki.internal/runbooks/slow-error-burn"
```

## PromQL Golden Signal Queries

```promql
# Latency — 99th percentile request duration
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))

# Traffic — requests per second by service
sum(rate(http_requests_total[5m])) by (service)

# Errors — error rate ratio
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
  /
sum(rate(http_requests_total[5m])) by (service)

# Saturation — CPU throttling ratio
sum(rate(container_cpu_cfs_throttled_seconds_total[5m])) by (pod)
  /
sum(rate(container_cpu_cfs_periods_total[5m])) by (pod)
```

## Datadog SLO + Burn Rate Monitor (Terraform)

> Examples show raw Terraform resources; wrap with Terragrunt for orchestration.

```hcl
resource "datadog_service_level_objective" "api_availability" {
  name = "API Availability SLO"
  type = "metric"

  query {
    numerator   = "sum:http.requests{service:api,status_class:2xx}.as_count() + sum:http.requests{service:api,status_class:4xx}.as_count()"
    denominator = "sum:http.requests{service:api}.as_count()"
  }

  thresholds {
    timeframe = "30d"
    target    = 99.9
    warning   = 99.95
  }

  tags = ["service:api", "team:platform", "env:production"]
}

resource "datadog_monitor" "api_slo_burn_rate" {
  name = "API SLO Burn Rate — Fast Burn"
  type = "slo alert"

  query = "burn_rate(\"${datadog_service_level_objective.api_availability.id}\").over(\"1h\").long_window(\"1h\").short_window(\"5m\") > 14.4"

  monitor_thresholds {
    critical = 14.4
    warning  = 6.0
  }

  message = <<-EOT
    {{#is_alert}}
    High SLO burn rate detected for API availability.
    Current burn rate: {{value}}x (threshold: {{threshold}})
    At this rate, the 30-day error budget will exhaust in ~2 days.
    Runbook: https://wiki.internal/runbooks/api-slo-burn
    @pagerduty-platform-oncall
    {{/is_alert}}

    {{#is_warning}}
    Elevated SLO burn rate for API availability.
    @slack-platform-alerts
    {{/is_warning}}
  EOT

  tags = ["service:api", "team:platform", "env:production", "slo:availability"]
}
```

## Toil Automation Script (Python)

```python
#!/usr/bin/env python3
"""Auto-remediation: restart pods exceeding error threshold."""
import subprocess, sys, json

ERROR_THRESHOLD = 0.05  # 5% error rate triggers restart

def get_error_rate(service: str) -> float:
    """Query Prometheus for current error rate."""
    import urllib.request
    query = f'sum(rate(http_requests_total{{status=~"5..",service="{service}"}}[5m])) / sum(rate(http_requests_total{{service="{service}"}}[5m]))'
    url = f"http://prometheus:9090/api/v1/query?query={urllib.request.quote(query)}"
    with urllib.request.urlopen(url) as resp:
        data = json.load(resp)
    results = data["data"]["result"]
    return float(results[0]["value"][1]) if results else 0.0

def restart_deployment(namespace: str, deployment: str) -> None:
    subprocess.run(
        ["kubectl", "rollout", "restart", f"deployment/{deployment}", "-n", namespace],
        check=True
    )
    print(f"Restarted {namespace}/{deployment}")

if __name__ == "__main__":
    service, namespace, deployment = sys.argv[1], sys.argv[2], sys.argv[3]
    rate = get_error_rate(service)
    print(f"Error rate for {service}: {rate:.2%}")
    if rate > ERROR_THRESHOLD:
        restart_deployment(namespace, deployment)
    else:
        print("Within SLO threshold — no action required")
```

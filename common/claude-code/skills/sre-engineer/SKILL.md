---
name: sre-engineer
description: Defines service level objectives, creates error budget policies, designs incident response procedures, develops capacity models, and produces monitoring configurations and automation scripts for production systems. Use when defining SLIs/SLOs, managing error budgets, building reliable systems at scale, incident management, chaos engineering, toil reduction, capacity planning, Datadog monitors, Datadog SLOs, Terraform reliability patterns, or observability-as-code.
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "2.0.0"
  domain: devops
  triggers: SRE, site reliability, SLO, SLI, error budget, incident management, chaos engineering, toil reduction, on-call, MTTR, Datadog, datadog_monitor, datadog_slo, terraform reliability, observability
  role: specialist
  scope: implementation
  output-format: code
  related-skills: devops-engineer, cloud-architect, kubernetes-specialist, secrets-management, devsecops-expert
---

# SRE Engineer

## Core Workflow

1. **Assess reliability** - Review architecture, SLOs, incidents, toil levels
2. **Define SLOs** - Identify meaningful SLIs and set appropriate targets
3. **Verify alignment** - Confirm SLO targets reflect user expectations before proceeding
4. **Implement monitoring** - Build golden signal dashboards and alerting
5. **Automate toil** - Identify repetitive tasks and build automation
6. **Test resilience** - Design and execute chaos experiments;
   verify recovery meets RTO/RPO targets before marking the
   experiment complete; validate recovery behavior end-to-end

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| SLO/SLI | `references/slo-sli-management.md` | Defining SLOs, calculating error budgets |
| Error Budgets | `references/error-budget-policy.md` | Managing budgets, burn rates, policies |
| Monitoring | `references/monitoring-alerting.md` | Golden signals, alert design, dashboards |
| Automation | `references/automation-toil.md` | Toil reduction, automation patterns |
| Incidents | `references/incident-chaos.md` | Incident response, chaos engineering |
| Terraform | `references/terraform-reliability.md` | IaC for reliability, capacity, drift detection |
| Datadog SLOs | `references/datadog-slo-alerting.md` | Datadog monitors, SLOs, error budgets, burn rate alerts |
| Datadog Observability | `references/datadog-observability.md` | Synthetics, log pipelines, APM, dashboards, service catalog |

## Constraints

### MUST DO

- Define quantitative SLOs (e.g., 99.9% availability)
- Calculate error budgets from SLO targets
- Monitor golden signals (latency, traffic, errors, saturation)
- Write blameless postmortems for all incidents
- Measure toil and track reduction progress
- Automate repetitive operational tasks
- Test failure scenarios with chaos engineering
- Balance reliability with feature velocity
- Define Datadog monitors and SLOs as Terraform resources (not ClickOps)

### MUST NOT DO

- Set SLOs without user impact justification
- Alert on symptoms without actionable runbooks
- Tolerate >50% toil without automation plan
- Skip postmortems or assign blame
- Implement manual processes for recurring tasks
- Deploy without capacity planning
- Ignore error budget exhaustion
- Build systems that can't degrade gracefully

## Output Templates

When implementing SRE practices, provide:

1. SLO definitions with SLI measurements and targets
2. Monitoring/alerting configuration (Prometheus, Datadog, etc.)
3. Automation scripts (Python, Go, Terraform)
4. Runbooks with clear remediation steps
5. Brief explanation of reliability impact

## Concrete Examples

### SLO Definition & Error Budget Calculation

```text
# 99.9% availability SLO over a 30-day window
# Allowed downtime: (1 - 0.999) * 30 * 24 * 60 = 43.2 minutes/month
# Error budget (request-based): 0.001 * total_requests

# Example: 10M requests/month → 10,000 error budget requests
# If 5,000 errors consumed in week 1 → 50% budget burned in 25% of window
# → Trigger error budget policy: freeze non-critical releases
```

### Prometheus SLO Alerting Rule (Multiwindow Burn Rate)

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

### PromQL Golden Signal Queries

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

### Datadog SLO + Burn Rate Monitor (Terraform)

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

### Toil Automation Script (Python)

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

# Datadog SLO & Alerting

Datadog monitors, SLOs, error budgets, and burn rate alerting
as Terraform resources. Examples show raw Terraform resources;
wrap with Terragrunt for orchestration.

## Monitors

### Metric Monitor

```hcl
resource "datadog_monitor" "api_error_rate" {
  name    = "[Production] API Error Rate High"
  type    = "query alert"
  query   = "sum(last_5m):sum:http.requests{service:api,env:production,status_class:5xx}.as_count() / sum:http.requests{service:api,env:production}.as_count() > 0.01"
  message = <<-EOT
    {{#is_alert}}
    API error rate has exceeded 1% over the last 5 minutes.
    Current value: {{value}}
    Threshold: {{threshold}}

    Runbook: https://wiki.internal/runbooks/api-error-rate
    @pagerduty-platform-oncall
    @slack-platform-alerts
    {{/is_alert}}

    {{#is_recovery}}
    API error rate has recovered below {{threshold}}.
    Current value: {{value}}
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  monitor_thresholds {
    critical          = 0.01
    critical_recovery = 0.007
    warning           = 0.005
    warning_recovery  = 0.003
  }

  notify_no_data    = true
  no_data_timeframe = 10
  evaluation_delay  = 60
  renotify_interval = 60

  tags = ["service:api", "team:platform", "env:production"]
}
```

### Anomaly Monitor

```hcl
resource "datadog_monitor" "api_latency_anomaly" {
  name    = "[Production] API p99 Latency Anomaly"
  type    = "query alert"
  query   = "avg(last_4h):anomalies(avg:http.request.duration.p99{service:api,env:production}, 'agile', 3, direction='above', interval=120, alert_window='last_30m', count_default_zero='true') >= 1"
  message = <<-EOT
    {{#is_alert}}
    API p99 latency is anomalously high compared to the previous 4 hours.
    This may indicate degraded backend performance or upstream dependency issues.

    Runbook: https://wiki.internal/runbooks/api-latency-anomaly
    @pagerduty-platform-oncall
    {{/is_alert}}

    {{#is_recovery}}
    API p99 latency has returned to expected levels.
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  monitor_threshold_windows {
    trigger_window  = "last_30m"
    recovery_window = "last_30m"
  }

  monitor_thresholds {
    critical = 1
  }

  notify_no_data    = false
  renotify_interval = 0

  tags = ["service:api", "team:platform", "env:production"]
}
```

### Composite Monitor

```hcl
resource "datadog_monitor" "api_degraded" {
  name    = "[Production] API Systemic Degradation"
  type    = "composite"
  query   = "${datadog_monitor.api_error_rate.id} && ${datadog_monitor.api_latency_anomaly.id}"
  message = <<-EOT
    {{#is_alert}}
    API is experiencing both elevated error rates and anomalous latency.
    This combination indicates systemic degradation, not an isolated spike.

    Error Rate Monitor: {{api_error_rate.name}}
    Latency Monitor: {{api_latency_anomaly.name}}

    Runbook: https://wiki.internal/runbooks/api-systemic-degradation
    @pagerduty-platform-oncall
    {{/is_alert}}

    {{#is_recovery}}
    Systemic degradation has resolved. Both error rate and latency are nominal.
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  renotify_interval = 0

  tags = ["service:api", "team:platform", "env:production"]
}
```

### Forecast Monitor

```hcl
resource "datadog_monitor" "disk_forecast" {
  name    = "[Production] Disk Usage Forecast - Capacity Warning"
  type    = "query alert"
  query   = "max(next_1w):forecast(max:system.disk.in_use{service:api,env:production}, 'linear', 1) > 0.9"
  message = <<-EOT
    {{#is_alert}}
    Disk usage is forecast to exceed 90% within the next 7 days based on linear projection.
    Current trajectory requires capacity expansion or cleanup.

    Host: {{host.name}}
    Device: {{device.name}}

    Actions:
    - Review log retention and archive policies
    - Check for unexpected data growth
    - Plan capacity expansion if growth is organic

    Runbook: https://wiki.internal/runbooks/disk-capacity-forecast
    @slack-platform-alerts
    {{/is_alert}}

    {{#is_recovery}}
    Disk usage forecast no longer predicts exceeding 90% within 7 days.
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  monitor_thresholds {
    critical = 0.9
  }

  notify_no_data    = false
  renotify_interval = 0

  tags = ["service:api", "team:platform", "env:production"]
}
```

## SLO Definitions

### Metric-Based SLO

```hcl
resource "datadog_service_level_objective" "api_availability" {
  name        = "API Availability"
  type        = "metric"
  description = "Proportion of API requests that return non-5xx responses, measured over rolling windows."

  query {
    numerator   = "sum:http.requests{service:api,env:production,!status_class:5xx}.as_count()"
    denominator = "sum:http.requests{service:api,env:production}.as_count()"
  }

  thresholds {
    timeframe       = "30d"
    target          = 99.9
    warning         = 99.95
  }

  thresholds {
    timeframe       = "7d"
    target          = 99.9
    warning         = 99.95
  }

  tags = ["service:api", "team:platform", "env:production"]
}
```

### Monitor-Based SLO

```hcl
resource "datadog_service_level_objective" "api_latency" {
  name        = "API Latency"
  type        = "monitor"
  description = "Proportion of time the API p99 latency stays within acceptable bounds, tracked via monitor uptime."

  monitor_ids = [datadog_monitor.api_latency_anomaly.id]

  thresholds {
    timeframe = "30d"
    target    = 99.5
    warning   = 99.7
  }

  tags = ["service:api", "team:platform", "env:production"]
}
```

## Burn Rate Alerts

### Fast Burn

```hcl
resource "datadog_monitor" "slo_fast_burn" {
  name    = "[SLO] API Availability - Fast Burn"
  type    = "slo alert"
  query   = "burn_rate(\"${datadog_service_level_objective.api_availability.id}\").over(\"1h\").short_window(\"5m\") > 14.4"
  message = <<-EOT
    {{#is_alert}}
    API availability SLO is burning error budget at 14.4x the sustainable rate.
    At this pace, the entire 30-day error budget will be exhausted in approximately 2 days.

    SLO: API Availability (99.9% over 30 days)
    Long window: 1h | Short window: 5m
    Burn rate: {{value}}x

    Immediate investigation required.
    Runbook: https://wiki.internal/runbooks/slo-fast-burn
    @pagerduty-platform-oncall
    {{/is_alert}}

    {{#is_recovery}}
    Fast burn rate on API availability SLO has dropped below 14.4x threshold.
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  monitor_thresholds {
    critical = 14.4
  }

  tags = ["service:api", "team:platform", "env:production"]
}
```

### Slow Burn

```hcl
resource "datadog_monitor" "slo_slow_burn" {
  name    = "[SLO] API Availability - Slow Burn"
  type    = "slo alert"
  query   = "burn_rate(\"${datadog_service_level_objective.api_availability.id}\").over(\"24h\").short_window(\"1h\") > 3"
  message = <<-EOT
    {{#is_alert}}
    API availability SLO is burning error budget at 3x the sustainable rate over 24 hours.
    This indicates sustained error budget consumption that will exhaust the budget before the window resets.

    SLO: API Availability (99.9% over 30 days)
    Long window: 24h | Short window: 1h
    Burn rate: {{value}}x

    Investigate gradual degradation or recurring transient failures.
    Runbook: https://wiki.internal/runbooks/slo-slow-burn
    @slack-platform-alerts
    {{/is_alert}}

    {{#is_recovery}}
    Slow burn rate on API availability SLO has dropped below 3x threshold.
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  monitor_thresholds {
    critical = 3
  }

  tags = ["service:api", "team:platform", "env:production"]
}
```

## Error Budget Tracking

```hcl
resource "datadog_dashboard_json" "slo_overview" {
  dashboard = jsonencode({
    title       = "SLO Overview - API"
    description = "Error budget tracking and SLO status for the API service."
    layout_type = "ordered"
    template_variables = [
      {
        name             = "env"
        prefix           = "env"
        default          = "production"
        available_values = ["production", "staging"]
      },
      {
        name             = "service"
        prefix           = "service"
        default          = "api"
        available_values = []
      }
    ]
    widgets = [
      {
        definition = {
          title      = "API Availability SLO - 30d / 7d"
          type       = "slo"
          slo_id     = datadog_service_level_objective.api_availability.id
          view_type  = "detail"
          time_windows = ["30d", "7d"]
          show_error_budget = true
          view_mode  = "overall"
        }
      },
      {
        definition = {
          title       = "Error Budget Remaining Over Time"
          type        = "timeseries"
          requests = [
            {
              response_format = "timeseries"
              queries = [
                {
                  data_source = "slo"
                  slo_id      = datadog_service_level_objective.api_availability.id
                  measure     = "error_budget_remaining"
                  slo_query_type = "metric"
                  name        = "query0"
                }
              ]
              display_type = "line"
              style = {
                palette    = "dog_classic"
                line_type  = "solid"
                line_width = "normal"
              }
            }
          ]
          yaxis = {
            min = "0"
            max = "100"
          }
        }
      }
    ]
  })
}
```

## Notification Routing

### Escalation Pattern

```hcl
locals {
  notify = {
    page    = "@pagerduty-platform-oncall"
    slack   = "@slack-platform-alerts"
    ticket  = "@jira-platform-backlog"
    manager = "@slack-platform-leads"
  }
}

resource "datadog_monitor" "api_error_rate_routed" {
  name    = "[Production] API Error Rate - Escalation Routing"
  type    = "query alert"
  query   = "sum(last_5m):sum:http.requests{service:api,env:production,status_class:5xx}.as_count() / sum:http.requests{service:api,env:production}.as_count() > 0.01"
  message = <<-EOT
    {{#is_alert}}
    API error rate has exceeded 1%. Paging on-call and notifying leads.
    ${local.notify.page}
    ${local.notify.manager}
    {{/is_alert}}

    {{#is_warning}}
    API error rate is elevated above 0.5%. Creating a tracking ticket.
    ${local.notify.slack}
    ${local.notify.ticket}
    {{/is_warning}}

    {{#is_recovery}}
    API error rate has recovered.
    ${local.notify.slack}
    {{/is_recovery}}

    {{#is_no_data}}
    No data received for API error rate monitor. Verify instrumentation.
    ${local.notify.slack}
    ${local.notify.ticket}
    {{/is_no_data}}
  EOT

  monitor_thresholds {
    critical          = 0.01
    critical_recovery = 0.007
    warning           = 0.005
    warning_recovery  = 0.003
  }

  notify_no_data    = true
  no_data_timeframe = 10

  tags = ["service:api", "team:platform", "env:production"]
}
```

### Downtime

```hcl
resource "datadog_downtime_schedule" "api_weekly_maintenance" {
  scope = "service:api AND env:production"

  monitor_identifier {
    monitor_tags = ["service:api"]
  }

  recurring_schedule {
    timezone   = "Europe/Berlin"
    recurrence {
      type     = "weeks"
      interval = 1
      start    = "04:00"
      duration = "1h"
      week_days = ["Sun"]
    }
  }

  display_timezone = "Europe/Berlin"
  message          = "Weekly maintenance window for API service. Suppresses alerts for routine deployments and database maintenance."
}
```

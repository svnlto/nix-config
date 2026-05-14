# Datadog Observability

Synthetics, log pipelines, APM service catalog, dashboards,
and tagging strategy as Terraform resources. Examples show raw
Terraform resources; wrap with Terragrunt for orchestration.

## Synthetics

### API Test

```hcl
resource "datadog_synthetics_test" "api_health" {
  name      = "API Health Check"
  type      = "api"
  subtype   = "http"
  status    = "live"
  locations = ["aws:eu-west-1", "aws:us-east-1"]

  request_definition {
    method = "GET"
    url    = "https://api.example.com/healthz"
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  assertion {
    type     = "responseTime"
    operator = "lessThan"
    target   = "2000"
  }

  assertion {
    type     = "body"
    operator = "validatesJSONSchema"
    targetjsonschema = jsonencode({
      type = "object"
      required = ["status"]
      properties = {
        status = {
          type = "string"
          enum = ["healthy"]
        }
      }
    })
  }

  options_list {
    tick_every           = 300
    min_location_failed  = 1
    min_failure_duration = 60

    retry {
      count    = 2
      interval = 500
    }

    monitor_options {
      renotify_interval = 120
    }
  }

  message = <<-EOT
    {{#is_alert}}
    API health check is failing from {{location}}.
    URL: {{url}}
    Status code: {{status_code}}
    Response time: {{response_time}}ms

    Runbook: https://wiki.internal/runbooks/api-health-check
    @slack-platform-alerts
    {{/is_alert}}

    {{#is_recovery}}
    API health check has recovered.
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  tags = ["service:api", "team:platform", "env:production"]
}
```

### Browser Test

```hcl
resource "datadog_synthetics_test" "login_flow" {
  name      = "Login Flow"
  type      = "browser"
  status    = "live"
  locations = ["aws:eu-west-1"]

  request_definition {
    url = "https://app.example.com/login"
  }

  browser_step {
    name = "Fill email"
    type = "typeText"
    params {
      element = jsonencode({
        multiLocator = {
          ab      = "/*[local-name()=\"input\"][@id=\"email\"]"
          at      = "/descendant::*[@id=\"email\"]"
          cl      = "/*[local-name()=\"input\"][contains(concat(\" \",normalize-space(@class),\" \"),\" email-input \")]"
          ro      = "//*[@id=\"email\"]"
        }
      })
      value = "test-user@example.com"
    }
  }

  browser_step {
    name = "Fill password"
    type = "typeText"
    params {
      element = jsonencode({
        multiLocator = {
          ab      = "/*[local-name()=\"input\"][@id=\"password\"]"
          at      = "/descendant::*[@id=\"password\"]"
          cl      = "/*[local-name()=\"input\"][contains(concat(\" \",normalize-space(@class),\" \"),\" password-input \")]"
          ro      = "//*[@id=\"password\"]"
        }
      })
      value = "{{ SYNTHETICS_PASSWORD }}"
    }
  }

  browser_step {
    name = "Click submit"
    type = "click"
    params {
      element = jsonencode({
        multiLocator = {
          ab      = "/*[local-name()=\"button\"][@type=\"submit\"]"
          at      = "/descendant::*[@type=\"submit\"]"
          cl      = "/*[local-name()=\"button\"][contains(concat(\" \",normalize-space(@class),\" \"),\" login-btn \")]"
          ro      = "//button[@type=\"submit\"]"
        }
      })
    }
  }

  browser_step {
    name = "Assert dashboard element present"
    type = "assertElementPresent"
    params {
      element = jsonencode({
        multiLocator = {
          ab      = "/*[local-name()=\"div\"][@data-testid=\"dashboard\"]"
          at      = "/descendant::*[@data-testid=\"dashboard\"]"
          cl      = "/*[local-name()=\"div\"][contains(concat(\" \",normalize-space(@class),\" \"),\" dashboard \")]"
          ro      = "//*[@data-testid=\"dashboard\"]"
        }
      })
    }
  }

  options_list {
    tick_every = 900
  }

  message = <<-EOT
    {{#is_alert}}
    Login flow browser test is failing.
    @slack-platform-alerts
    {{/is_alert}}

    {{#is_recovery}}
    Login flow browser test has recovered.
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  tags = ["service:api", "team:platform", "env:production"]
}
```

### Multistep API Test

```hcl
resource "datadog_synthetics_test" "api_workflow" {
  name      = "API Create and Retrieve Workflow"
  type      = "api"
  subtype   = "multi"
  status    = "live"
  locations = ["aws:eu-west-1", "aws:us-east-1"]

  api_step {
    name    = "Create resource"
    subtype = "http"

    request_definition {
      method = "POST"
      url    = "https://api.example.com/v1/resources"
      body   = jsonencode({ name = "test-resource", type = "synthetic" })
    }

    request_headers = {
      Content-Type  = "application/json"
      Authorization = "Bearer {{ SYNTHETICS_API_TOKEN }}"
    }

    assertion {
      type     = "statusCode"
      operator = "is"
      target   = "201"
    }

    extracted_value {
      name  = "resource_id"
      field = "body"
      type  = "json_path"
      parser {
        type  = "json_path"
        value = "$.id"
      }
    }
  }

  api_step {
    name    = "Retrieve created resource"
    subtype = "http"

    request_definition {
      method = "GET"
      url    = "https://api.example.com/v1/resources/{{ resource_id }}"
    }

    request_headers = {
      Authorization = "Bearer {{ SYNTHETICS_API_TOKEN }}"
    }

    assertion {
      type     = "statusCode"
      operator = "is"
      target   = "200"
    }

    assertion {
      type     = "body"
      operator = "validatesJSONPath"
      targetjsonpath {
        jsonpath    = "$.name"
        operator    = "is"
        targetvalue = "test-resource"
      }
    }
  }

  options_list {
    tick_every           = 300
    min_location_failed  = 1
    min_failure_duration = 60

    retry {
      count    = 2
      interval = 500
    }
  }

  message = <<-EOT
    {{#is_alert}}
    API create-and-retrieve workflow is failing.
    @slack-platform-alerts
    {{/is_alert}}

    {{#is_recovery}}
    API workflow test has recovered.
    @slack-platform-alerts
    {{/is_recovery}}
  EOT

  tags = ["service:api", "team:platform", "env:production"]
}
```

## Log Pipelines

### Custom Pipeline

```hcl
resource "datadog_logs_custom_pipeline" "api" {
  name       = "API Service Pipeline"
  is_enabled = true

  filter {
    query = "service:api"
  }

  processor {
    grok_parser {
      name       = "Parse structured logs"
      is_enabled = true
      source     = "message"

      grok {
        support_rules = ""
        match_rules   = <<-EOT
          api_log %%{date("yyyy-MM-dd'T'HH:mm:ss.SSSZ"):timestamp} %%{word:level} %%{notSpace:logger} %%{regex("[A-Z]+"):method} %%{notSpace:path} %%{integer:status_code} %%{integer:duration_ms}ms %%{data:message}
        EOT
      }

      samples = [
        "2025-01-15T10:30:45.123Z INFO api.handler GET /v1/resources 200 45ms request completed"
      ]
    }
  }

  processor {
    status_remapper {
      name       = "Map log level"
      is_enabled = true
      sources    = ["level"]
    }
  }

  processor {
    category_processor {
      name       = "Categorize HTTP status"
      is_enabled = true
      target     = "http.status_category"

      category {
        name = "Success"
        filter {
          query = "@status_code:[200 TO 299]"
        }
      }

      category {
        name = "Client Error"
        filter {
          query = "@status_code:[400 TO 499]"
        }
      }

      category {
        name = "Server Error"
        filter {
          query = "@status_code:[500 TO 599]"
        }
      }
    }
  }

  processor {
    attribute_remapper {
      name            = "Remap trace_id for APM correlation"
      is_enabled      = true
      sources         = ["trace_id"]
      target          = "dd.trace_id"
      source_type     = "attribute"
      target_type     = "attribute"
      preserve_source = true
    }
  }
}
```

### Index with Exclusions

```hcl
resource "datadog_logs_index" "api" {
  name = "api"

  filter {
    query = "service:api"
  }

  exclusion_filter {
    name       = "Exclude health checks"
    is_enabled = true

    filter {
      query       = "service:api @path:\"/healthz\""
      sample_rate = 0.0
    }
  }

  exclusion_filter {
    name       = "Sample debug logs"
    is_enabled = true

    filter {
      query       = "service:api status:debug"
      sample_rate = 0.1
    }
  }

  daily_limit = 5000000
}
```

### Log Archive

```hcl
resource "datadog_logs_archive" "s3" {
  name  = "API Logs S3 Archive"
  query = "service:api"

  s3_archive {
    bucket     = "datadog-logs-archive-production"
    path       = "/api"
    account_id = "123456789012"
    role_name  = "DatadogLogsArchiveRole"
  }

  rehydration_max_scan_size_in_gb = 100
  include_tags                    = true
}
```

## APM & Service Catalog

### Service Definition

```hcl
resource "datadog_service_definition_yaml" "api" {
  service_definition = yamlencode({
    schema-version = "v2.2"
    dd-service     = "api"
    team           = "platform"

    contacts = [
      {
        name    = "Platform Team"
        type    = "slack"
        contact = "https://slack.example.com/archives/C0123PLATFORM"
      },
      {
        name    = "Platform On-Call"
        type    = "pagerduty"
        contact = "https://pagerduty.example.com/services/PPLATFORM"
      }
    ]

    repos = [
      {
        name     = "api"
        url      = "https://github.com/example-org/api"
        provider = "github"
      }
    ]

    docs = [
      {
        name     = "Runbook"
        url      = "https://wiki.internal/runbooks/api"
        provider = "wiki"
      },
      {
        name     = "Architecture"
        url      = "https://wiki.internal/architecture/api"
        provider = "wiki"
      }
    ]

    integrations = {
      pagerduty = {
        service-url = "https://pagerduty.example.com/services/PPLATFORM"
      }
    }

    links = [
      {
        name = "Golden Signals Dashboard"
        type = "dashboard"
        url  = "https://app.datadoghq.eu/dashboard/${datadog_dashboard_json.golden_signals.id}"
      },
      {
        name = "Availability SLO"
        type = "slo"
        url  = "https://app.datadoghq.eu/slo?slo_id=${datadog_service_level_objective.api_availability.id}"
      }
    ]

    tags = ["tier:1", "lang:go"]
  })
}
```

## Dashboards

### Golden Signals Dashboard

```hcl
resource "datadog_dashboard_json" "golden_signals" {
  dashboard = jsonencode({
    title       = "Golden Signals — $service"
    description = "Latency, traffic, errors, and saturation for the selected service."
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
          title = "Latency — p50 / p95 / p99"
          type  = "timeseries"
          requests = [
            {
              response_format = "timeseries"
              queries = [
                {
                  data_source = "metrics"
                  name        = "p50"
                  query       = "avg:http.request.duration.p50{service:$service.value,env:$env.value}"
                },
                {
                  data_source = "metrics"
                  name        = "p95"
                  query       = "avg:http.request.duration.p95{service:$service.value,env:$env.value}"
                },
                {
                  data_source = "metrics"
                  name        = "p99"
                  query       = "avg:http.request.duration.p99{service:$service.value,env:$env.value}"
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
            label     = "ms"
            include_zero = true
          }
        }
      },
      {
        definition = {
          title = "Traffic — Requests/sec"
          type  = "timeseries"
          requests = [
            {
              response_format = "timeseries"
              queries = [
                {
                  data_source = "metrics"
                  name        = "traffic"
                  query       = "sum:http.requests{service:$service.value,env:$env.value}.as_rate()"
                }
              ]
              display_type = "bars"
              style = {
                palette    = "blue"
                line_type  = "solid"
                line_width = "normal"
              }
            }
          ]
        }
      },
      {
        definition = {
          title = "Errors — Error Rate %"
          type  = "timeseries"
          requests = [
            {
              response_format = "timeseries"
              queries = [
                {
                  data_source = "metrics"
                  name        = "a"
                  query       = "sum:http.requests{service:$service.value,env:$env.value,status_class:5xx}.as_count()"
                },
                {
                  data_source = "metrics"
                  name        = "b"
                  query       = "sum:http.requests{service:$service.value,env:$env.value}.as_count()"
                }
              ]
              formulas = [
                {
                  formula = "(a / b) * 100"
                  alias   = "Error Rate %"
                }
              ]
              display_type = "line"
              style = {
                palette    = "warm"
                line_type  = "solid"
                line_width = "normal"
              }
            }
          ]
          markers = [
            {
              display_type = "error dashed"
              value        = "y = 0.1"
              label        = "SLO Threshold (99.9%)"
            }
          ]
          yaxis = {
            label        = "%"
            include_zero = true
            max          = "5"
          }
        }
      },
      {
        definition = {
          title = "Saturation — CPU & Memory"
          type  = "timeseries"
          requests = [
            {
              response_format = "timeseries"
              queries = [
                {
                  data_source = "metrics"
                  name        = "cpu"
                  query       = "avg:kubernetes.cpu.usage.total{service:$service.value,env:$env.value} / avg:kubernetes.cpu.limits{service:$service.value,env:$env.value} * 100"
                },
                {
                  data_source = "metrics"
                  name        = "memory"
                  query       = "avg:kubernetes.memory.working_set{service:$service.value,env:$env.value} / avg:kubernetes.memory.limits{service:$service.value,env:$env.value} * 100"
                }
              ]
              display_type = "line"
              style = {
                palette    = "cool"
                line_type  = "solid"
                line_width = "normal"
              }
            }
          ]
          markers = [
            {
              display_type = "warning dashed"
              value        = "y = 80"
              label        = "80% Saturation"
            }
          ]
          yaxis = {
            label        = "%"
            include_zero = true
            max          = "100"
          }
        }
      }
    ]
  })
}
```

## Tagging Strategy

### Required Tags

| Tag | Purpose | Example |
|-----|---------|---------|
| `service` | APM service name, primary identifier across all Datadog products | `service:api` |
| `env` | Deployment environment, used for filtering and access control | `env:production` |
| `team` | Owning team, used for routing alerts and cost attribution | `team:platform` |

### Recommended Tags

| Tag | Purpose | Example |
|-----|---------|---------|
| `tier` | Service criticality level for prioritizing incidents and SLO targets | `tier:1` |
| `lang` | Primary language or runtime, useful for filtering APM traces | `lang:go` |
| `version` | Deployed version, enables deployment correlation in APM | `version:1.4.2` |

### Terraform Locals for Consistent Tagging

```hcl
variable "service" {
  description = "Service name"
  type        = string
  default     = "api"
}

variable "team" {
  description = "Owning team"
  type        = string
  default     = "platform"
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

locals {
  common_tags = [
    "service:${var.service}",
    "team:${var.team}",
    "env:${var.env}",
  ]
}

# Applied to monitors
resource "datadog_monitor" "example" {
  name    = "[${title(var.env)}] ${title(var.service)} Example Monitor"
  type    = "query alert"
  query   = "avg(last_5m):avg:http.request.duration.p99{service:${var.service},env:${var.env}} > 500"
  message = "@slack-${var.team}-alerts"

  tags = local.common_tags
}

# Applied to SLOs
resource "datadog_service_level_objective" "example" {
  name = "${title(var.service)} Availability"
  type = "metric"

  query {
    numerator   = "sum:http.requests{service:${var.service},env:${var.env},!status_class:5xx}.as_count()"
    denominator = "sum:http.requests{service:${var.service},env:${var.env}}.as_count()"
  }

  thresholds {
    timeframe = "30d"
    target    = 99.9
    warning   = 99.95
  }

  tags = local.common_tags
}

# Applied to synthetics
resource "datadog_synthetics_test" "example" {
  name    = "${title(var.service)} Health Check"
  type    = "api"
  subtype = "http"
  status  = "live"

  locations = ["aws:eu-west-1"]

  request_definition {
    method = "GET"
    url    = "https://${var.service}.example.com/healthz"
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  options_list {
    tick_every = 300
  }

  message = "@slack-${var.team}-alerts"

  tags = local.common_tags
}
```

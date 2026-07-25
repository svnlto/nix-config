# Monitoring Infrastructure (Terraform)

Terraform Helm releases for deploying monitoring
collection infrastructure. Wrap with Terragrunt for
orchestration. All examples show raw Terraform resources.

## 1. Datadog Agent

Deploy the Datadog Agent as a DaemonSet with APM, logs,
process monitoring, DogStatsD, and Prometheus scraping:

```hcl
resource "helm_release" "datadog_agent" {
  name             = "datadog"
  namespace        = "datadog"
  create_namespace = true
  repository       = "https://helm.datadoghq.com"
  chart            = "datadog"
  version          = "3.70.0"
  wait             = true
  timeout          = 600

  values = [yamlencode({
    datadog = {
      apiKeyExistingSecret = "datadog-api-key"
      site                 = "datadoghq.eu"

      apm = {
        portEnabled   = true
        socketEnabled = true
      }

      logs = {
        enabled            = true
        containerCollectAll = true
      }

      processAgent = {
        enabled = true
      }

      dogstatsd = {
        nonLocalTraffic = true
        port            = 8125
      }

      prometheusScrape = {
        enabled = true
      }
    }

    agents = {
      containers = {
        agent = {
          resources = {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }

      tolerations = [{
        operator = "Exists"
        effect   = "NoSchedule"
      }]
    }

    clusterAgent = {
      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "512Mi"
        }
      }
    }
  })]
}
```

The `apiKeyExistingSecret` references a Kubernetes Secret
named `datadog-api-key` with a `api-key` data key. Create
it before deploying the chart, for example via External
Secrets Operator or `kubernetes_secret` resource.

The `Exists` toleration on agents ensures the DaemonSet
schedules on every node, including tainted control-plane
and GPU nodes.

## 2. OTel Collector

Deploy the OpenTelemetry Collector as a gateway that
receives OTLP telemetry and forwards to Datadog:

```hcl
resource "helm_release" "otel_collector" {
  name             = "otel-collector"
  namespace        = "opentelemetry"
  create_namespace = true
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  version          = "0.97.0"
  wait             = true
  timeout          = 600

  values = [yamlencode({
    mode = "deployment"

    config = {
      receivers = {
        otlp = {
          protocols = {
            grpc = {
              endpoint = "0.0.0.0:4317"
            }
            http = {
              endpoint = "0.0.0.0:4318"
            }
          }
        }
      }

      processors = {
        batch = {
          timeout         = "5s"
          send_batch_size = 512
        }
        memory_limiter = {
          check_interval = "1s"
          limit_mib      = 512
        }
      }

      exporters = {
        datadog = {
          api = {
            key  = "$${DD_API_KEY}"
            site = "datadoghq.eu"
          }
        }
      }

      service = {
        pipelines = {
          traces = {
            receivers  = ["otlp"]
            processors = ["memory_limiter", "batch"]
            exporters  = ["datadog"]
          }
          metrics = {
            receivers  = ["otlp"]
            processors = ["memory_limiter", "batch"]
            exporters  = ["datadog"]
          }
        }
      }
    }
  })]

  set_sensitive {
    name  = "extraEnvs[0].name"
    value = "DD_API_KEY"
  }

  set_sensitive {
    name  = "extraEnvs[0].valueFrom.secretKeyRef.name"
    value = "datadog-api-key"
  }

  set_sensitive {
    name  = "extraEnvs[0].valueFrom.secretKeyRef.key"
    value = "api-key"
  }
}
```

Set `mode = "deployment"` for a centralized gateway that
receives telemetry from application SDKs. Use
`mode = "daemonset"` when you need a node-level collector
that scrapes local endpoints or receives from sidecar-less
workloads.

The `$${DD_API_KEY}` syntax is a Terraform-escaped
reference to the environment variable injected into the
collector pod from the Kubernetes Secret.

## 3. Log Forwarding

### Datadog Agent log collection

The Datadog Agent collects container logs when enabled
in the Helm values. Filter noisy namespaces with the
`containerExcludeLogs` setting:

```hcl
resource "helm_release" "datadog_agent_logs" {
  name             = "datadog"
  namespace        = "datadog"
  create_namespace = true
  repository       = "https://helm.datadoghq.com"
  chart            = "datadog"
  version          = "3.70.0"
  wait             = true
  timeout          = 600

  values = [yamlencode({
    datadog = {
      apiKeyExistingSecret = "datadog-api-key"
      site                 = "datadoghq.eu"

      logs = {
        enabled            = true
        containerCollectAll = true
      }

      containerExcludeLogs = "kube_namespace:kube-system"
    }
  })]
}
```

### Pod annotation autodiscovery

Datadog uses pod annotations to identify log sources and
services. Add these to your Kubernetes Deployment template:

```yaml
ad.datadoghq.com/<container>.logs: |
  [{"source":"go","service":"api"}]
```

Complete Deployment manifest with log annotations:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
      annotations:
        ad.datadoghq.com/api.logs: |
          [{"source":"go","service":"api"}]
    spec:
      containers:
        - name: api
          image: registry.example.com/api:latest
          ports:
            - containerPort: 8080
              name: http
          env:
            - name: DD_SERVICE
              value: api
            - name: DD_ENV
              value: production
```

### Processing pipelines

Log processing (grok parsing, category processors,
remappers, and pipeline configuration) is covered in the
`sre-engineer` skill's `datadog-observability.md`
reference. This file covers only the collection
infrastructure.

## 4. Prometheus Scraping

### OpenMetrics via pod annotations

The Datadog Agent discovers Prometheus endpoints using
pod annotations for the OpenMetrics integration:

```yaml
ad.datadoghq.com/<container>.checks: |
  {
    "openmetrics": {
      "instances": [{
        "openmetrics_endpoint": "http://%%host%%:9090/metrics",
        "namespace": "api",
        "metrics": [
          "http_requests_total",
          "http_request_duration_seconds.*"
        ]
      }]
    }
  }
```

### Global Prometheus scraping

Enable global scraping in the Datadog Agent Helm values
and add service-specific overrides with
`additionalConfigs`:

```hcl
resource "helm_release" "datadog_prometheus" {
  name             = "datadog"
  namespace        = "datadog"
  create_namespace = true
  repository       = "https://helm.datadoghq.com"
  chart            = "datadog"
  version          = "3.70.0"
  wait             = true
  timeout          = 600

  values = [yamlencode({
    datadog = {
      apiKeyExistingSecret = "datadog-api-key"
      site                 = "datadoghq.eu"

      prometheusScrape = {
        enabled           = true
        serviceEndpoints  = true
        additionalConfigs = [
          {
            configurations = [
              {
                autodiscovery = {
                  kubernetes_annotations = {
                    include = {
                      "prometheus.io/scrape" = "true"
                    }
                  }
                }
                namespace_mapping = {
                  "prometheus.io/namespace" = "namespace"
                }
                metrics = ["*"]
              }
            ]
          }
        ]
      }
    }
  })]
}
```

### Complete Go service with scraping annotations

A Kubernetes Deployment for a Go service that exposes
a `/metrics` endpoint and is scraped by the Datadog
Agent:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
      annotations:
        ad.datadoghq.com/api.checks: |
          {
            "openmetrics": {
              "instances": [{
                "openmetrics_endpoint": "http://%%host%%:9090/metrics",
                "namespace": "api",
                "metrics": [
                  "http_requests_total",
                  "http_request_duration_seconds.*",
                  "orders_processed_total",
                  "order_processing_duration_seconds.*"
                ]
              }]
            }
          }
    spec:
      containers:
        - name: api
          image: registry.example.com/api:latest
          ports:
            - containerPort: 8080
              name: http
            - containerPort: 9090
              name: metrics
          env:
            - name: DD_SERVICE
              value: api
            - name: DD_ENV
              value: production
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
```

### Datadog scraping vs OTel Collector scraping

**Use Datadog Agent scraping when:**

- You already run the Datadog Agent on every node
- Metrics come from Prometheus-instrumented pods
- You want zero additional infrastructure
- Pod annotations provide enough targeting control

**Use OTel Collector scraping when:**

- You need to transform or enrich metrics before export
- Multiple backends consume the same metrics (Datadog
  and a Prometheus-compatible TSDB)
- You need tail-based sampling or complex routing
- You want a vendor-neutral pipeline that can switch
  backends without changing application code

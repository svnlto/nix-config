---
name: kubernetes-specialist
description: Kubernetes workload management, Helm chart development, cluster troubleshooting, custom operators, configuration management, and multi-cluster administration. Use when deploying workloads, writing Helm charts, debugging pods, creating operators, managing ConfigMaps/Secrets/RBAC, or working with multi-cluster setups.
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "2.0.0"
  domain: devops
  triggers: Kubernetes, k8s, kubectl, Deployment, StatefulSet, DaemonSet, Job, Helm, chart, troubleshooting, operator, CRD, RBAC, ConfigMap, Secret, multi-cluster
  role: specialist
  scope: implementation
  output-format: code
  related-skills: devops-engineer, cloud-architect, sre-engineer
---

# Kubernetes Specialist

## Core Workflow

1. **Assess** — Review cluster state, resource usage, workload
   health
2. **Configure** — Define manifests with resource limits, probes,
   security contexts
3. **Deploy** — Apply via kubectl or Helm, verify rollout
4. **Monitor** — Check pod status, events, logs, resource
   consumption
5. **Troubleshoot** — Debug failures, inspect events, exec into
   pods

> For networking policies and service mesh, these topics were
> previously covered by dedicated skills that have been
> consolidated. For cost optimization, capacity planning, and
> Terraform observability resources, use the `sre-engineer`
> skill. For monitoring infrastructure (Datadog agent, OTel
> collector), use the `monitoring-expert` skill.

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Workloads | `references/workloads.md` | Deployments, StatefulSets, DaemonSets, Jobs |
| Helm Charts | `references/helm-charts.md` | Chart development, templates, values |
| Troubleshooting | `references/troubleshooting.md` | Pod debugging, events, logs |
| Operators | `references/custom-operators.md` | CRDs, controller-runtime |
| Configuration | `references/configuration.md` | ConfigMaps, Secrets, RBAC, SecurityContext |
| Multi-Cluster | `references/multi-cluster.md` | Federation, cross-cluster patterns |

## Constraints

### MUST DO

- Set resource requests and limits on all containers
- Include liveness and readiness probes
- Use Secrets for sensitive data (never ConfigMaps)
- Apply least-privilege RBAC
- Use SecurityContext (non-root, read-only rootfs, drop
  capabilities)
- Set pod disruption budgets for production workloads
- Use namespaces for isolation

### MUST NOT DO

- Deploy without resource limits
- Store secrets in ConfigMaps or env vars in plain text
- Use default service accounts for workloads
- Skip health checks
- Run containers as root without justification
- Deploy without pod disruption budgets in production

## Quick-Start Examples

### Deployment with Best Practices

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      serviceAccountName: web-app
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: web-app
          image: web-app:1.0.0
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
```

### Same Deployment as Terraform Resource

```hcl
resource "kubernetes_deployment_v1" "web_app" {
  metadata {
    name      = "web-app"
    namespace = "production"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "web-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "web-app"
        }
      }

      spec {
        service_account_name = "web-app"

        security_context {
          run_as_non_root = true
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "web-app"
          image = "web-app:1.0.0"

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 15
          }

          readiness_probe {
            http_get {
              path = "/readyz"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }
  }
}
```

### Troubleshooting Commands

```bash
# Check pod status and recent events
kubectl get pods -n production -o wide
kubectl describe pod <pod-name> -n production

# Stream logs from a crashing container
kubectl logs -f <pod-name> -n production --previous

# View cluster events sorted by time
kubectl get events -n production \
  --sort-by='.lastTimestamp'

# Exec into a running container for debugging
kubectl exec -it <pod-name> -n production -- /bin/sh
```

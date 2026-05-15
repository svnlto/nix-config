# Kubernetes Workloads

Kubernetes workload resources with both YAML manifests and
Terraform kubernetes provider examples.

## Deployments

Deployments manage stateless replicated pods with rolling
update strategies.

### YAML Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
  labels:
    app: web-app
    version: v1
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        version: v1
    spec:
      serviceAccountName: web-app
      terminationGracePeriodSeconds: 30
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: web-app
          image: registry.example.com/web-app:1.0.0
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
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
              port: http
            initialDelaySeconds: 10
            periodSeconds: 15
            timeoutSeconds: 3
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
          startupProbe:
            httpGet:
              path: /healthz
              port: http
            failureThreshold: 30
            periodSeconds: 10
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

### Terraform

```hcl
resource "kubernetes_deployment_v1" "web_app" {
  metadata {
    name      = "web-app"
    namespace = "production"
    labels = {
      app     = "web-app"
      version = "v1"
    }
  }

  spec {
    replicas               = 3
    revision_history_limit = 5

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "0"
      }
    }

    selector {
      match_labels = {
        app = "web-app"
      }
    }

    template {
      metadata {
        labels = {
          app     = "web-app"
          version = "v1"
        }
      }

      spec {
        service_account_name             = "web-app"
        termination_grace_period_seconds = 30

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          fs_group        = 1000
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "web-app"
          image = "registry.example.com/web-app:1.0.0"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
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
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 15
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/readyz"
              port = "http"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          startup_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
            failure_threshold = 30
            period_seconds    = 10
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }
}
```

## StatefulSets

StatefulSets manage stateful applications with stable network
identities and persistent storage.

### YAML Manifest

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
spec:
  serviceName: postgres-headless
  replicas: 3
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      serviceAccountName: postgres
      terminationGracePeriodSeconds: 60
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
        fsGroup: 999
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: postgres
          image: postgres:16-alpine
          ports:
            - name: postgresql
              containerPort: 5432
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-credentials
                  key: password
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          resources:
            requests:
              cpu: 250m
              memory: 512Mi
            limits:
              cpu: "1"
              memory: 1Gi
          livenessProbe:
            exec:
              command:
                - pg_isready
                - -U
                - postgres
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            exec:
              command:
                - pg_isready
                - -U
                - postgres
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 20Gi
```

### Terraform

```hcl
resource "kubernetes_stateful_set_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "production"
  }

  spec {
    service_name           = "postgres-headless"
    replicas               = 3
    pod_management_policy  = "OrderedReady"

    update_strategy {
      type = "RollingUpdate"
      rolling_update {
        partition = 0
      }
    }

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        service_account_name             = "postgres"
        termination_grace_period_seconds = 60

        security_context {
          run_as_non_root = true
          run_as_user     = 999
          fs_group        = 999
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "postgres"
          image = "postgres:16-alpine"

          port {
            name           = "postgresql"
            container_port = 5432
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "postgres-credentials"
                key  = "password"
              }
            }
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
          }

          liveness_probe {
            exec {
              command = [
                "pg_isready",
                "-U",
                "postgres",
              ]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            exec {
              command = [
                "pg_isready",
                "-U",
                "postgres",
              ]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }

          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "fast-ssd"

        resources {
          requests = {
            storage = "20Gi"
          }
        }
      }
    }
  }
}
```

## DaemonSets

DaemonSets ensure a pod runs on every (or selected) node in
the cluster.

### YAML Manifest

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  namespace: monitoring
  labels:
    app: log-collector
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      serviceAccountName: log-collector
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          effect: NoSchedule
      nodeSelector:
        kubernetes.io/os: linux
      terminationGracePeriodSeconds: 30
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: log-collector
          image: fluent/fluent-bit:3.0
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /api/v1/health
              port: 2020
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /api/v1/health
              port: 2020
            periodSeconds: 10
          volumeMounts:
            - name: varlog
              mountPath: /var/log
              readOnly: true
            - name: config
              mountPath: /fluent-bit/etc
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
        - name: config
          configMap:
            name: log-collector-config
```

### Terraform

```hcl
resource "kubernetes_daemon_set_v1" "log_collector" {
  metadata {
    name      = "log-collector"
    namespace = "monitoring"
    labels = {
      app = "log-collector"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "log-collector"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
      }
    }

    template {
      metadata {
        labels = {
          app = "log-collector"
        }
      }

      spec {
        service_account_name             = "log-collector"
        termination_grace_period_seconds = 30

        toleration {
          key    = "node-role.kubernetes.io/control-plane"
          effect = "NoSchedule"
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "log-collector"
          image = "fluent/fluent-bit:3.0"

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/api/v1/health"
              port = 2020
            }
            period_seconds = 30
          }

          readiness_probe {
            http_get {
              path = "/api/v1/health"
              port = 2020
            }
            period_seconds = 10
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
            read_only  = true
          }

          volume_mount {
            name       = "config"
            mount_path = "/fluent-bit/etc"
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "config"
          config_map {
            name = "log-collector-config"
          }
        }
      }
    }
  }
}
```

## Jobs & CronJobs

Jobs run tasks to completion. CronJobs schedule Jobs on a
recurring basis.

### Job YAML

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  namespace: production
spec:
  backoffLimit: 3
  completions: 1
  parallelism: 1
  ttlSecondsAfterFinished: 3600
  activeDeadlineSeconds: 600
  template:
    spec:
      serviceAccountName: db-migration
      restartPolicy: OnFailure
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: migrate
          image: registry.example.com/db-migrate:1.0.0
          command: ["./migrate", "up"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: url
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
```

### CronJob YAML

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
  namespace: production
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  startingDeadlineSeconds: 300
  jobTemplate:
    spec:
      backoffLimit: 2
      ttlSecondsAfterFinished: 86400
      template:
        spec:
          serviceAccountName: db-backup
          restartPolicy: OnFailure
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
            seccompProfile:
              type: RuntimeDefault
          containers:
            - name: backup
              image: registry.example.com/db-backup:1.0.0
              command: ["./backup.sh"]
              env:
                - name: DATABASE_URL
                  valueFrom:
                    secretKeyRef:
                      name: db-credentials
                      key: url
                - name: S3_BUCKET
                  value: my-backups
              resources:
                requests:
                  cpu: 100m
                  memory: 256Mi
                limits:
                  cpu: 500m
                  memory: 512Mi
              securityContext:
                allowPrivilegeEscalation: false
                readOnlyRootFilesystem: true
                capabilities:
                  drop: ["ALL"]
```

### Terraform Job

```hcl
resource "kubernetes_job_v1" "db_migration" {
  metadata {
    name      = "db-migration"
    namespace = "production"
  }

  spec {
    backoff_limit             = 3
    completions               = 1
    parallelism               = 1
    ttl_seconds_after_finished = 3600
    active_deadline_seconds   = 600

    template {
      metadata {}

      spec {
        service_account_name = "db-migration"
        restart_policy       = "OnFailure"

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name    = "migrate"
          image   = "registry.example.com/db-migrate:1.0.0"
          command = ["./migrate", "up"]

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = "db-credentials"
                key  = "url"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
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

### Terraform CronJob

```hcl
resource "kubernetes_cron_job_v1" "db_backup" {
  metadata {
    name      = "db-backup"
    namespace = "production"
  }

  spec {
    schedule                      = "0 2 * * *"
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3
    starting_deadline_seconds     = 300

    job_template {
      metadata {}

      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 86400

        template {
          metadata {}

          spec {
            service_account_name = "db-backup"
            restart_policy       = "OnFailure"

            security_context {
              run_as_non_root = true
              run_as_user     = 1000
              seccomp_profile {
                type = "RuntimeDefault"
              }
            }

            container {
              name    = "backup"
              image   = "registry.example.com/db-backup:1.0.0"
              command = ["./backup.sh"]

              env {
                name = "DATABASE_URL"
                value_from {
                  secret_key_ref {
                    name = "db-credentials"
                    key  = "url"
                  }
                }
              }

              env {
                name  = "S3_BUCKET"
                value = "my-backups"
              }

              resources {
                requests = {
                  cpu    = "100m"
                  memory = "256Mi"
                }
                limits = {
                  cpu    = "500m"
                  memory = "512Mi"
                }
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
  }
}
```

## Pod Disruption Budgets

PDBs protect workload availability during voluntary
disruptions like node drains and cluster upgrades.

### YAML Manifest (minAvailable)

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web-app
```

### YAML Manifest (maxUnavailable)

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
  namespace: production
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: web-app
```

### Terraform

```hcl
resource "kubernetes_pod_disruption_budget_v1" "web_app" {
  metadata {
    name      = "web-app-pdb"
    namespace = "production"
  }

  spec {
    min_available = "2"

    selector {
      match_labels = {
        app = "web-app"
      }
    }
  }
}
```

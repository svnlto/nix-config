# Helm Charts

Helm chart development patterns and Terraform integration.

## Chart Structure

Standard Helm chart directory layout:

```text
mychart/
  Chart.yaml          # Chart metadata and dependencies
  Chart.lock          # Pinned dependency versions
  values.yaml         # Default configuration values
  values.schema.json  # JSON Schema for values validation
  templates/          # Kubernetes manifest templates
    _helpers.tpl      # Named template definitions
    deployment.yaml
    service.yaml
    ingress.yaml
    hpa.yaml
    pdb.yaml
    serviceaccount.yaml
    configmap.yaml
    secret.yaml
    NOTES.txt         # Post-install usage instructions
  tests/              # Helm test definitions
    test-connection.yaml
  crds/               # Custom Resource Definitions
```

### Chart.yaml

```yaml
apiVersion: v2
name: mychart
description: A Helm chart for my application
type: application
version: 1.0.0
appVersion: "2.0.0"
kubeVersion: ">=1.26.0"
home: https://github.com/org/mychart
maintainers:
  - name: Team Name
    email: team@example.com
dependencies:
  - name: postgresql
    version: "~13.0"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: "~18.0"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

## Template Patterns

### Value Access and Defaults

```yaml
# Direct value access
replicas: {{ .Values.replicaCount }}

# With default fallback
replicas: {{ .Values.replicaCount | default 3 }}

# Nested value with quote
image: "{{ .Values.image.repository }}:{{
  .Values.image.tag | default .Chart.AppVersion }}"

# Required value (fails if missing)
namespace: {{ required "namespace is required"
  .Values.namespace }}
```

### Named Templates (_helpers.tpl)

```yaml
{{/*
Chart name, truncated to 63 chars.
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride
    | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name.
*/}}
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride
    | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name
    .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name
    | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ include "mychart.chart" . }}
{{ include "mychart.selectorLabels" . }}
app.kubernetes.io/version: {{
  .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### Conditionals and Loops

```yaml
# Conditional block
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "mychart.fullname" . }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{
                  include "mychart.fullname" $ }}
                port:
                  number: {{ .port | default 80 }}
          {{- end }}
    {{- end }}
{{- end }}
```

### Dynamic Values with tpl

```yaml
# values.yaml
annotations:
  custom: "{{ .Release.Name }}-annotation"

# template — use tpl to evaluate the string
metadata:
  annotations:
    {{- range $key, $val := .Values.annotations }}
    {{ $key }}: {{ tpl $val $ | quote }}
    {{- end }}
```

## Values Design

### Sensible Defaults

```yaml
# values.yaml
replicaCount: 3

image:
  repository: registry.example.com/myapp
  tag: ""  # Defaults to Chart.AppVersion
  pullPolicy: IfNotPresent

serviceAccount:
  create: true
  name: ""
  annotations: {}

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts: []
  tls: []

# Component-level nesting
postgresql:
  enabled: true
  auth:
    database: myapp
    existingSecret: pg-credentials

redis:
  enabled: false
  architecture: standalone
```

### Values Schema Validation

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["image", "resources"],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1
    },
    "image": {
      "type": "object",
      "required": ["repository"],
      "properties": {
        "repository": { "type": "string" },
        "tag": { "type": "string" },
        "pullPolicy": {
          "type": "string",
          "enum": [
            "Always",
            "IfNotPresent",
            "Never"
          ]
        }
      }
    },
    "resources": {
      "type": "object",
      "required": ["requests", "limits"],
      "properties": {
        "requests": {
          "type": "object",
          "properties": {
            "cpu": { "type": "string" },
            "memory": { "type": "string" }
          }
        },
        "limits": {
          "type": "object",
          "properties": {
            "cpu": { "type": "string" },
            "memory": { "type": "string" }
          }
        }
      }
    }
  }
}
```

### Overriding Values

```bash
# Override with --set
helm install myrelease ./mychart \
  --set replicaCount=5 \
  --set image.tag=2.0.0

# Override with values file
helm install myrelease ./mychart \
  -f production-values.yaml

# Multiple value files (last wins)
helm install myrelease ./mychart \
  -f values-base.yaml \
  -f values-production.yaml

# Set sensitive values
helm install myrelease ./mychart \
  --set-json 'ingress.hosts=[{"host":"app.example.com"}]'
```

## Hooks

Helm hooks execute actions at specific lifecycle points.

### Pre/Post Install Hooks

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mychart.fullname" . }}-db-init
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: db-init
          image: "{{ .Values.image.repository }}:{{
            .Values.image.tag
            | default .Chart.AppVersion }}"
          command: ["./init-db.sh"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: url
```

### Upgrade Hooks with Ordering

```yaml
# Pre-upgrade: backup database (runs first)
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mychart.fullname" . }}-backup
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: backup
          image: registry.example.com/db-backup:latest
          command: ["./backup.sh"]
---
# Pre-upgrade: run migration (runs second)
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mychart.fullname" . }}-migrate
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: migrate
          image: "{{ .Values.image.repository }}:{{
            .Values.image.tag
            | default .Chart.AppVersion }}"
          command: ["./migrate", "up"]
---
# Post-upgrade: verify deployment health
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mychart.fullname" . }}-verify
  annotations:
    "helm.sh/hook": post-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: verify
          image: curlimages/curl:latest
          command:
            - sh
            - -c
            - |
              curl -sf http://{{
                include "mychart.fullname" . }}:{{
                .Values.service.port }}/healthz
```

### Hook Delete Policies

| Policy | Behavior |
|--------|----------|
| `before-hook-creation` | Delete previous hook resource before new one |
| `hook-succeeded` | Delete after hook succeeds |
| `hook-failed` | Delete after hook fails |

## Testing

### Local Rendering

```bash
# Render templates without installing
helm template myrelease ./mychart

# Render with custom values
helm template myrelease ./mychart \
  -f production-values.yaml

# Render specific template
helm template myrelease ./mychart \
  -s templates/deployment.yaml

# Show computed values
helm template myrelease ./mychart --show-only templates/deployment.yaml
```

### Static Analysis

```bash
# Lint chart for issues
helm lint ./mychart

# Lint with values
helm lint ./mychart -f production-values.yaml

# Strict mode (warnings become errors)
helm lint ./mychart --strict
```

### Test Pods

```yaml
# tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "mychart.fullname" . }}-test
  annotations:
    "helm.sh/hook": test
spec:
  restartPolicy: Never
  containers:
    - name: test
      image: busybox:latest
      command: ["wget"]
      args:
        - "--spider"
        - "http://{{ include "mychart.fullname" . }}:{{
          .Values.service.port }}"
```

```bash
# Run tests after install
helm test myrelease -n production
```

### CI with chart-testing

```bash
# Lint and install changed charts
ct lint-and-install --config ct.yaml

# Lint only
ct lint --config ct.yaml

# ct.yaml
target-branch: main
chart-dirs:
  - charts
helm-extra-args: --timeout 600s
```

### Upgrade Preview with helm-diff

```bash
# Preview changes before upgrade
helm diff upgrade myrelease ./mychart \
  -f production-values.yaml

# Show only changed resources
helm diff upgrade myrelease ./mychart \
  --no-hooks --suppress-secrets
```

## Terraform Integration

### helm_release Resource

```hcl
resource "helm_release" "app" {
  name             = "myapp"
  repository       = "https://charts.example.com"
  chart            = "mychart"
  version          = "1.0.0"
  namespace        = "production"
  create_namespace = true

  # Deployment behavior
  wait             = true
  wait_for_jobs    = true
  atomic           = true
  timeout          = 600
  cleanup_on_fail  = true

  # Values from templatefile
  values = [
    templatefile("${path.module}/helm-values.yaml", {
      environment  = var.environment
      replicas     = var.replicas
      image_tag    = var.image_tag
      domain       = var.domain
    })
  ]

  # Individual value overrides
  set {
    name  = "image.repository"
    value = var.image_repository
  }

  # Sensitive values (hidden from plan output)
  set_sensitive {
    name  = "database.password"
    value = var.db_password
  }

  depends_on = [
    kubernetes_namespace.production,
    kubernetes_secret.db_credentials,
  ]
}
```

### Terraform Values Template

```yaml
# helm-values.yaml (used with templatefile)
replicaCount: ${replicas}

image:
  tag: "${image_tag}"

ingress:
  enabled: true
  hosts:
    - host: "${domain}"
      paths:
        - path: /
          pathType: Prefix

resources:
  requests:
    cpu: ${environment == "production" ? "500m" : "100m"}
    memory: ${environment == "production" ? "512Mi" : "128Mi"}
  limits:
    cpu: ${environment == "production" ? "1" : "500m"}
    memory: ${environment == "production" ? "1Gi" : "256Mi"}
```

### Multiple Releases Pattern

```hcl
locals {
  releases = {
    frontend = {
      chart     = "webapp"
      version   = "2.0.0"
      namespace = "frontend"
      values    = "frontend-values.yaml"
    }
    backend = {
      chart     = "api-service"
      version   = "1.5.0"
      namespace = "backend"
      values    = "backend-values.yaml"
    }
    worker = {
      chart     = "worker"
      version   = "1.2.0"
      namespace = "backend"
      values    = "worker-values.yaml"
    }
  }
}

resource "helm_release" "releases" {
  for_each = local.releases

  name             = each.key
  repository       = "https://charts.example.com"
  chart            = each.value.chart
  version          = each.value.version
  namespace        = each.value.namespace
  create_namespace = true

  wait    = true
  atomic  = true
  timeout = 600

  values = [
    templatefile(
      "${path.module}/${each.value.values}",
      {
        environment = var.environment
        release     = each.key
      }
    )
  ]
}
```

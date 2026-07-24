# GitOps toolkit: sources and appliers

Two layers: a **source** downloads an artifact on an interval; an **applier**
reconciles it into the cluster. Keep them in the same namespace as the app for
tenancy, or in `flux-system` for platform config.

## Sources

### GitRepository (source.toolkit.fluxcd.io/v1)

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata: { name: fleet, namespace: flux-system }
spec:
  interval: 5m
  url: ssh://git@github.com/my-org/fleet.git
  ref:
    branch: main            # or tag: / semver: / commit:
  secretRef:
    name: flux-system       # SSH key or token
```

### OCIRepository (source.toolkit.fluxcd.io/v1)

Prefer OCI for artifacts built in CI — faster, content-addressed, signable.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata: { name: podinfo, namespace: apps }
spec:
  interval: 10m
  url: oci://ghcr.io/stefanprodan/manifests/podinfo
  ref:
    tag: latest             # or semver: / digest:
  verify:                   # optional cosign verification
    provider: cosign
```

## Kustomization (kustomize.toolkit.fluxcd.io/v1)

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata: { name: podinfo, namespace: apps }
spec:
  interval: 10m
  retryInterval: 2m
  timeout: 3m
  sourceRef: { kind: OCIRepository, name: podinfo }
  path: "./kustomize"
  prune: true               # remove resources deleted from source
  wait: true                # wait for all applied resources to be Ready
  targetNamespace: apps
  dependsOn:
    - name: podinfo-crds     # apply CRDs first
  healthChecks:              # explicit gates when wait isn't enough
    - apiVersion: apps/v1
      kind: Deployment
      name: podinfo
      namespace: apps
  postBuild:
    substitute:
      cluster_env: "production"
    substituteFrom:
      - kind: ConfigMap
        name: cluster-vars
      - kind: Secret
        name: cluster-secrets
```

Key fields:

- `prune` — GitOps garbage collection. Off means deleted manifests linger.
- `wait` / `healthChecks` — block the Kustomization as Ready until workloads
  are actually healthy; upstream `dependsOn` gates on this.
- `dependsOn` — ordering across Kustomizations (CRDs → operators → apps).
- `postBuild.substitute[From]` — variable substitution at apply time; the
  clean way to template per-cluster values without a Helm chart.

## HelmRelease (helm.toolkit.fluxcd.io/v2)

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata: { name: podinfo, namespace: apps }
spec:
  interval: 30m
  url: https://stefanprodan.github.io/podinfo
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata: { name: podinfo, namespace: apps }
spec:
  interval: 10m
  chart:
    spec:
      chart: podinfo
      version: "6.x"                    # pinned range
      sourceRef: { kind: HelmRepository, name: podinfo }
  install: { remediation: { retries: 3 } }
  upgrade: { remediation: { retries: 3 } }
  values:
    replicaCount: 2
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-values
```

For a chart stored in OCI, set `chart.spec.sourceRef.kind: OCIRepository`.
`remediation` auto-rolls back failed installs/upgrades — always set it.

## Layout convention

```text
fleet/
  clusters/<cluster>/         # FluxInstance sync path; Kustomizations only
  infrastructure/             # controllers, CRDs, ingress (dependsOn ordered)
  apps/<app>/                 # per-app source + applier + values
```

Cluster overlays reference shared bases; per-cluster values come through
`postBuild.substituteFrom` or HelmRelease `valuesFrom`.

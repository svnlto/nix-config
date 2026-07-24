# flux-operator: installing and managing Flux

The operator manages Flux's own lifecycle via CRDs in the
`fluxcd.controlplane.io/v1` API group. Install the operator once (Helm or
OCI), then everything else is declarative.

## FluxInstance (full spec)

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
  annotations:
    fluxcd.controlplane.io/reconcileEvery: "1h"
    fluxcd.controlplane.io/reconcileArtifactEvery: "10m"
    fluxcd.controlplane.io/reconcileTimeout: "5m"
spec:
  distribution:
    version: "2.8.x"                 # pinned range
    registry: "ghcr.io/fluxcd"
    artifact: "oci://ghcr.io/controlplaneio-fluxcd/flux-operator-manifests"
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
    - image-reflector-controller
    - image-automation-controller
    - source-watcher                 # optional, for OCI source events
  cluster:
    type: kubernetes                 # kubernetes | openshift | aws | azure | gcp
    size: large                      # small | medium | large (resource presets)
    multitenant: true
    tenantDefaultServiceAccount: flux
    networkPolicy: true
    domain: "cluster.local"
  storage:
    class: "standard"
    size: "10Gi"
  sync:
    kind: GitRepository              # or OCIRepository / Bucket
    url: "ssh://git@github.com/my-org/my-fleet.git"
    ref: "refs/heads/main"
    path: "clusters/my-cluster"
    pullSecret: "flux-system"
  kustomize:
    patches:
      - target: { kind: Deployment }
        patch: |
          - op: add
            path: /spec/template/spec/tolerations
            value:
              - key: "CriticalAddonsOnly"
                operator: "Exists"
```

Notes:

- `sync` replaces the imperative `flux bootstrap` commit — the operator writes
  the root `GitRepository` + `Kustomization` for you.
- `kustomize.patches` customize the controller Deployments (node selectors,
  tolerations, resources) without forking manifests.
- Upgrade Flux by bumping `distribution.version` and committing — the operator
  rolls the controllers.

## Multi-tenancy

Set `cluster.multitenant: true` and `tenantDefaultServiceAccount`. Flux then
requires every Kustomization/HelmRelease to run under a named ServiceAccount,
so a tenant cannot apply cluster-scoped or cross-namespace resources it lacks
RBAC for. Give each tenant its own namespace, ServiceAccount, and a
`GitRepository` scoped to their path.

## ResourceSet and ResourceSetInputProvider

`ResourceSet` templates a group of resources from a list of inputs — the
self-service / preview-environment primitive. `ResourceSetInputProvider`
generates those inputs by scanning Git tags, PRs, or OCI tags.

Example: track the latest release tag for time-based delivery.

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: ResourceSetInputProvider
metadata:
  name: my-app-release
  namespace: apps
  annotations:
    fluxcd.controlplane.io/reconcileEvery: "10m"
spec:
  schedule:
    - cron: "0 8 * * 1-5"            # deployment window
      timeZone: "Europe/London"
      window: 8h
  type: GitHubTag                    # GitLabTag | AzureDevOpsTag | OCIArtifactTag
  url: https://github.com/my-org/my-app
  secretRef:
    name: gh-auth
  filter:
    semver: ">=1.0.0"
    limit: 1
```

The exported input (latest tag) feeds a `ResourceSet` that renders the app's
Kustomization/HelmRelease for that version. For PR previews, use a
`type: GitHubPullRequest` provider so each open PR templates an ephemeral
namespace + release, torn down when the PR closes.

## Migrating from `flux bootstrap`

1. Author a `FluxInstance` whose `sync` mirrors the existing bootstrap
   `GitRepository` (same url/ref/path/pullSecret).
2. Install the operator alongside the running Flux.
3. Apply the `FluxInstance`; the operator adopts the existing controllers.
4. Stop running `flux bootstrap` — the operator now owns upgrades.

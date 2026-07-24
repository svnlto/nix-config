---
name: flux-operator
description: >-
  FluxCD GitOps on Kubernetes, both installing/upgrading Flux itself via the
  flux-operator (FluxInstance, ResourceSet, ResourceSetInputProvider) and
  authoring day-to-day GitOps (GitRepository/OCIRepository, Kustomization,
  HelmRelease, image automation) plus flux CLI operations. Use when installing
  or upgrading Flux, writing or debugging Kustomization/HelmRelease/source
  manifests, wiring image update automation, setting up preview environments or
  multi-tenancy, or diagnosing stuck reconciliation and drift.
metadata:
  domain: kubernetes
  role: specialist
  related-skills: kubernetes-specialist, helm-generator, talos-os-expert
---

# Flux Operator

FluxCD GitOps end to end: install Flux declaratively with the flux-operator,
then author and operate the reconciliation objects.

## Install: flux-operator over `flux bootstrap`

Prefer the **flux-operator** (`FluxInstance`) to legacy `flux bootstrap`. The
operator manages Flux's own lifecycle (install, upgrade, uninstall) as a CRD,
so the version and components are declarative and drift-corrected — no
imperative bootstrap commit to maintain.

Install the operator (Helm/OCI), then one `FluxInstance` runs everything:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
  annotations:
    fluxcd.controlplane.io/reconcileEvery: "1h"
spec:
  distribution:
    version: "2.x"                      # pin a range, e.g. "2.8.x", not latest
    registry: "ghcr.io/fluxcd"
    artifact: "oci://ghcr.io/controlplaneio-fluxcd/flux-operator-manifests"
  components:                           # trim to what you use
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
  cluster:
    type: kubernetes                    # or openshift / aws / azure / gcp
    multitenant: false
    networkPolicy: true
    domain: "cluster.local"
  sync:                                 # bootstrap the fleet from Git/OCI
    kind: GitRepository
    url: "ssh://git@github.com/my-org/my-fleet.git"
    ref: "refs/heads/main"
    path: "clusters/my-cluster"
    pullSecret: "flux-system"
```

Details, multi-tenancy, storage, patches, migration from bootstrap, and
ResourceSet/preview environments → `references/flux-operator.md`.

## Core reconciliation model

A **source** fetches artifacts; an **applier** reconciles them into the cluster.

| Applier | Source kinds | Reconciles |
|---|---|---|
| `Kustomization` (kustomize.toolkit.fluxcd.io/v1) | GitRepository, OCIRepository, Bucket | Kustomize overlays / plain manifests |
| `HelmRelease` (helm.toolkit.fluxcd.io/v2) | HelmRepository, OCIRepository, GitRepository | Helm charts |

Minimal GitOps unit:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata: { name: podinfo, namespace: default }
spec:
  interval: 5m
  url: https://github.com/stefanprodan/podinfo
  ref: { branch: master }
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata: { name: podinfo, namespace: default }
spec:
  interval: 10m
  sourceRef: { kind: GitRepository, name: podinfo }
  path: "./kustomize"
  prune: true          # delete resources removed from source
  wait: true           # block until health checks pass
  timeout: 3m
```

Manifest authoring (postBuild substitution, dependsOn ordering, health checks,
HelmRelease specs) → `references/gitops-toolkit.md`.
Image update automation → `references/image-automation.md`.

## Day-2 CLI (quick ref)

```bash
flux get kustomizations -A            # state of all appliers
flux reconcile kustomization podinfo --with-source   # force sync now
flux diff kustomization podinfo --path ./manifests   # preview before commit
flux suspend / resume kustomization podinfo          # pause/unpause GitOps
flux trace deployment/podinfo                        # which source owns this?
```

Full CLI + operator-vs-CLI reconcile semantics → `references/cli-operations.md`.
Stuck reconciliation, drift, dependency deadlocks → `references/troubleshooting.md`.

## Constraints

### MUST DO

- Pin `distribution.version` to a range (`2.8.x`), never float to latest
- `prune: true` on Kustomizations so deletes propagate (Git is source of truth)
- `wait: true` + `dependsOn` to order dependent applies (CRDs before CRs)
- Store the fleet in Git/OCI; change the cluster only through commits
- On multi-tenant clusters set `multitenant: true` + `tenantDefaultServiceAccount`

### MUST NOT DO

- `kubectl edit` a Flux-managed resource — reconciliation reverts it (drift)
- Leave a resource `suspend`ed without a tracking note; it silently stops updating
- Put secrets in Git as plaintext — use SOPS or a secret store, reference by name
- Mix `flux bootstrap` and flux-operator management of the same install

## Reference Guide

| Topic | Reference | Load when |
|---|---|---|
| Install / upgrade Flux, multi-tenancy, previews | `references/flux-operator.md` | FluxInstance, ResourceSet, migration |
| Source + Kustomization + HelmRelease authoring | `references/gitops-toolkit.md` | Writing manifests |
| Image update automation | `references/image-automation.md` | Auto-bump image tags via Git |
| flux CLI operations | `references/cli-operations.md` | reconcile, diff, suspend, trace |
| Debugging reconciliation | `references/troubleshooting.md` | Stuck, drifting, failed health |

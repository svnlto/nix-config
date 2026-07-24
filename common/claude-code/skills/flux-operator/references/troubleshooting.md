# Troubleshooting reconciliation

Start every diagnosis the same way: read the object's status conditions and
events, then trace up to the source.

```bash
flux get kustomization podinfo -A          # Ready? last applied revision?
kubectl describe kustomization podinfo -n apps   # conditions + events
flux events --for Kustomization/podinfo
```

## Symptom → cause → fix

### Stuck "not ready", never applies

- Source failed to fetch. `flux get sources git -A` — check auth
  (`secretRef`), url, and ref. Fix the secret or ref, then
  `flux reconcile source git <name>`.
- Health check never passes. `wait: true` blocks on a workload that is
  CrashLooping. `kubectl get pods` in the target namespace; fix the app, not
  the Kustomization.

### Applied revision is stale after a push

- Interval not elapsed. Force it: `flux reconcile kustomization <name>
  --with-source`.
- Source ref points at the wrong branch/tag. Check `spec.ref`.

### Resource keeps reverting my manual edit (drift)

- Expected. Flux reconciles the resource back to Git. Change it in Git, or
  `flux suspend` the owning Kustomization first if you must hand-edit.
- Find the owner: `flux trace <kind>/<name> -n <ns>`.

### Silent — resource stopped updating

- It is suspended. `flux get kustomization -A` shows `Suspended`. Resume:
  `flux resume kustomization <name>`.

### Dependency deadlock / wrong order

- CRs applied before their CRDs. Add `dependsOn` from the app Kustomization to
  the CRD Kustomization, and `wait: true` on the CRD one so it reports Ready
  only after the CRDs are established.

### Prune deleted more than expected

- `prune: true` removes anything previously applied but now absent from source.
  Check the diff before merge (`flux diff kustomization`). Never disable prune
  to "fix" this — narrow the `path` or split the Kustomization instead.

### HelmRelease stuck / failed upgrade

- `flux get helmreleases -A`; `kubectl describe helmrelease <name>`.
- With `remediation.retries` set, Flux rolls back automatically. If wedged,
  `flux reconcile helmrelease <name> --with-source`. Check chart `version`
  pin and `values` schema against the chart.

## flux-operator install issues

```bash
kubectl get fluxinstance -n flux-system
kubectl describe fluxinstance flux -n flux-system   # distribution + component status
kubectl -n flux-system logs deploy/flux-operator
```

- Controllers not coming up: verify `distribution.version` is a valid range and
  the `registry`/`artifact` are reachable from the cluster (air-gapped clusters
  need a mirrored registry).
- Multi-tenant apply denied: the Kustomization/HelmRelease is missing a
  `serviceAccountName`, or the tenant SA lacks RBAC. Grant namespaced RBAC;
  do not disable `multitenant`.

## Notifications for faster signal

Wire `notification-controller` (Alert + Provider) to push reconcile failures to
Slack/Teams so drift and failed applies surface without polling `flux get`.

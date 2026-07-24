# flux CLI operations

Day-2 driving of a running install. The CLI triggers and inspects
reconciliation; it does not replace Git as the source of truth.

## Inspect

```bash
flux get all -A                       # every Flux object and its status
flux get kustomizations -A            # appliers + last applied revision
flux get sources git -A               # source fetch status
flux get helmreleases -A
flux events --for Kustomization/podinfo   # recent reconcile events
flux trace deployment/podinfo -n apps     # which source/applier owns a resource
flux stats -A                         # object counts, reconcile durations
```

## Reconcile (force now, off-interval)

```bash
flux reconcile kustomization podinfo               # re-apply current source
flux reconcile kustomization podinfo --with-source # fetch source first, then apply
flux reconcile helmrelease podinfo --with-source
flux reconcile source git fleet                    # just refetch the repo
```

`--with-source` is the usual one: it pulls the latest commit before applying,
so it reflects what you just pushed.

## Preview before commit

```bash
# Diff local manifests against what is live in the cluster
flux diff kustomization podinfo --path ./apps/podinfo

# Recursive across dependent Kustomizations, using local source copies
flux diff kustomization podinfo --path ./apps/podinfo \
  --recursive \
  --local-sources GitRepository/flux-system/fleet=./
```

Run `flux diff` in CI on a PR to show the exact cluster impact before merge.

## Suspend / resume

```bash
flux suspend kustomization podinfo    # stop reconciling (freeze during an incident)
flux resume kustomization podinfo     # resume; triggers an immediate reconcile
flux suspend helmrelease podinfo
```

Suspend freezes drift correction too — a suspended resource can be hand-edited
without Flux reverting it. Always leave a note; a forgotten suspend looks like
a healthy resource that silently stopped updating.

## Operator vs CLI

With the flux-operator, the CLI still works for reconcile/diff/suspend on the
toolkit objects. But do **not** `flux bootstrap` or `flux install` on an
operator-managed cluster — the FluxInstance owns the controllers. Change the
install by editing the FluxInstance, not with `flux` install commands.

## Build-time validation

```bash
flux --version                        # match client to distribution.version
kubeconform / flux diff in CI         # validate manifests before merge
```

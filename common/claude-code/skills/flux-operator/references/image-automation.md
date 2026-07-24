# Image update automation

Auto-bump image tags in Git when a new image is pushed. Three objects in the
`image.toolkit.fluxcd.io/v1` group plus a writable `GitRepository`. Requires
`image-reflector-controller` and `image-automation-controller` in the
FluxInstance `components`.

## Flow

1. `ImageRepository` scans a registry for tags.
2. `ImagePolicy` selects the "latest" tag (semver / regex / numeric).
3. `ImageUpdateAutomation` writes the chosen tag back to Git via a commit,
   which Flux then reconciles normally.

## Manifests

```yaml
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageRepository
metadata: { name: podinfo, namespace: default }
spec:
  image: ghcr.io/stefanprodan/podinfo
  interval: 5m
---
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImagePolicy
metadata: { name: podinfo, namespace: default }
spec:
  imageRepositoryRef: { name: podinfo }
  policy:
    semver:
      range: 5.0.x            # or numerical / alphabetical + filterTags
---
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageUpdateAutomation
metadata: { name: podinfo, namespace: default }
spec:
  interval: 30m
  sourceRef: { kind: GitRepository, name: podinfo }
  git:
    commit:
      author:
        name: fluxcdbot
        email: fluxcdbot@users.noreply.github.com
      messageTemplate: "chore: bump {{ .AutomationObject }}"
    push:
      branch: main            # or a dedicated branch to open PRs from
  update:
    path: ./
    strategy: Setters
```

## Marking what to update

The `Setters` strategy edits image fields tagged with a marker comment:

```yaml
image: ghcr.io/stefanprodan/podinfo:5.0.0 # {"$imagepolicy": "default:podinfo"}
```

The `# {"$imagepolicy": "namespace:policy"}` comment tells the automation which
field to rewrite with the policy's selected tag.

## Controls

- `policySelector` (matchLabels / matchExpressions) scopes an automation to a
  subset of ImagePolicies.
- Suspend without deleting:

  ```bash
  flux suspend image update podinfo
  flux resume image update podinfo
  ```

- Push to a side branch and gate merges through PR review instead of committing
  straight to `main` — set `git.push.branch` to a non-default branch.

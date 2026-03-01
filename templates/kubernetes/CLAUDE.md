# Kubernetes Project

## Commands

```bash
nix develop              # enter dev shell with kubectl, helm, k9s, talosctl, argocd, cilium
kubectl apply -f .       # apply manifests
helm template .          # render Helm chart
kubeconform *.yaml       # validate manifests against schemas
yamllint .               # lint YAML files
hadolint Dockerfile      # lint Dockerfiles
k9s                      # interactive cluster UI
pre-commit run --all-files  # run all pre-commit hooks
```

## Conventions

- Use namespaced resources; never deploy to `default` namespace
- Helm charts go in `charts/`; raw manifests in `manifests/` or by component
- Always set resource requests and limits
- Use `kubeconform` to validate manifests before applying
- Pin image tags; never use `:latest` in production
- Kustomize overlays for environment-specific config

## GitOps with ArgoCD

- Application definitions in `apps/` directory
- Use ApplicationSets for multi-cluster deployments
- Sync policy: auto-sync with self-heal for non-prod, manual for prod

## Security

- Never commit kubeconfig files or service account tokens
- Use NetworkPolicies (Cilium) for pod-to-pod traffic control
- Scan images with `trivy` before deployment

## Relevant Skills

This project benefits from globally installed Claude Code skills:
- **cilium-expert** — eBPF networking, network policies, service mesh
- **talos-os-expert** — Talos Linux cluster management
- **argo-expert** — GitOps workflows, ArgoCD configuration
- **devsecops-expert** — container security, supply chain protection
- **ci-cd** — deployment pipeline design

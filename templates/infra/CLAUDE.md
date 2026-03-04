# Infrastructure Platform Project

## Commands

```bash
nix develop              # enter dev shell with terraform, kubectl, trivy, az, packer
terraform init           # initialize providers
terraform plan           # preview changes
terraform apply          # apply changes
terraform validate       # validate configuration
tflint                   # lint HCL
terraform-docs .         # generate module documentation
packer build .           # build machine images
kubectl apply -f .       # apply K8s manifests
helm template .          # render Helm chart
kubeconform *.yaml       # validate manifests against schemas
trivy config .           # scan IaC for misconfigurations
trivy fs .               # scan filesystem for vulnerabilities
checkov -d .             # IaC policy scanning
yamllint .               # lint YAML files
hadolint Dockerfile      # lint Dockerfiles
az login                 # authenticate to Azure
pre-commit run --all-files  # run all pre-commit hooks
```

## Conventions

### Terraform

- Use HCL, not JSON, for all Terraform configuration
- One resource per file where practical; group related resources logically
- Use `terraform fmt` before committing (automated via hooks)
- Never commit `.tfstate` files or `.tfvars` with secrets
- Use remote state backends for team projects
- Pin provider versions in `versions.tf`
- Use `locals` to reduce repetition; prefer `for_each` over `count`
- Use `terraform-docs` to auto-generate module documentation

### Kubernetes

- Use namespaced resources; never deploy to `default` namespace
- Helm charts go in `charts/`; raw manifests in `manifests/` or by component
- Always set resource requests and limits
- Use `kubeconform` to validate manifests before applying
- Pin image tags; never use `:latest` in production
- Kustomize overlays for environment-specific config

### Packer

- Templates in `packer/` directory
- Use HCL2 syntax (not JSON)
- Pin plugin versions in `required_plugins`

## Security Rules

- Never hardcode credentials in `.tf` files or manifests
- Use `variable` blocks with `sensitive = true` for secrets
- All infrastructure must pass `trivy config` and `checkov` scans before apply
- Review `terraform plan` output before every `terraform apply`
- Scan container images with `trivy image` before deployment
- Never commit kubeconfig files or service account tokens
- Use managed identities / workload identity over static credentials

## Azure Optional Tools

These packages are available in nixpkgs but not included in the default devShell.
Add them to `buildInputs` in `flake.nix` as needed:

| Package | CLI | Use Case |
|---------|-----|----------|
| `azure-storage-azcopy` | `azcopy` | Bulk data transfer to/from Azure Storage |
| `azure-functions-core-tools` | `func` | Azure Functions local dev |
| `bicep` | `bicep` | ARM template DSL (alternative to Terraform for Azure-native) |
| `skopeo` | `skopeo` | Copy/inspect container images across registries (ACR) |
| `crane` | `crane` | OCI image manipulation |
| `oras` | `oras` | OCI artifact push/pull (Microsoft-backed, ACR-friendly) |

## Relevant Skills

This project benefits from globally installed Claude Code skills:

- **devsecops-expert** -- secure infrastructure patterns, compliance scanning
- **ci-cd** -- pipeline design for Terraform and K8s automation
- **security-auditing** -- infrastructure and container security review
- **cilium-expert** -- eBPF networking, network policies
- **talos-os-expert** -- Talos Linux cluster management
- **argo-expert** -- GitOps workflows, ArgoCD configuration

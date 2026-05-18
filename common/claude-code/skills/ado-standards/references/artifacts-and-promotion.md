# Artifacts and Environment Promotion

## Artifact Management

- Publish Terraform plans as pipeline artifacts for apply stages
- Use `PublishPipelineArtifact@1` (faster than `PublishBuildArtifacts@1`)
- Tag container images with build ID or git SHA, not `latest`
- Pin provider and module versions in `versions.tf`

## Environment Promotion

```text
PR Build (validate + plan) -> main Build (plan) -> Dev (auto-apply) -> Staging (approval) -> Production (approval)
```

- PR builds run validate + plan only (no apply)
- Automated apply to dev on merge to `main`
- Manual approval gate for staging and production
- Use ADO Environments with checks (approvals, business hours, exclusive lock)
- Same plan artifact promoted — never re-plan per environment

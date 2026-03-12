---
name: Azure DevOps Standards
description: "Azure DevOps pull request workflows and pipeline design standards. Use when creating or reviewing ADO pull requests, writing azure-pipelines.yml, designing build/release pipelines, or setting branch policies."
version: 1.0.0
tags: [azure-devops, ado, pull-requests, pipelines, ci-cd, yaml]
---

# Azure DevOps Standards

## 1. Pull Request Conventions

### Branch Strategy

- **Trunk-based**: short-lived feature branches off `main`, merge back via PR
- Branch naming: `<type>/<ticket>-<short-description>` (e.g., `feat/12345-add-auth`)
- Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `hotfix`
- Delete branches after merge — enforce via branch policy

### PR Requirements

- **Title**: `<type>(<scope>): <subject>` matching Conventional Commits
- **Description**: What changed, why, how to test, linked work items
- **Size**: Aim for < 400 lines changed; split larger work into stacked PRs
- **Work item linking**: Always link ADO work items (`AB#12345` in commit or PR description)
- **Draft PRs**: Use for early feedback before the PR is ready for formal review

### Branch Policies (recommended defaults)

- Minimum 1 reviewer (2 for `main`)
- Build validation — PR must pass CI before merge
- Comment resolution — all threads must be resolved
- Work item linking required
- Squash merge to `main` (clean linear history)
- Reset approval on new pushes

### Code Review Standards

- Review within 1 business day
- Use ADO's suggestion feature for small fixes
- Mark comments as `nit:`, `question:`, `blocking:` to signal severity
- Approve with comments for non-blocking feedback
- Reviewer checks: correctness, tests, security, naming, no secrets in code

## 2. Pipeline Design (azure-pipelines.yml)

### Structure

```yaml
trigger:
  branches:
    include: [main]
  paths:
    exclude: ['docs/**', '*.md']

pr:
  branches:
    include: [main]

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: <variable-group>       # secrets from Library
  - name: environment
    value: 'dev'

stages:
  - stage: Validate
    jobs:
      - job: Lint
        steps:
          - checkout: self
            fetchDepth: 1
          - script: |
              terraform fmt -check -recursive
              tflint --recursive
              yamllint -s .
            displayName: 'Lint HCL and YAML'

      - job: SecurityScan
        steps:
          - script: |
              trivy config --exit-code 1 .
              checkov -d . --compact --quiet
            displayName: 'IaC security scan'

  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: TerraformPlan
        steps:
          - script: |
              terraform init -backend-config=backends/$(environment).hcl
              terraform plan -out=tfplan -input=false
            displayName: 'Terraform plan'
          - publish: $(System.DefaultWorkingDirectory)/tfplan
            artifact: tfplan

  - stage: Apply
    dependsOn: Plan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: TerraformApply
        environment: $(environment)
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: tfplan
                - script: |
                    terraform init -backend-config=backends/$(environment).hcl
                    terraform apply -input=false $(Pipeline.Workspace)/tfplan/tfplan
                  displayName: 'Terraform apply'
```

### Principles

- **YAML pipelines only** — no classic editor pipelines for new work
- **Pipeline as code** — `azure-pipelines.yml` lives in the repo root
- **Multi-stage**: separate Validate, Plan, Apply stages
- **Conditions**: apply stages run only on `main`, not on PR builds
- **Templates**: extract reusable steps into `templates/` directory
- **Variable groups**: secrets in ADO Library, never hardcoded in YAML
- **Service connections**: use workload identity federation over service principal secrets
- **Bash steps**: prefer `script:` (bash) over ADO marketplace tasks where possible

### Template Patterns

```yaml
# templates/terraform-init.yml
parameters:
  - name: environment
    type: string
  - name: workingDirectory
    type: string
    default: '.'

steps:
  - script: |
      cd ${{ parameters.workingDirectory }}
      terraform init -backend-config=backends/${{ parameters.environment }}.hcl
    displayName: 'Terraform init (${{ parameters.environment }})'
```

```yaml
# azure-pipelines.yml
stages:
  - stage: Plan
    jobs:
      - job: Plan
        steps:
          - template: templates/terraform-init.yml
            parameters:
              environment: dev
          - script: terraform plan -out=tfplan -input=false
            displayName: 'Terraform plan'
```

### Pipeline Security

- Pin marketplace task versions explicitly: `task: AzureCLI@2` not `AzureCLI@*`
- Prefer `script:` (bash) over marketplace tasks — fewer supply chain dependencies
- Use `checkout: self` with `fetchDepth: 1` for faster builds
- Never echo secrets; use `issecret=true` for pipeline variables
- Limit pipeline permissions: disable "Grant access to all pipelines" on service connections
- Use environments with approval gates for production deployments
- Scan IaC in CI: `trivy config`, `checkov`, `tflint`

### Naming and Organization

- One pipeline per deployable unit / infrastructure component
- Pipeline name matches repo or component name
- Environment names: `dev`, `staging`, `production` (lowercase)
- Variable group naming: `<component>-<env>` (e.g., `network-production`)

## 3. Artifact Management

- Publish Terraform plans as pipeline artifacts for apply stages
- Use `PublishPipelineArtifact@1` (faster than `PublishBuildArtifacts@1`)
- Tag container images with build ID or git SHA, not `latest`
- Pin provider and module versions in `versions.tf`

## 4. Environment Promotion

```
PR Build (validate + plan) → main Build (plan) → Dev (auto-apply) → Staging (approval) → Production (approval)
```

- PR builds run validate + plan only (no apply)
- Automated apply to dev on merge to `main`
- Manual approval gate for staging and production
- Use ADO Environments with checks (approvals, business hours, exclusive lock)
- Same plan artifact promoted — never re-plan per environment

## 5. Common Anti-Patterns

- Hardcoded secrets in YAML or scripts
- Single monolithic pipeline doing validate + plan + apply without stages
- `trigger: '*'` — always scope triggers to specific branches/paths
- Skipping PR validation builds ("it works on my machine")
- Long-running pipelines without caching (`Cache@2` task for `.terraform/`)
- Manual infrastructure changes not tracked in pipeline
- Using classic release pipelines alongside YAML (pick one)
- Using marketplace tasks when a simple `script:` step would do
- Running `terraform apply` without a saved plan file

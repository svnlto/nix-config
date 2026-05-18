# Pipeline Design (azure-pipelines.yml)

## Structure

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

## Principles

- **YAML pipelines only** — no classic editor pipelines for new work
- **Pipeline as code** — `azure-pipelines.yml` lives in the repo root
- **Multi-stage**: separate Validate, Plan, Apply stages
- **Conditions**: apply stages run only on `main`, not on PR builds
- **Templates**: extract reusable steps into `templates/` directory
- **Variable groups**: secrets in ADO Library, never hardcoded in YAML
- **Service connections**: use workload identity federation
  over service principal secrets
- **Bash steps**: prefer `script:` (bash) over ADO marketplace tasks where possible

## Template Patterns

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

## Pipeline Security

- Pin marketplace task versions explicitly: `task: AzureCLI@2` not `AzureCLI@*`
- Prefer `script:` (bash) over marketplace tasks — fewer supply chain dependencies
- Use `checkout: self` with `fetchDepth: 1` for faster builds
- Never echo secrets; use `issecret=true` for pipeline variables
- Limit pipeline permissions: disable "Grant access to all
  pipelines" on service connections
- Use environments with approval gates for production deployments
- Scan IaC in CI: `trivy config`, `checkov`, `tflint`

## Naming and Organization

- One pipeline per deployable unit / infrastructure component
- Pipeline name matches repo or component name
- Environment names: `dev`, `staging`, `production` (lowercase)
- Variable group naming: `<component>-<env>` (e.g., `network-production`)

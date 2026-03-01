# Terraform Project

## Commands

```bash
nix develop              # enter dev shell with terraform, tflint, terragrunt, checkov
terraform init           # initialize providers
terraform plan           # preview changes
terraform apply          # apply changes
terraform validate       # validate configuration
tflint                   # lint HCL
checkov -d .             # security scanning
pre-commit run --all-files  # run all pre-commit hooks
```

## Conventions

- Use HCL, not JSON, for all Terraform configuration
- One resource per file where practical; group related resources logically
- Use `terraform fmt` before committing (automated via hooks)
- Never commit `.tfstate` files or `.tfvars` with secrets
- Use remote state backends (S3, GCS, etc.) for team projects
- Pin provider versions in `versions.tf`
- Use `locals` to reduce repetition; prefer `for_each` over `count`

## Security Rules

- Never hardcode credentials in `.tf` files
- Use `variable` blocks with `sensitive = true` for secrets
- All infrastructure must pass `checkov` scans before apply
- Review `terraform plan` output before every `terraform apply`

## Relevant Skills

This project benefits from globally installed Claude Code skills:

- **devsecops-expert** — secure infrastructure patterns, compliance scanning
- **ci-cd** — pipeline design for Terraform automation
- **security-auditing** — infrastructure security review

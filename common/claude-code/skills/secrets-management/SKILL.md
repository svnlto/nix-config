---
name: secrets-management
description: "Secure secrets management using Azure Key Vault, HashiCorp Vault, AWS Secrets Manager, or platform-native solutions. Use when storing credentials, managing API keys, handling certificates, configuring secret access in applications, infrastructure (Terraform/Ansible), Kubernetes, or CI/CD pipelines. Also covers secret rotation, scanning, ADO variable groups, workload identity, and least-privilege access patterns."
version: 1.0.0
tags: [secrets, vault, azure-key-vault, ado, aws-secrets-manager, kubernetes, terraform, security]
---

# Secrets Management

Secure secrets management across applications, infrastructure,
Kubernetes, and CI/CD — using Azure Key Vault, HashiCorp Vault,
AWS Secrets Manager, and platform-native solutions.

## When to Use

- Store or retrieve API keys, credentials, connection strings
- Manage database passwords or service account keys
- Handle TLS certificates and signing keys
- Configure secret access for applications (SDKs, env vars, config)
- Provision secret stores in Terraform or Ansible
- Inject secrets into Kubernetes workloads
- Integrate secrets into ADO, GitHub Actions, or GitLab pipelines
- Rotate secrets automatically
- Implement least-privilege access to secrets
- Set up secret scanning in repos or CI

## Core Workflow

1. **Choose a secret store** — Azure Key Vault (Azure-native),
   HashiCorp Vault (multi-cloud/on-prem), AWS Secrets Manager (AWS-native)
2. **Provision with IaC** — Terraform resources for the store, RBAC,
   networking, rotation policies
3. **Integrate into apps** — SDK (Go/Java), env vars, or config references
4. **Inject into K8s** — External Secrets Operator or CSI Driver
5. **Wire into CI/CD** — ADO variable groups, workload identity,
   GitHub Actions secrets
6. **Scan and audit** — Pre-commit hooks, CI secret scanning, audit logs

## Reference Guide

Load detailed guidance based on context:

| Topic | File | Load When |
|-------|------|-----------|
| Azure Key Vault | [references/azure-key-vault.md](references/azure-key-vault.md) | Creating vaults, RBAC, networking, rotation |
| Application Integration | [references/application-integration.md](references/application-integration.md) | SDK usage (Go/Java), env vars, 1Password CLI, App Config |
| Infrastructure | [references/infrastructure.md](references/infrastructure.md) | Terraform (Azure KV + AWS SM), state security, Ansible Vault |
| Kubernetes | [references/kubernetes.md](references/kubernetes.md) | External Secrets Operator, CSI Driver |
| CI/CD Integration | [references/ci-cd-integration.md](references/ci-cd-integration.md) | ADO pipelines, workload identity, GitHub Actions |
| Secret Scanning | [references/secret-scanning.md](references/secret-scanning.md) | Pre-commit hooks, CI scanning with TruffleHog |
| HashiCorp Vault | [references/hashicorp-vault.md](references/hashicorp-vault.md) | Vault setup, policies, dynamic secrets |
| AWS Secrets Manager | [references/aws-secrets-manager.md](references/aws-secrets-manager.md) | AWS SM CLI commands |

## Best Practices

1. **Never commit secrets** to Git — use `.gitignore`, pre-commit hooks, and scanning
2. **Use different secrets per environment** — separate Key Vaults for prod/non-prod
3. **Rotate secrets regularly** — automate with Key Vault
   rotation policies or Vault dynamic secrets
4. **Scope access to individual secrets** — RBAC at secret
   level, not vault level
5. **Enable audit logging** — Key Vault diagnostics, Vault
   audit backend, CloudTrail
6. **Scan for secrets** in repos and CI
   (TruffleHog, GitGuardian, Trivy)
7. **Mask secrets in logs** — `issecret=true` (ADO),
   `::add-mask::` (GitHub), masked variables (GitLab)
8. **Prefer managed identity** — Azure Managed Identity,
   workload identity federation, AWS IAM Roles
9. **Use short-lived credentials** — dynamic secrets,
   federated tokens over long-lived keys
10. **Never store secrets in Terraform state unencrypted** —
    use remote backend with encryption, mark variables `sensitive`
11. **Document secret inventory** — what each secret is,
    who owns it, rotation schedule, consumers

## Related Skills

- `ado-standards` — ADO pipeline design, variable groups, service connections
- `devsecops-expert` — Shift-left security, IaC scanning, supply chain protection
- `security-auditing` — Code and infrastructure security review
- `talos-os-expert` — Kubernetes cluster security

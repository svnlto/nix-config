# Security Posture Management

## CSPM in the Datadog Security Stack

Datadog's security products serve different purposes:

| Product | What it monitors | Timeframe |
|---------|-----------------|-----------|
| **CSPM** | Cloud resource misconfigurations | Preventive — find before exploit |
| **CWS (Cloud Workload Security)** | Runtime threats on hosts/containers | Detective — find during exploit |
| **Cloud SIEM** | Log-based threat detection and correlation | Detective — find from signals |
| **ASM (Application Security)** | Application-layer attacks (SQLi, XSS) | Detective — find at app layer |

CSPM is the preventive layer. It continuously scans your cloud
resources against compliance frameworks and flags misconfigurations
before they become incidents.

## Framework Selection

Enable frameworks based on your compliance requirements and maturity:

### Start here (always enable)

- **CIS Benchmarks** (AWS, Azure, GCP) — industry-standard security
  baseline. Covers IAM, networking, logging, encryption. These are
  the most actionable and widely recognized.

### Add when required

- **SOC 2** — if you handle customer data and have or plan SOC 2 audits
- **PCI DSS** — if you process payment card data
- **HIPAA** — if you handle protected health information
- **GDPR** — if you process EU personal data
- **ISO 27001** — if pursuing or maintaining certification

### Don't enable unless needed

- Multiple overlapping frameworks create duplicate findings. CIS
  benchmarks cover 80% of what SOC 2 and ISO 27001 check. Start with
  CIS, add compliance-specific frameworks only when auditors require
  specific evidence.

## Finding Prioritization

CSPM produces a lot of findings. Triage by impact, not by count:

### Critical — fix immediately

- **Public S3 buckets / storage accounts** — data exposure risk
- **Unrestricted security groups (0.0.0.0/0)** — network exposure
- **Root account without MFA** — account takeover risk
- **Unencrypted databases** — data-at-rest exposure
- **IAM policies with admin/wildcard** — privilege escalation

### High — fix within a sprint

- **Logging disabled** on CloudTrail, Flow Logs, or audit logs
- **Default VPC in use** — overly permissive networking
- **Old access keys** not rotated (> 90 days)
- **Public RDS/database instances** — unintended exposure
- **Missing encryption** on EBS volumes, S3, or transit

### Medium — plan and schedule

- **Tags missing** on resources (governance, not security)
- **Non-compliant naming** conventions
- **Unused security groups** — cleanup, not urgent
- **Minor configuration drift** from baseline

### Low / Informational — review periodically

- **Best practice suggestions** that don't represent active risk
- **Deprecated API usage** warnings
- **Resource inventory** discrepancies

## Remediation Workflow

### 1. Triage

- Review new findings daily (critical) or weekly (high/medium)
- Mute known exceptions with justification (don't just suppress)
- Group findings by resource type — fixing one pattern often resolves many findings

### 2. Assign

- Route findings to resource owners using `team` tags
- Use Datadog Case Management or Jira integration for tracking
- Set remediation SLAs: Critical = 24h, High = 1 sprint, Medium = 1 quarter

### 3. Fix

- Prefer infrastructure-as-code fixes (Terraform, CloudFormation)
  over console clicks — IaC prevents regression
- For widespread issues, fix the Terraform module/template once
  rather than patching individual resources

### 4. Verify

- CSPM rescans automatically — verify finding is resolved in next scan
- Add preventive controls: SCPs, Azure Policy, or Terraform validation
  rules to prevent the misconfiguration from recurring

### 5. Exempt (when appropriate)

- Some findings are intentional (e.g., a public static website bucket)
- Document the business justification
- Use Datadog's mute/suppress with a reason — not just "ignore"
- Set a review date for exemptions

## CSPM Monitors

Create monitors on CSPM findings to track posture over time:

**Posture score monitor:**
Alert when overall compliance score drops below threshold.
Catches bulk regressions (e.g., a Terraform change that removes
encryption from all new resources).

**Critical finding monitor:**
Alert immediately on new critical findings. These represent
active exposure risk.

**New resource monitor:**
Alert when new resources are created without required tags or
encryption. Catches shadow IT and non-compliant provisioning.

## Integration with Other Pillars

CSPM findings are more actionable when correlated:

- **CSPM + Cloud SIEM:** A misconfigured security group (CSPM) combined
  with suspicious network traffic (SIEM) = active exploitation attempt
- **CSPM + CWS:** An overly permissive IAM role (CSPM) with runtime
  process anomaly (CWS) = potential privilege escalation
- **CSPM + APM:** A public-facing service (APM) running on a
  misconfigured host (CSPM) = prioritize the fix

## Governance Reporting

Use CSPM data for regular security reporting:

| Report | Frequency | Audience | Content |
|--------|-----------|----------|---------|
| **Posture dashboard** | Real-time | Security team | Compliance scores, top findings, trends |
| **Executive summary** | Monthly | Leadership | Score trends, remediation velocity, risk areas |
| **Compliance evidence** | On-demand | Auditors | Framework-specific pass/fail with timestamps |
| **Team scorecard** | Weekly | Engineering leads | Per-team finding counts and resolution rates |

## Cost Considerations

CSPM costs scale with the number of cloud resources evaluated:

- Enable only the frameworks you need (each framework scans all resources)
- Use resource filters to exclude non-production accounts from
  compliance-specific frameworks
- Production accounts should always have CIS enabled regardless of cost

## Pup Execution

| Task | Command |
|------|---------|
| List security findings | `pup security findings` or invoke `pup:security-posture-management` |
| View compliance scores | `pup security posture` or invoke `pup:security-posture-management` |
| List security rules | `pup security rules list` or invoke `pup:security` |
| Mute a finding | `pup security findings mute` |
| Check CWS agents | `pup cloud-workload list` or invoke `pup:cloud-workload-security` |

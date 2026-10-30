# Secrets in Pipelines

Three mechanisms, lowest to highest assurance. Pick by what the value is
and who may see it.

## 1. CI/CD variables (masked / protected)

Default job inputs. Mask to keep them out of logs; protect to limit them
to protected branches/tags. Masking has format constraints and is not
encryption — a determined job can still print a value. Use for low-risk
config, not durable secrets. Doc: <https://docs.gitlab.com/ci/variables/>

## 2. GitLab Secrets Manager

Doc: <https://docs.gitlab.com/ci/secrets/secrets_manager/>. GA in GitLab
19.5, powered by OpenBao, Premium/Ultimate, consumes GitLab Credits.
Needs GitLab Runner 19.0+. Create under **Secure > Secrets manager** on
the project or group; values are write-only after creation, scoped to
environments + branches, auditable, with rotation reminders.

Consume with the `secrets` block — a secret must be **explicitly
requested** by the job (unlike variables):

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube_cert
  script:
    - kubectl config set-cluster e2e --certificate-authority="$KUBE_CA_PEM"
```

- Group secret: add `source: group/<full/group/path>` (must be the
  project's group or a parent).
- By default the variable holds a path to a temp file (secrets can carry
  newlines). For an inline value set `file: false`.
- Output is masked as `[MASKED]` in logs.

## 3. External secrets (HashiCorp Vault, etc.)

Doc: <https://docs.gitlab.com/ci/secrets/>. Also the `secrets:` keyword
but with an external provider backend instead of
`gitlab_secrets_manager`. Use when the org's system of record is an
existing Vault. Confirm the exact provider syntax on that page.

## Rule

Never hardcode a credential in `.gitlab-ci.yml` or a component. Never
echo a secret. Prefer Secrets Manager or external secrets over masked
variables for anything that grants real access.

# Security Scanning (Ultimate)

Dedicated is Ultimate tier, so the full scanner suite and the Security
Dashboard / MR security widget / Vulnerability Management are available.
Enable scanners with a `template` include or the published component;
results in MR widgets and the dashboard are Ultimate-only.

Start page: <https://docs.gitlab.com/user/application_security/>

## SAST

Doc: <https://docs.gitlab.com/user/application_security/sast/>

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml        # stable (production default)
# or the component:
  - component: gitlab.com/components/sast/sast@main
```

- `Jobs/SAST.gitlab-ci.yml` is the stable template;
  `Jobs/SAST.latest.gitlab-ci.yml` is the bleeding-edge one (testing).
- A `test` stage must exist (default stages include it; required if you
  redefine `stages`).
- Analyzers auto-run on detected languages. **GitLab Advanced SAST**
  (cross-file, cross-function) is Ultimate-only; standard Semgrep-based
  analyzers run in all tiers. Jobs appear under `test`
  (`semgrep-sast`, `gitlab-advanced-sast`, etc.).
- Needs a Linux runner with the Docker or Kubernetes executor. Windows
  and non-AMD64 are unsupported. See `dedicated.md` for hosted runners.
- Tier split: basic open-source scanning + JSON report in all tiers; new
  findings in MR reports/changes view, Vulnerability Management, ruleset
  customization, UI config = Ultimate.

## Other scanners

Confirm each on its own doc page before authoring — do not assume the
include path.

| Scanner | Template / notes | Doc |
|---------|------------------|-----|
| Secret detection | `template: Jobs/Secret-Detection.gitlab-ci.yml`; job `secret_detection` | `/user/application_security/secret_detection/` |
| Dependency scanning | `template: Jobs/Dependency-Scanning.gitlab-ci.yml` | `/user/application_security/dependency_scanning/` |
| Container scanning | `template: Jobs/Container-Scanning.gitlab-ci.yml` | `/user/application_security/container_scanning/` |
| DAST | `template: DAST.gitlab-ci.yml` | `/user/application_security/dast/` |
| IaC scanning | `template: Jobs/SAST-IaC.gitlab-ci.yml` | `/user/application_security/iac_scanning/` |

Paths above move between releases; on Dedicated's monthly cadence, open
the scanner's doc (base `https://docs.gitlab.com/`) and copy the current
include rather than trusting memory. GitLab is shifting scanners toward
published components under `gitlab.com/components/*` — prefer the
component form when the scanner's page documents one.

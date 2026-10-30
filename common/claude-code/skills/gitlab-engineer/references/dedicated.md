# GitLab Dedicated Constraints

Doc: <https://docs.gitlab.com/administration/dedicated/>. Single-tenant,
GitLab-managed AWS instance, Ultimate tier. Configured through
**Switchboard**, onboarding choices, and support tickets — not the
admin areas a self-managed instance exposes. These constraints shape
what pipelines and infra you can author.

## What engineers cannot self-serve

- **Release cadence**: GitLab ships monthly. You do not pin a version —
  features arrive on their schedule. Always check a keyword/feature's
  version note against the current instance before relying on it.
- **Maintenance**: one weekly 4-hour window (you pick it). Expect brief
  unavailability; design long jobs and deploys around it.
- **Infra**: regions, Geo secondary, customer-managed KMS keys are set at
  onboarding.

## Networking (affects runners, includes, deploys)

- **IP allowlist** (Switchboard): restricts who reaches the instance.
- **PrivateLink** inbound and outbound (Switchboard) for private AWS
  connectivity.
- **Custom certificate authorities** (Switchboard) — needed when jobs
  call internal services presenting a private CA.
- **Custom domains**: support ticket; GitLab manages the Let's Encrypt
  cert. Internal apps reached via the instance present real public certs,
  so no corp CA is needed in-job for those.

## Hosted runners (Ultimate, Dedicated-only)

Doc: <https://docs.gitlab.com/administration/dedicated/hosted_runners/>.
Enabled by your GitLab account rep/CSM, then created in **Switchboard >
Hosted runners > New hosted runner**; managed under **Admin > CI/CD >
Runners**. Billed via GitLab Credits (exempt from usage caps — jobs keep
running on on-demand credits). 99.9% SLA.

Linux, Docker Autoscaler executor. One runner per type+size per instance.

| Size | x86-64 tag | Arm64 tag | vCPU / Mem / Disk |
|------|-----------|-----------|-------------------|
| Small | `linux-small-amd64` (default) | `linux-small-arm64` | 2 / 8 GB / 30 GB |
| Medium | `linux-medium-amd64` | `linux-medium-arm64` | 4 / 16 GB / 50 GB |
| Large | `linux-large-amd64` | `linux-large-arm64` | 8 / 32 GB / 100 GB |
| X-Large | `linux-xlarge-amd64` | `linux-xlarge-arm64` | 16 / 64 GB / 200 GB |
| 2X-Large | `linux-2xlarge-amd64` | `linux-2xlarge-arm64` | 32 / 128 GB / 200 GB |

Limits to design around:

- Untagged jobs land on small x86-64 by default. Tag jobs to steer size
  (`tags: [linux-large-amd64]`).
- Up to 1000 concurrent jobs per runner stack; the rest queue.
- Default image is `ruby:3.1` if `image` is unset — always set `image`.
- Runs `privileged` (DinD works). Each job is a fresh VM, passwordless
  `sudo`; OS + image + repo share disk, cutting free space.
- Inbound internet to job VMs is blocked; outbound open (best-effort deny
  list on request). Only two outbound PrivateLinks by default (instance +
  GitLab Prometheus); more need a support request per runner.
- Shared NAT IP → Docker Hub rate limits can bite; use a pull-through or
  authenticated pulls.

No Windows/macOS hosted runners — register self-managed for those.

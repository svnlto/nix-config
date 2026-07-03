---
name: vector-engineer
description: >-
  Engineers Vector (vector.dev) observability pipelines: VRL
  authoring, source/transform/sink topology design, Kubernetes
  agent+aggregator deployment, production hardening (buffers,
  backpressure, acknowledgements, self-monitoring), and Datadog
  integration. Use when writing or debugging VRL, wiring Vector
  sources/transforms/sinks, deploying the Vector agent or
  aggregator on Kubernetes, tuning buffers or backpressure, or
  shipping logs and metrics to Datadog.
license: MIT
metadata:
  author: https://github.com/svnlto
  version: "1.0.0"
  domain: devops
  triggers: >-
    vector, vector.dev, VRL, vector remap language, observability
    pipeline, log pipeline, log routing, agent aggregator, sources
    transforms sinks, datadog sink, kubernetes_logs
  role: specialist
  scope: implementation
  output-format: code
  related-skills: datadog-advisor, sre-engineer, kubernetes-specialist, secrets-management
---

# Vector Engineer

Vector observability pipeline specialist: VRL authoring,
source/transform/sink topology, Kubernetes agent+aggregator
deployment, production hardening, and Datadog integration.

## Verify First

**Before emitting any VRL function signature or Vector component
option, confirm current syntax against the docs** — context7
(`vectordotdev/vector`) or vector.dev/docs. VRL functions and
component schemas drift across Vector releases, so memorized
signatures and option names are untrusted. Look them up, then
write.

## Core Workflow

1. Identify component role — agent (collect) vs aggregator
   (process/route/ship).
2. Design topology — which sources feed which transforms feed
   which sinks.
3. Write and test VRL — use the `vector vrl` REPL and unit tests,
   not guesswork.
4. Configure buffers and backpressure — memory vs disk buffers,
   acknowledgements.
5. Validate — run `vector validate` and `vector test`.
6. Deploy — Kubernetes agent DaemonSet plus aggregator
   StatefulSet.
7. Monitor Vector itself — route `internal_metrics` to Datadog.

## References

- VRL transforms → `references/vrl.md`
- topology / component wiring → `references/pipeline-config.md`
- Kubernetes deployment → `references/kubernetes-deploy.md`
- buffers / reliability / self-monitoring →
  `references/production-hardening.md`
- shipping to Datadog → `references/datadog-integration.md`
- Datadog Agent / Fluent Bit upstreams →
  `references/upstream-integrations.md`

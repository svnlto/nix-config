# Alert Design

## Three Questions Before Any Alert

Before creating a monitor, answer these:

1. **Is it real?** Does this condition actually indicate a problem, or
   is it transient noise? If it self-resolves in under 2 minutes,
   it's not worth alerting on.

2. **Does it require attention?** Can the system handle this itself
   (autoscaling, retries, circuit breakers)? If yes, log it and
   dashboard it — don't alert.

3. **Is it urgent?** Does someone need to act *now*, or can it wait
   until business hours? This determines severity.

If any answer is "no," don't create a page. Create a dashboard widget
or a low-priority notification instead.

## Severity Framework

| Severity | Criteria | Action | Routing |
|----------|----------|--------|---------|
| **P1 — Page** | User-facing impact, SLO breach imminent, data loss risk | Wake someone up | PagerDuty high-urgency |
| **P2 — Notify** | Degraded but functional, will become P1 if unaddressed | Fix during business hours | Slack alert channel |
| **P3 — Record** | Anomaly worth tracking, no immediate impact | Review in weekly triage | Slack low-priority or log |

**Decision tree:**

- Users affected RIGHT NOW? → P1
- Will become user-facing within hours? → P2
- Interesting but not impactful? → P3
- None of the above? → Dashboard, not an alert

## Symptom-Based Alerting

Alert on what the user experiences, not what the system does internally.

| Symptom (alert on this) | Cause (dashboard this) |
|--------------------------|----------------------|
| Error rate > 5% | Pod CrashLoopBackOff |
| Latency p95 > 500ms | CPU utilization > 90% |
| Throughput dropped 50% | DNS resolution failures |
| SLO budget burn > 2x | Memory pressure on node |
| Checkout failures > 0.1% | Database connection pool exhausted |

**Why:** A pod restarting is not a problem if traffic is still served.
CPU at 95% is not a problem if latency is within SLO. Causes explain
symptoms — they are investigation aids, not alert triggers.

**Exception:** Alert on causes only when there is no observable symptom
*and* the cause guarantees a future problem (e.g., disk at 95% — it
will fill, and when it does, everything fails silently).

## Monitor Types and When to Use Them

| Type | Use when | Example |
|------|----------|---------|
| **Metric threshold** | Clear, static boundary | Error rate > 5% |
| **Metric anomaly** | Normal varies by time-of-day/week | Traffic 3σ below expected |
| **Log-based** | No metric exists, need pattern matching | ERROR log spike |
| **APM trace analytics** | Latency on specific endpoints | p99 of `/api/checkout` > 2s |
| **Composite** | Multiple conditions must be true together | High error rate AND low traffic (not just a deploy) |
| **SLO burn rate** | Protecting error budget | Fast burn: 2% budget in 5 min |
| **Forecast** | Slow-moving resource exhaustion | Disk full in < 48 hours |
| **Process/host** | Infrastructure baseline | Process not running, host unreachable |

## Composite Monitor Strategy

Composites reduce noise by requiring multiple conditions. Common patterns:

**Error rate + traffic guard:**
Trigger only when error rate is high AND traffic is above minimum.
Prevents false alerts during low-traffic windows or deploy drains.

**Latency + saturation confirmation:**
Trigger when latency exceeds threshold AND underlying resource
(CPU, memory, connections) shows saturation. Filters out one-off
slow requests.

**Cross-service correlation:**
Trigger when both a service AND its primary dependency show errors.
Distinguishes between "our code is broken" and "the database is down."

## Monitor Naming Convention

```text
[P1|P2|P3] env - service - symptom
```

Examples:

- `[P1] prod - payment-api - error rate > 5%`
- `[P2] prod - user-service - latency p95 > 800ms`
- `[P3] staging - order-worker - queue depth anomaly`

Benefits: sortable by severity, filterable by env/service, symptom
is immediately clear without opening the monitor.

## Alert Message Template

```text
## {{monitor_name}}

**Impact:** What users are experiencing.
**Likely cause:** Top 2-3 things to check.
**Runbook:** Link to investigation steps.

**Quick links:**
- [Service dashboard](link)
- [Related traces](link)
- [Recent deploys](link)
```

Keep messages actionable. The on-call engineer reads this at 3 AM —
they need to know what's broken, what to check first, and where to
look. Not a history of why the monitor was created.

## Anti-Flapping Configuration

| Setting | Recommended | Why |
|---------|-------------|-----|
| **Evaluation window** | 5 min minimum | Absorbs transient spikes |
| **Recovery threshold** | Lower than alert threshold | Prevents oscillation at boundary |
| **Recovery window** | Same or longer than alert window | Confirms genuine recovery |
| **Notify on no data** | Yes for critical, No for intermittent | Missing data on a critical service is itself a problem |
| **Renotification interval** | 30-60 min for P1, none for P3 | Reminds without spamming |
| **New group delay** | 60s for auto-scaling services | Prevents alerts during scale-up |

## Alert Routing Patterns

| Severity | Channel | Escalation |
|----------|---------|------------|
| **P1** | PagerDuty (high-urgency) | Auto-escalate after 15 min if unacked |
| **P2** | Slack `#alerts-{team}` + PagerDuty (low-urgency) | Review in daily standup |
| **P3** | Slack `#alerts-{team}-low` | Review in weekly triage |
| **SLO burn** | Same as P1 for fast burn, P2 for slow burn | Error budget policy determines response |

Tag monitors with `team:<name>` to enable routing. Use Datadog
notification rules to map tags to channels automatically.

## Pup Execution

| Task | Command |
|------|---------|
| Create a monitor | `pup monitors create` or invoke `pup:monitoring-alerting` |
| List monitors by service | `pup monitors list --query "service:<name>"` |
| Mute during maintenance | `pup downtimes create` |
| Search monitors by tag | `pup monitors list --query "tag:team:<name>"` |

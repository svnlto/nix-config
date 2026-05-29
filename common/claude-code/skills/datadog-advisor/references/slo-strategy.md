# SLO Strategy

## SLO Type Selection

Datadog offers three SLO types. Choose based on your data:

| Type | Best for | Data source | Precision |
|------|----------|-------------|-----------|
| **Metric-based** | High-volume request metrics | Custom or APM metrics | Highest — uses raw metric data |
| **Monitor-based** | Complex multi-condition logic | Existing monitors | Medium — binary up/down per check |
| **Time-slice** | Uptime-style availability | Monitors evaluated per interval | Good for "was the system healthy at time T?" |

**Decision guide:**

- Have a request-based metric (hits, errors, latency)? → **Metric-based**
- Need to combine multiple conditions (AND/OR)? → **Monitor-based** on composite
- Measuring infrastructure uptime or batch job success? → **Time-slice**
- Unsure? → Start with **metric-based** on APM traces — it's the most flexible

## Metric-Based SLO Patterns

### Availability SLO

```text
Good events:  trace.<service>.hits - trace.<service>.errors
Total events: trace.<service>.hits
Target:       99.9% over 30 days
```

### Latency SLO

```text
Good events:  trace.<service>.hits where duration < threshold
Total events: trace.<service>.hits
Target:       99% of requests under 500ms over 30 days
```

### Custom Business SLO

```text
Good events:  custom.checkout.success
Total events: custom.checkout.attempts
Target:       99.5% over 30 days
```

Metric-based SLOs are the most accurate because they count individual
events rather than sampling monitor status at intervals.

## Target Derivation

Do not pick arbitrary nines. Derive targets from reality:

1. **Measure the baseline.** What is the service actually achieving
   today? If it's running at 99.7%, don't set a target of 99.99%.

2. **Understand user tolerance.** Internal tools tolerate more errors
   than payment processing. A 99% SLO might be fine for a dev portal
   but unacceptable for checkout.

3. **Calculate the error budget.** A 99.9% SLO over 30 days allows
   43.2 minutes of downtime. A 99.95% allows 21.6 minutes. Can your
   team respond and fix issues within that window?

4. **Start conservative, tighten later.** It's easier to raise a target
   from 99.5% to 99.9% than to explain why you're lowering it from
   99.99% to 99.9%.

| Target | Monthly error budget | Good for |
|--------|---------------------|----------|
| 99% | 7.3 hours | Internal tools, non-critical batch |
| 99.5% | 3.6 hours | Internal APIs, staging environments |
| 99.9% | 43.2 minutes | Production APIs, user-facing services |
| 99.95% | 21.6 minutes | Payment, authentication, core flows |
| 99.99% | 4.3 minutes | Platform-level infrastructure only |

## Multi-Window Strategy

Use multiple SLO windows for different audiences:

| Window | Purpose | Audience |
|--------|---------|----------|
| **7 days** | Rapid feedback on recent changes | On-call, deploying team |
| **30 days** | Operational health, error budget tracking | Service owner, team lead |
| **90 days** | Business reliability reporting | Leadership, customers |

The 30-day window is your primary operational SLO. The 7-day window
is your early warning. The 90-day window smooths out one-off incidents
and shows the trend.

## Error Budget Policy

Define what happens as the error budget depletes:

### Budget > 75% remaining

- Normal operations
- Ship features freely
- Standard change management

### Budget 25-75% remaining

- Increased caution
- Require extra review for risky changes
- Prioritize reliability fixes alongside features
- Investigate top error contributors

### Budget < 25% remaining

- Reliability focus
- Feature freeze for the service (exceptions need leadership approval)
- Dedicate engineering time to reliability improvements
- Post-incident review on budget-consuming events

### Budget exhausted (0%)

- Emergency mode
- All changes require explicit approval
- Roll back recent changes if they contributed
- Incident review mandatory
- Recovery plan with timeline

## Burn-Rate Alerting

SLO burn-rate alerts replace threshold monitors for services with SLOs.
They answer: "Are we consuming error budget faster than sustainable?"

### Fast burn — P1 page

- **Window:** 5 minutes
- **Threshold:** Burning 14.4x the sustainable rate (2% of 30-day budget in 1 hour)
- **Meaning:** At this rate, budget exhausts in ~2 hours
- **Action:** Page on-call immediately

### Slow burn — P2 notify

- **Window:** 6 hours
- **Threshold:** Burning 6x the sustainable rate (5% of 30-day budget in 6 hours)
- **Meaning:** At this rate, budget exhausts in ~5 days
- **Action:** Notify team, fix during business hours

### Multi-window confirmation

Use a short window AND a long window together. The short window
detects the spike, the long window confirms it's sustained.
This prevents alerting on a 30-second blip that's already recovered.

Recommended: alert if 5-min burn rate > 14.4x AND 1-hour burn rate > 6x.

## SLO-to-Monitor Linkage

Every SLO should have:

1. A **burn-rate monitor** (fast + slow) that pages/notifies
2. A **dashboard widget** showing budget remaining
3. An **error budget policy** document that the team has agreed to
4. An entry in the **Service Catalog** linking SLO to service

Without the monitor, the SLO is a dashboard decoration.
Without the policy, the SLO has no teeth.

## Pup Execution

| Task | Command |
|------|---------|
| Create an SLO | `pup slos create` or invoke `pup:slos` |
| List SLOs | `pup slos list` |
| Check SLO history | `pup slos history --id <id>` |
| Create burn-rate monitor | `pup monitors create` (type: slo alert) |

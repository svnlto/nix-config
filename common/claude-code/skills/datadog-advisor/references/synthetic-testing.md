# Synthetic Testing

## Purpose

Synthetic tests verify that critical user journeys work before real
users hit them. They are proactive — they catch outages, regressions,
and third-party failures without waiting for user reports.

Synthetics serve three roles:

1. **Availability signal** — "Is the system reachable and functional?"
2. **Performance baseline** — "Is latency within expected bounds?"
3. **SLI source** — feed synthetic pass/fail into SLOs for uptime targets

## Test Type Selection

| Type | Best for | Complexity | Cost |
|------|----------|------------|------|
| **API test** | Endpoint health, auth flows, response validation | Low | Lowest |
| **Browser test** | Full user journeys with rendering, JS execution | High | Highest |
| **Multistep API** | Chained API calls (auth → action → verify) | Medium | Medium |
| **gRPC test** | gRPC service health checks | Low | Lowest |
| **TCP/SSL/DNS** | Infrastructure connectivity, cert expiry | Low | Lowest |

**Decision guide:**

- Can you verify it with an HTTP request? → **API test**
- Does it require a browser (JS rendering, clicks, form fills)? → **Browser test**
- Does it need multiple sequential API calls? → **Multistep API**
- Just checking connectivity or cert expiry? → **TCP/SSL/DNS**

Default to API tests. Only use browser tests when you genuinely need
to verify client-side rendering or user interaction flows.

## What to Test

### Tier 1 — Always test (high frequency)

These are your revenue and trust flows. Test every 1-2 minutes from
2+ locations.

- **Authentication** — login, token refresh, SSO redirect
- **Core transaction** — checkout, payment, order submission
- **Primary API** — the endpoints your customers or frontend depend on
- **Homepage/landing** — first impression, often the canary for CDN/DNS issues

### Tier 2 — Important (medium frequency)

Test every 5-15 minutes from 2 locations.

- **Search** — query execution and result rendering
- **User profile** — account access, settings
- **Notifications** — email/webhook delivery endpoints
- **Key integrations** — third-party APIs your service depends on

### Tier 3 — Coverage (low frequency)

Test every 15-60 minutes from 1 location.

- **Admin/internal tools** — back-office dashboards
- **Reporting** — export, PDF generation
- **Onboarding** — signup, activation flows
- **Documentation** — docs site availability

## Test Design Principles

**Test the contract, not the implementation.**
Assert on HTTP status codes, response schema, and key field values.
Don't assert on exact response bodies — they change with every deploy.

**Include timing assertions.**
Every API test should assert latency: `response_time < threshold`.
This catches performance regressions that don't break functionality.

**Test from the user's perspective.**
Browser tests should follow the actual user flow: navigate, click,
fill forms, verify outcomes. Don't shortcut with direct URL access
unless that's how users actually interact.

**Test third-party dependencies separately.**
Don't embed third-party health into your own service tests. Create
dedicated synthetics for Stripe, Auth0, Twilio, etc. so failures
attribute correctly.

## Location Strategy

| Strategy | Locations | Use when |
|----------|-----------|----------|
| **Single region** | 1 location near primary users | Internal tools, single-region services |
| **Primary + secondary** | 2 locations (primary region + DR) | Most production services |
| **Global** | 3-5 locations across continents | Global user base, CDN-backed services |

More locations = higher cost and more alert noise. Two well-chosen
locations catch 95% of issues. Add more only for globally distributed
services where regional failures are a real concern.

**Alert on location aggregation:** Require failure from 2+ locations
before alerting. Single-location failures are often transient network
issues, not real outages.

## Frequency and Cost Balance

| Scenario | Frequency | Rationale |
|----------|-----------|-----------|
| SLO-backing test | 1 min | Needs granular data for SLO calculation |
| Critical user journey | 1-2 min | Fast detection of outages |
| Important API health | 5 min | Balances coverage with cost |
| Secondary flows | 15 min | Sufficient for non-critical paths |
| Third-party checks | 15-30 min | External services change slowly |
| Business hours only | Skip overnight | Non-critical paths with no overnight users |

**Cost rule of thumb:** Doubling frequency doubles cost. Going from
5 min to 1 min is a 5x cost increase. Only do it for tests that
back SLOs or protect revenue-critical flows.

## Synthetics as SLI Source

Synthetic tests can feed SLOs directly:

**Uptime SLO from synthetics:**

```text
Good: synthetic test passes
Bad:  synthetic test fails
Target: 99.9% over 30 days
```

This works well for external-facing availability where you want to
measure "can a user reach and use the service?" independent of
internal metrics.

**When to use synthetic-based SLOs:**

- Public-facing services where you care about external reachability
- Third-party dependency availability tracking
- End-to-end user journey success rate

**When NOT to use:**

- Internal services (use metric-based SLOs from APM instead)
- High-throughput APIs (synthetic sampling is too coarse)
- Latency SLOs (use real traffic percentiles, not synthetic)

## CI/CD Integration

Run synthetics as deployment gates:

1. **Pre-deploy:** Run API tests against staging after deploy
2. **Post-deploy:** Trigger critical synthetics immediately after production deploy
3. **Canary validation:** Run synthetics against canary before promoting

This catches regressions before they reach all users. Use Datadog's
CI/CD integration to trigger tests from your pipeline.

## Alert Configuration for Synthetics

| Setting | Recommendation |
|---------|---------------|
| **Failure threshold** | 2 consecutive failures (avoids transient flaps) |
| **Location threshold** | Fail from 2+ locations before alerting |
| **Renotification** | 30 min for Tier 1, none for Tier 3 |
| **Recovery** | Notify on recovery (confirms the issue is resolved) |
| **Severity** | Tier 1 = P1, Tier 2 = P2, Tier 3 = P3 |

## Pup Execution

| Task | Command |
|------|---------|
| List synthetic tests | `pup synthetics list` or invoke `pup:synthetics` |
| Get test details | `pup synthetics get --id <id>` |
| Trigger a test run | `pup synthetics trigger --id <id>` |
| View test results | `pup synthetics results --id <id>` |

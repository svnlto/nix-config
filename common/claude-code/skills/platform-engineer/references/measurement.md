# Platform Measurement

Measure from day one. Technical sophistication without adoption
delivers nothing.

## Three Measurement Categories

### 1. User Satisfaction and Productivity

| Metric | How to Measure |
|--------|----------------|
| Active users | Count of teams/developers using platform capabilities monthly |
| Retention | User growth vs. churn over time |
| NPS / Satisfaction | Quarterly developer surveys (keep short: 5 questions max) |
| Developer productivity | SPACE framework dimensions (see below) |
| Time to onboard | Days from new hire to first merged PR |

### 2. Organizational Efficiency

| Metric | How to Measure |
|--------|----------------|
| Provisioning latency | Time from request to capability availability (databases, environments) |
| Service creation lead time | Time to build and deploy a new service to production |
| Toil reduction | Hours of manual work eliminated per quarter |
| Support ticket volume | Tickets filed against platform capabilities over time |
| Self-service ratio | % of provisioning done via self-service vs. tickets |

### 3. Product and Feature Delivery (DORA)

| Metric | How to Measure |
|--------|----------------|
| Deployment frequency | How often teams deploy to production |
| Lead time for changes | Commit to production duration |
| Time to restore service | Incident detection to resolution |
| Change failure rate | % of deployments causing incidents |

## SPACE Framework

Five dimensions of developer productivity (not all need measurement):

- **S**atisfaction and wellbeing — survey-based
- **P**erformance — outcome quality (not output volume)
- **A**ctivity — observable actions (deploys, PRs, builds)
- **C**ommunication and collaboration — review turnaround, knowledge sharing
- **E**fficiency and flow — uninterrupted work time, wait states

Pick 2-3 dimensions that matter most. Don't measure all five.

## Measurement Anti-Patterns

- Measuring platform output (features shipped) instead of developer outcomes
- Vanity metrics (portal page views) instead of capability adoption
- Annual surveys instead of continuous lightweight feedback
- Measuring without acting on results
- Optimizing metrics that don't correlate with developer experience

## Starting Point

Minimum viable measurement for a new platform:

1. **Adoption**: how many teams use each capability
2. **Lead time**: how long from request to provisioned
3. **Satisfaction**: one quarterly question — "would you recommend this platform?"

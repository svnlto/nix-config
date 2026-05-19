# Team Topologies for Platform Teams

Based on Team Topologies by Matthew Skelton and Manuel Pais.

## Four Team Types

| Type | Purpose | Relationship to Platform |
|------|---------|--------------------------|
| Stream-aligned | Own business domain slices end-to-end | Primary platform users |
| Platform | Provide compelling internal product to accelerate stream-aligned teams | This is you |
| Enabling | Temporarily boost skills in other teams, detect missing capabilities | Partners who surface platform gaps |
| Complicated Subsystem | Handle components requiring deep specialist knowledge | May own platform subsystems |

## Three Interaction Modes

### X-as-a-Service (default for platform teams)

The primary mode. Platform provides capabilities; stream-aligned
teams consume them through self-service interfaces.

- Clear API boundaries and contracts
- Low coordination cost at steady state
- Platform team owns reliability; consuming team owns usage

### Collaboration (time-boxed)

Used when discovering new platform capabilities or onboarding
early adopter teams. High bandwidth, high cost.

- Pair with 1-2 stream-aligned teams to co-design new capabilities
- Time-box to weeks, not months
- Output: new x-as-a-service capability

### Facilitation (temporary)

Used when teams need help adopting platform capabilities.
Enabling teams often do this on behalf of the platform team.

- Teach teams to use golden paths effectively
- Identify UX gaps in platform self-service
- Transition to x-as-a-service once team is self-sufficient

## Thinnest Viable Platform (TVP)

Build the minimum platform layer over existing implementations:

1. Start with documentation and templates (even a wiki page counts)
2. Add automation for the highest-toil, most-requested capabilities
3. Wrap managed services with governance, not reimplementation
4. Only build custom when no viable adopt/buy option exists

**Anti-pattern**: building a Kubernetes-based PaaS when teams
need a CI pipeline and a database provisioning form.

## Platform Team Sizing

- Don't start a platform team below ~20-30 developers in the org
- A single platform team serves 5-15 stream-aligned teams
- Multiple platform teams form a platform group with shared standards
- Platform teams need product management, not just engineering

## Platform Team Responsibilities

1. Research user requirements through interviews, surveys, observability
2. Plan feature roadmap based on collected feedback
3. Build and maintain self-service interfaces (portals, APIs, CLIs, templates)
4. Market and evangelize platform adoption (demos, docs, office hours)
5. Define platform contracts (SLOs, ownership, deprecation policies)
6. Measure adoption and developer satisfaction continuously

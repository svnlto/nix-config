# Architecture Decision Record Template

## ADR Format

Each ADR is a markdown file with YAML frontmatter:

```yaml
---
title: "ADR-NNNN: Short Descriptive Title"
date: YYYY-MM-DD
status: proposed | accepted | deprecated | superseded
tags: [architecture, relevant-domain-tags]
---
```

The body uses standard markdown with the sections below.

## Template

```markdown
---
title: "ADR-NNNN: Short Descriptive Title"
date: YYYY-MM-DD
status: proposed
tags: [architecture]
---

# ADR-NNNN: Short Descriptive Title

## Status

Proposed

## Context

Why this decision is needed. Describe the forces at play:
technical constraints, business requirements, team capabilities,
existing system state, and any time pressure. Be specific
enough that a reader unfamiliar with the project understands
the problem space.

## Decision

State what was decided, in active voice. Example: "We will
use PostgreSQL as the primary data store for tenant
configuration." Keep it concrete and unambiguous.

## Consequences

### Positive

- Benefit one
- Benefit two

### Negative

- Drawback or risk one
- Drawback or risk two

### Neutral

- Observation that is neither clearly positive nor negative

## Alternatives Considered

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Option A | ... | ... | Chosen |
| Option B | ... | ... | Rejected |
| Option C | ... | ... | Deferred |
```

## Status Lifecycle

```text
Proposed --> Accepted --> Deprecated
                     \-> Superseded by ADR-NNNN
```

- **Proposed**: Decision is drafted and open for review.
- **Accepted**: Decision is approved and in effect.
- **Deprecated**: Decision is no longer relevant (the system
  or feature it applied to has been removed).
- **Superseded by ADR-NNNN**: A newer decision replaces this
  one. Link to the superseding ADR.

**When to supersede vs. amend**: Supersede when the
fundamental decision changes (different technology, different
pattern). Amend in place (with a dated changelog entry at the
bottom) for minor clarifications that do not change the core
decision.

## Example

```markdown
---
title: "ADR-0012: Use PostgreSQL for Tenant Configuration Store"
date: 2026-03-15
status: accepted
tags: [architecture, database, multi-tenancy]
---

# ADR-0012: Use PostgreSQL for Tenant Configuration Store

## Status

Accepted

## Context

The platform needs a persistent store for tenant
configuration (feature flags, branding, limits). Current
configuration lives in environment variables, which requires
redeployment on every change. Requirements:

- Read-heavy workload (~500 reads/sec, ~5 writes/sec)
- Strong consistency needed (tenant limits must apply
  immediately)
- Schema will evolve as new tenant settings are added
- Operations team is already experienced with PostgreSQL

## Decision

We will use PostgreSQL with a JSONB column for extensible
tenant settings, backed by a typed Go struct for
compile-time safety. A thin caching layer (5-second TTL)
sits in front to reduce database load.

## Consequences

### Positive

- Leverages existing PostgreSQL expertise and infrastructure
- JSONB provides schema flexibility without sacrificing
  query capability
- Strong consistency guarantees out of the box
- Mature ecosystem for migrations, backups, monitoring

### Negative

- JSONB queries are slower than native columns for complex
  filters
- Cache TTL introduces up to 5 seconds of staleness
- Single-database dependency for a critical path

### Neutral

- Requires a migration framework (golang-migrate selected)
- Monitoring dashboards need a new panel for config-store
  query latency

## Alternatives Considered

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| PostgreSQL + JSONB | Team expertise, strong consistency, flexible schema | JSONB query perf, single DB dependency | Chosen |
| MongoDB | Native document model, flexible schema | No team expertise, eventual consistency default, new operational burden | Rejected |
| DynamoDB | Fully managed, auto-scaling | Vendor lock-in, eventual consistency, limited query patterns, no team experience | Rejected |
```

## File Naming

ADR files follow the pattern:

```text
NNNN-short-title.md
```

- `NNNN` is a zero-padded sequential number (0001, 0002, ...)
- `short-title` is a lowercase, hyphenated summary
- Example: `0001-use-postgresql.md`, `0012-adopt-grpc.md`

Store ADRs in the `docs/adr/` directory at the repository
root. Maintain sequential numbering — never reuse numbers,
even for deprecated decisions.

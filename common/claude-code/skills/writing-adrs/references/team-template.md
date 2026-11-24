# Team ADR template (11 sections)

The team's ADR format. Source of truth is the ADR documentation template in
the team's Confluence space; this mirrors it for in-vault authoring. Use for
team platform decisions and any ADR that attaches to an Epic.

Copy the skeleton below. Keep the section numbers. Drop a section only when it
genuinely does not apply; prefer a one-line "None" over deleting it.

```markdown
---
type: decision
date: YYYY-MM-DD
domain: work
project: <project>
status: proposed
tags: [adr, ...]
---

# ADR - 00XX - Title

## Revision

| Date       | Version | Note          | Author |
| ---------- | ------- | ------------- | ------ |
| YYYY-MM-DD | 0.1     | Initial draft | Name   |

## 1. Purpose and Scope

One or two sentences on what this ADR proposes.

| | |
|---|---|
| **Scope** | What this decision covers. |
| **Out of scope** | What it deliberately does not, with a wikilink to the companion ADR if there is one. |
| **Stakeholders** | Who is affected and who decides. |

## 2. Context (Baseline)

What exists today and why it matters now. Describe the current state plainly.
Acknowledge that it has worked. Then list the problems it carries as the
platform grows, as a short bullet list.

## 3. Opportunities and Solutions

| Opportunity | Background | Problem Statement | Solution |
|-------------|------------|-------------------|----------|
| ... | ... | ... | ... |

## 4. Decision (Target)

What is proposed as the standard. Frame as a proposal ("the platform should
adopt ..."), not a conclusion. Follow with the key points as bullets.

## 5. Constraints and Assumptions

| Type | Item |
|------|------|
| Technical constraint | ... |
| Assumption | ... |

## 6. Security and Risk

| Risk | Mitigation |
|------|------------|
| ... | ... |

## 7. Consequences

Positive:

| Consequence | Benefit |
|-------------|---------|
| ... | ... |

Negative and trade-offs:

| Trade-off | Impact |
|-----------|--------|
| ... | ... |

## 8. Alternatives Considered

| Alternative | Strength | Why not, for now |
|-------------|----------|------------------|
| ... | ... | ... |

## 9. Implementation

Where the rollout is tracked (wikilink to the roadmap or epic). Implementation
detail belongs in the follow-up work items, not here.

## 10. References

- [[note|Label]] for related ADRs, roadmaps, and standards.
- External sources (Confluence template, vendor docs) as needed.

## 11. Approvals

| Role | Name | Date | Decision |
|------|------|------|----------|
| | | | |
```

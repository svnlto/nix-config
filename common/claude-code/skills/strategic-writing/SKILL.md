---
name: strategic-writing
description: >-
  Use when writing, reviewing, or editing strategy
  documents, concept papers, or decision documents
  scoped to 'what and why' rather than 'how'.
  Triggers: strategy, concept, SRE strategy,
  architecture strategy, platform strategy, decision
  document, strategy review, strategy trimming.
metadata:
  domain: writing
  role: discipline
  scope: strategy
  related-skills: datadog-advisor, architecture-designer, platform-engineer, sre-engineer, doc-standards
---

# Strategic Writing

Discipline skill for strategy documents. Complements
doc-standards (invoke that skill too -- it covers general
writing quality). This skill adds constraints specific to
strategy-level content.

## Core Principle

Strategy documents state decisions and principles. They
answer what and why, never how. Implementation belongs
in follow-up work.

## The Two-Pass Test

Before saving any edit to a strategy document, re-read
it asking:

> Is this a decision or an instruction?

Instructions don't belong. If a sentence tells someone
how to execute, it's implementation detail.

**Strategy (keep):**

- "Synthetic monitoring is split into base checks
  and application checks"
- "Datadog is the operational pane of glass"
- "The platform provides the self-registration
  mechanism"
- "Logs route to three tiers by retention need"

**Implementation (remove):**

- "A Crossplane XRD defines the Claim schema with
  fields for endpoint, health path..."
- "All monitors defined as Terraform
  datadog_monitor resources of type slo alert"
- "ArgoCD deploys the Claim with the app, Crossplane
  reconciles via provider-terraform"
- "Fluent Bit filter: status:(error OR critical)
  AND service:(argocd OR haproxy-ingress...)"

## Red Flags -- STOP and Rewrite

- Tooling mechanism names in architectural descriptions
  (Terraform locals, Helm values, Crossplane Compositions)
- Filter syntax, config snippets, or CLI commands
- Step-by-step implementation instructions
- Specific service account names or API paths
- Sentences starting with "Configure...", "Deploy...",
  "Run..."
- Referencing how a feature is implemented rather than
  what it achieves

## Structure Conventions

Every strategy document must have (per doc-standards):

1. **Version history** -- table with version,
   description, author, date
2. **Maintainer** -- who owns this document
3. **Purpose statement** -- one sentence: what this
   document is and who it's for
4. **Jargon glossary** -- define terms on first use
   (acronyms, domain-specific concepts)

## Writing Discipline

- **Tables over prose.** If content has structure, it
  belongs in a table
- **One sentence over a paragraph.** If the point fits
  in one sentence, don't write three
- **British English throughout**
- **No redundant navigation.** No "Part of..." lines
  when page hierarchy is clear. No Jira ticket
  references in body text. One document index, not
  duplicate lists
- **Ownership in every section.** State who owns the
  decision, not who implements it
- **Holistic edits.** Review the full document before
  editing. Don't make piecemeal changes that create
  inconsistency

## Common Mistakes

- **Mixing strategy and implementation** -- Split:
  strategy doc states the decision, link to
  implementation doc for the how
- **Trimming by deleting content** -- Trim by
  elevating: replace detail with the principle it serves
- **Adding tool-specific detail "for clarity"** -- The
  reader doesn't need to know the tool to understand
  the decision
- **Writing for the implementer** -- Write for the
  approver. They need to understand the decision, not
  execute it
- **Piecemeal edits across a document** -- Read the
  whole document first, identify all changes, make one
  coherent pass

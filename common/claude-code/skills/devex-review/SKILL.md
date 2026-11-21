---
name: devex-review
description: >-
  Evaluate platform team outputs (blueprints, golden-path docs, ADRs,
  generated repos, standards) through the lens of the people who consume
  them. Shared foundation for the devex-persona-* agents and the
  devex-reviewer orchestrator. Provides the evaluation framework,
  finding format, and domain guard. Trigger on: persona review, devex
  review, evaluate from consumer perspective, friction review, golden
  path review, blueprint review from user perspective.
---

# DevEx Review

Evaluate platform outputs from the consumer's perspective. This skill
is the shared foundation for the devex persona agents; it defines how
findings are structured, how domain knowledge is handled, and how
evaluation works.

## Evaluation framework

An evaluation answers one question: can the target persona complete
their job with what the platform gave them?

For each artifact under review, walk the persona's likely path through
it. At every step, check:

1. **Assumption gap** — does the artifact assume knowledge the persona
   does not have? A backend developer does not know what devbox is. A
   tech lead does not know the three-bucket model until the docs
   explain it.
2. **Missing step** — is there a step the persona must take that the
   artifact does not mention? The gap between `direnv allow` and a
   working shell includes a nix download the docs may not cover.
3. **Wrong order** — does the artifact present information in an order
   that does not match the persona's task flow? Setup instructions
   that explain the compiler before showing the first command lose the
   reader.
4. **Escape-path silence** — when something goes wrong, does the
   artifact tell the persona what to do? A pre-commit hook that fails
   with a nix error needs a troubleshooting note, not silence.
5. **Terminology barrier** — does the artifact use terms the persona
   has not seen? "Passthrough inputs", "render-once", "template-owned"
   are platform vocabulary. The consumer may not share it.

## Finding format

Each finding is one structured observation:

```text
**[severity]** As [persona], doing [task], I hit [friction point].
The artifact says [what it says] but I expected [what I needed].
Suggestion: [concrete fix].
```

Severity levels:

- **blocker** — the persona cannot proceed without solving this.
  Missing a prerequisite, undocumented error, broken path.
- **friction** — the persona can proceed but wastes time or
  confidence. Unclear phrasing, buried information, assumed knowledge.
- **gap** — a scenario the artifact does not cover. The persona works
  around it but should not have to.
- **nit** — a minor clarity or wording improvement.

## Domain guard

Platform-engineering and DevEx terms carry weight. Do not simplify
away terms that encode real distinctions:

- "Terraform state is forward-only" — real constraint, keep it.
- "render-once vs template-owned" — meaningful split, explain it
  rather than removing it.
- "shift-left" — standard DevEx term, the persona may know it.
- "copier update applies a 3-way merge" — load-bearing, keep it
  but verify the persona can follow it.

When a term is load-bearing but the persona likely does not know it,
the finding is "explain this term" not "remove this term".

## What to evaluate

The skill works against any platform output:

- **Generated repo** — clone it, read the docs, try the setup path.
  Check: does `direnv allow` → `just setup` → `just check` work
  as described? Are errors explained?
- **Consumer docs** — read as the persona, following the task flow.
  Check: can I complete the documented task without prior knowledge
  beyond my role?
- **ADR / standard** — read as a stakeholder who must understand and
  approve. Check: do I understand what changes for me and why?
- **Manifest reference** — read as someone writing a manifest for
  the first time. Check: can I produce a valid manifest from this
  page alone?

## Deduplication

When multiple personas flag the same finding, the orchestrator keeps
one finding and notes which personas hit it. Three personas unable to
parse the same paragraph is one finding with three voices, not three
findings.

## Chaining with devex-writer

After persona findings are collected, `devex-writer` can tighten the
fixes. The persona agents identify what is wrong; `devex-writer`
sharpens the rewrite. The orchestrator chains both passes when asked.

---
name: spex-discovery
description: >-
  Use when an open question must end in a recorded go / needs-clarification /
  kill verdict before anything is specified or built: whether to adopt,
  replace or build something, whether an idea is feasible, which of several
  options to pursue. Triggers: should we, can we, is it feasible, discovery,
  assess this idea, go/no-go, compare options before we commit, spike,
  specify workflow run assess, /speckit-assess. NOT for designing the
  architecture of an option already chosen (`architecture-designer`),
  writing strategy documents (`strategic-writing`), or agreed features
  (`spex-feature`).
license: MIT
metadata:
  version: "1.0.0"
  domain: devops
  triggers: should we, feasibility, discovery, assess, go/no-go, spike, compare options
  role: workflow
  scope: process
  related-skills: cc-spex, spex-feature, jira-intake, architecture-designer, writing-adrs
---

# spex-discovery

**REQUIRED when `.specify/` exists: the `cc-spex` skill.**

## Input

An idea, a URL, a codebase pointer, a ticket (`jira-intake` may build a
brief), or pasted ticket text. No ticket is needed.

## Stages

| Stage | Output |
|---|---|
| Intake | The question in one sentence, who asked, which decision it feeds |
| Research | Current state of the code and platform, constraints, prior decisions |
| Define | Success criteria and what is out of scope |
| Shape | 2–3 options with trade-offs; a timeboxed spike only if an option cannot be judged without one |
| Decide | A recommendation and the proposed verdict |

Where the assessment goes:

- `assess` extension installed (`.specify/extensions/assess/`): its
  commands, or `specify workflow run assess` once the workflow was added.
- spec-kit without it: `brainstorm/NN-<slug>-assessment.md`.
- No spec-kit: in the session, then wherever the user keeps decisions.

## Verdict

The recommendation is the agent's; the verdict is the user's. Present it as
"Recommended verdict: …" and ask for the decision; never state the verdict
as made. Consult the architect before the verdict when an option changes
architecture or needs a security review.

| Verdict | Next |
|---|---|
| Go | `spex-feature`: brainstorm starts at the agreed approach |
| Needs clarification | List the open questions and who answers each |
| Kill | Record the decision and reasons with `writing-adrs`; note what would reopen it |

## Rules

- No production code. Spike code is throwaway and stays off `main`.
- Name the evidence behind each claim; mark guesses as guesses.
- Stop at the verdict: no spec, no plan.

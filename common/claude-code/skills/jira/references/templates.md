# Ticket Templates

Body templates for the description field, by issue type. Pick
the one matching the issue type and fill the placeholders.

| Issue type | Template              |
| ---------- | --------------------- |
| Story      | `templates/story.md`  |
| Epic       | `templates/epic.md`   |
| Bug        | `templates/bug.md`    |
| Task       | `templates/task.md`   |
| Sub-task   | `templates/subtask.md`|

## Description structure

- Story and Epic lead with a persona line: "As a {persona},
  I want {goal}, so that {benefit}." Then Context, then
  Acceptance Criteria.
- Bug adds Steps to Reproduce and Expected vs Actual before
  the Acceptance Criteria.
- Keep tickets at the what/why level. Implementation detail
  belongs in sub-tasks and linked specs; decisions belong in
  an ADR.

## Summary convention

Many projects prefix summaries with a scope path, for example
`Area | Subarea | short summary`. Before creating, `search`
recent issues in the project and match the prevailing prefix
scheme. The prefix vocabulary and the available issue types
are instance-specific. Do not assume them; project-specific
conventions may be documented outside this skill.

## Hierarchy

Typical Jira hierarchy: Initiative -> Epic -> Story ->
Sub-task. Task and Bug usually sit at Story level under an
Epic. Confirm against the project.

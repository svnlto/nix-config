---
name: jira
description: >-
  Read, search, create, and update Jira issues via browser
  automation. Use when viewing a Jira ticket, running a JQL
  or natural-language issue search, creating an issue, or
  transitioning/commenting/reassigning an existing issue.
version: 1.0.0
tags: [jira, issues, browser-automation, atlassian]
metadata:
  related-skills: confluence-sync
---

# Jira

Read and write Jira issues using Chrome DevTools MCP. No Jira
API access required -- all interaction is browser-based,
reusing the authenticated Chrome session.

## Prerequisites

1. Chrome running with remote debugging:
   - macOS: `open -a "Google Chrome" --args`
     `--remote-debugging-port=9222`
     `--user-data-dir="$(mktemp -d)"`
2. Logged into Jira in that Chrome instance
3. Chrome DevTools MCP available (user-scope, port 9222)
4. `Meta/claude-config.md` in the vault has a
   `jira_base_url` frontmatter field

## Instance Resolution

Read `jira_base_url` from the frontmatter of
`$HOME/Documents/obsidian-vault/Meta/claude-config.md`
(use the Read tool, parse the YAML frontmatter).

- Bare key `KAAS-123` ->
  `${jira_base_url}/browse/KAAS-123`
- Full URL passed by user -> use as-is
- Config note missing or `jira_base_url` absent AND no full
  URL -> abort, name the note and field

Never hardcode the instance URL -- this repo is public.

## Invocation

Accepts a command plus arguments. If no command is given,
infer from context or ask. If a command needs an issue and
none is given, ask.

## Command Routing

| Command | Reference                | Load When                         |
| ------- | ------------------------ | --------------------------------- |
| read    | `references/read.md`     | Viewing an issue                  |
| search  | `references/search.md`   | JQL or natural-language search    |
| create  | `references/create.md`   | Creating an issue                 |
| update  | `references/update.md`   | Transition/reassign/field/comment |

Drafting an issue description: see `references/templates.md`
and the per-type bodies in `references/templates/`.

## Safety

`create` and `update` change shared state visible to others.
Always show a preview of the exact change and get explicit
user confirmation before clicking submit. Never submit
silently. No retry loops.

## Error Handling

Report clearly and stop.

| Condition                     | Action                          |
| ----------------------------- | ------------------------------- |
| config note / field missing   | Abort, name the note and field  |
| Issue 404 / not found         | Report stale or wrong key       |
| Not logged in                 | Report; ask to log into Chrome  |
| Field locked / not editable   | Report permission/workflow      |
| Transition unavailable        | Report offered transitions      |
| Create/edit dialog not found  | Report editor structure change  |
| Submit button not found       | Report not in edit mode         |
| Chrome DevTools fails         | Report debug port issue (:9222) |
| No results (search)           | Report empty result set         |

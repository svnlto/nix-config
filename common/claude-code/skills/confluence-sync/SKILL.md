---
name: confluence-sync
description: >-
  Sync Obsidian documents to Confluence wiki pages via
  browser automation. Use when pushing docs to Confluence,
  pulling or replying to comments, incorporating comment
  feedback, checking page status, or creating new wiki pages.
version: 1.0.0
tags: [confluence, wiki, sync, obsidian, browser-automation]
metadata:
  related-skills: doc-standards, obsidian:obsidian-markdown
---

# Confluence Sync

Sync Obsidian documents to Confluence wiki pages using
Chrome DevTools MCP. No Confluence API access required --
all interaction is browser-based.

## Related Skills

- Invoke `doc-standards` before pushing -- content must
  follow the team's documentation code of conduct
- Use `obsidian:obsidian-markdown` conventions when
  reading or writing frontmatter

## Prerequisites

1. Chrome is running with remote debugging:
   - macOS: `open -a "Google Chrome" --args`
     `--remote-debugging-port=9222`
     `--user-data-dir="$(mktemp -d)"`
   - Linux: `google-chrome`
     `--remote-debugging-port=9222`
     `--user-data-dir="$(mktemp -d)"`
2. Logged into Confluence in that Chrome instance
3. Chrome DevTools MCP configured in `.mcp.json`
   (port 9222)

## Invocation

Accepts an Obsidian note path as argument. If no path
provided, ask the user. If no command specified, infer
from context or ask.

## Frontmatter Convention

The skill reads and writes a `confluence` field in the
note's YAML frontmatter:

```yaml
confluence: >-
  https://INSTANCE.atlassian.net/wiki/spaces/
  SPACE_KEY/pages/PAGE_ID/Page+Title
```

- Present: use that URL for push/pull/status
- Absent on push: ask user to create new page or abort
- Absent on pull-comments or status: abort with message

## Command Routing

1. Read the target Obsidian note using the Read tool
2. Parse YAML frontmatter to extract the `confluence` URL
3. Route to the appropriate workflow:

| Command        | Reference                             | Load When                         |
| -------------- | ------------------------------------- | --------------------------------- |
| push           | `references/push.md`                  | Pushing or creating               |
| pull-comments  | `references/pull-comments.md`         | Extracting comments               |
| reply-comments | `references/reply-comments.md`        | Replying to comments              |
| apply-feedback | `references/apply-feedback.md`        | Incorporating comment feedback    |
| status         | `references/status.md`                | Checking page metadata            |

### Supporting References

| Reference                                  | Purpose                              |
| ------------------------------------------ | ------------------------------------ |
| `references/confluence-native-elements.md` | Native editor elements and shortcuts |
| `references/diagram-conversion.md`         | Rendering diagrams for upload        |

## Error Handling

Handle errors by reporting clearly and stopping.
No retry loops.

| Condition                     | Action                         |
| ----------------------------- | ------------------------------ |
| No `confluence` (push)        | Ask: create new or abort?      |
| No `confluence` (pull/status) | Abort with message             |
| Page 404 or not found         | Report stale URL               |
| Edit button not found         | Report permission issue        |
| Editor not found              | Report editor structure change |
| Publish button not found      | Report not in edit mode        |
| Chrome DevTools fails         | Report debug port issue        |
| No comments found             | Report no comments             |
| Reply field not found         | Report editor structure change |
| Comment resolved unexpectedly | Report and stop                |
| Diagram render fails          | Report tool/dependency issue   |
| Image upload fails            | Report and suggest manual step |

# Read a Jira Issue

## Steps

1. Resolve the issue URL (see SKILL.md "Instance Resolution").
2. `navigate_page` to the issue URL.
3. `wait_for` text that confirms load (the issue key, or the
   summary heading). If a login screen appears instead,
   stop and report "not logged in".
4. `take_snapshot` to capture the accessibility tree.
5. Extract from the snapshot:
   - Summary (the issue heading / `h1`)
   - Status (the status button near the top)
   - Assignee
   - Issue type and key
   - Description body
   - Comments (author + text, in order)
6. If the description or comments are not legible in the
   snapshot, use `evaluate_script` to read the rendered text
   of the description region and comment list, then format.

## Output

Default: print a clean summary to the terminal:

```text
PROJ-123  [In Progress]  Bug
Summary: <summary>
Assignee: <name>

Description:
<description>

Comments (N):
- <author>: <text>
```

If the user named an output file, write the same content as
markdown to that path instead.

## Errors

- 404 / "issue does not exist" -> report stale or wrong key.
- Login screen -> report not logged in.
- Snapshot empty -> report Chrome DevTools / page-load issue.

# Search Jira Issues

## Input

Accepts either:

- A JQL string -> use directly.
- Natural language -> construct JQL. Examples:
  - "my open tickets" ->
    `assignee = currentUser() AND statusCategory != Done
     ORDER BY updated DESC`
  - "bugs in PROJ this sprint" ->
    `project = PROJ AND issuetype = Bug AND sprint in
     openSprints() ORDER BY priority DESC`
  - "unassigned in PROJ" ->
    `project = PROJ AND assignee is EMPTY`

When constructing JQL from natural language, show the JQL to
the user before running so they can correct it.

## Steps

1. URL-encode the JQL.
2. `navigate_page` to
   `${jira_base_url}/issues/?jql=<encoded-jql>`.
3. `wait_for` the results list (or an empty-state message).
4. `take_snapshot`; extract each row's key, summary, status.
5. If rows are not legible in the snapshot, use
   `evaluate_script` to read the results table rows.

## Output

```text
N results for: <jql>
PROJ-1   [To Do]        <summary>
PROJ-2   [In Progress]  <summary>
```

## Errors

- Empty result set -> report no matches and echo the JQL.
- JQL error banner -> report the Jira error text; offer to
  revise the JQL.

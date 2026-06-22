# Create a Jira Issue

## Required input

Project, issue type, summary. Description optional. Ask for
any missing required field before opening the dialog.

## Parent link

Set the parent so the issue lands in the hierarchy (see
`templates.md`): a Story or Task under its Epic, an Epic under
its Initiative, a Sub-task under its Story. If the parent is
not given and the type needs one, ask for it (or `search` to
find it) before submitting. The field is usually labelled
"Parent" or "Epic" in the create dialog.

## Drafting the description

Base the description on the matching body template in
`references/templates/` and the structure in
`references/templates.md` (persona line, Context, Acceptance
Criteria; Bug adds repro and expected vs actual). Match the
project's summary prefix convention; if unsure, `search`
recent issues in the project first.

## Steps

1. `navigate_page` to `${jira_base_url}` (any in-app page).
2. `take_snapshot`; find the global "Create" button and
   `click` it.
3. `take_snapshot` of the create dialog. Find the Project,
   Issue type, Summary, Description, and Parent/Epic fields.
4. Set fields:
   - Project / Issue type / Parent are usually comboboxes ->
     `click` to open, `take_snapshot`, `click` the matching
     option.
   - Summary / Description are text inputs -> `fill`.
   Prefer `fill_form` when several plain inputs are visible
   at once.
5. `take_screenshot` of the filled dialog.

## Confirmation (required)

Show the user a preview before submitting:

```text
About to create:
  Project: <project>
  Type:    <type>
  Parent:  <parent key or none>
  Summary: <summary>
  Description: <first lines>
```

Ask for explicit confirmation. Only on "yes":
6. `click` the dialog's Create/Submit button.
7. `wait_for` the success toast or the new issue.
8. Report the new key and URL
   (`${jira_base_url}/browse/<KEY>`).

If the user says no, abort without submitting.

## Errors

- Create button not found -> report editor structure change.
- Required field still flagged after fill -> report which
  field; do not submit.
- Submit button not found -> report not in create mode.

# Update a Jira Issue

Covers four change types: transition status, reassign, edit a
field, add a comment. All require preview + explicit
confirmation before submit. No retry loops.

## Common setup

1. Resolve the issue URL (see SKILL.md).
2. `navigate_page` to the issue; `wait_for` load.
3. `take_snapshot`.

## Transition status

1. `click` the status button.
2. `take_snapshot`; read the offered transitions.
3. If the requested target is not offered, report the
   available transitions and stop.
4. Preview: "Transition PROJ-123: <from> -> <to>?" Confirm.
5. On yes, `click` the target transition. `wait_for` the new
   status. If a transition screen (required fields) appears,
   surface its fields and confirm again before submitting.

## Reassign

1. `click` the Assignee field.
2. `fill` the assignee name; `take_snapshot`; `click` the
   matching person.
3. Preview: "Assign PROJ-123 to <name>?" Confirm, then
   confirm the selection in the UI.

## Edit a field

1. `click` the field's inline-edit control.
2. `fill` / select the new value.
3. Preview: "Set <field> = <value> on PROJ-123?" Confirm,
   then commit the inline edit (Enter / the field's check).

## Add a comment

1. `click` the comment box.
2. `fill` the comment text.
3. Preview the full comment text. Confirm.
4. On yes, `click` Save. `wait_for` the comment to appear.

## Errors

- Field locked / not editable -> report permission/workflow.
- Transition unavailable -> report offered transitions.
- Save/confirm control not found -> report editor change; do
  not leave a half-applied edit -- report current state.

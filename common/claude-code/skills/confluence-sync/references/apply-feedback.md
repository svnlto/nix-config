# Apply Feedback Workflow

Read Confluence comments, incorporate feedback into the
Obsidian source document, then push updates and optionally
reply to or resolve comments.

This is a composite workflow that chains `pull-comments`,
document editing, `push`, and `reply-comments`.

## Step 1: Pull comments

Follow `references/pull-comments.md` to extract all page
and inline comments from the Confluence page.

Present the comments to the user grouped by type:

```text
## Confluence Feedback for [Page Title]

### Inline Comments (3)
1. **Kirill** on "error budget threshold": "Should this
   be 5% or 10%? We discussed 10% in the last review."
2. **Hendrik** on "SaaS-CD-P": "Clarify whether staging
   counts as a separate instance."
3. ...

### Page Comments (1)
1. **Lucian**: "Missing section on backup strategy."
```

## Step 2: Triage with user

Ask the user which comments to act on:

- **Accept** -- incorporate the feedback into the
  Obsidian source
- **Reject** -- skip (optionally reply explaining why)
- **Discuss** -- needs clarification, reply with a
  question
- **Defer** -- acknowledge but handle later

Wait for the user to classify each comment (or batch
classify: "accept all inline, reject page comment 1").

## Step 3: Edit the Obsidian source

For each accepted comment:

1. Read the current Obsidian source document
2. Locate the relevant section (use the inline comment's
   anchor text or the page comment's topic to find it)
3. Propose the edit to the user before applying
4. Apply the edit using the Edit tool
5. Track which comments drove which changes

Do not make edits without user approval. Present each
change as a diff or description first.

## Step 4: Push updates

After all accepted changes are applied to the Obsidian
source, follow `references/push.md` to push the updated
sections to Confluence.

Only push sections that changed -- the incremental push
workflow handles this automatically via the diff step.

## Step 5: Reply and resolve

For each comment that was addressed:

1. Follow `references/reply-comments.md` to reply with
   a brief confirmation, e.g.:
   - "Updated to 10% as discussed."
   - "Added clarification about staging instances."
2. Ask the user if they want to resolve the comment
3. Resolve if approved

For rejected comments, reply with the user's reasoning
if they provided one.

For deferred comments, do nothing (leave them open).

## Step 6: Report

Summarise what was done:

```text
## Feedback Applied

### Changes made (3)
1. Updated error budget threshold from 5% to 10%
   (inline comment by Kirill -- replied and resolved)
2. Clarified SaaS-CD-P staging definition
   (inline comment by Hendrik -- replied and resolved)
3. Added backup strategy section
   (page comment by Lucian -- replied, left open)

### Skipped (1)
1. Page comment by Friedemann -- deferred to next review

### Sections pushed
- SLO Framework (updated)
- Organisational Prerequisites (updated)
- Backup Strategy (new)
```

## Important constraints

- **User controls triage** -- never accept or reject
  feedback without user input
- **Edit Obsidian first** -- the Obsidian note is the
  source of truth, always edit there before pushing
- **Propose before editing** -- show the planned change
  and get approval before modifying the source
- **Reply confirms the action** -- replies should state
  what was changed, not just "done"
- **Don't resolve without permission** -- some teams
  prefer the comment author resolves their own comments

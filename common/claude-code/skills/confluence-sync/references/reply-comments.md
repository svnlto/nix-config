# Reply to Comments Workflow

Respond to inline or page-level comments on a Confluence
page. Useful after `pull-comments` has surfaced feedback
that can be addressed directly.

## Step 1: Navigate to the page

1. Use `navigate_page` to open the `confluence` URL
   from frontmatter
2. Use `wait_for` with text `["Edit", "edit", "Edited"]`
   to confirm the page loaded

## Step 2: Locate the comment

### Page-level comments

1. Use `take_snapshot` to capture the page
2. Look for "View all comments" button and click it
3. Use `take_snapshot` to find the target comment
4. Each comment should have a "Reply" button or link

### Inline comments

1. Use `evaluate_script` to find inline comment markers:

```javascript
() => {
  const markers = document.querySelectorAll(
    'mark[data-mark-type="annotation"]'
  );
  return Array.from(markers).map((m, i) => ({
    index: i,
    anchorText: m.textContent.substring(0, 100),
    id: m.dataset.id || m.dataset.annotationId || null
  }));
}
```

1. Click the marker matching the target comment's
   anchor text
1. Use `take_snapshot` to see the comment thread

## Step 3: Reply to the comment

1. Find the reply input field in the snapshot (typically
   a textbox or placeholder like "Reply..." or
   "Write a reply...")
2. Click the reply field to focus it
3. Type the reply text using `type_text`
4. Use native elements where appropriate:
   - `@name` for mentioning people
   - `//` for date references
5. Look for a "Save" or "Reply" button and click it
6. Use `take_snapshot` to verify the reply posted

## Step 4: Resolve comments (if requested)

If the user asks to resolve a comment after replying:

1. Look for a "Resolve" button in the comment thread
2. Click it
3. Use `take_snapshot` to confirm the comment is resolved

Only resolve when explicitly asked. Resolving hides the
comment from the default view.

## Step 5: Report

Report which comments were replied to and/or resolved:

```text
Replied to 2 comments:
1. Inline on "error budget threshold" -- replied with
   clarification about the 5% threshold
2. Page comment by Kirill -- replied with updated
   timeline

Resolved: comment 1 (as requested)
```

## Important constraints

- **Confirm replies before posting** -- show the draft
  reply text to the user and get approval before
  submitting
- **Never resolve without permission** -- resolving
  hides comments, only do this when explicitly asked
- **Preserve threading** -- reply to the specific
  comment, don't create new top-level comments
- **Use native elements in replies** -- `@mentions`
  for people, `//` for dates, not plain text

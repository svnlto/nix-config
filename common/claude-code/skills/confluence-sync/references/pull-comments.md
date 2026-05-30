# Pull Comments Workflow

## Step 1: Navigate to the page

1. Use `navigate_page` to open the `confluence` URL from frontmatter
2. Use `wait_for` with text `["Edit", "edit"]` to confirm the page loaded

## Step 2: Extract page-level comments

1. Use `take_snapshot` to capture the page
2. Look for a "View all comments" button in the snapshot
3. If found, `click` it to expand the comments section
4. Use `take_snapshot` again to capture expanded comments
5. Parse the snapshot for comment entries, collecting:
   - Author name (typically in a link or static text near the comment)
   - Date/timestamp
   - Comment body text

## Step 3: Extract inline comments

1. Use `evaluate_script` to find all inline comment markers:

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

1. For each inline comment marker found, click it to open the comment thread
1. Use `take_snapshot` after each click to read the comment thread content
1. Collect: anchor text, author, date, comment body, any replies

## Step 4: Format and output

Present all comments as a formatted list:

```markdown
## Confluence Comments for [Page Title]

### Page Comments
1. **Author Name** (2026-05-20): Comment text here...
2. **Author Name** (2026-05-21): Another comment...

### Inline Comments
1. **On:** "the highlighted anchor text..."
   - **Author Name** (2026-05-19): Comment about this section...
   - **Reply Author** (2026-05-20): Reply to the comment...

2. **On:** "another highlighted section..."
   - **Author Name** (2026-05-22): Feedback here...
```

If no comments are found (page-level or inline), report:
"No comments found on this Confluence page."

# Push Workflow

## Step 1: Read and convert the document

1. Read the Obsidian note with the Read tool
2. Strip the YAML frontmatter (everything between the opening and closing `---`)
3. Strip Obsidian-specific syntax that Confluence cannot render:
   - Remove `> [!type]` callout markers (keep the content as blockquotes)
   - Remove `%%comments%%` (Obsidian hidden comments)
   - Convert `[[wikilinks]]` to plain text
   - Convert `[[wikilink|display text]]` to the display text only
4. Write the stripped markdown to a temp file
5. Convert to HTML:

   ```bash
   npx marked --gfm < /tmp/confluence-push-content.md
   ```

6. Capture the HTML output for injection

## Step 2: Navigate to the Confluence page

1. Use `navigate_page` to open the `confluence` URL from frontmatter
2. Use `wait_for` with text `["Edit", "edit"]` to confirm the page loaded
3. Use `take_snapshot` to capture the page state

## Step 3: Enter edit mode

1. In the snapshot, find the edit button -- look for a button with aria-label
   containing "Edit" or text "Edit" (typically uid pattern like `uid=1_24`)
2. Use `click` on that uid
3. Use `wait_for` with text `["Publish", "publish", "Update"]` to confirm
   the editor loaded

## Step 4: Clear existing content and inject HTML

1. Use `evaluate_script` to select all content and inject the new HTML:

```javascript
() => {
  const editor = document.querySelector('[contenteditable="true"]');
  if (!editor) throw new Error('Editor not found');
  editor.focus();
  const selection = window.getSelection();
  const range = document.createRange();
  range.selectNodeContents(editor);
  selection.removeAllRanges();
  selection.addRange(range);

  const dt = new DataTransfer();
  dt.setData('text/html', INJECTED_HTML_HERE);
  const pasteEvent = new ClipboardEvent('paste', {
    clipboardData: dt,
    bubbles: true,
    cancelable: true
  });
  editor.dispatchEvent(pasteEvent);
}
```

Replace `INJECTED_HTML_HERE` with the actual HTML string from Step 1,
properly escaped for JavaScript (escape backslashes, quotes, newlines).

1. Use `take_snapshot` to verify content appeared in the editor

## Step 5: Publish

1. Use `take_snapshot` to find the Publish/Update button
2. Use `click` on the publish button uid
3. If a publish dialog appears (Confluence sometimes shows one), use
   `take_snapshot` to find the confirmation button and `click` it
4. Use `wait_for` with text `["Edit", "Edited"]` to confirm the page
   saved and returned to view mode

## Step 6: Confirm

1. Use `take_snapshot` to verify the page is in view mode
2. Report success to the user with the page URL

---

## New Page Variant

When the `confluence` frontmatter field is absent:

1. Ask the user for the parent page URL in Confluence
2. Use `navigate_page` to open the parent page
3. Use `take_snapshot` to find the page controls
4. Look for a "Create" button or use the Confluence create page URL pattern:
   `https://msggroup.atlassian.net/wiki/spaces/MSGDIGITAL/pages/create?parentPageId=PARENT_ID`
   Extract the parent page ID from the URL the user provided
5. Follow Steps 4-5 above to inject content and publish
6. After publish, use `take_snapshot` or read the browser URL to get the
   new page URL
7. Write the new URL back to the Obsidian note's frontmatter using the
   Edit tool -- add `confluence: <new-url>` to the YAML frontmatter
8. Report success with the new page URL

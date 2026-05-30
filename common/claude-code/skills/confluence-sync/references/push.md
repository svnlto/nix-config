# Push Workflow

Incremental update strategy: read the live Confluence page,
compare section-by-section against the Obsidian source, and
only edit sections that changed. This preserves Confluence-native
elements (smart links, @mentions, date objects, macros) in
unchanged sections.

## Step 1: Prepare the Obsidian source

1. Read the Obsidian note with the Read tool
2. Strip the YAML frontmatter (everything between `---` markers)
3. Strip Obsidian-specific syntax:
   - Convert `> [!type] title` callout markers to
     `**type: title**` followed by the content as a blockquote
   - Remove `%%comments%%` (Obsidian hidden comments)
   - Convert `[[wikilinks]]` to plain text
   - Convert `[[wikilink|display text]]` to display text only
4. **Exclude Obsidian-only sections.** Drop any section whose
   body consists entirely of wikilinks or internal references
   (e.g. `## Related` with only `[[link]]` entries). These are
   Obsidian navigation and have no meaning in Confluence.
5. Split the remaining content into sections by H2 headings.
   Each section is a tuple of (heading text, body text). Content
   before the first H2 is the "preamble" section.

## Step 2: Navigate and snapshot the live page

1. Use `navigate_page` to open the `confluence` URL from frontmatter
2. Use `wait_for` with text `["Edit", "edit", "Edited"]` to
   confirm the page loaded
3. Use `take_snapshot` to capture the full page content

## Step 3: Detect page mode

Confluence pages can be either:

- **Live docs** (always editable): the snapshot shows a textbox
  with `"Page editing area"` in its description. No Edit/Publish
  buttons needed.
- **Classic pages** (view/edit toggle): the snapshot shows an
  Edit button. Click it, then `wait_for` with
  `["Publish", "publish", "Update"]`.

Detect which mode by checking the snapshot. Live docs are the
default for newer pages.

## Step 4: Extract live content by section

From the snapshot's textbox value or editor content, extract
the text organised by H2 heading. Build a map of
`heading -> body text` for the live page.

## Step 5: Diff and identify changed sections

Compare each section from the Obsidian source against the
live page section map:

- **Unchanged**: heading exists on both sides and body text
  is semantically equivalent (ignore whitespace, Confluence
  formatting artefacts like tab characters, smart link
  decorations). Skip these entirely.
- **Changed**: heading exists on both sides but body text
  differs. These need updating.
- **New**: heading exists in Obsidian but not on the live page.
  These need inserting.
- **Removed**: heading exists on the live page but not in
  Obsidian. Flag to the user but do NOT delete automatically.

Report the diff summary to the user before making changes:
"Sections to update: [list]. Sections unchanged: [list].
New sections: [list]. Proceed?"

Wait for user confirmation before editing.

## Step 6: Edit changed sections incrementally

For each changed section, use the Chrome DevTools to make
targeted edits in the editor:

### 6a. Locate the section

Use `take_snapshot` and find the H2 heading element matching
the section title. Note its uid.

### 6b. Select the section content

Use `evaluate_script` to select from after the heading to
the next heading (or end of document):

```javascript
(headingText) => {
  const headings = document.querySelectorAll('h2');
  const heading = Array.from(headings).find(h =>
    h.textContent.trim() === headingText
  );
  if (!heading) throw new Error('Heading not found: ' + headingText);

  const range = document.createRange();
  range.setStartAfter(heading);

  // Walk siblings until the next H2 or end of editor
  let node = heading.nextElementSibling;
  let lastNode = heading;
  while (node && !node.matches?.('h2')) {
    lastNode = node;
    node = node.nextElementSibling;
  }
  range.setEndAfter(lastNode);

  const selection = window.getSelection();
  selection.removeAllRanges();
  selection.addRange(range);
  return { selected: true, heading: headingText };
}
```

Pass the heading text as the first argument.

### 6c. Replace with updated content

Convert only the section body (not the heading) from markdown
to HTML:

```bash
echo 'SECTION_BODY_MD' | npx marked --gfm
```

**Table header fix:** After conversion, replace bare `<th>`
content with `<th><strong>...</strong></th>`. Confluence does
not bold `<th>` elements by default -- explicit `<strong>`
tags are required inside table headers.

Then paste over the selection:

```javascript
(html) => {
  const editor = document.querySelector('[contenteditable="true"]');
  if (!editor) throw new Error('Editor not found');
  editor.focus();
  const dt = new DataTransfer();
  dt.setData('text/html', html);
  const pasteEvent = new ClipboardEvent('paste', {
    clipboardData: dt,
    bubbles: true,
    cancelable: true
  });
  editor.dispatchEvent(pasteEvent);
  return 'Section replaced';
}
```

Pass the HTML string as the first argument.

### 6d. Verify

Use `take_snapshot` after each section edit to confirm the
change applied correctly before moving to the next section.

## Step 7: Insert new sections

For new sections (present in Obsidian, absent from Confluence):

1. Use `take_snapshot` to find the insertion point (after the
   last existing section, or at a logical position)
2. Click to place the cursor at the insertion point
3. Convert the new section (including its H2 heading) to HTML
4. Paste using the ClipboardEvent method from Step 6c

## Step 8: Confirm and save

- **Live docs**: changes auto-save. Use `take_snapshot` to
  verify the status shows "Saved" (visible near the page
  header, typically as a link with text "Saved").
- **Classic pages**: click the Publish/Update button. If a
  publish dialog appears, take a snapshot and click confirm.
  Use `wait_for` with `["Edit", "Edited"]` to confirm save.

Report success with the page URL and a summary of which
sections were updated.

## Important constraints

- **Never delete sections** from the live page without
  explicit user confirmation
- **Never replace the full page body** -- always edit
  section by section
- **Preserve headings** -- only replace the body content
  under each heading, not the heading itself (the heading
  may have Confluence-specific formatting or anchors)
- **One section at a time** -- verify each edit before
  proceeding to the next
- **Report, don't guess** -- if a section can't be located
  in the editor, report the issue rather than attempting
  a workaround
- **Skip Obsidian-only sections** -- sections whose body is
  entirely wikilinks (e.g. Related) are vault navigation and
  should never be pushed to Confluence
- **Bold table headers** -- wrap `<th>` content in `<strong>`
  tags. Confluence ignores default `<th>` styling
- **Use native Confluence elements** -- see
  `references/confluence-native-elements.md` for the full
  reference. Key rules:
  - Use `/link` or `Cmd+K` for wiki page references (creates
    smart links, not plain `<a>` tags)
  - Use `@name` for user mentions (creates interactive tokens)
  - Use `//` for dates (creates date objects)
  - Use `/panel` for callouts (replaces legacy `/note` etc.)
  - Use `/status` for coloured status lozenges
  - Never use raw HTML for elements that have native equivalents
- **Convert diagrams to images** -- see
  `references/diagram-conversion.md`. Mermaid, Excalidraw,
  and other non-Confluence diagram formats must be rendered
  to PNG and inserted as images. Confluence cannot render
  these natively

---

## New Page Variant

When the `confluence` frontmatter field is absent:

1. Ask the user for the parent page URL in Confluence
2. Use `navigate_page` to open the parent page
3. Use `take_snapshot` to find the page controls
4. Look for a "Create" button or use the Confluence create
   page URL pattern:
   `https://INSTANCE.atlassian.net/wiki/spaces/SPACE_KEY/pages/create?parentPageId=PARENT_ID`
   Extract the instance, space key, and parent page ID from
   the URL the user provided
5. For new pages, full HTML injection is acceptable since
   there is no existing content to preserve
6. Convert the full document (minus frontmatter, with
   Obsidian syntax stripped) to HTML via `npx marked --gfm`
7. Use the paste method to inject content
8. After save, use `take_snapshot` or read the browser URL
   to get the new page URL
9. Write the new URL back to the Obsidian note's frontmatter
   using the Edit tool
10. Report success with the new page URL

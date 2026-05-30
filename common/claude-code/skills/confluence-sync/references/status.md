# Status Workflow

1. Use `navigate_page` to open the `confluence` URL from frontmatter
2. Use `wait_for` with text `["Edit", "edit"]` to confirm the page loaded
3. Use `take_snapshot` to capture the page
4. Extract metadata from the snapshot:
   - **Page title**: the main heading or document title
   - **Last modified**: look for text like "Edited May 20" or similar
     timestamp near the page header (typically a button element)
   - **Last modified by**: if visible in the page header area
5. Report the status:

```markdown
## Confluence Page Status

- **Page:** [title]
- **URL:** [confluence url]
- **Last edited:** [date]
- **Local file:** [obsidian file path]
```

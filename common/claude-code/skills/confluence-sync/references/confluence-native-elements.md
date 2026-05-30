# Confluence Native Elements

When editing Confluence pages via Chrome DevTools, always use
native Confluence editor commands instead of raw HTML. Native
elements provide interactive behaviour (hover previews, profile
cards, date formatting, link unfurling) that plain HTML cannot
replicate.

## Why This Matters

Confluence's ProseMirror editor stores content as structured
nodes, not raw HTML. A plain `<a>` tag creates a dumb link;
the `/link` command creates a smart link (inline card) with
hover preview, icon, and automatic title updates. The same
applies to mentions, dates, statuses, and panels.

## Element Reference

### Links

| Method | Trigger | Result |
|--------|---------|--------|
| Smart link dialog | `Cmd+K` (Mac) / `Ctrl+K` (Win) | Opens link search dialog with Confluence and Jira tabs |
| Slash command | `/link` | Same dialog via slash menu |
| Paste URL | Paste any URL | Auto-converts to smart link (inline card) |

**Display modes** for smart links (selectable from floating
toolbar after insertion):

- **URL** -- plain web address
- **Inline** -- link title as styled text (default for wiki links)
- **Card** -- content summary with preview
- **Embed** -- interactive preview (iframes where supported)

**When to use:** Any reference to a Confluence page, Jira
ticket, or external URL. Never insert raw `<a href="...">` tags.

**How to use via DevTools:** Click the target cell/paragraph,
type `/link`, wait for typeahead, select "Link", search for the
page in the dialog, select it, then click Insert.

### Mentions (@)

| Method | Trigger | Result |
|--------|---------|--------|
| Autocomplete | `@` + name | User/team mention with notification |

**What it creates:** An interactive mention token with profile
card on hover. The mentioned user receives a notification.

**When to use:** Author fields, assignee references, any place
a person is referenced by name.

**How to use via DevTools:** Click the target location, type
`@` followed by the person's name, wait for the autocomplete
dropdown, then click the correct match.

### Dates (//)

| Method | Trigger | Result |
|--------|---------|--------|
| Autocomplete | `//` | Opens date picker |

**What it creates:** A grey-background date lozenge that
displays in the viewer's locale. Stored as structured data,
not plain text.

**When to use:** Version history dates, deadlines, any
date that should be machine-readable and locale-aware.

**How to use via DevTools:** Click the target location, type
`//`, wait for the date picker to appear, navigate to the
correct date, and click to select.

### Status (/status)

| Method | Trigger | Result |
|--------|---------|--------|
| Slash command | `/status` | Coloured lozenge |

**Available colours:** Grey (default), Red, Yellow, Green, Blue.
Supports outline style (coloured border, no fill).

**What it creates:** A rounded coloured box with customisable
text. Useful for project status, document state, etc.

**When to use:** Status indicators, workflow states, priority
markers.

**How to use via DevTools:** Click the target location, type
`/status`, select from typeahead, then configure colour and
text in the dialog.

### Panels (/panel)

| Method | Trigger | Result |
|--------|---------|--------|
| Slash command | `/panel` | Styled callout panel |

**What it creates:** A panel element with customisable
background colour, icon, and optional title. Replaces the
legacy info/tip/note/warning macros (deprecated Jan 2026).

**Panel presets** (available as emoji + colour combinations):

- Info (blue, info icon)
- Success (green, check icon)
- Note (yellow/purple, note icon)
- Warning (red, warning icon)
- Custom (any colour, any emoji)

**When to use:** Callouts, warnings, tips, important notes.
Map Obsidian callouts (`> [!note]`, `> [!warning]`) to panels.

**How to use via DevTools:** Click the target location, type
`/panel`, select from typeahead, then configure style. Or type
`/info`, `/note`, `/warning`, `/success` for preset variants.

### Other Useful Elements

| Element | Trigger | Use case |
|---------|---------|----------|
| Action item | `/action` | Checklist with assignee via `@` |
| Decision | `/decision` | Project decision record |
| Expand | `/expand` | Collapsible section |
| Divider | `/divider` or `---` | Horizontal rule |
| Code block | `/code` or ```` ``` ```` | Syntax-highlighted code |
| Quote | `/quote` or `>` | Block quote |
| Emoji | `/emoji` or `:` | Emoji picker |
| Table | `/table` | Insert table |
| Cards | `/cards` | Display links as card grid |

## Mapping Obsidian Syntax to Confluence Elements

| Obsidian | Confluence equivalent |
|----------|----------------------|
| `[[Page Name]]` | Smart link via `/link` or `Cmd+K` |
| `> [!note] Title` | `/panel` (note preset) |
| `> [!warning] Title` | `/panel` (warning preset) |
| `> [!info] Title` | `/panel` (info preset) |
| `%%hidden comment%%` | Remove (no equivalent) |
| Person name in text | `@name` mention |
| Plain date text | `//` date picker |
| `- [ ] Task` | `/action` action item |

## Keyboard Shortcuts Reference

Useful shortcuts when interacting with the editor:

| Action | Mac | Windows |
|--------|-----|---------|
| Insert link | `Cmd+K` | `Ctrl+K` |
| Bold | `Cmd+B` | `Ctrl+B` |
| Italic | `Cmd+I` | `Ctrl+I` |
| Undo | `Cmd+Z` | `Ctrl+Z` |
| Find & replace | `Cmd+F` | `Ctrl+F` |
| Insert files/images | `Cmd+M` | `Ctrl+M` |
| Code block | `Cmd+Shift+M` | `Ctrl+Shift+M` |
| Heading 1-6 | `Cmd+Opt+1-6` | `Ctrl+Alt+1-6` |
| Bullet list | `Cmd+Shift+8` | `Ctrl+Shift+8` |
| Numbered list | `Cmd+Shift+7` | `Ctrl+Shift+7` |

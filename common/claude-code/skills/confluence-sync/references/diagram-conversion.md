# Diagram Conversion

Confluence cannot render Mermaid, Excalidraw, or other
Obsidian-native diagram formats. These must be converted
to images before pushing.

## Supported Source Formats

| Format | File pattern | Conversion tool |
|--------|-------------|-----------------|
| Mermaid | ` ```mermaid ` blocks in `.md` | `mmdc` (mermaid-cli) |
| Excalidraw | `.excalidraw` or `.excalidraw.md` | Excalidraw MCP `export_to_excalidraw` |
| Pre-rendered SVG/PNG | `.svg`, `.png` in `diagrams/` | No conversion needed |

## Step 1: Identify diagrams in the document

Scan the Obsidian source for:

- Inline mermaid code blocks: ` ```mermaid ... ``` `
- Excalidraw embeds: `![[Something.excalidraw]]`
- Image embeds: `![[diagrams/something.svg]]` or
  `![[diagrams/something.png]]`

## Step 2: Render to image

### Mermaid

Extract the mermaid block to a temp file, then render:

```bash
cat <<'MERMAID' > /tmp/diagram.mmd
graph LR
  A --> B
MERMAID
npx -y @mermaid-js/mermaid-cli mmdc \
  -i /tmp/diagram.mmd \
  -o /tmp/diagram.png \
  -b transparent \
  -w 1200
```

Prefer PNG over SVG for Confluence compatibility. Use
`-w 1200` for readable resolution.

If the document already has a pre-rendered file in a
`diagrams/` subfolder (e.g. `diagrams/phase-dependencies.svg`),
use that directly instead of re-rendering.

### Excalidraw

Use the Excalidraw MCP tool if available:

```text
mcp__claude_ai_Excalidraw__export_to_excalidraw
```

Or render via the Excalidraw CLI if installed. Output
as PNG.

## Step 3: Upload to Confluence

1. In the editor, place the cursor where the diagram
   should appear
2. Use `Cmd+M` (Mac) or `Ctrl+M` (Win) to open the
   file/image insertion dialog
3. Alternatively, drag and drop is possible via
   DevTools but unreliable -- prefer the keyboard
   shortcut method
4. After upload, use `take_snapshot` to verify the
   image appears correctly

## Step 4: Size and alignment

After insertion, click the image to access the floating
toolbar. Options:

- Width: text-width, wide, or full-width
- Alignment: left, centre, right
- Alt text: add descriptive text for accessibility
- Border: optional border around the image

## Convention

Store rendered diagrams alongside the Obsidian source
in a `diagrams/` subfolder:

```text
sre-strategy/
  sre-implementation.md
  diagrams/
    phase-dependencies.svg
```

The Obsidian note references them via:
`![[diagrams/phase-dependencies.svg|692]]`

When pushing, check whether a rendered version already
exists before re-rendering.

## Important constraints

- **Never paste mermaid source** into Confluence -- it
  renders as plain text
- **Prefer existing renders** -- if a `diagrams/` folder
  has a current SVG/PNG, use it
- **Check render freshness** -- if the mermaid source in
  the document differs from the last render, re-render
- **Alt text** -- always set meaningful alt text after
  uploading

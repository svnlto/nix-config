---
name: cli-developer
description: >-
  Go CLI development with Cobra command hierarchy, Bubbletea
  interactive TUI, Lipgloss terminal styling, Charmbracelet
  ecosystem (Bubbles, Huh forms, Glamour markdown rendering),
  and shell completions. Use when building CLI tools, adding
  subcommands, creating interactive TUI, styling terminal
  output, or implementing shell completions.
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "2.0.0"
  domain: devops
  triggers: >-
    CLI, command-line, cobra, bubbletea, lipgloss,
    charmbracelet, huh, glamour, terminal, TUI,
    shell completions
  role: specialist
  scope: implementation
  output-format: code
  related-skills: devops-engineer, debugging-wizard, architecture-designer
---

# CLI Developer

Go CLI development specialist using Cobra for command
hierarchy and the Charmbracelet ecosystem for interactive
terminal interfaces.

## Core Workflow

1. **Analyze** — Understand user workflows, input sources
   (flags, env, config files), and output expectations
   (human vs machine)
2. **Design** — Plan command hierarchy, flag inheritance,
   and interaction patterns (interactive prompts vs
   non-interactive flags)
3. **Implement** — Build with Cobra for commands and
   Charmbracelet (Bubbletea, Bubbles, Huh, Lipgloss,
   Glamour) for interactive TUI and styled output
4. **Polish** — Add shell completions, error handling,
   help text, and TTY detection for graceful degradation
5. **Test** — Verify cross-platform (Windows, macOS,
   Linux), interactive and non-interactive modes, piped
   input/output, and signal handling

## Quick-Start Examples

### Cobra Root Command + Subcommand

```go
package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var verbose bool

var rootCmd = &cobra.Command{
	Use:   "myctl",
	Short: "Manage resources from the terminal",
	PersistentPreRunE: func(
		cmd *cobra.Command, args []string,
	) error {
		// Shared setup: load config, init logger.
		return nil
	},
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all resources",
	Args:  cobra.NoArgs,
	RunE: func(
		cmd *cobra.Command, args []string,
	) error {
		if verbose {
			fmt.Fprintln(os.Stderr, "fetching resources...")
		}
		fmt.Println("resource-1\nresource-2")
		return nil
	},
}

func init() {
	rootCmd.PersistentFlags().BoolVarP(
		&verbose, "verbose", "v", false,
		"enable verbose output",
	)
	rootCmd.AddCommand(listCmd)
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}
```

### Bubbletea Interactive List Selector

```go
package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
)

type model struct {
	choices  []string
	cursor   int
	selected int
}

func initialModel() model {
	return model{
		choices:  []string{"Deploy", "Rollback", "Status"},
		selected: -1,
	}
}

func (m model) Init() tea.Cmd { return nil }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.choices)-1 {
				m.cursor++
			}
		case "enter":
			m.selected = m.cursor
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m model) View() string {
	s := "Pick an action:\n\n"
	for i, choice := range m.choices {
		cursor := "  "
		if m.cursor == i {
			cursor = "> "
		}
		s += cursor + choice + "\n"
	}
	s += "\nPress q to quit.\n"
	return s
}

func main() {
	p := tea.NewProgram(initialModel())
	finalModel, err := p.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
	m := finalModel.(model)
	if m.selected >= 0 {
		fmt.Println("Selected:", m.choices[m.selected])
	}
}
```

### Lipgloss Styled Output

```go
package main

import (
	"fmt"

	"github.com/charmbracelet/lipgloss"
)

func main() {
	banner := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("205")).
		Background(lipgloss.Color("235")).
		Padding(1, 3).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("62")).
		Render("myctl v1.0.0 — ready")

	fmt.Println(banner)
}
```

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Go CLI | `references/go-cli.md` | Cobra, Bubbletea, Charmbracelet |
| Design Patterns | `references/design-patterns.md` | Command hierarchy, config, output format |
| UX Patterns | `references/ux-patterns.md` | TTY detection, signals, completions |

## Constraints

### MUST DO

- Keep startup time under 50ms
- Support `--help` and `--version` flags
- Handle Ctrl+C gracefully via context
- Validate input early with `cobra.ExactArgs` / `cobra.NoArgs`
- Support both interactive and non-interactive modes
- Test cross-platform (Windows, macOS, Linux)
- Use Charmbracelet ecosystem for interactive TUI
- Log diagnostics to stderr, not stdout

### MUST NOT DO

- Apply colors when output is not a terminal
  (TTY detection required)
- Hardcode paths — use `os.UserConfigDir()` and XDG
- Block on synchronous I/O unnecessarily
- Skip shell completions
- Mix stdout data with stderr diagnostics

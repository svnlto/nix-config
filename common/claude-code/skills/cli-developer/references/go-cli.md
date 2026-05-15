# Go CLI Reference

Comprehensive patterns for building Go CLIs with Cobra
and the Charmbracelet ecosystem.

## 1. Cobra Command Structure

### Root Command with Config Loading

```go
package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var cfgFile string

var rootCmd = &cobra.Command{
	Use:   "myctl",
	Short: "Manage resources from the terminal",
	Long: `myctl is a CLI for managing cloud resources.

It supports interactive and non-interactive workflows,
shell completions, and machine-readable output.`,
	SilenceUsage:  true,
	SilenceErrors: true,
	PersistentPreRunE: func(
		cmd *cobra.Command, args []string,
	) error {
		return initConfig()
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().StringVar(
		&cfgFile, "config", "",
		"config file (default $XDG_CONFIG_HOME/myctl/config.yaml)",
	)
	rootCmd.PersistentFlags().BoolP(
		"verbose", "v", false,
		"enable verbose output on stderr",
	)
	rootCmd.PersistentFlags().StringP(
		"output", "o", "text",
		"output format: text, json, yaml",
	)
}

func initConfig() error {
	if cfgFile != "" {
		viper.SetConfigFile(cfgFile)
	} else {
		configDir, err := os.UserConfigDir()
		if err != nil {
			return fmt.Errorf("config dir: %w", err)
		}
		viper.AddConfigPath(
			filepath.Join(configDir, "myctl"),
		)
		viper.SetConfigName("config")
		viper.SetConfigType("yaml")
	}

	viper.SetEnvPrefix("MYCTL")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return fmt.Errorf("config: %w", err)
		}
	}
	return nil
}
```

### Subcommand with Argument Validation

```go
package cmd

import (
	"context"
	"fmt"
	"os/signal"
	"syscall"

	"github.com/spf13/cobra"
)

var deleteCmd = &cobra.Command{
	Use:   "delete <resource-id>",
	Short: "Delete a resource by ID",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := signal.NotifyContext(
			cmd.Context(),
			syscall.SIGINT, syscall.SIGTERM,
		)
		defer cancel()

		force, _ := cmd.Flags().GetBool("force")
		return deleteResource(ctx, args[0], force)
	},
}

func init() {
	deleteCmd.Flags().BoolP(
		"force", "f", false,
		"skip confirmation prompt",
	)
	rootCmd.AddCommand(deleteCmd)
}

func deleteResource(
	ctx context.Context, id string, force bool,
) error {
	if !force {
		fmt.Printf("Delete %s? [y/N]: ", id)
		// Use Huh for interactive confirmation.
	}
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return nil // Proceed with deletion.
	}
}
```

### Command Groups

```go
func init() {
	rootCmd.AddGroup(
		&cobra.Group{ID: "core", Title: "Core Commands:"},
		&cobra.Group{ID: "admin", Title: "Admin Commands:"},
	)

	listCmd.GroupID = "core"
	getCmd.GroupID = "core"
	deleteCmd.GroupID = "admin"
	configCmd.GroupID = "admin"

	rootCmd.AddCommand(listCmd, getCmd, deleteCmd, configCmd)
}
```

## 2. Bubbletea Patterns

### Model with Loading State

```go
package tui

import (
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type state int

const (
	stateLoading state = iota
	stateReady
	stateError
)

type model struct {
	state   state
	spinner spinner.Model
	items   []string
	err     error
}

type itemsLoadedMsg struct{ items []string }
type errMsg struct{ err error }

func newModel() model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().
		Foreground(lipgloss.Color("205"))
	return model{state: stateLoading, spinner: s}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(m.spinner.Tick, loadItems)
}

func loadItems() tea.Msg {
	// Replace with actual data fetching.
	items := []string{"item-1", "item-2", "item-3"}
	return itemsLoadedMsg{items: items}
}

func (m model) Update(
	msg tea.Msg,
) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if msg.String() == "ctrl+c" || msg.String() == "q" {
			return m, tea.Quit
		}
	case itemsLoadedMsg:
		m.state = stateReady
		m.items = msg.items
		return m, nil
	case errMsg:
		m.state = stateError
		m.err = msg.err
		return m, nil
	}

	if m.state == stateLoading {
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m model) View() string {
	switch m.state {
	case stateLoading:
		return m.spinner.View() + " Loading..."
	case stateError:
		return "Error: " + m.err.Error()
	default:
		s := "Items:\n"
		for _, item := range m.items {
			s += "  - " + item + "\n"
		}
		return s
	}
}
```

### Table Display with Bubbles

```go
package tui

import (
	"github.com/charmbracelet/bubbles/table"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

func newTable(rows []table.Row) table.Model {
	columns := []table.Column{
		{Title: "Name", Width: 20},
		{Title: "Status", Width: 12},
		{Title: "Age", Width: 10},
	}

	t := table.New(
		table.WithColumns(columns),
		table.WithRows(rows),
		table.WithFocused(true),
		table.WithHeight(10),
	)

	s := table.DefaultStyles()
	s.Header = s.Header.
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(lipgloss.Color("240")).
		BorderBottom(true).
		Bold(true)
	s.Selected = s.Selected.
		Foreground(lipgloss.Color("229")).
		Background(lipgloss.Color("57")).
		Bold(false)
	t.SetStyles(s)

	return t
}

type tableModel struct {
	table table.Model
}

func (m tableModel) Init() tea.Cmd { return nil }

func (m tableModel) Update(
	msg tea.Msg,
) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "enter":
			row := m.table.SelectedRow()
			_ = row // Handle selection.
			return m, tea.Quit
		}
	}
	m.table, cmd = m.table.Update(msg)
	return m, cmd
}

func (m tableModel) View() string {
	return m.table.View() + "\n"
}
```

### Text Input with Bubbles

```go
package tui

import (
	"fmt"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
)

type inputModel struct {
	input textinput.Model
	done  bool
}

func newInputModel(placeholder string) inputModel {
	ti := textinput.New()
	ti.Placeholder = placeholder
	ti.Focus()
	ti.CharLimit = 256
	ti.Width = 40
	return inputModel{input: ti}
}

func (m inputModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m inputModel) Update(
	msg tea.Msg,
) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			return m, tea.Quit
		case "enter":
			m.done = true
			return m, tea.Quit
		}
	}
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m inputModel) View() string {
	if m.done {
		return fmt.Sprintf("Input: %s\n", m.input.Value())
	}
	return fmt.Sprintf("Enter value:\n\n%s\n", m.input.View())
}
```

## 3. Huh Forms

### Multi-Field Form

```go
package tui

import (
	"fmt"

	"github.com/charmbracelet/huh"
)

type DeployConfig struct {
	Environment string
	Replicas    int
	DryRun      bool
	Confirm     bool
}

func RunDeployForm() (*DeployConfig, error) {
	cfg := &DeployConfig{}

	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[string]().
				Title("Environment").
				Options(
					huh.NewOption("Development", "dev"),
					huh.NewOption("Staging", "staging"),
					huh.NewOption("Production", "prod"),
				).
				Value(&cfg.Environment),

			huh.NewInput().
				Title("Replicas").
				Placeholder("3").
				Validate(func(s string) error {
					if s == "" {
						return fmt.Errorf("required")
					}
					return nil
				}),

			huh.NewConfirm().
				Title("Dry run?").
				Value(&cfg.DryRun),
		),
		huh.NewGroup(
			huh.NewConfirm().
				Title("Deploy now?").
				Affirmative("Yes").
				Negative("No").
				Value(&cfg.Confirm),
		),
	)

	err := form.Run()
	if err != nil {
		return nil, err
	}
	return cfg, nil
}
```

### Inline Confirmation

```go
package tui

import "github.com/charmbracelet/huh"

func Confirm(prompt string) (bool, error) {
	var confirmed bool
	err := huh.NewConfirm().
		Title(prompt).
		Affirmative("Yes").
		Negative("No").
		Value(&confirmed).
		Run()
	return confirmed, err
}
```

## 4. Lipgloss Styling

### Theme Constants

```go
package ui

import "github.com/charmbracelet/lipgloss"

var (
	Primary   = lipgloss.Color("205")
	Secondary = lipgloss.Color("62")
	Muted     = lipgloss.Color("240")
	Success   = lipgloss.Color("78")
	Warning   = lipgloss.Color("214")
	Error     = lipgloss.Color("196")

	TitleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(Primary)

	SubtitleStyle = lipgloss.NewStyle().
			Foreground(Muted)

	ErrorStyle = lipgloss.NewStyle().
			Foreground(Error).
			Bold(true)

	SuccessStyle = lipgloss.NewStyle().
			Foreground(Success)

	BoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(Secondary).
			Padding(1, 2)
)
```

### Conditional Styling (TTY-aware)

```go
package ui

import (
	"os"

	"github.com/charmbracelet/lipgloss"
	"golang.org/x/term"
)

func IsTerminal() bool {
	return term.IsTerminal(int(os.Stdout.Fd()))
}

func Render(style lipgloss.Style, s string) string {
	if !IsTerminal() {
		return s
	}
	return style.Render(s)
}
```

## 5. Glamour Markdown Rendering

### Render Help as Markdown

```go
package ui

import (
	"os"

	"github.com/charmbracelet/glamour"
	"golang.org/x/term"
)

func RenderMarkdown(md string) (string, error) {
	width := 80
	if term.IsTerminal(int(os.Stdout.Fd())) {
		if w, _, err := term.GetSize(
			int(os.Stdout.Fd()),
		); err == nil && w > 0 {
			width = w
		}
	}

	r, err := glamour.NewTermRenderer(
		glamour.WithAutoStyle(),
		glamour.WithWordWrap(width),
	)
	if err != nil {
		return "", err
	}
	return r.Render(md)
}
```

## 6. Version and Build Info

### Embed at Build Time

```go
package version

import (
	"fmt"
	"runtime"
)

var (
	Version = "dev"
	Commit  = "unknown"
	Date    = "unknown"
)

func Full() string {
	return fmt.Sprintf(
		"%s (commit: %s, built: %s, %s/%s)",
		Version, Commit, Date,
		runtime.GOOS, runtime.GOARCH,
	)
}
```

```makefile
VERSION ?= $(shell git describe --tags --always)
COMMIT  ?= $(shell git rev-parse --short HEAD)
DATE    ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS := -s -w \
  -X myctl/version.Version=$(VERSION) \
  -X myctl/version.Commit=$(COMMIT) \
  -X myctl/version.Date=$(DATE)

build:
	go build -ldflags "$(LDFLAGS)" -o bin/myctl .
```

### Version Command

```go
package cmd

import (
	"fmt"

	"myctl/version"

	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print version information",
	Args:  cobra.NoArgs,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(version.Full())
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
```

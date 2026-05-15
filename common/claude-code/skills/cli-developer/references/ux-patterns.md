# CLI UX Patterns

Terminal detection, signal handling, shell completions,
and progressive enhancement for Go CLIs.

## 1. TTY Detection

### Detect Interactive Terminal

```go
package ui

import (
	"os"

	"golang.org/x/term"
)

func StdoutIsTerminal() bool {
	return term.IsTerminal(int(os.Stdout.Fd()))
}

func StdinIsTerminal() bool {
	return term.IsTerminal(int(os.Stdin.Fd()))
}

func StderrIsTerminal() bool {
	return term.IsTerminal(int(os.Stderr.Fd()))
}
```

### Progressive Enhancement

Degrade gracefully when output is piped or redirected.

```go
package ui

import (
	"fmt"
	"os"

	"github.com/charmbracelet/lipgloss"
)

func PrintStyled(style lipgloss.Style, s string) {
	if StdoutIsTerminal() {
		fmt.Println(style.Render(s))
	} else {
		fmt.Println(s)
	}
}

func PrintError(msg string) {
	if StderrIsTerminal() {
		fmt.Fprintln(
			os.Stderr,
			lipgloss.NewStyle().
				Foreground(lipgloss.Color("196")).
				Bold(true).
				Render("error: "+msg),
		)
	} else {
		fmt.Fprintf(os.Stderr, "error: %s\n", msg)
	}
}
```

### Interactive vs Non-Interactive Mode

```go
package cmd

import (
	"fmt"
	"os"

	"github.com/charmbracelet/huh"
	"github.com/spf13/cobra"
	"myctl/ui"
)

var createCmd = &cobra.Command{
	Use:   "create [name]",
	Short: "Create a resource",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(
		cmd *cobra.Command, args []string,
	) error {
		name := ""
		if len(args) > 0 {
			name = args[0]
		}

		// Interactive mode: prompt if TTY and no args.
		if name == "" && ui.StdinIsTerminal() {
			err := huh.NewInput().
				Title("Resource name").
				Value(&name).
				Run()
			if err != nil {
				return err
			}
		}

		if name == "" {
			return fmt.Errorf(
				"name required (pass as argument " +
					"or run interactively)",
			)
		}

		fmt.Fprintf(os.Stderr, "Creating %s...\n", name)
		return nil
	},
}
```

## 2. Signal Handling

### Graceful Shutdown with Context

```go
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	ctx, cancel := signal.NotifyContext(
		context.Background(),
		syscall.SIGINT,
		syscall.SIGTERM,
	)
	defer cancel()

	if err := run(ctx); err != nil {
		if ctx.Err() != nil {
			fmt.Fprintln(os.Stderr, "interrupted")
			os.Exit(130) // 128 + SIGINT(2)
		}
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	// Long-running work respects ctx cancellation.
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return nil
	}
}
```

### Bubbletea Signal Handling

Bubbletea handles Ctrl+C internally. For additional
signals, wrap the program:

```go
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	tea "github.com/charmbracelet/bubbletea"
)

func runTUI(ctx context.Context) error {
	ctx, cancel := signal.NotifyContext(
		ctx, syscall.SIGINT, syscall.SIGTERM,
	)
	defer cancel()

	p := tea.NewProgram(
		newModel(),
		tea.WithContext(ctx),
		tea.WithAltScreen(),
	)

	_, err := p.Run()
	if err != nil && ctx.Err() != nil {
		fmt.Fprintln(os.Stderr, "interrupted")
		return nil
	}
	return err
}
```

## 3. Shell Completions

### Built-in Cobra Completions

```go
package cmd

import "github.com/spf13/cobra"

func init() {
	// Cobra generates completion commands automatically.
	// Users run:
	//   myctl completion bash > /etc/bash_completion.d/myctl
	//   myctl completion zsh > "${fpath[1]}/_myctl"
	//   myctl completion fish > ~/.config/fish/completions/myctl.fish
	//   myctl completion powershell > myctl.ps1
}
```

### Dynamic Completions

```go
package cmd

import "github.com/spf13/cobra"

var getCmd = &cobra.Command{
	Use:   "get <resource>",
	Short: "Get a resource by name",
	Args:  cobra.ExactArgs(1),
	ValidArgsFunction: func(
		cmd *cobra.Command,
		args []string,
		toComplete string,
	) ([]string, cobra.ShellCompDirective) {
		if len(args) != 0 {
			return nil,
				cobra.ShellCompDirectiveNoFileComp
		}
		// Fetch completions dynamically.
		names, err := fetchResourceNames(
			cmd.Context(),
		)
		if err != nil {
			return nil,
				cobra.ShellCompDirectiveError
		}
		return names,
			cobra.ShellCompDirectiveNoFileComp
	},
	RunE: runGet,
}
```

### Flag Value Completions

```go
package cmd

import "github.com/spf13/cobra"

func init() {
	createCmd.Flags().StringP(
		"env", "e", "",
		"target environment",
	)
	_ = createCmd.RegisterFlagCompletionFunc(
		"env",
		func(
			cmd *cobra.Command,
			args []string,
			toComplete string,
		) ([]string, cobra.ShellCompDirective) {
			return []string{
					"dev\tDevelopment",
					"staging\tStaging",
					"prod\tProduction",
				},
				cobra.ShellCompDirectiveNoFileComp
		},
	)
}
```

## 4. Progress Indicators

### Spinner for Short Operations

```go
package ui

import (
	"fmt"
	"os"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type spinnerModel struct {
	spinner spinner.Model
	title   string
	done    bool
	err     error
	work    func() error
}

type workDoneMsg struct{ err error }

func RunWithSpinner(
	title string, work func() error,
) error {
	if !StderrIsTerminal() {
		fmt.Fprintf(os.Stderr, "%s...\n", title)
		return work()
	}

	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().
		Foreground(lipgloss.Color("205"))

	m := spinnerModel{
		spinner: s,
		title:   title,
		work:    work,
	}

	p := tea.NewProgram(m, tea.WithOutput(os.Stderr))
	result, err := p.Run()
	if err != nil {
		return err
	}
	if final, ok := result.(spinnerModel); ok {
		return final.err
	}
	return nil
}

func (m spinnerModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		func() tea.Msg {
			return workDoneMsg{err: m.work()}
		},
	)
}

func (m spinnerModel) Update(
	msg tea.Msg,
) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case workDoneMsg:
		m.done = true
		m.err = msg.err
		return m, tea.Quit
	case tea.KeyMsg:
		if msg.String() == "ctrl+c" {
			return m, tea.Quit
		}
	}
	var cmd tea.Cmd
	m.spinner, cmd = m.spinner.Update(msg)
	return m, cmd
}

func (m spinnerModel) View() string {
	if m.done {
		return ""
	}
	return m.spinner.View() + " " + m.title + "...\n"
}
```

### Progress Bar for Long Operations

```go
package ui

import (
	"fmt"
	"os"

	"github.com/charmbracelet/bubbles/progress"
	tea "github.com/charmbracelet/bubbletea"
)

type progressModel struct {
	progress progress.Model
	percent  float64
	title    string
}

type progressMsg float64
type progressDoneMsg struct{}

func newProgressModel(title string) progressModel {
	p := progress.New(
		progress.WithDefaultGradient(),
		progress.WithWidth(40),
	)
	return progressModel{
		progress: p,
		title:    title,
	}
}

func (m progressModel) Init() tea.Cmd { return nil }

func (m progressModel) Update(
	msg tea.Msg,
) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case progressMsg:
		m.percent = float64(msg)
		if m.percent >= 1.0 {
			return m, tea.Quit
		}
		return m, nil
	case tea.KeyMsg:
		if msg.String() == "ctrl+c" {
			return m, tea.Quit
		}
	case tea.WindowSizeMsg:
		m.progress.Width = msg.Width - 10
		if m.progress.Width > 60 {
			m.progress.Width = 60
		}
		return m, nil
	}
	return m, nil
}

func (m progressModel) View() string {
	return fmt.Sprintf(
		"\n  %s\n\n  %s\n",
		m.title,
		m.progress.ViewAs(m.percent),
	)
}
```

## 5. Piped Input

### Read from Stdin or File

```go
package input

import (
	"bufio"
	"fmt"
	"io"
	"os"

	"golang.org/x/term"
)

func ReadInput(filename string) ([]byte, error) {
	if filename != "" && filename != "-" {
		return os.ReadFile(filename)
	}

	// Check if stdin has data (piped).
	if !term.IsTerminal(int(os.Stdin.Fd())) {
		return io.ReadAll(os.Stdin)
	}

	return nil, fmt.Errorf(
		"no input: pipe data or pass --file",
	)
}

func ReadLines(r io.Reader) ([]string, error) {
	var lines []string
	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines, scanner.Err()
}
```

### Streaming Output

```go
package output

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
)

func StreamJSON(items <-chan any, w io.Writer) error {
	bw := bufio.NewWriter(w)
	defer bw.Flush()

	enc := json.NewEncoder(bw)
	for item := range items {
		if err := enc.Encode(item); err != nil {
			return err
		}
	}
	return nil
}

func StreamLines(lines <-chan string) {
	bw := bufio.NewWriter(os.Stdout)
	defer bw.Flush()

	for line := range lines {
		fmt.Fprintln(bw, line)
	}
}
```

## 6. Environment Variables

### NO_COLOR and TERM

Respect the `NO_COLOR` convention
(<https://no-color.org/>):

```go
package ui

import "os"

func ColorsEnabled() bool {
	if _, ok := os.LookupEnv("NO_COLOR"); ok {
		return false
	}
	if os.Getenv("TERM") == "dumb" {
		return false
	}
	return StdoutIsTerminal()
}
```

### Force Color (CI Environments)

```go
package ui

import "os"

func ColorsForced() bool {
	v := os.Getenv("CLICOLOR_FORCE")
	return v != "" && v != "0"
}

func ShouldColor() bool {
	if ColorsForced() {
		return true
	}
	return ColorsEnabled()
}
```

## 7. Help Text

### Custom Help Template

```go
package cmd

import "github.com/spf13/cobra"

func init() {
	rootCmd.SetUsageTemplate(`Usage:
  {{.CommandPath}} [command] [flags]

{{if .HasAvailableSubCommands}}Commands:
{{range .Commands}}{{if .IsAvailableCommand}}  {{rpad .Name .NamePadding}} {{.Short}}
{{end}}{{end}}{{end}}
{{if .HasAvailableLocalFlags}}Flags:
{{.LocalFlags.FlagUsages | trimTrailingWhitespaces}}
{{end}}
{{if .HasAvailableInheritedFlags}}Global Flags:
{{.InheritedFlags.FlagUsages | trimTrailingWhitespaces}}
{{end}}
Use "{{.CommandPath}} [command] --help" for more info.
`)
}
```

### Example Annotations

```go
var deployCmd = &cobra.Command{
	Use:   "deploy <env>",
	Short: "Deploy to an environment",
	Example: `  # Deploy to staging
  myctl deploy staging

  # Deploy with dry run
  myctl deploy production --dry-run

  # Deploy specific version
  myctl deploy staging --version v1.2.3`,
	Args: cobra.ExactArgs(1),
	RunE: runDeploy,
}
```

## 8. Testing

### Test Commands without Running main()

```go
package cmd_test

import (
	"bytes"
	"testing"

	"myctl/cmd"
)

func TestListCommand(t *testing.T) {
	stdout := &bytes.Buffer{}
	stderr := &bytes.Buffer{}

	root := cmd.NewRootCmd()
	root.SetOut(stdout)
	root.SetErr(stderr)
	root.SetArgs([]string{"list", "--output", "json"})

	err := root.Execute()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if stdout.Len() == 0 {
		t.Error("expected output, got empty")
	}
}
```

### Test Interactive TUI

```go
package tui_test

import (
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"myctl/internal/tui"
)

func TestModelInit(t *testing.T) {
	m := tui.NewModel()
	cmd := m.Init()
	if cmd == nil {
		t.Error("expected init command")
	}
}

func TestModelUpdate(t *testing.T) {
	m := tui.NewModel()

	// Simulate key press.
	updated, cmd := m.Update(tea.KeyMsg{
		Type: tea.KeyDown,
	})

	model := updated.(tui.Model)
	if model.Cursor() != 1 {
		t.Errorf(
			"expected cursor at 1, got %d",
			model.Cursor(),
		)
	}
	_ = cmd
}
```

### Golden File Tests for Output

```go
package output_test

import (
	"os"
	"path/filepath"
	"testing"

	"myctl/output"
)

func TestPrintJSON(t *testing.T) {
	p := output.NewPrinter("json")
	buf := &bytes.Buffer{}
	p.SetWriter(buf)

	items := []output.Item{
		{Name: "foo", Status: "Running", Age: "2d"},
	}
	if err := p.Print(items); err != nil {
		t.Fatal(err)
	}

	golden := filepath.Join("testdata", "list.json")
	if os.Getenv("UPDATE_GOLDEN") != "" {
		os.WriteFile(golden, buf.Bytes(), 0644)
		return
	}

	expected, err := os.ReadFile(golden)
	if err != nil {
		t.Fatal(err)
	}
	if buf.String() != string(expected) {
		t.Errorf(
			"output mismatch:\ngot:\n%s\nwant:\n%s",
			buf.String(), expected,
		)
	}
}
```

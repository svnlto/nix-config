# CLI Design Patterns

Patterns for command hierarchy, configuration management,
and output formatting in Go CLIs.

## 1. Command Hierarchy

### Noun-Verb Pattern

Organize commands as `<noun> <verb>` for resource-centric
CLIs. This maps naturally to CRUD operations.

```text
myctl cluster create
myctl cluster list
myctl cluster delete <name>
myctl node drain <name>
myctl config set <key> <value>
myctl config get <key>
```

```go
package cmd

import "github.com/spf13/cobra"

var clusterCmd = &cobra.Command{
	Use:   "cluster",
	Short: "Manage clusters",
}

var clusterCreateCmd = &cobra.Command{
	Use:   "create <name>",
	Short: "Create a new cluster",
	Args:  cobra.ExactArgs(1),
	RunE:  runClusterCreate,
}

var clusterListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all clusters",
	Args:  cobra.NoArgs,
	RunE:  runClusterList,
}

var clusterDeleteCmd = &cobra.Command{
	Use:   "delete <name>",
	Short: "Delete a cluster",
	Args:  cobra.ExactArgs(1),
	RunE:  runClusterDelete,
}

func init() {
	clusterCmd.AddCommand(
		clusterCreateCmd,
		clusterListCmd,
		clusterDeleteCmd,
	)
	rootCmd.AddCommand(clusterCmd)
}
```

### Verb-First Pattern

For action-oriented CLIs where the action matters more
than the resource.

```text
myctl deploy --env staging
myctl rollback --revision 3
myctl validate config.yaml
```

### Flag Inheritance

Use `PersistentFlags` on parent commands. Child commands
inherit them automatically.

```go
func init() {
	// Available to all subcommands.
	rootCmd.PersistentFlags().StringP(
		"output", "o", "text",
		"output format: text, json, yaml",
	)
	rootCmd.PersistentFlags().BoolP(
		"verbose", "v", false,
		"enable verbose logging to stderr",
	)

	// Only on this specific command.
	createCmd.Flags().IntP(
		"replicas", "r", 3,
		"number of replicas",
	)
}
```

## 2. Configuration Management

### Precedence (highest to lowest)

1. Flags (explicit user intent)
2. Environment variables
3. Config file
4. Defaults

### Viper Integration

```go
package cmd

import (
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func initConfig() error {
	if cfgFile != "" {
		viper.SetConfigFile(cfgFile)
	} else {
		configDir, err := os.UserConfigDir()
		if err != nil {
			return err
		}
		dir := filepath.Join(configDir, "myctl")
		viper.AddConfigPath(dir)
		viper.SetConfigName("config")
		viper.SetConfigType("yaml")
	}

	// MYCTL_API_URL -> api-url
	viper.SetEnvPrefix("MYCTL")
	viper.AutomaticEnv()

	// Bind specific flags to viper keys.
	_ = viper.BindPFlag(
		"output",
		rootCmd.PersistentFlags().Lookup("output"),
	)

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return err
		}
	}
	return nil
}
```

### Config File Structure

```yaml
# $XDG_CONFIG_HOME/myctl/config.yaml
api-url: https://api.example.com
output: json
verbose: false

contexts:
  production:
    api-url: https://prod.example.com
    token: op://Vault/myctl-prod/token
  staging:
    api-url: https://staging.example.com

current-context: production
```

### Config Command

```go
package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var configSetCmd = &cobra.Command{
	Use:   "set <key> <value>",
	Short: "Set a configuration value",
	Args:  cobra.ExactArgs(2),
	RunE: func(
		cmd *cobra.Command, args []string,
	) error {
		viper.Set(args[0], args[1])
		return viper.WriteConfig()
	},
}

var configGetCmd = &cobra.Command{
	Use:   "get <key>",
	Short: "Get a configuration value",
	Args:  cobra.ExactArgs(1),
	RunE: func(
		cmd *cobra.Command, args []string,
	) error {
		val := viper.Get(args[0])
		if val == nil {
			return fmt.Errorf("key not found: %s", args[0])
		}
		fmt.Println(val)
		return nil
	},
}
```

## 3. Output Formatting

### Multi-Format Output

```go
package output

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"text/tabwriter"

	"gopkg.in/yaml.v3"
)

type Format string

const (
	Text Format = "text"
	JSON Format = "json"
	YAML Format = "yaml"
)

type Printer struct {
	format Format
	writer io.Writer
}

func NewPrinter(format string) *Printer {
	return &Printer{
		format: Format(format),
		writer: os.Stdout,
	}
}

func (p *Printer) Print(data any) error {
	switch p.format {
	case JSON:
		enc := json.NewEncoder(p.writer)
		enc.SetIndent("", "  ")
		return enc.Encode(data)
	case YAML:
		enc := yaml.NewEncoder(p.writer)
		return enc.Encode(data)
	default:
		return p.printText(data)
	}
}

func (p *Printer) printText(data any) error {
	items, ok := data.([]Item)
	if !ok {
		_, err := fmt.Fprintln(p.writer, data)
		return err
	}
	w := tabwriter.NewWriter(
		p.writer, 0, 0, 2, ' ', 0,
	)
	fmt.Fprintln(w, "NAME\tSTATUS\tAGE")
	for _, item := range items {
		fmt.Fprintf(
			w, "%s\t%s\t%s\n",
			item.Name, item.Status, item.Age,
		)
	}
	return w.Flush()
}

type Item struct {
	Name   string `json:"name"   yaml:"name"`
	Status string `json:"status" yaml:"status"`
	Age    string `json:"age"    yaml:"age"`
}
```

### Usage in Commands

```go
var listCmd = &cobra.Command{
	Use:  "list",
	RunE: func(cmd *cobra.Command, args []string) error {
		format, _ := cmd.Flags().GetString("output")
		printer := output.NewPrinter(format)

		items, err := fetchItems(cmd.Context())
		if err != nil {
			return err
		}
		return printer.Print(items)
	},
}
```

## 4. Error Handling

### Typed Errors

```go
package cli

import "fmt"

type ExitError struct {
	Code    int
	Message string
	Err     error
}

func (e *ExitError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Err)
	}
	return e.Message
}

func (e *ExitError) Unwrap() error { return e.Err }

// Common exit codes (BSD sysexits.h).
const (
	ExitOK         = 0
	ExitError_     = 1
	ExitUsage      = 64
	ExitNoInput    = 66
	ExitUnavail    = 69
	ExitTempFail   = 75
	ExitNoPerm     = 77
	ExitConfig     = 78
)

func NewUsageError(msg string) *ExitError {
	return &ExitError{Code: ExitUsage, Message: msg}
}

func NewConfigError(msg string, err error) *ExitError {
	return &ExitError{
		Code: ExitConfig, Message: msg, Err: err,
	}
}
```

### Error Handling in main()

```go
package main

import (
	"errors"
	"fmt"
	"os"

	"myctl/cli"
	"myctl/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		var exitErr *cli.ExitError
		if errors.As(err, &exitErr) {
			fmt.Fprintf(os.Stderr, "error: %s\n", exitErr)
			os.Exit(exitErr.Code)
		}
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
```

## 5. Middleware Pattern

### Pre/Post Run Hooks

```go
package cmd

import "github.com/spf13/cobra"

func withAuth(
	fn func(*cobra.Command, []string) error,
) func(*cobra.Command, []string) error {
	return func(cmd *cobra.Command, args []string) error {
		if err := ensureAuthenticated(cmd.Context()); err != nil {
			return err
		}
		return fn(cmd, args)
	}
}

var deployCmd = &cobra.Command{
	Use:  "deploy",
	RunE: withAuth(runDeploy),
}
```

### Shared Dependencies

```go
package cmd

import (
	"context"
	"log/slog"

	"myctl/client"
)

type appContext struct {
	client *client.Client
	logger *slog.Logger
}

type ctxKey string

const appCtxKey ctxKey = "app"

func newAppContext(
	ctx context.Context,
) (context.Context, error) {
	c, err := client.New(client.Config{
		BaseURL: viper.GetString("api-url"),
	})
	if err != nil {
		return ctx, err
	}
	app := &appContext{
		client: c,
		logger: slog.Default(),
	}
	return context.WithValue(ctx, appCtxKey, app), nil
}

func getApp(ctx context.Context) *appContext {
	return ctx.Value(appCtxKey).(*appContext)
}
```

## 6. Project Layout

```text
myctl/
  cmd/
    root.go           # Root command, config init
    version.go        # Version command
    cluster.go        # cluster parent command
    cluster_create.go # cluster create subcommand
    cluster_list.go   # cluster list subcommand
  internal/
    client/           # API client
    tui/              # Bubbletea models
    ui/               # Lipgloss styles, output helpers
  output/
    printer.go        # Multi-format output
  cli/
    errors.go         # Typed exit errors
  version/
    version.go        # Build-time version info
  main.go             # Entry point
  go.mod
  go.sum
```

Naming rules:

- One file per command (or per noun group)
- `internal/` for non-exported packages
- `cmd/` for Cobra command definitions only
  (business logic lives elsewhere)
- `output/` for formatting concerns

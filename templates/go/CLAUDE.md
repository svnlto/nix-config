# Go Project

## Commands

```bash
nix develop              # enter dev shell with go, gopls, golangci-lint, delve
go run .                 # run the application
go test ./...            # run all tests
go test -race ./...      # run tests with race detector
golangci-lint run        # comprehensive linting
dlv debug .              # start debugger
go mod tidy              # clean up dependencies
pre-commit run --all-files  # run all pre-commit hooks
```

## Conventions

- Follow standard Go project layout
- Use `gofmt`/`goimports` for formatting (automated via hooks)
- Write table-driven tests with `t.Run` subtests
- Use `context.Context` for cancellation and timeouts
- Error handling: wrap errors with `fmt.Errorf("...: %w", err)`
- Prefer interfaces at the consumer, not the producer
- Keep packages small and focused; avoid package-level state

## Testing

- `_test.go` files alongside source
- Use `testing.T` helpers, not assertion libraries
- Mock external dependencies with interfaces
- Run `go test -race ./...` before committing

## Relevant Skills

This project benefits from globally installed Claude Code skills:
- **rest-api-design** — API design patterns, HTTP handler structure
- **ci-cd** — Go build and release pipeline design
- **security-auditing** — dependency and code security review

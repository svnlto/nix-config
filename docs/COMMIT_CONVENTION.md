# Nix Configuration Conventional Commit Guide

This repository follows the [Conventional Commits](https://www.conventionalcommits.org/) specification to automate versioning and changelog generation.

## Commit Message Format

Each commit message consists of a **header**, a **body**, and a **footer**. The header has a special format that includes a **type**, a **scope**, and a **subject**:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to our CI configuration files and scripts
- **chore**: Other changes that don't modify source or test files
- **revert**: Reverts a previous commit

### Scopes

- **darwin**: macOS-specific configurations
- **vagrant**: Vagrant VM configurations
- **common**: Shared configurations
- **overlays**: Nix overlays
- **deps**: Dependency updates
- **release**: Release-related changes

### Examples

```
feat(darwin): add Firefox configuration
```

```
fix(vagrant): resolve RAM disk permission issues
```

```
docs: update README with new setup instructions
```

```
chore(deps): update nixpkgs to latest version
```

## Breaking Changes

Breaking changes should be indicated with a `!` after the type/scope and also include a `BREAKING CHANGE:` footer:

```
feat(darwin)!: redesign dock configuration

BREAKING CHANGE: The dock configuration format has changed and requires manual migration.
```

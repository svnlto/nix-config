# Pull Request Conventions

## Branch Strategy

- **Trunk-based**: short-lived feature branches off `main`, merge back via PR
- Branch naming: `<type>/<ticket>-<short-description>` (e.g., `feat/12345-add-auth`)
- Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `hotfix`
- Delete branches after merge — enforce via branch policy

## PR Requirements

- **Title**: `<type>(<scope>)[KAAS-0000]: <subject>` matching Conventional Commits
- **Description**: What changed, why, how to test, linked work items
- **Size**: Aim for < 400 lines changed; split larger work into stacked PRs
- **Work item linking**: Always link ADO work items
  (`AB#12345` in commit or PR description)
- **Draft PRs**: Use for early feedback before the PR is ready for formal review

## Branch Policies (recommended defaults)

- Minimum 1 reviewer (2 for `main`)
- Build validation — PR must pass CI before merge
- Comment resolution — all threads must be resolved
- Work item linking required
- Squash merge to `main` (clean linear history)
- Reset approval on new pushes

## Code Review Standards

- Review within 1 business day
- Use ADO's suggestion feature for small fixes
- Mark comments as `nit:`, `question:`, `blocking:` to signal severity
- Approve with comments for non-blocking feedback
- Reviewer checks: correctness, tests, security, naming, no secrets in code

# Pull Request Conventions

## Branch Strategy

- **Trunk-based**: short-lived feature branches off `main`, merge back via PR
- Branch naming: `<type>/<ticket>-<short-description>` (e.g., `feat/12345-add-auth`)
- Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `hotfix`
- Delete branches after merge — enforce via branch policy

## PR Requirements

- **Title**: `<type>(<scope>)[PROJ-1234]: <subject>` matching Conventional
  Commits, where `PROJ-1234` is the Jira issue key
- **Description**: What changed, why, how to test, and the Jira issue
  (key + link)
- **Size**: Aim for < 400 lines changed; split larger work into stacked PRs
- **Jira linking**: Reference the Jira issue by key in the branch name and
  PR title, and include a link to the Jira issue in the PR description.
  (This team tracks work in Jira, not Azure Boards — do not use ADO
  `AB#` work-item syntax.)
- **Draft PRs**: Use for early feedback before the PR is ready for formal review

## PR Templates — always use the repo's existing template

Azure DevOps repos frequently ship a PR description template. The **web UI
auto-fills** the description from it, but **`az repos pr create` does NOT** —
so a CLI-created PR silently ignores the template unless you apply it
yourself. Before creating any ADO PR, detect the repo's template, fill it
in, and pass it as the description. A PR that discards the team's template
(dropping its checklists, Jira/issue sections, or required headings) will
bounce in review.

### Where ADO looks for templates

Templates must live on the repository's **default branch** (usually `main`),
regardless of your source branch. Folder and file names are **not** case
sensitive. These folders are searched **in order**, first match wins:
`.azuredevops/`, `.vsts/`, `docs/`, repository root.

| Template kind | Path (under one of the folders above) | Applies when |
|---------------|----------------------------------------|--------------|
| Default | `pull_request_template.md` (or `.txt`) | Any PR, unless a branch-specific template matches |
| Branch-specific | `pull_request_template/branches/<branch>.md` (or `.txt`) | PR targets `<branch>` or any sub-branch — `<branch>` is the first path segment (`feature.md` matches `feature/*`) |
| Additional (named) | `pull_request_template/<name>.md` (or `.txt`) | Optional; appended by choice |

Resolution order: a branch-specific template matching the **target** branch
wins; otherwise the default template applies.

### CLI workflow

1. **Find the template** for the target branch (branch-specific → default):

   ```bash
   base="${1:-main}"                    # PR target branch
   seg="${base%%/*}"                    # first path segment
   for dir in .azuredevops .vsts docs .; do
     for f in "$dir/pull_request_template/branches/$seg".{md,txt} \
              "$dir/pull_request_template".{md,txt}; do
       [ -f "$f" ] && { tmpl="$f"; break 2; }
     done
   done
   ```

2. **Fill it in** — keep the template's headings, checklists, and sections;
   replace placeholder prose with the real what/why/how-to-test, and add
   the Jira issue key and link (e.g. `PROJ-1234`). Do not delete sections
   you think are irrelevant; leave the structure intact.

3. **Create the PR with the filled template.** `az repos pr create` has no
   `--description-file`; pass the file contents to `--description`:

   ```bash
   az repos pr create \
     --source-branch "$src" --target-branch "$base" \
     --title "$title" \
     --description "$(cat filled-pr.md)"
   ```

4. **No template found?** Fall back to the standard structure below
   (What / Why / How to test + the Jira issue key and link).

## Branch Policies (recommended defaults)

- Minimum 1 reviewer (2 for `main`)
- Build validation — PR must pass CI before merge
- Comment resolution — all threads must be resolved
- Jira issue referenced by convention (key in branch/title, link in
  description) — Azure Boards work-item-linking policy does not apply here
- Squash merge to `main` (clean linear history)
- Reset approval on new pushes

## Code Review Standards

- Review within 1 business day
- Use ADO's suggestion feature for small fixes
- Mark comments as `nit:`, `question:`, `blocking:` to signal severity
- Approve with comments for non-blocking feedback
- Reviewer checks: correctness, tests, security, naming, no secrets in code

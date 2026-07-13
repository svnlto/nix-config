# Merge Requests

All commands run inside the target repo checkout unless a
`-R <host>/<group>/<project>` is given.

## List

    glab mr list                 # open MRs
    glab mr list --all           # all states
    glab mr list --assignee=@me  # yours

## View

    glab mr view <id>            # summary + description
    glab mr view <id> --comments # include discussion
    glab mr diff <id>            # the change

`<id>` may be an MR number, a branch name, or omitted to use
the current branch's MR.

## Review

    glab mr diff <id>            # read the change first
    glab mr note <id> -m "..."   # leave a comment

## State-changing (confirm first — see SKILL.md Safety)

    glab mr create --fill        # from current branch commits
    glab mr approve <id>
    glab mr merge <id>

For `create`, draft the description with
`references/templates.md`, show it to the user, and run with
`--description` (or `-d`) only after confirmation. Never
merge without explicit instruction.

## Checkout

    glab mr checkout <id>        # check out the MR branch locally

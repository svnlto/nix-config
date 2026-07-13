# Issues

## List and search

    glab issue list                    # open issues
    glab issue list --assignee=@me
    glab issue list --search "text"

## View

    glab issue view <id>
    glab issue view <id> --comments

## State-changing (confirm first — see SKILL.md Safety)

    glab issue create -t "title" -d "description"
    glab issue note <id> -m "..."
    glab issue update <id> --label "..."
    glab issue close <id>

For `create`, show the title and description to the user and
run only after confirmation.

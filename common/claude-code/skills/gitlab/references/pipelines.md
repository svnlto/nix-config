# CI/CD Pipelines

## Status and history

    glab ci status              # current branch's latest pipeline
    glab ci list                # recent pipelines

## Inspect

    glab ci view <id>           # jobs in a pipeline
    glab ci trace <job-id>      # stream a job's logs

Omit `<id>` to target the current branch's latest pipeline.

## Act (confirm first — see SKILL.md Safety)

    glab ci retry <id>          # retry failed jobs

When a pipeline is red, read the failing job's logs with
`glab ci trace <job-id>` before proposing a fix — quote the
actual error, do not guess.

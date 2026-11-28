# MR Description Template

Draft descriptions in this shape, then show the user before
`glab mr create`:

    ## What

    <one-paragraph summary of the change>

    ## Why

    <the reason / linked issue>

    ## How to test

    - <step>
    - <step>

    Closes #<issue-number>

Keep it to what reviewers need. Omit sections that do not
apply rather than leaving them empty.

## cc-spex feature branch

Run `/speckit-spex-finish` first and pick **Keep branch
as-is** (see the GitLab rule in the `cc-spex` skill). Then
draft:

    <type>(<scope>): <summary>        # Conventional Commit title

    ## What

    <one paragraph from spec.md's summary>

    ## Why

    Spec: `specs/<NNN-slug>/spec.md`
    Decision: ADR <date> "<title>"
    Jira: <KEY>, <KEY>

    ## How to test

    - <from the spec's acceptance scenarios or quickstart.md>

The squash commit message from finish is a good source for
the title; keep the two identical.

## Bug fix branch

For `fix/<slug>` branches (`spex-bugfix`):

    fix(<scope>): <summary>

    ## What

    <the defect, as a user sees it>

    ## Root cause

    <from the assessment>

    ## Repro

    <the failing test or exact command; now passing>

    ## Tests

    - <tests added or changed>

    Spec: <requirement reference, or "no spec covers this">
    Ticket: <KEY, if any>

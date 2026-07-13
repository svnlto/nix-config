# GitLab Setup

## Authenticate (user-run)

`glab` auth is interactive — the user runs it, never the
skill:

    ! glab auth login

Verify:

    glab auth status

## Host resolution

Inside a repo checkout, `glab` reads the host and project
from the git remote automatically. Outside a repo, target a
project explicitly:

    glab <command> -R <host>/<group>/<project>

or set the host for the session:

    GITLAB_HOST=<host> glab <command>

## Config location

Per-host tokens and defaults live in
`~/.config/glab-cli/config.yml`. Never copy host values from
there into any repo file — this repo is public.

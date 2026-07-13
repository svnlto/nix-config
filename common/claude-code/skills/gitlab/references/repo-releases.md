# Repo and Releases

## Repo

    glab repo view                     # project overview
    glab repo clone <group>/<project>

## Releases

    glab release list
    glab release view <tag>

## Releases — state-changing (confirm first)

    glab release create <tag> --notes "..."

## CI/CD variables

    glab variable list                 # names + scopes

`glab variable set` writes a secret to shared project config.
Treat it as high-risk: show the exact command, confirm, and
never echo the value into logs or the terminal history
unnecessarily.

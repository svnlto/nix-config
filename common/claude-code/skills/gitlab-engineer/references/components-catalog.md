# CI/CD Components & Catalog

Doc: <https://docs.gitlab.com/ci/components/>. GA in GitLab 17.0. This is
the standard way to share pipeline config across repos — prefer it over
copy-pasted `include:template`/`include:project`.

## Component project layout

```text
├── templates/
│   ├── my-component.yml            # single-file component
│   └── my-other-component/
│       ├── template.yml            # directory component (only template.yml is released)
│       ├── Dockerfile
│       └── test.sh
├── LICENSE.md
├── README.md                       # required; documents each component
└── .gitlab-ci.yml
```

One project holds up to 100 components. Components needing independent
versioning belong in separate projects.

## Inputs (`spec`)

Declare inputs in a `spec` section separated by `---`; reference with
`$[[ inputs.<name> ]]`:

```yaml
spec:
  inputs:
    stage:
      default: test
---
component-job:
  stage: $[[ inputs.stage ]]
  script: echo job
```

Component context (`spec:component`) exposes `name`, `sha`, `version`,
`reference` via `$[[ component.<field> ]]`. `spec:include` is not
supported inside components.

## Using a component

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0.0
    inputs:
      stage: build
```

Reference format:
`<fqdn>/<project-path>/<component-name>@<version>`. Use the predefined
`$CI_SERVER_FQDN` so it stays instance-correct — never hardcode the
Dedicated hostname. Components resolve only within the same instance.
Included config merges in, so job names and `extends` targets can collide
with yours.

## Versioning (priority order)

1. Commit SHA (beats a same-named tag).
2. Tag — catalog releases must be semver (`1.0.0`, `1.0.0-alpha`).
3. Branch name (`main`).
4. `~latest` or a partial version — resolve only against published
   catalog releases. `1` = latest `1.*.*`; `1.2` = latest `1.2.*`;
   `~latest` = latest release (may include breaking changes).

Pin production includes to a **tag or SHA**, never `main`. Pre-releases
(`1.0.1-rc`) are never selected by partial/`~latest`.

## Publishing to the catalog

1. Project needs a description, root `README.md`, ≥1 component in
   `templates/`.
1. Settings > General > Visibility — enable **CI/CD Catalog project**
   (Owner role; `catalogResourcesCreate` GraphQL mutation can automate).
1. Add a release job using the `release` keyword (Releases API is not
   supported for this):

```yaml
create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  script: echo "Releasing $CI_COMMIT_TAG"
  rules:
    - if: $CI_COMMIT_TAG
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG"
```

1. Push a semver tag — the tag pipeline runs the release job and
   publishes. Disabling the catalog toggle removes metadata, keeps the
   repo.

Catalog: Search or go to > Explore > CI/CD Catalog. Adoption analytics
tab (18.9+); per-project usage tab (19.0+).

# Releasing

This repository uses a tagpr-equivalent release flow built on CSM actions and [git-cliff](https://git-cliff.org/).

## Overview

1. Commits land on `main` via squash-merged pull requests.
2. The **Release PR** workflow runs git-cliff to bump the version and regenerate `CHANGELOG.md`, then asks `civitaspo/securefix-server` to open or update `release/next`.
3. The **Release PR Sync** workflow updates the open `release/next` pull request title and body from `.release-version` (securefix creates the PR once and does not refresh metadata on later pushes).
4. A human squash-merges `chore(release): vX.Y.Z`.
5. The **Release Tag** workflow creates an annotated tag `vX.Y.Z` and requests a server-side release.
6. The securefix-server **Release dbt Authorized Models** workflow checks out the tag and publishes the GitHub Release.

## Repository release protections

- Prefer a tag protection ruleset that blocks force-pushes and deletion of tags outside the allowed release path.
- Prefer immutable releases: the publisher creates a draft release, attaches notes, then publishes once.

## Version bump rules (while major is 0)

Configured in `cliff.toml` (`[bump]`) and applied by git-cliff:

- Conventional Commit breaking change (`type!:` or `BREAKING CHANGE`) → minor
- `feat:` → minor
- everything else releasable → patch
- Only `chore(release):` commits since the last tag → nothing to release

The Release PR workflow floors the base version on both the latest `v*` tag and `.release-version` on `main`. If the floor tag is not present yet (release merged, Release Tag still running), it creates a **local** tag at the matching `chore(release):` commit so git-cliff does not re-propose the version that just shipped. That local tag is never pushed.

## Local preview

```bash
mise install --locked
mise exec -- git cliff --bumped-version
mise exec -- git cliff --tag vX.Y.Z --output CHANGELOG.md
```

git-cliff regenerates the full changelog from git history. **Do not edit `CHANGELOG.md` on feature PRs** — Lint fails if a non-`release/next` PR touches that file. Use Conventional Commit subjects; the Release PR is the only writer. Hand-edited `## Unreleased` notes cause merge conflicts with the long-lived `release/next` branch.

## Server request format

The Release Tag workflow creates a label on `civitaspo/securefix-server` whose description is:

```text
civitaspo/dbt-authorized-models/<run_id>/vX.Y.Z/<merge-commit-sha>
```

If that string would exceed GitHub's 100-character label description limit, the merge commit SHA is omitted and the server resolves it from the merged `release/next` pull request.

The merge commit SHA is preferred because `Release Tag` on a merged `release/next` PR tags the squash-merge commit on `main`, while the workflow run's `head_sha` is the PR head.

Label names use the `release-dbt-auth-` prefix so the server can route them separately from other packages.

## Required securefix-server companion

This repository's client workflows create `release-dbt-auth-*` labels. Copy [`docs/securefix-server-release-dbt-authorized-models.yml`](securefix-server-release-dbt-authorized-models.yml) into [`civitaspo/securefix-server`](https://github.com/civitaspo/securefix-server) as `.github/workflows/release-dbt-authorized-models.yml`.

That workflow:

- Triggers on `release-dbt-auth-*` labels
- Allows only `civitaspo/dbt-authorized-models`
- Validates the referenced run is a `Release Tag` workflow
- Checks out the tag, verifies it matches the expected merge commit and is contained in `main`
- Publishes the GitHub Release (`draft` then publish once)
- Deletes the request label

Until that server workflow exists, Release Tag can create the annotated tag, but the GitHub Release will not be published automatically.

See [securefix.md](securefix.md) for client/server credential layout.

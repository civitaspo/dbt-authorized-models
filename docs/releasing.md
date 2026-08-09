# Releasing

This repository uses the shared Securefix client release flow hosted in [`civitaspo/securefix-server`](https://github.com/civitaspo/securefix-server).

**Canonical specification:** [securefix-server docs/client-releases.md](https://github.com/civitaspo/securefix-server/blob/main/docs/client-releases.md)

## Overview

1. Commits land on `main` via squash-merged pull requests.
2. **Release PR** (reusable on securefix-server) runs git-cliff, updates `.release-version` / `CHANGELOG.md`, and syncs `dbt_project.yml` / `pyproject.toml` when present, then opens or updates `release/next` via Securefix.
3. **Release PR Sync** keeps the open `release/next` PR title/body aligned with `.release-version`.
4. A human squash-merges `chore(release): vX.Y.Z`.
5. **Release Tag** creates annotated tag `vX.Y.Z` and creates a `release-request-*` label on `civitaspo/securefix-server`.
6. The server **Release** workflow validates the allowlist entry and publishes a GitHub Release.

Local workflows under `.github/workflows/` are thin wrappers that `uses:` the securefix-server reusables at a pinned commit SHA.

## Repository release protections

- **Tag protection** (`Protect tags` ruleset): active — blocks force-pushes and deletion of tags outside the allowed release path.
- **Immutable releases**: enabled when the publisher creates a draft release, attaches notes, then publishes once.

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

## Credentials

Repository secret `SECUREFIX_CLIENT_PRIVATE_KEY` only. See [securefix.md](securefix.md) and the [canonical client-releases doc](https://github.com/civitaspo/securefix-server/blob/main/docs/client-releases.md).

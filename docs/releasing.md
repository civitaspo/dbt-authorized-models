# Releasing

This package uses the [csm-ci release flow](https://github.com/civitaspo/csm-ci-actions/blob/main/docs/release-pr.md) hosted by [civitaspo/csm-ci-server](https://github.com/civitaspo/csm-ci-server).

1. Squash-merge a change into `main` through `/merge`.
2. **csm-ci-release-pr** runs git-cliff and opens or updates `release/next`. It updates `CHANGELOG.md`, `.release-version`, the root `dbt_project.yml` version, and the root `pyproject.toml` version together.
3. Review the generated `release-pr: chore(release): vX.Y.Z` PR. The owner comments `/approve` for its sensitive version manifest, waits for `status-check` and `csm-ci/policy`, then comments `/merge`.
4. **csm-ci-release** requests server-side publication. The server verifies the merged release PR, creates `vX.Y.Z`, and publishes an immutable GitHub Release with `SHA256SUMS` and provenance attestation. This is a source-only dbt package; there are no compiled binary assets.

The preparation workflow skips release commits to avoid proposing the just-merged version before its tag exists. Use workflow dispatch with an optional explicit semantic version to prepare or retry a real release. The publish request runs only for a merged, same-repository `release/next` PR targeting the default branch.

## Version bump rules

`cliff.toml` controls inferred versions. While major is zero, breaking changes and `feat:` commits bump the minor version; other releasable changes bump the patch version. Release commits alone do not produce another release.

```bash
mise install --locked
mise exec -- git cliff --bumped-version
mise exec -- git cliff --tag vX.Y.Z --output CHANGELOG.md
```

The release PR owns `CHANGELOG.md`. Keep it out of feature PRs and use Conventional Commit subjects for release notes. Release version files must remain valid semantic versions; preparation rejects unsupported manifest formats before changing any file.

## Credentials and protection

Only the Client App key is held here; see [securefix.md](securefix.md). Server and Approver credentials stay in the server's `csm-ci` environment. The managed `release-tags` ruleset restricts `v*` tag creation to the Server App. The existing general tag integrity ruleset remains active. Published releases are immutable.

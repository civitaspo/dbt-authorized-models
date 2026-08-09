# Contributing

Thanks for contributing to `dbt-authorized-models`.

## Development setup

Install pinned tools with [mise](https://mise.jdx.dev/):

```bash
mise install --locked
uv sync --frozen
```

## Pull requests

- Write commits, PR titles/bodies, documentation, and comments in **English only**.
- Use Conventional Commits for PR titles (`feat`, `fix`, `docs`, `refactor`, `test`, `ci`, `build`, `chore`, `perf`, `revert`; use `!` for breaking changes).
- Never push directly to `main`. Open a PR and squash-merge after required checks pass.
- Keep changes small, reviewable, and focused on one meaningful unit of work.
- Do **not** edit `CHANGELOG.md` on feature PRs. git-cliff regenerates it on the `release/next` Release PR from Conventional Commit subjects (see [docs/releasing.md](docs/releasing.md)).

Before opening a PR, run the package checks described in [AGENTS.md](AGENTS.md).

## Release flow (summary)

1. Merges to `main` trigger the Release PR workflow, which runs git-cliff and opens or updates the changelog / version bump PR on `release/next`.
2. Merging the release PR creates a tag and requests a server-side publish in `civitaspo/securefix-server`.
3. A GitHub Release is published for the tag.

See [docs/releasing.md](docs/releasing.md) and [docs/securefix.md](docs/securefix.md) for details.

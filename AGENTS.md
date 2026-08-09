# Repository Guidelines

## Project Scope

This repository contains `dbt-authorized-models`, a dbt package that enforces explicit authorization rules for model references.

## Contributor Expectations

- Write commits, pull request titles/bodies, documentation, comments, and user-facing messages in **English only**.
- Use Conventional Commits for pull request titles (`feat`, `fix`, `docs`, `refactor`, `test`, `ci`, `build`, `chore`, `perf`, `revert`; use `!` for breaking changes).
- Never push directly to `main`. Open a pull request and squash-merge after required checks pass.
- Keep changes small, reviewable, and focused on the package behavior described in the README.
- Prefer clear dbt macros and integration tests over clever abstractions.
- Document security-sensitive behavior, especially deny-by-default authorization semantics.
- Avoid generated files unless they are required for reproducible dependency resolution.
- Sign commits (SSH signing is configured for maintainers and coding agents committing as `civitaspo`).
- When Codex creates commits, sign them and include `Co-authored-by: Codex <codex@openai.com>`.
- Do not rewrite or amend commits that have already been merged. If commit metadata is wrong after merge, create a clean replacement repository or follow the maintainer's explicit recovery plan.
- Use squash merge only for pull requests in this repository.
- If local `main` has diverged, branch from `origin/main` and leave the local branch history untouched.
- Keep pull request descriptions complete enough for an outside OSS maintainer to review, but do not include unnecessary personal information.
- Do not store strong credentials in this repository. GPG keys, machine-user PATs, and `contents: write` app keys live only in `civitaspo/securefix-server`.

## Package Behavior Notes

- Authorization is deny-by-default. Missing, empty, or malformed `meta.authorize` should fail closed.
- The package must enforce both `ref()` model references and `source()` source references.
- Source authorization should cover metadata declared in source YAML and `+meta` declared in `dbt_project.yml`.
- Keep tests for dbt source metadata precedence: table-local `meta.authorize` wins over source-level `+meta`, and plain `meta` without the `+` config prefix in `dbt_project.yml` is not a valid inherited source configuration.
- Treat dbt Fusion compatibility as a required behavior surface, not an optional smoke test.

## Tooling

Install pinned tools with mise:

```bash
mise install --locked
```

Before opening a pull request, run:

```bash
mise run lint
mise run test
mise run test:fusion
```

- Use `uv run` consistently for Python and dbt commands in local docs, scripts, and GitHub Actions.
- Do not mix equivalent entry points such as `uv run python ...` and `python3 ...` for the same workflow.
- Do not hide CI workflows behind mise tasks; keep the failing command visible in the GitHub Actions step.
- Prefer Python test helpers with dbt programmatic invocation over shell scripts for negative authorization assertions.
- Keep `uv`, ShellCheck, git-cliff, ghalint, pinact, and disable-checkout-persist-credentials managed by mise.

## GitHub Actions

- Pin public GitHub Actions to immutable SHAs.
- Use `persist-credentials: false` with `actions/checkout` unless a workflow explicitly needs push credentials.
- Keep workflow permissions least-privilege and job names descriptive.
- Run workflow linting with ghalint, pinact, and disable-checkout-persist-credentials.
- Use Securefix for automated workflow security fixes when configured.
- Approvals for trusted authors are requested through `csm-actions/approve-pr-action`.
- Do not provide hidden defaults for required repository variables in workflows; fail clearly when required configuration is missing.

See [docs/securefix.md](docs/securefix.md) and [docs/releasing.md](docs/releasing.md).

## Verification

For unit-test changes, run the package unit tests from the dedicated unit test project:

```bash
uv run dbt deps --project-dir unit_tests --profiles-dir unit_tests
uv run dbt run-operation run_unit_tests --project-dir unit_tests --profiles-dir unit_tests
```

For integration behavior, run the integration project checks:

```bash
uv run dbt deps --project-dir integration_tests --profiles-dir integration_tests
uv run python integration_tests/run_authorization_failure_tests.py
uv run python integration_tests/assert_project_source_meta.py
uv run dbt compile --project-dir integration_tests --profiles-dir integration_tests
```

When changing source reference behavior, include tests for successful source authorization, missing authorization failures, empty authorization failures, and `dbt_project.yml` source `+meta` inheritance.

When changing compatibility-sensitive macro behavior, also verify with dbt Fusion using the existing workflow pattern.

## Release

Releases are prepared by the **Release PR** workflow (git-cliff + Securefix `release/next`). A human squash-merges `chore(release): vX.Y.Z`; **Release Tag** creates the annotated tag and asks `civitaspo/securefix-server` to publish the GitHub Release.

Do not edit `CHANGELOG.md` on feature PRs. See [docs/releasing.md](docs/releasing.md).

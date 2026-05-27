# Repository Guidelines

## Project Scope

This repository contains `dbt-authorized-models`, a dbt package that enforces explicit authorization rules for model references.

## Contributor Expectations

- Write commits, pull request descriptions, documentation, comments, and user-facing messages in English.
- Keep changes small, reviewable, and focused on the package behavior described in the README.
- Prefer clear dbt macros and integration tests over clever abstractions.
- Document security-sensitive behavior, especially deny-by-default authorization semantics.
- Avoid generated files unless they are required for reproducible dependency resolution.
- When Codex creates commits, sign them and include `Co-authored-by: Codex <codex@openai.com>`.
- Do not rewrite or amend commits that have already been merged. If commit metadata is wrong after merge, create a clean replacement repository or follow the maintainer's explicit recovery plan.
- Use squash merge only for pull requests in this repository.
- If local `main` has diverged, branch from `origin/main` and leave the local branch history untouched.
- Keep pull request descriptions complete enough for an outside OSS maintainer to review, but do not include unnecessary personal information.

## Package Behavior Notes

- Authorization is deny-by-default. Missing, empty, or malformed `meta.authorize` should fail closed.
- The package must enforce both `ref()` model references and `source()` source references.
- Source authorization should cover metadata declared in source YAML and `+meta` declared in `dbt_project.yml`.
- Keep tests for dbt source metadata precedence: table-local `meta.authorize` wins over source-level `+meta`, and plain `meta` without the `+` config prefix in `dbt_project.yml` is not a valid inherited source configuration.
- Treat dbt Fusion compatibility as a required behavior surface, not an optional smoke test.

## Tooling

- Install pinned tools with mise:

```bash
mise install --locked
```

- Use `uv run` consistently for Python and dbt commands in local docs, scripts, and GitHub Actions.
- Do not mix equivalent entry points such as `uv run python ...` and `python3 ...` for the same workflow.
- Do not hide CI workflows behind mise tasks; keep the failing command visible in the GitHub Actions step.
- Prefer Python test helpers with dbt programmatic invocation over shell scripts for negative authorization assertions.
- Keep `uv`, ShellCheck, ghalint, pinact, and disable-checkout-persist-credentials managed by mise.

## GitHub Actions

- Pin public GitHub Actions to immutable SHAs.
- Use `persist-credentials: false` with `actions/checkout` unless a workflow explicitly needs push credentials.
- Keep workflow permissions least-privilege and job names descriptive.
- Run workflow linting with ghalint, pinact, and disable-checkout-persist-credentials.
- Use Securefix for automated workflow security fixes when configured.
- Do not provide hidden defaults for required repository variables in workflows; fail clearly when required configuration is missing.

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

## Release Checklist

- Update `CHANGELOG.md` with user-facing release notes.
- Bump `version` in `dbt_project.yml`.
- Update README installation examples to the new tag.
- Open a normal pull request and wait for CI to pass.
- Squash merge the release preparation pull request.
- Create a signed annotated release tag from the merged `origin/main` commit.
- Push the tag and watch the release workflow until the GitHub Release is published.

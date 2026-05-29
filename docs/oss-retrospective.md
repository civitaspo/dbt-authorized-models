# OSS Launch Retrospective

This retrospective records lessons from creating `dbt-authorized-models` so the next OSS launch can start cleaner and move faster.

## What Worked Well

- Starting from a new public repository kept the OSS history clean.
- Writing all commits, pull request descriptions, documentation, comments, and user-facing text in English made the project easier for external maintainers to review.
- Adding `AGENTS.md` early helped preserve repository-specific expectations across many follow-up changes.
- Using small pull requests kept each reviewable: implementation, CI, docs, source support, security hardening, release prep, and compatibility tests were easier to reason about separately.
- Squash merging kept `main` readable while still allowing detailed PR discussion.
- Adding `Co-authored-by: Codex <codex@openai.com>` and signed commits from the beginning avoided later attribution repair work.
- Treating dbt Fusion as required compatibility caught design assumptions that would otherwise have remained implicit.
- Dedicated `unit_tests` and `integration_tests` projects made the intent of each test type clear.
- Python test helpers with dbt programmatic invocation were easier to maintain than shell scripts for negative authorization scenarios.
- `mise` plus a lockfile made local and CI tool versions reproducible without hiding failing commands behind custom tasks.
- GitHub Actions hardening was easier once it had automated checks: SHA pinning, `persist-credentials: false`, explicit permissions, ghalint, pinact, and disable-checkout-persist-credentials.
- A `CHANGELOG.md` made the `v0.2.0` release notes much easier to assemble.

## Pain Points

- Commit attribution and signature expectations were discovered after early merges. For OSS work, decide them before the first commit.
- Local `main` diverged from `origin/main`, which made later merges noisy. Branch from `origin/main` and avoid using a stale local `main` as the source of truth.
- Source and snapshot support were real behavior surfaces, but they became explicit only after user questions. Enumerate supported dbt resource types early.
- The README initially explained the happy path but did not show enough first-run failure behavior. Deny-by-default packages need concrete error examples.
- GitHub Actions security hardening came after CI already existed. It is cheaper to start secure than to retrofit pinned actions and checkout settings.
- Securefix setup required a separate server repository, GitHub Apps, variables, secrets, and repository rules. This should be planned as its own task, not squeezed into ordinary CI work.
- The dbt Hub submission PR needed better package context and maintainer-friendly wording. External upstream PRs deserve extra care before creation.
- Some docs risked including unnecessary personal information. Keep OSS documentation focused on technical references and avoid naming people unless the project explicitly requires it.

## Recommended Next-Time Order

1. Create the public repository with a clear name, license, README skeleton, `AGENTS.md`, `.gitignore`, and package metadata.
2. Configure repository settings before feature work: squash merge only, branch rules, force-push protection for `main`, default Actions permissions, and required checks.
3. Decide commit hygiene before the first commit: signed commits, verified tags, and any required co-author trailers.
4. Add pinned tool management with `mise.toml` and `mise.lock`.
5. Add secure GitHub Actions from the first CI PR: SHA-pinned actions, `persist-credentials: false`, least-privilege permissions, and workflow linting.
6. Implement the smallest useful package behavior with focused tests.
7. Add unit tests in a dedicated unit-test project and integration tests in a dedicated integration-test project.
8. Add negative tests for deny-by-default behavior before release: missing rules, empty rules, malformed rules, unauthorized references, and warning mode.
9. Add compatibility coverage for each runtime the README claims to support, including dbt Fusion when relevant.
10. Improve user docs before release: quick start, rollout mode, common errors, behavior model, examples, and comparison with built-in alternatives.
11. Add `CHANGELOG.md` before the first release.
12. Release with a normal PR, green CI, a signed annotated tag, and a watched release workflow.
13. Submit registry or upstream hub PRs only after the package repository has a stable release tag and clear README.
14. Add optional automation such as Securefix after the core repository workflow is stable.

## Documentation Checklist

- State the package purpose in one sentence.
- List supported dbt resource types explicitly.
- Explain deny-by-default behavior near the top.
- Show warning-mode rollout for existing projects.
- Include a realistic failure message and the fix path.
- Document each configuration variable.
- Include examples for public resources, restricted resources, package-based rules, schema-based rules, tag-based rules, sources, and snapshots.
- Compare against the nearest built-in feature so users know when not to use the package.
- State what the package does not do, especially database grants or warehouse permissions.
- Keep release notes in `CHANGELOG.md`.

## Testing Checklist

- Unit-test pure macro behavior in a dedicated unit test project.
- Integration-test successful authorization through a real dbt project.
- Integration-test authorization failures with programmatic dbt invocation.
- Cover both enforcing mode and warning mode.
- Cover missing, empty, malformed, and wildcard authorization rules.
- Cover each supported referenced resource type.
- Cover each supported referencing resource type that has special behavior.
- Cover dbt metadata inheritance and precedence when the package relies on dbt graph metadata.
- Run the same behavioral tests against dbt Fusion when compatibility is claimed.

## GitHub Actions Checklist

- Pin third-party actions by commit SHA.
- Set `persist-credentials: false` on checkout steps by default.
- Declare minimal `permissions` at workflow or job level.
- Use descriptive workflow and job names.
- Keep commands visible in workflow steps instead of hiding them behind task aliases.
- Run ghalint, pinact, and disable-checkout-persist-credentials.
- Manage action-linting tools with mise.
- Use automated fix workflows only after the security model is clear.
- Avoid fallback defaults for required repository variables; fail clearly when configuration is missing.

## Release Checklist

- Confirm all tests pass locally or in CI.
- Update README installation examples to the new tag.
- Update `CHANGELOG.md`.
- Bump package version metadata.
- Open a release preparation pull request.
- Squash merge after required checks pass.
- Create a signed annotated tag from the merged `origin/main` commit.
- Push the tag.
- Watch the release workflow until the GitHub Release is published.
- Verify the release URL, tag target, and tag verification status.

## Registry And Upstream PR Checklist

- Read recently merged upstream PRs before drafting.
- Keep the PR description concise but useful for maintainers.
- Explain what the package does, who it is for, and which release tag should be indexed.
- Avoid unchecked checklist items unless maintainers explicitly require them.
- Do not claim real-world usage if the package does not need that claim for acceptance.
- Let the repository README carry detailed usage docs; keep the upstream PR easy to review.

## Security Checklist

- Forbid force pushes to `main`.
- Require pull requests and status checks before merging to `main`.
- Keep repository secrets and variables explicit.
- Avoid giving pull request workflows write tokens.
- Use GitHub Apps or trusted automation boundaries for workflows that must write commits.
- Keep generated or machine-managed files only when they improve reproducibility.
- Document security-sensitive package behavior, especially fail-closed semantics.

## Final Lesson

The cleanest OSS launch is not just clean code. It is clean history, clear attribution, reproducible tools, secure automation, behavior-focused tests, and documentation that tells users what will happen when things fail.

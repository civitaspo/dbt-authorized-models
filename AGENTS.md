# Repository Guidelines

## Project Scope

This repository contains `dbt-authorized-models`, a dbt package that enforces explicit authorization rules for model references.

## Contributor Expectations

- Write commits, pull request descriptions, documentation, comments, and user-facing messages in English.
- Keep changes small, reviewable, and focused on the package behavior described in the README.
- Prefer clear dbt macros and integration tests over clever abstractions.
- Document security-sensitive behavior, especially deny-by-default authorization semantics.
- Avoid generated files unless they are required for reproducible dependency resolution.

## Verification

When package implementation files are present, verify macro behavior from the integration test project:

```bash
cd integration_tests
dbt deps
dbt run-operation test_all_macros
```

When GitHub Actions files are present, keep workflow names and job names descriptive so pull request checks are easy to understand.

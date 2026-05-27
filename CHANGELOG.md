# Changelog

All notable changes to this project are documented in this file.

## [0.2.0] - 2026-05-28

### Added

- Support authorization checks for dbt source references, including missing and empty `meta.authorize` failure paths.
- Add unit tests for package macros and broader integration coverage for source authorization behavior.
- Add dbt Core and dbt Fusion coverage for source metadata configured with `+meta` in `dbt_project.yml`.
- Add Securefix workflow autofix setup for workflow security fixes.

### Changed

- Improve README guidance for first-run rollout, deny-by-default behavior, and common authorization errors.
- Manage development and CI tools with mise, including uv, ShellCheck, ghalint, pinact, and disable-checkout-persist-credentials.

### Security

- Harden GitHub Actions by pinning actions, disabling checkout credential persistence, and adding workflow lint checks.

## [0.1.0] - 2026-05-26

### Added

- Initial public release of `dbt-authorized-models`.
- Add model authorization checks with deny-by-default `meta.authorize` semantics.
- Add GitHub Actions CI/CD and dbt Fusion compatibility coverage.

[0.2.0]: https://github.com/civitaspo/dbt-authorized-models/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/civitaspo/dbt-authorized-models/releases/tag/v0.1.0

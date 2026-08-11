# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [0.3.0] - 2026-08-11


### Bug Fixes

- update dependency dbt-duckdb to >=1.11,<1.12 (#30)
- update dependency dbt-core to >=1.12,<1.13 (#29)


### Documentation

- point releasing guide at shared client-releases spec (#34)
- compare with dbt model access
- update agent guidance from retrospectives


### Features

- prefix package logs with (dbt-authorized-models) (#38)


### Maintenance

- harden reusable workflow calls for status-check (#41)
- update dependency jdx/mise to v2026.8.4 (#40)
- grant nested reusable workflow permissions from callers (#39)
- update actions/checkout action to v7 (#31)
- collapse PR checks into status-check gate (#37)
- lock file maintenance (#36)
- update actions/setup-python action to v7 (#32)
- migrate Renovate config (#33)
- bump securefix-server reusables for job summary links (#35)
- use securefix-server release workflow reusables (#24)
- update jdx/mise-action action to v4.2.4 (#28)
- update dependency python to 3.14 (#27)
- update dependency jdx/mise to v2026.8.3 (#26)
- update dependency aqua:suzuki-shunsuke/pinact to v4.1.1 (#25)
- update dependency aqua:astral-sh/uv to v0.12.3 (#23)
- update actions/checkout action to v4.4.0 (#22)
- add auto-approve and CSM release workflows (#20)
- Bump msgpack from 1.1.2 to 1.2.1 (#18)
- cover snapshot authorization


### Miscellaneous

- Add GitHub Sponsors funding settings

## [0.2.0] - 2026-05-27


### Documentation

- improve first-run authorization guidance


### Features

- authorize source references


### Maintenance

- prepare v0.2.0 release
- cover source metadata from dbt_project
- manage uv with mise (#10)
- add Securefix workflow autofix
- harden GitHub Actions workflows
- add package unit test project

## [0.1.0] - 2026-05-26


### Features

- implement dbt-authorized-models logic


### Maintenance

- add dbt Fusion compatibility coverage
- add GitHub Actions CI/CD
- add initial OSS project files



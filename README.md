# dbt-authorized-models

[![CI](https://github.com/civitaspo/dbt-authorized-models/actions/workflows/ci.yml/badge.svg)](https://github.com/civitaspo/dbt-authorized-models/actions/workflows/ci.yml)

`dbt-authorized-models` is a dbt package for enforcing explicit authorization rules on model references.

It lets model owners declare which dbt resources may reference a model, using regular-expression rules over dbt node properties such as `resource_type`, `database`, `schema`, `identifier`, `tags`, and `package_name`.

## Features

- Deny-by-default authorization for protected models.
- Regular-expression matching with full-string anchoring.
- AND logic within a rule and OR logic across rules.
- Configurable enforcement mode for failures or warnings.
- Focused integration tests for the package macros.

## Requirements

- dbt Core 1.10 or later.
- dbt Fusion 2.0 preview is parse-compatible and covered by CI.

## Installation

Add the package to your `packages.yml`:

```yaml
packages:
  - git: "https://github.com/civitaspo/dbt-authorized-models.git"
    revision: main
```

Install dependencies:

```bash
dbt deps
```

## Quick Start

Enable authorization checks from your root `dbt_project.yml`:

```yaml
on-run-start:
  - "{{ dbt_authorized_models.check_authorization() }}"

vars:
  dbt_authorized_models:
    enforce: true
    exclude_resource_types: ["test", "analysis"]
```

Declare authorization rules on a protected model:

```yaml
models:
  - name: sensitive_customer_data
    config:
      meta:
        authorize:
          - resource_type: "model"
            database: "analytics"
            schema: "finance"
          - resource_type: "model"
            database: "analytics"
            schema: "compliance"
```

Only matching resources can reference the protected model:

```sql
{{ config(schema="finance") }}

select * from {{ ref("sensitive_customer_data") }}
```

## Configuration

```yaml
vars:
  dbt_authorized_models:
    enforce: true
    exclude_resource_types: ["test", "analysis"]
```

`enforce` controls violation handling:

- `true`: raise a compiler error when unauthorized references are found.
- `false`: log violations and continue.

`exclude_resource_types` skips authorization checks for referencing resources of the listed types.

## Authorization Syntax

Rules are stored under `config.meta.authorize` on the referenced model.

```yaml
authorize:
  - resource_type: "model"
    database: "analytics"
    schema: "finance"
  - package_name: "trusted_package"
```

Evaluation semantics:

- All properties inside one rule must match.
- Any matching rule authorizes the reference.
- Missing or empty `authorize` configuration denies all references.

Use a wildcard rule to allow all references:

```yaml
authorize:
  - "*"
```

## Supported Properties

- `resource_type`
- `database`
- `schema`
- `identifier`
- `alias`
- `name`
- `tags`
- `package_name`

`tags` matches when any tag on the referencing node matches the configured pattern.

## Property Hierarchy

Some properties require parent properties so authorization stays explicit:

- `database` requires `resource_type`.
- `schema` requires `resource_type` and `database`.
- `identifier` or `alias` requires `resource_type`, `database`, and `schema`.
- `tags` requires `resource_type`, `database`, `schema`, and `identifier` or `alias`.

Use `.*` when a parent level should intentionally match anything.

```yaml
authorize:
  - resource_type: "model"
    database: ".*"
    schema: ".*"
    identifier: ".*"
    tags: "pii_approved"
```

## Regular Expressions

Patterns are Python regular expressions and are automatically anchored. For example, `finance` is treated as `^finance$`, while `rpt_.*` matches values that start with `rpt_`.

## Examples

Authorize models in finance and compliance schemas:

```yaml
models:
  - name: customer_pii
    config:
      meta:
        authorize:
          - resource_type: "model"
            database: "analytics"
            schema: "finance"
          - resource_type: "model"
            database: "analytics"
            schema: "compliance"
```

Authorize specific packages:

```yaml
models:
  - name: core_model
    config:
      meta:
        authorize:
          - package_name: "analytics_app"
          - package_name: "trusted_metrics"
```

Authorize models with a required tag:

```yaml
models:
  - name: restricted_metrics
    config:
      meta:
        authorize:
          - resource_type: "model"
            database: ".*"
            schema: ".*"
            identifier: ".*"
            tags: "restricted_access"
```

## Development

Run the macro tests from the integration test project:

```bash
cd integration_tests
uv run dbt deps
uv run dbt run-operation test_all_macros --profiles-dir .
uv run dbt compile --profiles-dir .
```

Check dbt Fusion compatibility:

```bash
curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --to /tmp/dbt-fusion-bin --update
/tmp/dbt-fusion-bin/dbt deps --profiles-dir .
/tmp/dbt-fusion-bin/dbt parse --profiles-dir .
/tmp/dbt-fusion-bin/dbt run-operation test_all_macros --profiles-dir .
/tmp/dbt-fusion-bin/dbt compile --profiles-dir .
```

## License

Apache License 2.0.

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
    revision: v0.1.0
```

Install dependencies:

```bash
dbt deps
```

## Quick Start

`dbt-authorized-models` is intentionally secure by default. After the hook is enabled, a referenced model with no `config.meta.authorize` rules denies all references to it.

For an existing project, start in warning mode so you can see what would fail before you block builds:

```yaml
# dbt_project.yml
on-run-start:
  - "{{ dbt_authorized_models.check_authorization() }}"

vars:
  dbt_authorized_models:
    enforce: false
    exclude_resource_types: ["test", "analysis"]
```

Run a compile to inventory references:

```bash
dbt compile
```

If every model is currently missing `meta.authorize`, you will see warnings for each reference. That is expected during rollout.

Make public models explicit with the wildcard rule:

```yaml
models:
  - name: public_customer_metrics
    config:
      meta:
        authorize:
          - "*"
```

Protect sensitive models with allow-list rules:

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

Only matching referencing resources can call `ref("sensitive_customer_data")`:

```sql
{{ config(schema="finance") }}

select * from {{ ref("sensitive_customer_data") }}
```

After the warnings look right, turn enforcement on:

```yaml
vars:
  dbt_authorized_models:
    enforce: true
    exclude_resource_types: ["test", "analysis"]
```

## Mental Model

Authorization rules live on the model being referenced, but each rule describes the model that is doing the referencing.

```text
finance_report -> ref("sensitive_customer_data")
```

In this example:

- `sensitive_customer_data` owns the `meta.authorize` allow-list.
- `finance_report` is checked against that allow-list.
- If no rule matches `finance_report`, the check fails.

This package checks dbt graph metadata. It does not query your warehouse, create permissions, create views, or grant database privileges.

## What Gets Checked

The `check_authorization()` macro runs from your root project's `on-run-start` hook.

- For `dbt run` and `dbt build`, dbt usually provides `selected_resources`; the package checks references made by the selected resources.
- For commands such as `dbt compile` or `dbt run-operation`, the package checks all graph nodes when selected resources are not available.
- Referencing resource types in `exclude_resource_types` are skipped.
- By default, tests and analyses are skipped.
- References to dbt sources are not checked by this package.

## What You Will See

### Passing Checks

When all references are authorized, the hook logs a short success message:

```text
Authorization check passed (2 references checked)
```

### Violations With Enforcement Enabled

With `enforce: true`, unauthorized references raise a compiler error and stop the command.

Example log:

```text
================================================================================
Authorization check failed
================================================================================

Found 1 authorization violation(s):

Violation 1:
  Referencing: finance_report (model.my_project.finance_report)
  Referenced:  sensitive_customer_data (model.my_project.sensitive_customer_data)
  Authorization rules:
    - {'resource_type': 'model', 'database': 'analytics', 'schema': 'compliance'}

================================================================================
Compilation Error
  Authorization check failed with 1 violation(s). Set dbt_authorized_models.enforce to false to warn only.
```

To fix this, either update the protected model's `meta.authorize` rules to allow the referencing model, or remove the unauthorized `ref()`.

### Violations With Enforcement Disabled

With `enforce: false`, the same violations are logged, but dbt continues:

```text
Continuing because dbt_authorized_models.enforce is false
```

Use this mode when introducing the package to an existing project or when you want an audit-only check.

### Missing Rules

If a referenced model has no `meta.authorize`, it denies all references:

```text
Authorization: deny all because meta.authorize is not defined
```

If that model should be public, add:

```yaml
config:
  meta:
    authorize:
      - "*"
```

If that model should be protected, add one or more explicit allow-list rules.

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
- A rule object describes the referencing node, not the referenced node.

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

These values come from dbt's node metadata. If a rule does not match as expected, inspect the compiled graph or run:

```bash
dbt ls --select your_model --output json
```

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

### Public Model

Allow any dbt resource to reference the model:

```yaml
models:
  - name: dim_dates
    config:
      meta:
        authorize:
          - "*"
```

### Schema-Based Authorization

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

### Package-Based Authorization

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

### Tag-Based Authorization

Authorize models with a required tag. Tag rules require the parent properties shown below, so use `.*` when a parent level can match anything:

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

### Same Project Only

Allow only resources from the same dbt package or project:

```yaml
models:
  - name: internal_model
    config:
      meta:
        authorize:
          - package_name: "my_dbt_project"
```

### Warn-Only Rollout

Run the check without failing builds:

```yaml
vars:
  dbt_authorized_models:
    enforce: false
```

This is useful while you add `meta.authorize` rules across an existing project.

## Troubleshooting

### The Check Fails Immediately After Installation

This usually means referenced models do not have `meta.authorize` rules yet. Because the package is deny-by-default, add either explicit rules or `["*"]` for public models. Use `enforce: false` while rolling this out.

### A Schema Rule Does Not Match

dbt may generate schema names with target-specific prefixes or suffixes. Match the actual node metadata, not just the folder name. Use a regex such as `.*finance` only when that is really the intended policy.

### A Tag Rule Raises A Hierarchy Error

`tags` rules must include `resource_type`, `database`, `schema`, and `identifier` or `alias`:

```yaml
authorize:
  - resource_type: "model"
    database: ".*"
    schema: ".*"
    identifier: ".*"
    tags: "pii_approved"
```

### `meta.authorize` As A Single Object Fails

Wrap rule objects in a list:

```yaml
# Good
authorize:
  - resource_type: "model"
    database: "analytics"

# Bad
authorize:
  resource_type: "model"
  database: "analytics"
```

### I Only Want To Protect A Few Models

Make every unprotected referenced model explicit with `authorize: ["*"]`, and add restrictive rules only to the models that need protection. This keeps public models public while still making the policy visible in code review.

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

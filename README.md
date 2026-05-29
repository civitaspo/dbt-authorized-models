# dbt-authorized-models

[![CI](https://github.com/civitaspo/dbt-authorized-models/actions/workflows/ci.yml/badge.svg)](https://github.com/civitaspo/dbt-authorized-models/actions/workflows/ci.yml)

`dbt-authorized-models` is a dbt package for enforcing explicit authorization rules on model, snapshot, and source references.

It lets resource owners declare which dbt resources may reference a model, snapshot, or source, using regular-expression rules over dbt node properties such as `resource_type`, `database`, `schema`, `identifier`, `tags`, and `package_name`.

## Features

- Deny-by-default authorization for protected resources.
- Authorization checks for `ref()` model and snapshot dependencies, plus `source()` dependencies.
- Regular-expression matching with full-string anchoring.
- AND logic within a rule and OR logic across rules.
- Configurable enforcement mode for failures or warnings.
- Focused unit and integration tests for the package macros.

## Requirements

- dbt Core 1.10 or later.
- dbt Fusion 2.0 preview is parse-compatible and covered by CI.

## Installation

Add the package to your `packages.yml`:

```yaml
packages:
  - git: "https://github.com/civitaspo/dbt-authorized-models.git"
    revision: v0.2.0
```

Install dependencies:

```bash
dbt deps
```

## Quick Start

`dbt-authorized-models` is intentionally secure by default. After the hook is enabled, a referenced model, snapshot, or source with no `config.meta.authorize` rules denies all references to it.

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

If every referenced model, snapshot, or source is currently missing `meta.authorize`, you will see warnings for each reference. That is expected during rollout.

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

Authorization rules live on the model, snapshot, or source being referenced, but each rule describes the dbt resource that is doing the referencing.

```text
finance_report -> ref("sensitive_customer_data")
```

In this example:

- `sensitive_customer_data` owns the `meta.authorize` allow-list.
- `finance_report` is checked against that allow-list.
- If no rule matches `finance_report`, the check fails.

This package checks dbt graph metadata. It does not query your warehouse, create permissions, create views, or grant database privileges.

## Relationship to dbt Model Access

dbt's built-in [model access](https://docs.getdbt.com/docs/mesh/govern/model-access) feature and this package solve related but different problems.

Use dbt model access when your policy can be expressed as a model interface boundary:

- dbt model access is a first-party dbt governance feature based on `group` and `access`.
- A model can be `private`, `protected`, or `public`.
- `private` models are referenceable only inside the same group.
- `protected` models are referenceable inside the same project or package, and this is the default for backward compatibility.
- `public` models are referenceable by any group, package, or project.
- For installed package projects, access restrictions are off by default unless the package sets `restrict-access: True`.

Use `dbt-authorized-models` when you need an explicit allow-list for individual model, snapshot, or source dependencies:

- Rules live in `meta.authorize` on the referenced model, snapshot, or source.
- Missing or empty rules deny all references.
- Rules match the referencing dbt node's metadata with regular expressions.
- Policies can target properties such as `resource_type`, `database`, `schema`, `identifier`, `tags`, and `package_name`.
- The same mechanism works for `ref()` model and snapshot dependencies, plus `source()` dependencies.
- Enforcement can run in warning mode during rollout, then switch to failing mode.

The two features can be used together. dbt model access is a good default for stable model interface boundaries in dbt Mesh-style projects. This package adds a stricter, code-reviewed dependency allow-list for cases such as sensitive tables, snapshots, source references, schema-specific restrictions, package-specific restrictions, tag-based approval, or gradual adoption in an existing project.

Neither feature grants database permissions. Continue to manage warehouse privileges separately with dbt grants or your platform's access-control system.

## What Gets Checked

The `check_authorization()` macro runs from your root project's `on-run-start` hook.

- For `dbt run` and `dbt build`, dbt usually provides `selected_resources`; the package checks references made by the selected resources.
- For commands such as `dbt compile` or `dbt run-operation`, the package checks all graph nodes when selected resources are not available.
- Referencing resource types in `exclude_resource_types` are skipped.
- By default, tests and analyses are skipped.
- References to dbt models, snapshots, and sources are checked.

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

If a referenced model, snapshot, or source has no `meta.authorize`, it denies all references:

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

Rules are stored under `config.meta.authorize` on the referenced model, snapshot, or source.

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

### Snapshot References

Protect a snapshot that downstream models read with `ref()`:

```sql
{% snapshot customer_snapshot %}
{{
    config(
        target_schema="snapshots",
        unique_key="customer_id",
        strategy="check",
        check_cols=["customer_name"],
        meta={
            "authorize": [
                {
                    "resource_type": "model",
                    "database": ".*",
                    "schema": ".*marts",
                    "identifier": "snapshot_customer_report",
                }
            ]
        },
    )
}}

select * from {{ ref("customers") }}

{% endsnapshot %}
```

When a snapshot references another protected resource, match the snapshot with `resource_type: "snapshot"` in that referenced resource's allow-list.

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

Install the pinned development tools with mise:

```bash
mise install --locked
```

Run the unit tests from the repository root:

```bash
uv run dbt deps --project-dir unit_tests --profiles-dir unit_tests
uv run dbt run-operation run_unit_tests --project-dir unit_tests --profiles-dir unit_tests
```

The unit-test project follows dbt's package unit-testing pattern: each package macro has focused tests under `unit_tests/macros/unit_tests`, and `run_unit_tests` executes them with `dbt run-operation`.

Run the integration project compile check:

```bash
uv run dbt deps --project-dir integration_tests --profiles-dir integration_tests
uv run python integration_tests/assert_project_source_meta.py
uv run dbt compile --project-dir integration_tests --profiles-dir integration_tests
```

Check dbt Fusion compatibility:

```bash
curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --to /tmp/dbt-fusion-bin --update
/tmp/dbt-fusion-bin/dbt deps --project-dir unit_tests --profiles-dir unit_tests
/tmp/dbt-fusion-bin/dbt run-operation run_unit_tests --project-dir unit_tests --profiles-dir unit_tests
/tmp/dbt-fusion-bin/dbt deps --project-dir integration_tests --profiles-dir integration_tests
/tmp/dbt-fusion-bin/dbt parse --project-dir integration_tests --profiles-dir integration_tests
uv run python integration_tests/assert_project_source_meta.py --dbt-executable /tmp/dbt-fusion-bin/dbt
/tmp/dbt-fusion-bin/dbt compile --project-dir integration_tests --profiles-dir integration_tests
```

## License

Apache License 2.0.

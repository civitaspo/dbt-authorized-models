# Integration Tests

This dbt project verifies the `dbt-authorized-models` package against DuckDB.

Run the test macros:

```bash
uv run dbt deps
uv run dbt run-operation test_all_macros --profiles-dir .
```

Run a full compile with the authorization hook enabled:

```bash
uv run dbt compile --profiles-dir .
```

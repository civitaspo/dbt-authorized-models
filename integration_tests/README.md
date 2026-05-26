# Integration Tests

This dbt project verifies the `dbt-authorized-models` package against DuckDB with fixture models and the authorization hook enabled.

Run a full compile with the authorization hook enabled from the repository root:

```bash
uv --project integration_tests run dbt deps --project-dir integration_tests --profiles-dir integration_tests
uv --project integration_tests run dbt compile --project-dir integration_tests --profiles-dir integration_tests
```

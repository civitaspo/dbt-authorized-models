# Unit Tests

This dbt project runs macro-level unit tests for `dbt-authorized-models`.

Run the unit tests from the repository root:

```bash
uv --project integration_tests run dbt deps --project-dir unit_tests --profiles-dir unit_tests
uv --project integration_tests run dbt run-operation run_unit_tests --project-dir unit_tests --profiles-dir unit_tests
```

The tests live in `macros/unit_tests`. Each test macro exercises one package macro directly with `dbt-unittest` assertions, and `run_unit_tests` runs the full suite.

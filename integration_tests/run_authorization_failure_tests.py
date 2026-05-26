from __future__ import annotations

import argparse
import io
import subprocess
import sys
from contextlib import redirect_stderr, redirect_stdout
from dataclasses import dataclass


BASE_DBT_ARGS = [
    "compile",
    "--project-dir",
    "integration_tests",
    "--profiles-dir",
    "integration_tests",
]


@dataclass(frozen=True)
class Scenario:
    name: str
    vars: str
    expected_message: str
    expect_success: bool = False


@dataclass(frozen=True)
class Invocation:
    description: str
    output: str
    success: bool


SCENARIOS = [
    Scenario(
        name="unauthorized source reference",
        vars='{"enable_unauthorized_source_report": true}',
        expected_message=(
            "Referenced:  customers "
            "(source.dbt_authorized_models_integration_tests.raw.customers)"
        ),
    ),
    Scenario(
        name="missing source authorize metadata",
        vars='{"enable_missing_authorize_source_report": true}',
        expected_message="Authorization: deny all because meta.authorize is not defined",
    ),
    Scenario(
        name="empty source authorize metadata",
        vars='{"enable_empty_authorize_source_report": true}',
        expected_message="Authorization: deny all because meta.authorize is empty",
    ),
    Scenario(
        name="warning mode source violation",
        vars=(
            '{"enable_unauthorized_source_report": true, '
            '"dbt_authorized_models": {"enforce": false}}'
        ),
        expected_message="Continuing because dbt_authorized_models.enforce is false",
        expect_success=True,
    ),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run source authorization failure-path integration tests."
    )
    parser.add_argument(
        "--dbt-executable",
        help=(
            "Path to a dbt CLI executable. Omit this to use dbt Core's "
            "programmatic dbtRunner API."
        ),
    )
    return parser.parse_args()


def fail(message: str, invocation: Invocation) -> None:
    print(message, file=sys.stderr)
    print("Invocation: " + invocation.description, file=sys.stderr)
    print(invocation.output, file=sys.stderr)
    raise SystemExit(1)


def invoke_dbt_core(dbt_args: list[str]) -> Invocation:
    from dbt.cli.main import dbtRunner

    stdout = io.StringIO()
    stderr = io.StringIO()

    with redirect_stdout(stdout), redirect_stderr(stderr):
        result = dbtRunner().invoke(dbt_args)

    output = stdout.getvalue() + stderr.getvalue()
    if result.exception is not None:
        output += f"\n{type(result.exception).__name__}: {result.exception}\n"

    return Invocation(
        description="dbtRunner().invoke(" + repr(dbt_args) + ")",
        output=output,
        success=result.success,
    )


def invoke_dbt_executable(dbt_executable: str, dbt_args: list[str]) -> Invocation:
    command = [dbt_executable, *dbt_args]
    completed = subprocess.run(command, capture_output=True, text=True, check=False)

    return Invocation(
        description=" ".join(command),
        output=completed.stdout + completed.stderr,
        success=completed.returncode == 0,
    )


def invoke_dbt(dbt_args: list[str], dbt_executable: str | None) -> Invocation:
    if dbt_executable:
        return invoke_dbt_executable(dbt_executable, dbt_args)

    return invoke_dbt_core(dbt_args)


def run_scenario(scenario: Scenario, dbt_executable: str | None) -> None:
    dbt_args = [
        *BASE_DBT_ARGS,
        "--vars",
        scenario.vars,
    ]
    invocation = invoke_dbt(dbt_args, dbt_executable)

    if scenario.expect_success and not invocation.success:
        fail(f"Expected success but command failed: {scenario.name}", invocation)

    if not scenario.expect_success and invocation.success:
        fail(f"Expected failure but command passed: {scenario.name}", invocation)

    if scenario.expected_message not in invocation.output:
        fail(
            f"Expected message was not found for: {scenario.name}\n"
            f"Expected: {scenario.expected_message}",
            invocation,
        )

    print(f"passed: {scenario.name}")


def main() -> None:
    args = parse_args()
    for scenario in SCENARIOS:
        run_scenario(scenario, args.dbt_executable)


if __name__ == "__main__":
    main()

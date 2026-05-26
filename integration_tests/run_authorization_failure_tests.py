from __future__ import annotations

import argparse
import subprocess
import sys
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
        "--dbt-command",
        nargs="+",
        default=["dbt"],
        help="Command used to invoke dbt, for example: dbt or /path/to/dbt.",
    )
    return parser.parse_args()


def fail(message: str, command: list[str], output: str) -> None:
    print(message, file=sys.stderr)
    print("Command: " + " ".join(command), file=sys.stderr)
    print(output, file=sys.stderr)
    raise SystemExit(1)


def run_scenario(dbt_command: list[str], scenario: Scenario) -> None:
    command = [
        *dbt_command,
        *BASE_DBT_ARGS,
        "--vars",
        scenario.vars,
    ]
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    output = completed.stdout + completed.stderr

    if scenario.expect_success and completed.returncode != 0:
        fail(f"Expected success but command failed: {scenario.name}", command, output)

    if not scenario.expect_success and completed.returncode == 0:
        fail(f"Expected failure but command passed: {scenario.name}", command, output)

    if scenario.expected_message not in output:
        fail(
            f"Expected message was not found for: {scenario.name}\n"
            f"Expected: {scenario.expected_message}",
            command,
            output,
        )

    print(f"passed: {scenario.name}")


def main() -> None:
    args = parse_args()
    for scenario in SCENARIOS:
        run_scenario(args.dbt_command, scenario)


if __name__ == "__main__":
    main()

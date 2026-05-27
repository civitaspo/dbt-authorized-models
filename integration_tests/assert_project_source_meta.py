from __future__ import annotations

import argparse
import io
import json
import subprocess
import sys
from contextlib import redirect_stderr, redirect_stdout
from dataclasses import dataclass
from pathlib import Path


PROJECT_DIR = Path("integration_tests")
PROFILES_DIR = Path("integration_tests")
MANIFEST_PATH = PROJECT_DIR / "target" / "manifest.json"


SOURCE_CASES = {
    "source.dbt_authorized_models_integration_tests.project_meta_source.customers": [
        {
            "resource_type": "model",
            "database": ".*",
            "schema": ".*marts",
            "identifier": "source_project_meta_source_report",
        }
    ],
    "source.dbt_authorized_models_integration_tests.project_meta_table.customers": [
        {
            "resource_type": "model",
            "database": ".*",
            "schema": ".*marts",
            "identifier": "source_project_meta_table_report",
        }
    ],
    "source.dbt_authorized_models_integration_tests.project_meta_source_with_table_meta.customers": [
        "*"
    ],
}


@dataclass(frozen=True)
class Invocation:
    description: str
    output: str
    success: bool


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Assert that source authorization metadata configured in "
            "dbt_project.yml is present in the parsed manifest."
        )
    )
    parser.add_argument(
        "--dbt-executable",
        help=(
            "Path to a dbt CLI executable. Omit this to use dbt Core's "
            "programmatic dbtRunner API."
        ),
    )
    return parser.parse_args()


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


def run_parse(dbt_executable: str | None) -> None:
    if MANIFEST_PATH.exists():
        MANIFEST_PATH.unlink()

    dbt_args = [
        "parse",
        "--project-dir",
        str(PROJECT_DIR),
        "--profiles-dir",
        str(PROFILES_DIR),
    ]
    invocation = invoke_dbt(dbt_args, dbt_executable)

    if not invocation.success:
        print("Invocation: " + invocation.description, file=sys.stderr)
        print(invocation.output, file=sys.stderr)
        raise SystemExit(1)

    if not MANIFEST_PATH.exists():
        print(f"Manifest was not generated at {MANIFEST_PATH}", file=sys.stderr)
        raise SystemExit(1)


def assert_authorize_rules(source_id: str, expected_rules: list[object]) -> None:
    manifest = json.loads(MANIFEST_PATH.read_text())
    source = manifest["sources"].get(source_id)

    if source is None:
        print(f"Source was not found in manifest: {source_id}", file=sys.stderr)
        raise SystemExit(1)

    top_level_rules = source.get("meta", {}).get("authorize")
    config_rules = source.get("config", {}).get("meta", {}).get("authorize")

    if top_level_rules != config_rules:
        print(
            f"Expected top-level meta.authorize to match config.meta.authorize for {source_id}",
            file=sys.stderr,
        )
        raise SystemExit(1)

    if not isinstance(top_level_rules, list):
        print(f"Expected meta.authorize to be a list for {source_id}", file=sys.stderr)
        raise SystemExit(1)

    if top_level_rules != expected_rules:
        print(f"Expected {source_id} to have rules: {expected_rules}", file=sys.stderr)
        print(f"Actual rules: {top_level_rules}", file=sys.stderr)
        raise SystemExit(1)


def main() -> None:
    args = parse_args()
    run_parse(args.dbt_executable)

    for source_id, expected_rules in SOURCE_CASES.items():
        assert_authorize_rules(source_id, expected_rules)
        print(f"passed: {source_id} has expected meta.authorize")


if __name__ == "__main__":
    main()

#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  dbt_cmd=(dbt)
else
  dbt_cmd=("$@")
fi

run_expect_failure() {
  local name="$1"
  local expected_message="$2"
  shift 2

  set +e
  local output
  output="$("${dbt_cmd[@]}" "$@" 2>&1)"
  local status="$?"
  set -e

  if [ "$status" -eq 0 ]; then
    printf '%s\n' "Expected failure but command passed: ${name}"
    printf '%s\n' "$output"
    return 1
  fi

  if ! grep -Fq "$expected_message" <<<"$output"; then
    printf '%s\n' "Expected message was not found for: ${name}"
    printf '%s\n' "Expected: ${expected_message}"
    printf '%s\n' "$output"
    return 1
  fi
}

run_expect_success() {
  local name="$1"
  local expected_message="$2"
  shift 2

  local output
  output="$("${dbt_cmd[@]}" "$@" 2>&1)"

  if ! grep -Fq "$expected_message" <<<"$output"; then
    printf '%s\n' "Expected message was not found for: ${name}"
    printf '%s\n' "Expected: ${expected_message}"
    printf '%s\n' "$output"
    return 1
  fi
}

run_expect_failure \
  "unauthorized source reference" \
  "Referenced:  customers (source.dbt_authorized_models_integration_tests.raw.customers)" \
  compile \
  --project-dir integration_tests \
  --profiles-dir integration_tests \
  --vars '{"enable_unauthorized_source_report": true}'

run_expect_failure \
  "missing source authorize metadata" \
  "Authorization: deny all because meta.authorize is not defined" \
  compile \
  --project-dir integration_tests \
  --profiles-dir integration_tests \
  --vars '{"enable_missing_authorize_source_report": true}'

run_expect_failure \
  "empty source authorize metadata" \
  "Authorization: deny all because meta.authorize is empty" \
  compile \
  --project-dir integration_tests \
  --profiles-dir integration_tests \
  --vars '{"enable_empty_authorize_source_report": true}'

run_expect_success \
  "warning mode source violation" \
  "Continuing because dbt_authorized_models.enforce is false" \
  compile \
  --project-dir integration_tests \
  --profiles-dir integration_tests \
  --vars '{"enable_unauthorized_source_report": true, "dbt_authorized_models": {"enforce": false}}'

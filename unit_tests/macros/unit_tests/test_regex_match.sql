{% macro test_regex_match() %}
  {{ dbt_unittest.assert_true(dbt_authorized_models.regex_match('exact', 'exact')) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.regex_match('exact', 'different')) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.regex_match('exact', 'exactly')) }}

  {{ dbt_unittest.assert_true(dbt_authorized_models.regex_match('.*', 'anything')) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.regex_match('rpt_.*', 'rpt_sales')) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.regex_match('rpt_.*', 'stg_sales')) }}

  {{ dbt_unittest.assert_true(dbt_authorized_models.regex_match('^finance$', 'finance')) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.regex_match('^finance$', 'finance_ops')) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.regex_match('analytics\\.prod', 'analytics.prod')) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.regex_match('analytics\\.prod', 'analytics_prod')) }}

  {{ dbt_unittest.assert_true(dbt_authorized_models.regex_match('finance|compliance', 'finance')) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.regex_match('finance|compliance', 'compliance')) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.regex_match('finance|compliance', 'marketing')) }}
{% endmacro %}

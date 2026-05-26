{% macro test_matches_rule() %}
  {% set node = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'identifier': 'customers',
    'name': 'customer_model',
    'tags': ['finance']
  } %}

  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule('*', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'resource_type': 'model'}, node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'name': 'customer_model'}, node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts'}, node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'identifier': 'customers', 'tags': 'finance'}, node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'alias': 'customers'}, node)) }}

  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_rule({'resource_type': 'snapshot'}, node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'staging'}, node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'identifier': 'customers', 'tags': 'pii'}, node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_rule({'name': 'orders'}, node)) }}
{% endmacro %}

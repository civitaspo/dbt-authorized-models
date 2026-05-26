{% macro test_matches_property() %}
  {% set node = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'identifier': 'customers',
    'alias': 'customers_v2',
    'name': 'customer_model',
    'tags': ['finance', 'pii'],
    'package_name': 'analytics_app'
  } %}

  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('resource_type', 'model', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('database', 'analytics', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('schema', 'marts', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('identifier', 'customers', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('alias', 'customers_v2', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('name', 'customer_model', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('tags', 'finance', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('tags', 'p.*', node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('package_name', 'analytics_app', node)) }}

  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_property('resource_type', 'snapshot', node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_property('database', 'warehouse', node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_property('schema', 'staging', node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_property('tags', 'marketing', node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_property('package_name', 'external_app', node)) }}

  {% set node_with_alias_only = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'alias': 'dim_customers',
    'name': 'customers'
  } %}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('identifier', 'dim_customers', node_with_alias_only)) }}

  {% set node_with_name_only = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'name': 'orders'
  } %}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('identifier', 'orders', node_with_name_only)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('alias', 'orders', node_with_name_only)) }}

  {% set node_with_string_tag = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'identifier': 'daily_finance',
    'tags': 'finance'
  } %}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('tags', 'finance', node_with_string_tag)) }}

  {% set node_without_tags = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'identifier': 'daily_finance'
  } %}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_property('tags', 'finance', node_without_tags)) }}
{% endmacro %}

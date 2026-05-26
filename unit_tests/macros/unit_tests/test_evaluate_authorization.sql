{% macro test_evaluate_authorization() %}
  {% set referencing_node = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'identifier': 'customers',
    'alias': 'dim_customers',
    'name': 'customers',
    'tags': ['finance', 'pii_approved'],
    'package_name': 'analytics_app'
  } %}
  {% set referenced_node = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'staging',
    'identifier': 'stg_customers',
    'name': 'stg_customers'
  } %}

  {{ dbt_unittest.assert_false(dbt_authorized_models.evaluate_authorization(none, referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.evaluate_authorization([], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization(['*'], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization('*', referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization([{'package_name': 'analytics_app'}], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization([{'resource_type': 'model', 'database': 'analytics', 'schema': 'marts'}], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization([
    {'resource_type': 'model', 'database': 'analytics', 'schema': 'restricted'},
    {'resource_type': 'model', 'database': 'analytics', 'schema': 'marts'}
  ], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization([
    {'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'alias': 'dim_customers'}
  ], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization([
    {'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'identifier': '.*', 'tags': 'pii_approved'}
  ], referencing_node, referenced_node)) }}

  {{ dbt_unittest.assert_false(dbt_authorized_models.evaluate_authorization([{'package_name': 'external_app'}], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.evaluate_authorization([{'resource_type': 'model', 'database': 'analytics', 'schema': 'restricted'}], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.evaluate_authorization([
    {'resource_type': 'snapshot'},
    {'resource_type': 'model', 'database': 'analytics', 'schema': 'restricted'}
  ], referencing_node, referenced_node)) }}
{% endmacro %}

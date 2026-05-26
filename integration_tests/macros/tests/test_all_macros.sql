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
{% endmacro %}

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
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_property('tags', 'marketing', node)) }}

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

  {% set node_with_string_tag = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'identifier': 'daily_finance',
    'tags': 'finance'
  } %}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_property('tags', 'finance', node_with_string_tag)) }}
{% endmacro %}

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
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts'}, node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'identifier': 'customers', 'tags': 'finance'}, node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'alias': 'customers'}, node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.matches_rule({'name': 'customer_model'}, node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_rule({'resource_type': 'snapshot'}, node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'staging'}, node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.matches_rule({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'identifier': 'customers', 'tags': 'pii'}, node)) }}
{% endmacro %}

{% macro test_evaluate_authorization() %}
  {% set referencing_node = {
    'resource_type': 'model',
    'database': 'analytics',
    'schema': 'marts',
    'identifier': 'customers',
    'name': 'customers',
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
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization([{'resource_type': 'model', 'database': 'analytics', 'schema': 'marts'}], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization([
    {'resource_type': 'model', 'database': 'analytics', 'schema': 'restricted'},
    {'resource_type': 'model', 'database': 'analytics', 'schema': 'marts'}
  ], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_true(dbt_authorized_models.evaluate_authorization([{'package_name': 'analytics_app'}], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.evaluate_authorization([{'resource_type': 'model', 'database': 'analytics', 'schema': 'restricted'}], referencing_node, referenced_node)) }}
  {{ dbt_unittest.assert_false(dbt_authorized_models.evaluate_authorization([
    {'resource_type': 'snapshot'},
    {'resource_type': 'model', 'database': 'analytics', 'schema': 'restricted'}
  ], referencing_node, referenced_node)) }}
{% endmacro %}

{% macro test_validate_rule_hierarchy() %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'resource_type': 'model'}) %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'resource_type': 'model', 'database': 'analytics'}) %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts'}) %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'identifier': '.*'}) %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'alias': '.*'}) %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'identifier': '.*', 'tags': 'finance'}) %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'resource_type': 'model', 'database': 'analytics', 'schema': 'marts', 'alias': '.*', 'tags': 'finance'}) %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'name': 'customer_model'}) %}
  {% do dbt_authorized_models.validate_rule_hierarchy({'package_name': 'analytics_app'}) %}
{% endmacro %}

{% macro test_all_macros() %}
  {% do test_regex_match() %}
  {% do test_matches_property() %}
  {% do test_matches_rule() %}
  {% do test_evaluate_authorization() %}
  {% do test_validate_rule_hierarchy() %}

  {{ log("All dbt-authorized-models macro tests passed.", info=true) }}
{% endmacro %}

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

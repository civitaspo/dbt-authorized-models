{% macro test_get_referenced_node() %}
  {% set graph_context = {
    'nodes': {
      'model.analytics.customers': {
        'resource_type': 'model',
        'name': 'customers'
      },
      'snapshot.analytics.customer_snapshot': {
        'resource_type': 'snapshot',
        'name': 'customer_snapshot'
      }
    },
    'sources': {
      'source.analytics.raw.customers': {
        'resource_type': 'source',
        'source_name': 'raw',
        'name': 'customers'
      }
    }
  } %}

  {% set model_node = dbt_authorized_models.get_referenced_node('model.analytics.customers', graph_context) %}
  {{ dbt_unittest.assert_equals(model_node.get('resource_type'), 'model') }}
  {{ dbt_unittest.assert_equals(model_node.get('name'), 'customers') }}

  {% set snapshot_node = dbt_authorized_models.get_referenced_node('snapshot.analytics.customer_snapshot', graph_context) %}
  {{ dbt_unittest.assert_equals(snapshot_node.get('resource_type'), 'snapshot') }}
  {{ dbt_unittest.assert_equals(snapshot_node.get('name'), 'customer_snapshot') }}

  {% set source_node = dbt_authorized_models.get_referenced_node('source.analytics.raw.customers', graph_context) %}
  {{ dbt_unittest.assert_equals(source_node.get('resource_type'), 'source') }}
  {{ dbt_unittest.assert_equals(source_node.get('source_name'), 'raw') }}

  {{ dbt_unittest.assert_is_none(dbt_authorized_models.get_referenced_node('model.analytics.missing', graph_context)) }}
{% endmacro %}

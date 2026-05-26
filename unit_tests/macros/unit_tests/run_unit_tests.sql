{% macro run_unit_tests() %}
  {% do test_regex_match() %}
  {% do test_matches_property() %}
  {% do test_matches_rule() %}
  {% do test_get_referenced_node() %}
  {% do test_evaluate_authorization() %}
  {% do test_validate_rule_hierarchy() %}

  {{ log("All dbt-authorized-models unit tests passed.", info=true) }}
{% endmacro %}

{% macro test_all_macros() %}
  {% do return(run_unit_tests()) %}
{% endmacro %}

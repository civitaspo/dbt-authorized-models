{#
  Entry point for authorization checks.

  Add this macro to the root project's on-run-start hooks:
    on-run-start:
      - "{{ dbt_authorized_models.check_authorization() }}"
#}
{% macro check_authorization() %}
  {{ return(adapter.dispatch('check_authorization', 'dbt_authorized_models')()) }}
{% endmacro %}

{% macro default__check_authorization() %}
  {% if graph is not defined or graph is none or graph.nodes is not defined %}
    {{ return('') }}
  {% endif %}

  {% set authorization_config = var('dbt_authorized_models', {}) %}
  {% set enforce = authorization_config.get('enforce', true) %}
  {% set exclude_types = authorization_config.get('exclude_resource_types', ['test', 'analysis']) %}

  {% set ns = namespace(
    violations=[],
    total_checks=0
  ) %}

  {% set nodes_to_check = {} %}
  {% if selected_resources is defined and selected_resources is not none and selected_resources | length > 0 %}
    {% for node_id in selected_resources %}
      {% set node = graph.nodes.get(node_id) %}
      {% if node %}
        {% do nodes_to_check.update({node_id: node}) %}
      {% endif %}
    {% endfor %}
  {% else %}
    {% set nodes_to_check = graph.nodes %}
  {% endif %}

  {% for node_id, node in nodes_to_check.items() %}
    {% set referencing_type = node.get('resource_type', '') %}

    {% if referencing_type not in exclude_types %}
      {% set depends_on = node.get('depends_on', {}) %}
      {% set ref_nodes = depends_on.get('nodes', []) %}

      {% for referenced_id in ref_nodes %}
        {% set referenced_node = dbt_authorized_models.get_referenced_node(referenced_id, graph) %}

        {% if referenced_node %}
          {% set ns.total_checks = ns.total_checks + 1 %}
          {% set referenced_meta = referenced_node.get('meta', {}) %}
          {% set auth_rules = referenced_meta.get('authorize') %}
          {% set is_authorized = dbt_authorized_models.evaluate_authorization(
              auth_rules,
              node,
              referenced_node
            )
          %}

          {% if not is_authorized %}
            {% set violation = {
              'referencing_id': node_id,
              'referencing_name': node.get('name', node_id),
              'referenced_id': referenced_id,
              'referenced_name': referenced_node.get('name', referenced_id),
              'auth_rules': auth_rules
            } %}
            {% do ns.violations.append(violation) %}
          {% endif %}
        {% endif %}
      {% endfor %}
    {% endif %}
  {% endfor %}

  {% if ns.violations | length > 0 %}
    {{ log("", info=true) }}
    {{ log("=" * 80, info=true) }}
    {{ log("Authorization check failed", info=true) }}
    {{ log("=" * 80, info=true) }}
    {{ log("", info=true) }}
    {{ log("Found " ~ ns.violations | length ~ " authorization violation(s):", info=true) }}
    {{ log("", info=true) }}

    {% for violation in ns.violations %}
      {{ log("Violation " ~ loop.index ~ ":", info=true) }}
      {{ log("  Referencing: " ~ violation.referencing_name ~ " (" ~ violation.referencing_id ~ ")", info=true) }}
      {{ log("  Referenced:  " ~ violation.referenced_name ~ " (" ~ violation.referenced_id ~ ")", info=true) }}

      {% if violation.auth_rules is none %}
        {{ log("  Authorization: deny all because meta.authorize is not defined", info=true) }}
      {% elif violation.auth_rules | length == 0 %}
        {{ log("  Authorization: deny all because meta.authorize is empty", info=true) }}
      {% else %}
        {{ log("  Authorization rules:", info=true) }}
        {% for rule in violation.auth_rules %}
          {{ log("    - " ~ rule, info=true) }}
        {% endfor %}
      {% endif %}
      {{ log("", info=true) }}
    {% endfor %}

    {{ log("=" * 80, info=true) }}

    {% if enforce %}
      {{ exceptions.raise_compiler_error("Authorization check failed with " ~ ns.violations | length ~ " violation(s). Set dbt_authorized_models.enforce to false to warn only.") }}
    {% else %}
      {{ log("Continuing because dbt_authorized_models.enforce is false", info=true) }}
    {% endif %}
  {% else %}
    {{ log("Authorization check passed (" ~ ns.total_checks ~ " references checked)", info=true) }}
  {% endif %}

  {% do return('') %}
{% endmacro %}

{#
  Return a referenced resource from the dbt graph.
#}
{% macro get_referenced_node(referenced_id, graph_context) %}
  {% set graph_nodes = graph_context.nodes if graph_context.nodes is defined and graph_context.nodes is not none else {} %}
  {% set graph_sources = graph_context.sources if graph_context.sources is defined and graph_context.sources is not none else {} %}
  {% set referenced_node = graph_nodes.get(referenced_id) %}

  {% if referenced_node is none %}
    {% set referenced_node = graph_sources.get(referenced_id) %}
  {% endif %}

  {{ return(referenced_node) }}
{% endmacro %}

{#
  Evaluate whether a referencing node is authorized to reference a protected node.
#}
{% macro evaluate_authorization(auth_rules, referencing_node, referenced_node) %}
  {% if auth_rules is none %}
    {{ return(false) }}
  {% endif %}

  {% if auth_rules is string %}
    {% if auth_rules == "*" %}
      {{ return(true) }}
    {% else %}
      {{ exceptions.raise_compiler_error("meta.authorize must be a list of rules or the wildcard '*'. Got string: " ~ auth_rules) }}
    {% endif %}
  {% endif %}

  {% if auth_rules is mapping %}
    {{ exceptions.raise_compiler_error("meta.authorize must be a list of rules. Wrap the rule object in a list.") }}
  {% endif %}

  {% if auth_rules | length == 0 %}
    {{ return(false) }}
  {% endif %}

  {% for rule in auth_rules %}
    {% if dbt_authorized_models.matches_rule(rule, referencing_node) %}
      {{ return(true) }}
    {% endif %}
  {% endfor %}

  {{ return(false) }}
{% endmacro %}

{#
  Validate hierarchy constraints for one authorization rule.
#}
{% macro validate_rule_hierarchy(rule) %}
  {% set hierarchy = [
    ['resource_type'],
    ['database'],
    ['schema'],
    ['identifier', 'alias'],
    ['tags']
  ] %}
  {% set properties = rule.keys() | list %}

  {% set ns = namespace(max_level=-1) %}
  {% for prop in properties %}
    {% for level_idx in range(hierarchy | length) %}
      {% if prop in hierarchy[level_idx] and level_idx > ns.max_level %}
        {% set ns.max_level = level_idx %}
      {% endif %}
    {% endfor %}
  {% endfor %}

  {% if ns.max_level >= 0 %}
    {% for level_idx in range(ns.max_level) %}
      {% set level_props = hierarchy[level_idx] %}
      {% set has_prop = namespace(found=false) %}

      {% for prop in level_props %}
        {% if prop in properties %}
          {% set has_prop.found = true %}
        {% endif %}
      {% endfor %}

      {% if not has_prop.found %}
        {% set missing_levels = [] %}
        {% for i in range(level_idx + 1) %}
          {% set has_any = namespace(found=false) %}
          {% for p in hierarchy[i] %}
            {% if p in properties %}
              {% set has_any.found = true %}
            {% endif %}
          {% endfor %}
          {% if not has_any.found %}
            {% do missing_levels.append('[' ~ hierarchy[i] | join(' or ') ~ ']') %}
          {% endif %}
        {% endfor %}

        {{ exceptions.raise_compiler_error(
          "Invalid authorization rule. Missing parent properties: " ~ missing_levels | join(', ') ~ ". Rule: " ~ rule
        ) }}
      {% endif %}
    {% endfor %}
  {% endif %}
{% endmacro %}

{#
  Check whether a node matches one authorization rule.
#}
{% macro matches_rule(rule, node) %}
  {% if rule == "*" %}
    {{ return(true) }}
  {% endif %}

  {% if rule is not mapping %}
    {{ exceptions.raise_compiler_error("Authorization rule must be an object or the wildcard '*'. Got: " ~ rule) }}
  {% endif %}

  {% if rule | length == 0 %}
    {{ exceptions.raise_compiler_error("Authorization rule objects must contain at least one property.") }}
  {% endif %}

  {% do dbt_authorized_models.validate_rule_hierarchy(rule) %}

  {% for property, pattern in rule.items() %}
    {% if not dbt_authorized_models.matches_property(property, pattern, node) %}
      {{ return(false) }}
    {% endif %}
  {% endfor %}

  {{ return(true) }}
{% endmacro %}

{#
  Check whether one node property matches a regular-expression pattern.
#}
{% macro matches_property(property, pattern, node) %}
  {% set value = none %}

  {% if property == "database" %}
    {% set value = node.get('database', '') %}
  {% elif property == "schema" %}
    {% set value = node.get('schema', '') %}
  {% elif property == "identifier" %}
    {% set value = node.get('identifier', '') or node.get('alias', '') or node.get('name', '') %}
  {% elif property == "alias" %}
    {% set value = node.get('alias', '') or node.get('identifier', '') or node.get('name', '') %}
  {% elif property == "name" %}
    {% set value = node.get('name', '') %}
  {% elif property == "tags" %}
    {% set node_tags = node.get('tags', []) %}
    {% if node_tags is string %}
      {% set node_tags = [node_tags] %}
    {% endif %}
    {% for tag in node_tags %}
      {% if dbt_authorized_models.regex_match(pattern, tag) %}
        {{ return(true) }}
      {% endif %}
    {% endfor %}
    {{ return(false) }}
  {% elif property == "resource_type" %}
    {% set value = node.get('resource_type', '') %}
  {% elif property == "package_name" %}
    {% set value = node.get('package_name', '') %}
  {% else %}
    {{ exceptions.raise_compiler_error("Unsupported authorization property: '" ~ property ~ "'. Supported properties are resource_type, database, schema, identifier, alias, name, tags, and package_name.") }}
  {% endif %}

  {{ return(dbt_authorized_models.regex_match(pattern, value)) }}
{% endmacro %}

{#
  Match a value against a full-string regular-expression pattern.
#}
{% macro regex_match(pattern, value) %}
  {% set pattern_str = pattern | string %}
  {% set value_str = value | string %}
  {% set anchored_pattern = pattern_str %}

  {% if not pattern_str.startswith("^") %}
    {% set anchored_pattern = "^" ~ anchored_pattern %}
  {% endif %}
  {% if not pattern_str.endswith("$") %}
    {% set anchored_pattern = anchored_pattern ~ "$" %}
  {% endif %}

  {% set match_result = modules.re.match(anchored_pattern, value_str) %}
  {{ return(match_result is not none) }}
{% endmacro %}

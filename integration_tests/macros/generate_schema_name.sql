{#- Use custom schema names as they are, so the fixture lands in 'segment_web'. -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name if custom_schema_name else target.schema }}
{%- endmacro %}

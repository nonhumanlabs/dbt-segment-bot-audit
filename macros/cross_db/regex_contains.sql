{#- Returns a boolean expression: true when `expression` contains a match for `pattern`.
    Write patterns in lowercase, without backslashes and without single quotes. -#}
{% macro regex_contains(expression, pattern) -%}
    {{ return(adapter.dispatch('regex_contains', 'segment_bot_audit')(expression, pattern)) }}
{%- endmacro %}

{% macro default__regex_contains(expression, pattern) -%}
    ({{ expression }} ~ '{{ pattern }}')
{%- endmacro %}

{% macro bigquery__regex_contains(expression, pattern) -%}
    regexp_contains({{ expression }}, r'{{ pattern }}')
{%- endmacro %}

{% macro snowflake__regex_contains(expression, pattern) -%}
    (regexp_instr({{ expression }}, '{{ pattern }}') > 0)
{%- endmacro %}

{% macro duckdb__regex_contains(expression, pattern) -%}
    regexp_matches({{ expression }}, '{{ pattern }}')
{%- endmacro %}

{% macro databricks__regex_contains(expression, pattern) -%}
    ({{ expression }} rlike '{{ pattern }}')
{%- endmacro %}

{% macro spark__regex_contains(expression, pattern) -%}
    ({{ expression }} rlike '{{ pattern }}')
{%- endmacro %}

{#- Converts a dotted IPv4 string to an integer. Returns null for other values. -#}
{% macro ipv4_part(expression, part) -%}
    {{ dbt.safe_cast(dbt.split_part(expression, "'.'", part), dbt.type_bigint()) }}
{%- endmacro %}

{% macro ipv4_to_int(expression) -%}
    case when {{ segment_bot_audit.regex_contains(expression, '^[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}$') }} then
        {{ segment_bot_audit.ipv4_part(expression, 1) }} * 16777216
        + {{ segment_bot_audit.ipv4_part(expression, 2) }} * 65536
        + {{ segment_bot_audit.ipv4_part(expression, 3) }} * 256
        + {{ segment_bot_audit.ipv4_part(expression, 4) }}
    end
{%- endmacro %}

{% macro ipv4_first_octet(expression) -%}
    case when {{ segment_bot_audit.regex_contains(expression, '^[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}$') }} then
        {{ segment_bot_audit.ipv4_part(expression, 1) }}
    end
{%- endmacro %}

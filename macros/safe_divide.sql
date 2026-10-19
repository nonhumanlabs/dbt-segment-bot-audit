{#- Placeholder macro. Replace it with the real macro. -#}
{% macro safe_divide(numerator, denominator) -%}
    {{ return(adapter.dispatch('safe_divide', 'nonhumanlabs')(numerator, denominator)) }}
{%- endmacro %}

{% macro default__safe_divide(numerator, denominator) -%}
    case when ({{ denominator }}) = 0 then null
         else ({{ numerator }}) * 1.0 / ({{ denominator }}) end
{%- endmacro %}

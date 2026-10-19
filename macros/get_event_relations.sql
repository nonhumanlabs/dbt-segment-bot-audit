{#- Returns the Segment tables to audit, as a list of mappings with
    `relation`, `event_type` and the actual column names that exist. -#}
{% macro get_event_relations() %}
    {% set sources = var('segment_bot_audit_sources') %}
    {% if sources | length == 0 %}
        {{ exceptions.raise_compiler_error(
            "segment_bot_audit: set the var 'segment_bot_audit_sources' to the list of your Segment schemas.") }}
    {% endif %}

    {% set found = [] %}
    {% for source in sources %}
        {% if source is mapping %}
            {% set database = source.get('database', target.database) %}
            {% set schema = source['schema'] %}
        {% else %}
            {% set database = target.database %}
            {% set schema = source %}
        {% endif %}

        {% for table in ['pages', 'tracks', 'identifies'] %}
            {% set relation = adapter.get_relation(database=database, schema=schema, identifier=table) %}
            {% if relation is not none %}
                {% set columns = {} %}
                {% for column in adapter.get_columns_in_relation(relation) %}
                    {% do columns.update({column.name | lower: column.name}) %}
                {% endfor %}
                {% do found.append({'relation': relation, 'schema': schema, 'event_type': table, 'columns': columns}) %}
            {% endif %}
        {% endfor %}
    {% endfor %}

    {% if found | length == 0 %}
        {{ exceptions.raise_compiler_error(
            "segment_bot_audit: no pages, tracks or identifies table was found in " ~ sources | join(', ')) }}
    {% endif %}
    {{ return(found) }}
{% endmacro %}

{#- Selects a column when it exists, or a typed null when it does not. -#}
{% macro column_or_null(columns, names, data_type) %}
    {%- for name in names -%}
        {%- if name in columns -%}
            {{ return('cast(' ~ adapter.quote(columns[name]) ~ ' as ' ~ data_type ~ ')') }}
        {%- endif -%}
    {%- endfor -%}
    {{ return('cast(null as ' ~ data_type ~ ')') }}
{% endmacro %}

{% macro audit_end_timestamp() -%}
    {%- set end_date = var('segment_bot_audit_end_date') -%}
    {%- if end_date -%}
        cast('{{ end_date }}' as {{ dbt.type_timestamp() }})
    {%- else -%}
        cast({{ dbt.current_timestamp() }} as {{ dbt.type_timestamp() }})
    {%- endif -%}
{%- endmacro %}

{% macro audit_start_timestamp() -%}
    cast({{ dbt.dateadd('month', -1 * var('segment_bot_audit_lookback_months'), segment_bot_audit.audit_end_timestamp()) }}
        as {{ dbt.type_timestamp() }})
{%- endmacro %}

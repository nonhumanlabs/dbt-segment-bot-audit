{#- One row for each Segment event in the audit window, from all configured
    schemas. Tables or columns that do not exist become nulls. -#}

{%- set string_type = dbt.type_string() -%}
{%- set timestamp_type = dbt.type_timestamp() -%}

with unioned as (
{%- if execute %}
    {%- for source in segment_bot_audit.get_event_relations() %}
    {%- set ts = segment_bot_audit.column_or_null(source.columns, ['timestamp', 'received_at'], timestamp_type) %}
    {%- set path_columns = ['path', 'context_page_path'] if source.event_type == 'pages' else ['context_page_path'] %}
    select
        '{{ source.schema }}' as source_schema,
        '{{ source.event_type }}' as event_type,
        {{ segment_bot_audit.column_or_null(source.columns, ['anonymous_id'], string_type) }} as anonymous_id,
        {{ segment_bot_audit.column_or_null(source.columns, ['user_id'], string_type) }} as user_id,
        {{ ts }} as event_at,
        {{ segment_bot_audit.column_or_null(source.columns, ['context_ip'], string_type) }} as context_ip,
        {{ segment_bot_audit.column_or_null(source.columns, ['context_user_agent'], string_type) }} as context_user_agent,
        {{ segment_bot_audit.column_or_null(source.columns, path_columns, string_type) }} as page_path
    from {{ source.relation }}
    where {{ ts }} >= {{ segment_bot_audit.audit_start_timestamp() }}
      and {{ ts }} < {{ segment_bot_audit.audit_end_timestamp() }}
    {% if not loop.last %}union all{% endif %}
    {%- endfor %}
{%- else %}
    select
        cast(null as {{ string_type }}) as source_schema,
        cast(null as {{ string_type }}) as event_type,
        cast(null as {{ string_type }}) as anonymous_id,
        cast(null as {{ string_type }}) as user_id,
        cast(null as {{ timestamp_type }}) as event_at,
        cast(null as {{ string_type }}) as context_ip,
        cast(null as {{ string_type }}) as context_user_agent,
        cast(null as {{ string_type }}) as page_path
{%- endif %}
)

select
    source_schema,
    event_type,
    anonymous_id,
    user_id,
    coalesce(anonymous_id, user_id) as visitor_key,
    event_at,
    {{ dbt.date_trunc('month', 'event_at') }} as activity_month,
    case when context_ip in ('', '0.0.0.0', '::') then null else context_ip end as context_ip,
    case when context_user_agent = '' then null else context_user_agent end as context_user_agent,
    lower(context_user_agent) as user_agent_lower,
    lower(page_path) as page_path_lower
from unioned
where coalesce(anonymous_id, user_id) is not null

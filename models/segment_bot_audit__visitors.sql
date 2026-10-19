{#- One row for each visitor (MTU) in each month, with each signal and the verdict.
    Strong signals are enough alone. Weak signals count only when both are present.
    Identified visitors (with a user_id) are never counted as non-human. -#}

with events as (
    select * from {{ ref('int_sba__events') }}
),

datacenter_ips as (
    select * from {{ ref('int_sba__datacenter_ips') }}
),

visitors as (
    select
        events.activity_month,
        events.visitor_key,
        max(case when events.user_id is not null then 1 else 0 end) as is_identified,
        max(case when events.context_ip is not null then 1 else 0 end) as has_ip,
        count(*) as event_count,
        sum(case when events.event_type = 'pages' then 1 else 0 end) as page_count,
        max(case
            when events.user_agent_lower is not null
                and {{ segment_bot_audit.regex_contains('events.user_agent_lower', segment_bot_audit.bot_user_agent_pattern()) }}
                and not {{ segment_bot_audit.regex_contains('events.user_agent_lower', segment_bot_audit.bot_user_agent_exclusion_pattern()) }}
            then 1 else 0
        end) as signal_bot_user_agent,
        max(case
            when events.event_type = 'pages'
                and events.user_agent_lower is not null
                and (
                    {{ dbt.length('events.user_agent_lower') }} < {{ var('segment_bot_audit_min_ua_length') }}
                    or events.user_agent_lower not like 'mozilla/%'
                )
            then 1 else 0
        end) as signal_malformed_user_agent,
        max(case
            when events.event_type = 'pages'
                and events.page_path_lower is not null
                and {{ segment_bot_audit.regex_contains('events.page_path_lower', segment_bot_audit.scanner_path_pattern()) }}
            then 1 else 0
        end) as signal_scanner_path,
        max(case when datacenter_ips.ip is not null then 1 else 0 end) as signal_datacenter_ip
    from events
    left join datacenter_ips
        on datacenter_ips.ip = events.context_ip
    group by events.activity_month, events.visitor_key
),

combined as (
    select
        visitors.*,
        coalesce(timing.signal_fast_pages, 0) as signal_fast_pages,
        coalesce(timing.signal_regular_interval, 0) as signal_regular_interval,
        case when bursts.visitor_key is not null then 1 else 0 end as signal_ip_ua_burst
    from visitors
    left join {{ ref('int_sba__page_timing') }} as timing
        on timing.visitor_key = visitors.visitor_key
        and timing.activity_month = visitors.activity_month
    left join {{ ref('int_sba__ip_ua_bursts') }} as bursts
        on bursts.visitor_key = visitors.visitor_key
        and bursts.activity_month = visitors.activity_month
)

select
    *,
    case
        when is_identified = 1 then 0
        when signal_bot_user_agent + signal_malformed_user_agent + signal_scanner_path
            + signal_fast_pages + signal_regular_interval > 0 then 1
        when signal_datacenter_ip = 1 and signal_ip_ua_burst = 1 then 1
        else 0
    end as is_non_human,
    case
        when is_identified = 1 then null
        when signal_bot_user_agent = 1 then 'bot_user_agent'
        when signal_malformed_user_agent = 1 then 'malformed_user_agent'
        when signal_scanner_path = 1 then 'scanner_path'
        when signal_fast_pages = 1 then 'fast_pages'
        when signal_regular_interval = 1 then 'regular_interval'
        when signal_datacenter_ip = 1 and signal_ip_ua_burst = 1 then 'datacenter_ip_burst'
    end as primary_reason
from combined

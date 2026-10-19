{#- Visitors that share an IP address and a user agent with many other new IDs in the same hour. -#}

with events as (
    select
        visitor_key,
        activity_month,
        context_ip,
        context_user_agent,
        {{ dbt.date_trunc('hour', 'event_at') }} as event_hour
    from {{ ref('int_sba__events') }}
    where context_ip is not null
      and context_user_agent is not null
),

bursts as (
    select context_ip, context_user_agent, event_hour
    from events
    group by context_ip, context_user_agent, event_hour
    having count(distinct visitor_key) >= {{ var('segment_bot_audit_burst_min_ids') }}
)

select distinct
    events.visitor_key,
    events.activity_month
from events
inner join bursts
    on bursts.context_ip = events.context_ip
    and bursts.context_user_agent = events.context_user_agent
    and bursts.event_hour = events.event_hour

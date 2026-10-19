{#- Timing signals from the gaps between the page calls of each visitor in each month. -#}

with pages as (
    select
        visitor_key,
        activity_month,
        event_at,
        lag(event_at) over (partition by visitor_key, activity_month order by event_at) as previous_event_at
    from {{ ref('int_sba__events') }}
    where event_type = 'pages'
),

gaps as (
    select
        visitor_key,
        activity_month,
        {{ dbt.datediff('previous_event_at', 'event_at', 'millisecond') }} as gap_ms
    from pages
    where previous_event_at is not null
),

summary as (
    select
        visitor_key,
        activity_month,
        count(*) as gap_count,
        sum(case when gap_ms < {{ var('segment_bot_audit_fast_gap_ms') }} then 1 else 0 end) as fast_gap_count,
        avg(cast(gap_ms as {{ dbt.type_float() }})) as avg_gap_ms,
        stddev_samp(cast(gap_ms as {{ dbt.type_float() }})) as stddev_gap_ms
    from gaps
    group by visitor_key, activity_month
)

select
    visitor_key,
    activity_month,
    gap_count,
    fast_gap_count,
    avg_gap_ms,
    stddev_gap_ms,
    case when fast_gap_count >= {{ var('segment_bot_audit_min_fast_gaps') }} then 1 else 0 end as signal_fast_pages,
    case
        when gap_count >= {{ var('segment_bot_audit_min_regular_gaps') }}
            and avg_gap_ms >= 1000
            and avg_gap_ms <= 600000
            and stddev_gap_ms / avg_gap_ms <= {{ var('segment_bot_audit_max_regular_cv') }}
        then 1 else 0
    end as signal_regular_interval
from summary

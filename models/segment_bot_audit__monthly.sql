{#- MTUs, non-human MTUs and the estimated cost for each month. -#}

select
    activity_month,
    count(*) as total_mtus,
    sum(is_non_human) as non_human_mtus,
    round(100.0 * sum(is_non_human) / count(*), 2) as non_human_pct,
    round(sum(is_non_human) * {{ var('segment_bot_audit_price_per_1000_mtus') }} / 1000.0, 2) as estimated_cost_usd,
    sum(case when primary_reason = 'bot_user_agent' then 1 else 0 end) as bot_user_agent_mtus,
    sum(case when primary_reason = 'malformed_user_agent' then 1 else 0 end) as malformed_user_agent_mtus,
    sum(case when primary_reason = 'scanner_path' then 1 else 0 end) as scanner_path_mtus,
    sum(case when primary_reason = 'fast_pages' then 1 else 0 end) as fast_pages_mtus,
    sum(case when primary_reason = 'regular_interval' then 1 else 0 end) as regular_interval_mtus,
    sum(case when primary_reason = 'datacenter_ip_burst' then 1 else 0 end) as datacenter_ip_burst_mtus,
    round(100.0 * sum(has_ip) / count(*), 2) as ip_coverage_pct
from {{ ref('segment_bot_audit__visitors') }}
group by activity_month

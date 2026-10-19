{#- One row: the totals for the full audit window. -#}

select
    min(activity_month) as first_month,
    max(activity_month) as last_month,
    count(distinct activity_month) as month_count,
    count(*) as total_mtus,
    sum(is_non_human) as non_human_mtus,
    round(100.0 * sum(is_non_human) / count(*), 2) as non_human_pct,
    {{ var('segment_bot_audit_price_per_1000_mtus') }} as price_per_1000_mtus,
    round(sum(is_non_human) * {{ var('segment_bot_audit_price_per_1000_mtus') }} / 1000.0, 2) as estimated_cost_usd,
    round(100.0 * sum(has_ip) / count(*), 2) as ip_coverage_pct
from {{ ref('segment_bot_audit__visitors') }}

-- 36 MTUs in September 2026: 18 non-human. The visit from 2025 is outside the window.
select *
from {{ ref('segment_bot_audit__summary') }}
where not (
    total_mtus = 36
    and non_human_mtus = 18
    and month_count = 1
    and estimated_cost_usd = 0.18
)

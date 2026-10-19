-- Returns each visitor whose verdict or reason is not the expected value,
-- and each expected visitor that is missing or unexpected.
select
    coalesce(actual.visitor_key, expected.visitor_key) as visitor_key,
    actual.is_non_human,
    expected.expected_non_human,
    actual.primary_reason,
    expected.expected_reason
from {{ ref('segment_bot_audit__visitors') }} as actual
full outer join {{ ref('expected_visitors') }} as expected
    on expected.visitor_key = actual.visitor_key
where actual.visitor_key is null
   or expected.visitor_key is null
   or actual.is_non_human != expected.expected_non_human
   or coalesce(actual.primary_reason, '') != coalesce(expected.expected_reason, '')

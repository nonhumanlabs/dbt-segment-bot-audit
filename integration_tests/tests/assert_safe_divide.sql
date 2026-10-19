-- Returns the rows where the macro output is not the expected value.
select *
from {{ ref('test_safe_divide') }}
where actual is distinct from expected

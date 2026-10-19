select
    {{ nonhumanlabs.safe_divide('numerator', 'denominator') }} as actual,
    expected
from {{ ref('divide_cases') }}

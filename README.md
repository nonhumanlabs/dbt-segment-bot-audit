# nonhumanlabs dbt package

> Working name. Change the package name when the idea is final.

## Install

Add this to the `packages.yml` file of your dbt project:

```yaml
packages:
  - git: "https://github.com/nonhumanlabs/dbt-package.git"
    revision: 0.1.0
```

Then run `dbt deps`.

## Macros

### `safe_divide(numerator, denominator)`

Placeholder. Divides two numbers and returns null when the denominator is zero.

```sql
select {{ nonhumanlabs.safe_divide('revenue', 'orders') }} as revenue_per_order
from {{ ref('orders') }}
```

## Development

```bash
cd integration_tests
pip install dbt-core dbt-duckdb
DBT_PROFILES_DIR=. dbt deps
DBT_PROFILES_DIR=. dbt build
```

More information: [nonhumanlabs.dev](https://nonhumanlabs.dev)

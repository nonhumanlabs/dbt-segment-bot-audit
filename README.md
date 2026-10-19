# segment_bot_audit

Find out how many of your Segment MTUs are bots, and what they cost you.

Segment bills on monthly tracked users (MTUs). Each anonymous visitor counts, and
this includes crawlers, uptime monitors, headless browsers and vulnerability
scanners that run your analytics.js snippet. This dbt package reads the Segment
tables in your warehouse and estimates the share of your MTUs that are not human.

Example output (the numbers are made up):

```text
Segment bot audit: 2025-10-01 to 2026-09-01 (12 months)
------------------------------------------------------------
18.4% of your MTUs look non-human: 221040 of 1201300.
At $10 for each 1,000 MTUs, that is approximately $2210.4.
```

The audit works on a basic Segment setup. It needs only the data that analytics.js
collects automatically on each `page` call. You do not need `identify` or `track` calls.

## Signals

| Signal | Strength | What it looks for |
|---|---|---|
| Bot user agent | Strong | Crawlers, monitors, AI agents and headless browsers in `context_user_agent` |
| Malformed user agent | Strong | A page call with a user agent that is too short or does not start with `Mozilla/` |
| Scanner path | Strong | Page calls on paths such as `/wp-login.php`, `/.env` or `/phpmyadmin` |
| Fast pages | Strong | Many page calls less than one second apart |
| Regular interval | Strong | Page calls at an almost fixed interval |
| Datacenter IP | Weak | `context_ip` in an AWS, GCP, DigitalOcean, Oracle or Linode range |
| IP and user-agent burst | Weak | Many new visitor IDs from one IP address and user agent in one hour |

One strong signal is enough. The two weak signals count only together, so an office
behind one IP address, or a person on a cloud VPN, is not counted as a bot.
Visitors with a `user_id` are never counted as bots.

If your setup removes IP addresses, the audit skips the IP signals and tells you so.

## Install

Add the package to `packages.yml`:

```yaml
packages:
  - git: "https://github.com/nonhumanlabs/dbt-segment-bot-audit.git"
    revision: 0.1.0
```

Tell it where your Segment data is, in `dbt_project.yml`:

```yaml
vars:
  segment_bot_audit_sources: ["javascript_prod"]   # your Segment schema names
  segment_bot_audit_price_per_1000_mtus: 10        # your overage price in USD
```

A source can also be a mapping: `{database: analytics, schema: javascript_prod}`.

## Run

```bash
dbt deps
dbt build --select package:segment_bot_audit
dbt run-operation segment_bot_audit.print_report
```

For a free review of your results, paste the output at [nonhumanlabs.dev/#review](https://nonhumanlabs.dev/#review).

The models are:

- `segment_bot_audit__summary`: one row with the totals.
- `segment_bot_audit__monthly`: one row for each month.
- `segment_bot_audit__visitors`: one row for each MTU in each month, with each signal. Use it to examine the results.

The audit reads 12 months of `pages`, `tracks` and `identifies`. On large tables this
scan can be expensive. To read less data, set `segment_bot_audit_lookback_months` to a lower value.

## Configuration

| Var | Default | Description |
|---|---|---|
| `segment_bot_audit_sources` | `[]` | The Segment schemas to audit. Required. |
| `segment_bot_audit_lookback_months` | `12` | The number of months to audit. |
| `segment_bot_audit_end_date` | now | A fixed end date, as `'YYYY-MM-DD'`. |
| `segment_bot_audit_price_per_1000_mtus` | `10` | Your price in USD for each 1,000 MTUs. |
| `segment_bot_audit_min_ua_length` | `30` | A shorter user agent is malformed. |
| `segment_bot_audit_fast_gap_ms` | `1000` | A gap shorter than this is fast. |
| `segment_bot_audit_min_fast_gaps` | `5` | The number of fast gaps for the fast-pages signal. |
| `segment_bot_audit_min_regular_gaps` | `10` | The minimum number of gaps for the regular-interval signal. |
| `segment_bot_audit_max_regular_cv` | `0.05` | The maximum variation of the gaps for the regular-interval signal. |
| `segment_bot_audit_burst_min_ids` | `10` | The number of IDs in one hour for the burst signal. |
| `segment_bot_audit_bot_ua_pattern` | see `macros/patterns.sql` | The bot user-agent regex. |
| `segment_bot_audit_scanner_path_pattern` | see `macros/patterns.sql` | The scanner path regex. |

## Limits

- This is an estimate. It finds the bots that leave traces in the warehouse. Advanced
  bots that act like real browsers on residential IP addresses are not found.
- The MTU count is an approximation of the Segment count. Segment joins anonymous IDs
  and user IDs in its own way.
- Only IPv4 addresses are compared with the datacenter ranges.
- The SQL is written for BigQuery, Snowflake, Redshift, Databricks and DuckDB.
  The automatic tests run only on DuckDB. Please open an issue if a warehouse fails.

## Development

```bash
cd integration_tests
pip install dbt-core dbt-duckdb
export DBT_PROFILES_DIR=.
dbt deps && dbt seed && dbt build
dbt run-operation segment_bot_audit.print_report
```

To update the datacenter ranges, run `python3 scripts/update_datacenter_ranges.py`.

More information: [nonhumanlabs.dev](https://nonhumanlabs.dev)

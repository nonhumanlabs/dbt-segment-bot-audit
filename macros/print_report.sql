{#- Prints the audit result. Run: dbt run-operation segment_bot_audit.print_report -#}
{% macro print_report() %}
    {% set summary = run_query('select * from ' ~ ref('segment_bot_audit__summary')) %}
    {% if summary.rows | length == 0 or summary.rows[0][3] in [none, 0] %}
        {{ log("segment_bot_audit: no MTUs in the audit window. Do a check of 'segment_bot_audit_sources'.", info=True) }}
        {{ return(none) }}
    {% endif %}

    {% set row = summary.rows[0] %}
    {% set monthly = run_query('select * from ' ~ ref('segment_bot_audit__monthly') ~ ' order by 1') %}

    {{ log("", info=True) }}
    {{ log("Segment bot audit: " ~ row[0] ~ " to " ~ row[1] ~ " (" ~ row[2] ~ " months)", info=True) }}
    {{ log("-" * 60, info=True) }}
    {{ log(row[5] ~ "% of your MTUs look non-human: " ~ row[4] ~ " of " ~ row[3] ~ ".", info=True) }}
    {{ log("At $" ~ row[6] ~ " for each 1,000 MTUs, that is approximately $" ~ row[7] ~ ".", info=True) }}
    {% if row[8] is not none and row[8] < 50 %}
        {{ log("Only " ~ row[8] ~ "% of MTUs have an IP address. The IP signals are partly skipped.", info=True) }}
    {% endif %}
    {{ log("", info=True) }}
    {{ log("Month        MTUs   Non-human      %    Cost (USD)", info=True) }}
    {% for m in monthly.rows %}
        {{ log((m[0] | string)[:10] ~ "  " ~ ("%8s" | format(m[1])) ~ "  " ~ ("%10s" | format(m[2])) ~ "  " ~ ("%5s" | format(m[3])) ~ "  " ~ ("%12s" | format(m[4])), info=True) }}
    {% endfor %}
    {{ log("", info=True) }}
    {{ log("Details: the segment_bot_audit__visitors model shows the signals for each MTU.", info=True) }}
{% endmacro %}

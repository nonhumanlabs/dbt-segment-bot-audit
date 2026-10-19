{#- The distinct IPv4 addresses in the audit window that are in a cloud provider range. -#}

with ips as (
    select distinct context_ip as ip
    from {{ ref('int_sba__events') }}
    where context_ip is not null
),

parsed as (
    select
        ip,
        {{ segment_bot_audit.ipv4_first_octet('ip') }} as first_octet,
        {{ segment_bot_audit.ipv4_to_int('ip') }} as ip_int
    from ips
)

select
    parsed.ip,
    max(ranges.provider) as provider
from parsed
inner join {{ ref('segment_bot_audit_datacenter_ranges') }} as ranges
    on ranges.first_octet = parsed.first_octet
    and parsed.ip_int between ranges.start_int and ranges.end_int
group by parsed.ip

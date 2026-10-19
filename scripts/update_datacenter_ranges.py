"""Regenerate seeds/segment_bot_audit_datacenter_ranges.csv.

Downloads the published IPv4 ranges of the large cloud providers, merges
overlapping ranges, and splits each range at first-octet boundaries so the
models can join on the first octet before the range comparison.

Usage: python3 scripts/update_datacenter_ranges.py
Only the standard library is used.
"""

import csv
import ipaddress
import json
import sys
import urllib.request
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent / "seeds" / "segment_bot_audit_datacenter_ranges.csv"


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "segment-bot-audit-range-updater"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read().decode("utf-8")


def aws():
    data = json.loads(fetch("https://ip-ranges.amazonaws.com/ip-ranges.json"))
    return [p["ip_prefix"] for p in data["prefixes"]]


def gcp():
    data = json.loads(fetch("https://www.gstatic.com/ipranges/cloud.json"))
    return [p["ipv4Prefix"] for p in data["prefixes"] if "ipv4Prefix" in p]


def digitalocean():
    rows = csv.reader(fetch("https://digitalocean.com/geo/google.csv").splitlines())
    return [row[0] for row in rows if row and ":" not in row[0]]


def oracle():
    data = json.loads(fetch("https://docs.oracle.com/iaas/tools/public_ip_ranges.json"))
    return [c["cidr"] for region in data["regions"] for c in region["cidrs"]]


def linode():
    rows = csv.reader(line for line in fetch("https://geoip.linode.com/").splitlines() if not line.startswith("#"))
    return [row[0] for row in rows if row and ":" not in row[0]]


PROVIDERS = {"aws": aws, "gcp": gcp, "digitalocean": digitalocean, "oracle": oracle, "linode": linode}


def merge(networks):
    ranges = sorted((int(n.network_address), int(n.broadcast_address)) for n in networks)
    merged = []
    for start, end in ranges:
        if merged and start <= merged[-1][1] + 1:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    return merged


def split_by_first_octet(start, end):
    while start <= end:
        octet = start >> 24
        octet_end = min(end, (octet << 24) | 0xFFFFFF)
        yield octet, start, octet_end
        start = octet_end + 1


def main():
    rows = []
    for name, loader in PROVIDERS.items():
        try:
            prefixes = loader()
        except Exception as error:  # Keep the other providers when one source fails.
            print(f"skipped {name}: {error}", file=sys.stderr)
            continue
        networks = []
        for prefix in prefixes:
            try:
                network = ipaddress.ip_network(prefix.strip(), strict=False)
            except ValueError:
                continue
            if network.version == 4:
                networks.append(network)
        for start, end in merge(networks):
            for octet, part_start, part_end in split_by_first_octet(start, end):
                rows.append((name, octet, part_start, part_end))
        print(f"{name}: {len(networks)} prefixes", file=sys.stderr)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["provider", "first_octet", "start_int", "end_int"])
        writer.writerows(sorted(rows, key=lambda r: (r[1], r[2])))
    print(f"wrote {len(rows)} rows to {OUTPUT}", file=sys.stderr)


if __name__ == "__main__":
    main()

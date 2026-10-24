#!/usr/bin/env python3
"""CI-only check, invoked after unshare --net, before running installer tests."""
import errno
import json
from pathlib import Path
import socket
import subprocess


for route_file in ("/proc/net/route", "/proc/net/ipv6_route"):
    raw = Path(route_file).read_bytes()
    print(f"{route_file}: {len(raw)} bytes, {len(raw.splitlines())} lines", flush=True)
    print(raw.decode("ascii"), end="", flush=True)

interfaces = subprocess.run(
    ["ip", "-brief", "link"], check=True, capture_output=True, text=True, timeout=5
)
print(interfaces.stdout, end="", flush=True)

# procfs may be empty or header-only. Check actual routes, not header formatting.
for family in ("-4", "-6"):
    result = subprocess.run(
        ["ip", "-j", family, "route", "show", "table", "all"],
        check=True, capture_output=True, text=True, timeout=5,
    )
    routes = json.loads(result.stdout)
    print(f"{family} routes: {routes!r}", flush=True)
    if routes != []:
        raise SystemExit("Expected an isolated network namespace with no routes")

address_result = subprocess.run(
    ["ip", "-j", "-6", "address", "show"],
    check=True, capture_output=True, text=True, timeout=5,
)
ipv6_addresses = [
    address
    for interface in json.loads(address_result.stdout)
    for address in interface["addr_info"]
    if address.get("family") == "inet6"
]
print(f"IPv6 source addresses: {ipv6_addresses!r}", flush=True)

# No route exists, so these documentation-address probes cannot leave the
# namespace. A timeout/refusal is not accepted as proof of network isolation.
for family, address in (
    (socket.AF_INET, ("192.0.2.1", 9)),
    (socket.AF_INET6, ("2001:db8::1", 9, 0, 0)),
):
    with socket.socket(family, socket.SOCK_STREAM) as probe:
        probe.settimeout(1)
        result = probe.connect_ex(address)
    print(f"{address[0]}: {errno.errorcode.get(result, result)}", flush=True)
    if result == errno.ENETUNREACH:
        continue
    if family == socket.AF_INET6 and result == errno.EADDRNOTAVAIL and not ipv6_addresses:
        print("IPv6 probe has no source address in this namespace.", flush=True)
        continue
    raise SystemExit("Expected no route, or IPv6 EADDRNOTAVAIL with no IPv6 addresses")
print("Network isolation verified: no routes; IPv4 unreachable; IPv6 unreachable or addressless.")

#!/usr/bin/env python3
"""Keep wg-quick tunnels' routes right after a network change (macOS, root).

wg-quick adds a route per AllowedIPs range only when the tunnel comes up. A
range that was on-link at that moment (the home LAN, while at home) gets no
tunnel route, so after moving to another network that traffic leaks to the
local gateway. For every running tunnel this:

- routes each AllowedIPs range through the tunnel when no local interface is
  on it (away from home);
- removes the tunnel route when a local interface is on it (back home), so
  the LAN goes direct.
"""

import glob
import ipaddress
import os
import re
import subprocess

CONFIG_DIRS = ("/etc/wireguard", "/usr/local/etc/wireguard", "/opt/homebrew/etc/wireguard")
NAME_FILES = "/var/run/wireguard/*.name"
# WG_ROUTES_DRY_RUN=1: print route changes instead of making them.
DRY_RUN = os.environ.get("WG_ROUTES_DRY_RUN") == "1"


def run(*args):
    return subprocess.run(args, capture_output=True, text=True).stdout


def local_networks():
    """IPv4 networks of the non-tunnel interfaces."""
    networks = []
    interface = None
    for line in run("ifconfig").splitlines():
        header = re.match(r"^(\S+): flags=", line)
        if header:
            interface = header.group(1)
            continue
        found = re.match(r"\s+inet (\S+) netmask (0x[0-9a-f]+)", line)
        if found and interface and not interface.startswith(("utun", "lo")):
            prefix = bin(int(found.group(2), 16)).count("1")
            networks.append(ipaddress.ip_network(f"{found.group(1)}/{prefix}", strict=False))
    return networks


def allowed_ranges(name):
    for directory in CONFIG_DIRS:
        path = os.path.join(directory, f"{name}.conf")
        if os.path.exists(path):
            text = open(path).read()
            ranges = []
            for value in re.findall(r"^\s*AllowedIPs\s*=\s*(.+)$", text, re.M):
                for item in value.split(","):
                    network = ipaddress.ip_network(item.strip(), strict=False)
                    if network.version == 4 and network.prefixlen > 0:
                        ranges.append(network)
            return ranges
    return []


def change(*args):
    if DRY_RUN:
        print("dry-run: " + " ".join(args))
    else:
        run(*args)


def route_interface(network):
    found = re.search(r"interface: (\S+)", run("route", "-n", "get", "-net", str(network)))
    return found.group(1) if found else None


def tunnels():
    """(name, utunN) of every running wg-quick tunnel."""
    for name_file in glob.glob(NAME_FILES):
        yield os.path.basename(name_file)[: -len(".name")], open(name_file).read().strip()


def main():
    local = local_networks()
    for name, tunnel in tunnels():
        for network in allowed_ranges(name):
            on_link = any(network.overlaps(net) for net in local)
            current = route_interface(network)
            if not on_link and current != tunnel:
                change("route", "-q", "-n", "delete", "-inet", "-net", str(network))
                change("route", "-q", "-n", "add", "-inet", "-net", str(network), "-interface", tunnel)
                print(f"{name}: {network} -> {tunnel}")
            elif on_link and current == tunnel:
                change("route", "-q", "-n", "delete", "-inet", "-net", str(network), "-interface", tunnel)
                print(f"{name}: {network} direct (on-link)")


if __name__ == "__main__":
    main()

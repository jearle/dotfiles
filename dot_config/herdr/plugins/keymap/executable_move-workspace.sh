#!/usr/bin/env bash
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
direction="${1:-}"

python3 - "$herdr" "$direction" <<'PY'
import json, os, socket, subprocess, sys

herdr, direction = sys.argv[1], sys.argv[2]
if direction not in ("up", "down"):
    sys.exit(f"usage: move-workspace.sh up|down")


def run(*args):
    proc = subprocess.run(
        [herdr, *args],
        check=True,
        capture_output=True,
        text=True,
    )
    out = proc.stdout.strip()
    return json.loads(out) if out else None


def rpc(method, params):
    path = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser(
        "~/.config/herdr/herdr.sock"
    )
    req = {"id": "local.keymap.move", "method": method, "params": params}
    sock = socket.socket(socket.AF_UNIX)
    sock.connect(path)
    sock.sendall((json.dumps(req) + "\n").encode())
    buf = b""
    while b"\n" not in buf:
        chunk = sock.recv(65536)
        if not chunk:
            break
        buf += chunk
    sock.close()
    resp = json.loads(buf.decode())
    if "error" in resp:
        raise SystemExit(resp["error"].get("message") or json.dumps(resp["error"]))
    return resp.get("result")


workspaces = run("workspace", "list")["result"]["workspaces"]
focused = next((w for w in workspaces if w.get("focused")), None)
if focused is None:
    sys.exit(0)

idx = next(
    i
    for i, w in enumerate(workspaces)
    if w["workspace_id"] == focused["workspace_id"]
)
dest = idx - 1 if direction == "up" else idx + 1
if dest < 0 or dest >= len(workspaces):
    sys.exit(0)

rpc(
    "workspace.move",
    {"workspace_id": focused["workspace_id"], "insert_index": dest},
)
PY

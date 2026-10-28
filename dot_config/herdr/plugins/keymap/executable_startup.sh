#!/usr/bin/env bash
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"

python3 - "$herdr" <<'PY'
import json, subprocess, sys

herdr = sys.argv[1]
source = "local.keymap"
tokens = [
    ("hk_title", "cheat sheet"),
    ("hk1", "⇧N  new workspace"),
    ("hk2", "⇧W  rename workspace"),
    ("hk3", "W↑↓ select workspace"),
    ("hk4", "C   new tab"),
    ("hk5", "⇧T  rename tab"),
    ("hk6", "⇧P  slide tab left"),
    ("hk7", "⇧]  slide tab right"),
    ("hk8", "⇧↑  slide workspace up"),
    ("hk9", "⇧↓  slide workspace down"),
]


def run(*args):
    proc = subprocess.run(
        [herdr, *args],
        check=True,
        capture_output=True,
        text=True,
    )
    out = proc.stdout.strip()
    if not out:
        return None
    return json.loads(out)


workspaces = run("workspace", "list")["result"]["workspaces"]
ws_index = {w["workspace_id"]: i for i, w in enumerate(workspaces)}

tab_index = {}
for ws in workspaces:
    tabs = run("tab", "list", "--workspace", ws["workspace_id"])["result"]["tabs"]
    for i, tab in enumerate(tabs):
        tab_index[tab["tab_id"]] = i

agents = run("agent", "list")["result"]["agents"]
if not agents:
    sys.exit(0)

agents.sort(
    key=lambda a: (
        ws_index.get(a.get("workspace_id"), 10_000),
        tab_index.get(a.get("tab_id"), 10_000),
        a.get("pane_id") or "",
    )
)
target = agents[-1]["pane_id"]


def set_tokens(pane_id, values):
    args = ["pane", "report-metadata", pane_id, "--source", source]
    if values is None:
        for name, _ in tokens:
            args.extend(["--clear-token", name])
    else:
        for name, value in values:
            args.extend(["--token", f"{name}={value}"])
    run(*args)


for agent in agents:
    pane_id = agent["pane_id"]
    set_tokens(pane_id, tokens if pane_id == target else None)

print(json.dumps({"target": target}))
PY

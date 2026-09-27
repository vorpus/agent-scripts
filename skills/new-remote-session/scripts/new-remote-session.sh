#!/usr/bin/env bash
# Start a detached tmux session running `claude --remote-control` for a repo.
# Usage: new-remote-session.sh <repo-path>
set -euo pipefail

repo="${1:?usage: new-remote-session.sh <repo-path>}"
repo="${repo/#\~/$HOME}"            # expand a leading ~
repo="$(cd "$repo" && pwd)"        # absolute path; fails if it doesn't exist
name="$(basename "$repo")"

# Model the remote Claude runs as. Fable 5 is the orchestrator by default
# (delegates to subagents); override with CLAUDE_MODEL=... if needed.
model="${CLAUDE_MODEL:-fable}"

if tmux has-session -t "$name" 2>/dev/null; then
  echo "tmux session '$name' already exists — attach with: tmux attach -t $name" >&2
  exit 1
fi

# Pre-accept the "trust this folder?" dialog. Claude shows it for any repo it
# hasn't seen and Remote Control doesn't start until it's answered — which
# nobody can do from the phone, since the session is detached.
python3 - "$repo" <<'PY'
import json, os, sys
path = os.path.expanduser("~/.claude.json")
cfg = json.load(open(path)) if os.path.exists(path) else {}
proj = cfg.setdefault("projects", {}).setdefault(sys.argv[1], {})
if not proj.get("hasTrustDialogAccepted"):
    proj["hasTrustDialogAccepted"] = True
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(cfg, f, indent=2)
    os.replace(tmp, path)
PY

tmux new-session -d -s "$name" -c "$repo" "claude --model $model --remote-control $name"

echo "Started detached tmux session '$name' running: claude --model $model --remote-control $name"
echo "Working dir: $repo"
echo "Attach later with: tmux attach -t $name"

#!/usr/bin/env bash
# Launch a detached, named, Remote-Control Claude session for a repo.
# Usage: spawn.sh <name> <repo> [model] [effort]
#   name   — tmux session name AND the session's addressable name (they match)
#   repo   — path under ~/projects, or an absolute path
#   model  — fable | opus | sonnet | a full id (default: fable)
#   effort — low | medium | high | xhigh | max (default: high)
set -euo pipefail

name="${1:?usage: spawn.sh <name> <repo> [model] [effort]}"
repo="${2:?usage: spawn.sh <name> <repo> [model] [effort]}"
model="${3:-fable}"
effort="${4:-high}"

case "$repo" in
  /*) ;;
  ~*) repo="${repo/#\~/$HOME}" ;;
  *)  [ -d "$repo" ] || repo="$HOME/projects/$repo" ;;
esac
repo="$(cd "$repo" && pwd)"   # fails loudly if it does not exist

if tmux has-session -t "$name" 2>/dev/null; then
  echo "tmux session '$name' already exists — pick another name or kill it first" >&2
  exit 1
fi

# --name is what makes the session addressable under $name. Without it the peer
# name is DERIVED from the repo (e.g. all-roads-lead-home-2d) and no amount of
# --remote-control naming changes that.
tmux new-session -d -s "$name" -c "$repo" \
  "claude --model $model --effort $effort --name $name --remote-control $name"

# Wait for it to register. A session stuck on the directory trust prompt never
# will, so bail out loudly rather than hanging.
bridge=""
for _ in $(seq 1 30); do
  sleep 1
  if ! tmux has-session -t "$name" 2>/dev/null; then
    echo "session '$name' exited during startup — check auth (claude /login)" >&2
    exit 1
  fi
  if tmux capture-pane -p -t "$name":0.0 -S -40 2>/dev/null | grep -q 'Quick safety check'; then
    cat >&2 <<EOF
session '$name' is blocked on the directory trust prompt for:
  $repo
Do NOT guess at the prompt — a wrong key exits the session. Trust the directory
once by running \`claude\` in it interactively, then spawn again.
EOF
    exit 1
  fi
  bridge="$(python3 - "$HOME/.claude/sessions" "$name" <<'PY'
import json, os, sys
d, target = sys.argv[1], sys.argv[2]
for fn in os.listdir(d) if os.path.isdir(d) else []:
    if not fn.endswith('.json'):
        continue
    try:
        with open(os.path.join(d, fn)) as fh:
            s = json.load(fh)
    except Exception:
        continue
    if s.get('name') == target and s.get('nameSource') == 'user':
        print(s.get('bridgeSessionId', ''))
        break
PY
)"
  [ -n "$bridge" ] && break
done

if [ -z "$bridge" ]; then
  echo "session '$name' started but never registered under that name — check it with fleet.sh" >&2
  exit 1
fi

echo "spawned: $name"
echo "  model:  $model, effort $effort"
echo "  cwd:    $repo"
echo "  remote: https://claude.ai/code/$bridge"

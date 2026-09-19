#!/usr/bin/env bash
# Kill sessions WITHOUT losing what they were holding. For each one: save a pane
# snapshot, surface any unsent draft and uncommitted work, then kill.
# Usage: retire.sh <name> [name ...]
set -uo pipefail

[ $# -ge 1 ] || { echo "usage: retire.sh <name> [name ...]" >&2; exit 1; }

outdir="$HOME/.claude/retired/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"

for s in "$@"; do
  echo "################ $s"
  if ! tmux has-session -t "$s" 2>/dev/null; then
    echo "  already gone (nothing to kill)"
    continue
  fi

  # Full scrollback, not just the visible pane — this is the only copy once the
  # session is killed.
  snap="$outdir/$s.txt"
  tmux capture-pane -p -t "$s":0.0 -S - >"$snap" 2>/dev/null
  echo "  snapshot  $snap ($(wc -l <"$snap" | tr -d ' ') lines)"

  # The draft the human typed but never submitted. Killing loses it forever.
  draft="$(python3 "$(dirname "$0")/draft.py" <"$snap")"
  [ -n "$draft" ] && echo "  UNSENT    $draft"

  # Uncommitted work in its working directory, which outlives the session.
  cwd="$(python3 - "$HOME/.claude/sessions" "$s" <<'PY'
import json, os, sys
d, target = sys.argv[1], sys.argv[2]
for fn in os.listdir(d) if os.path.isdir(d) else []:
    if not fn.endswith('.json'):
        continue
    try:
        with open(os.path.join(d, fn)) as fh:
            st = json.load(fh)
    except Exception:
        continue
    if str(st.get('tmux', '')).split(':')[0] == target:
        print(st.get('cwd', ''))
        break
PY
)"
  if [ -n "$cwd" ] && [ -d "$cwd" ]; then
    dirty="$(git -C "$cwd" status --porcelain 2>/dev/null | head -20)"
    if [ -n "$dirty" ]; then
      echo "  DIRTY     uncommitted in $cwd:"
      printf '%s\n' "$dirty" | sed 's/^/              /'
    fi
  fi

  tmux kill-session -t "$s" 2>/dev/null && echo "  killed" || echo "  KILL FAILED"
done

echo
echo "snapshots: $outdir"

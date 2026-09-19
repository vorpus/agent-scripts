#!/usr/bin/env bash
# Inventory every Claude session on this machine: liveness, name, model, cwd,
# and — the important one — any UNSENT draft sitting in a session's input box.
# Usage: fleet.sh [name ...]      (no args = all tmux sessions)
set -uo pipefail

SESSIONS_DIR="$HOME/.claude/sessions"

# Registry lookup by tmux target. The registry is keyed by pid, so the only way
# back from a tmux session name is to scan. A session that is alive but absent
# here is still booting (or stuck on a trust prompt — see SKILL.md).
registry_for() {
  local target="$1"
  python3 - "$SESSIONS_DIR" "$target" <<'PY'
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
    if str(s.get('tmux', '')).split(':')[0] == target:
        print('\t'.join([
            str(s.get('name', '?')),
            str(s.get('nameSource', '?')),
            str(s.get('status', '?')),
            str(s.get('cwd', '?')),
            str(s.get('bridgeSessionId', '')),
        ]))
        break
PY
}

# No mapfile: macOS ships bash 3.2.
names=()
if [ $# -gt 0 ]; then
  names=("$@")
else
  while IFS= read -r line; do
    [ -n "$line" ] && names+=("$line")
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)
fi

if [ ${#names[@]} -eq 0 ]; then
  echo "no tmux sessions"
  exit 0
fi

for s in "${names[@]}"; do
  if ! tmux has-session -t "$s" 2>/dev/null; then
    printf '%-22s DEAD (no tmux session)\n' "$s"
    continue
  fi

  pane="$(tmux capture-pane -p -t "$s":0.0 -S -60 2>/dev/null)"
  reg="$(registry_for "$s")"
  IFS=$'\t' read -r rname rsrc rstatus rcwd rbridge <<<"${reg:-}"

  printf '%-22s %s\n' "$s" "${rstatus:-booting}"
  printf '  name      %s%s\n' "${rname:-<unregistered>}" \
    "$([ "${rsrc:-}" = derived ] && echo '  (derived — pass --name next time)')"
  [ -n "${rcwd:-}" ] && printf '  cwd       %s\n' "$rcwd"

  # Model/effort come from the startup banner, not the registry.
  banner="$(printf '%s\n' "$pane" | grep -m1 -E 'with (low|medium|high|xhigh|max) effort|Claude Max' || true)"
  [ -n "$banner" ] && printf '  model     %s\n' "$(echo "$banner" | sed 's/^[^A-Za-z]*//')"

  [ -n "${rbridge:-}" ] && printf '  remote    https://claude.ai/code/%s\n' "$rbridge"

  if printf '%s\n' "$pane" | grep -q 'Quick safety check'; then
    printf '  !! BLOCKED on the directory trust prompt — it has not started work\n'
  fi

  # The unsent draft the human typed but never submitted. Parsed in python:
  # the caret is followed by a NO-BREAK SPACE, so grep with a normal space fails.
  draft="$(printf '%s\n' "$pane" | python3 "$(dirname "$0")/draft.py")"
  if [ -n "$draft" ]; then
    printf '  UNSENT    %s\n' "$draft"
  fi
done

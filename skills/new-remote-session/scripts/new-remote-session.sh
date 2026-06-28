#!/usr/bin/env bash
# Start a detached tmux session running `claude --remote-control` for a repo.
# Usage: new-remote-session.sh <repo-path>
set -euo pipefail

repo="${1:?usage: new-remote-session.sh <repo-path>}"
repo="${repo/#\~/$HOME}"            # expand a leading ~
repo="$(cd "$repo" && pwd)"        # absolute path; fails if it doesn't exist
name="$(basename "$repo")"

if tmux has-session -t "$name" 2>/dev/null; then
  echo "tmux session '$name' already exists — attach with: tmux attach -t $name" >&2
  exit 1
fi

tmux new-session -d -s "$name" -c "$repo" "claude --remote-control $name"

echo "Started detached tmux session '$name' running: claude --remote-control $name"
echo "Working dir: $repo"
echo "Attach later with: tmux attach -t $name"

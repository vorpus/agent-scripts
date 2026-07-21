#!/usr/bin/env bash
# Scaffold a new project: folder in ~/projects, git init, GitHub repo, README.
#
# Usage: new-project.sh <name> [description] [--public] [--local]
#   --public   create the GitHub repo public (default: private)
#   --local    skip GitHub entirely (folder + git + README only)
#
# Base dir is ~/projects, override with PROJECTS_DIR. Pushes over HTTPS using
# the gh credential helper (SSH pushes fail in this environment).
set -euo pipefail

name=""
description=""
visibility="--private"
remote=1

for arg in "$@"; do
  case "$arg" in
    --public) visibility="--public" ;;
    --private) visibility="--private" ;;
    --local) remote=0 ;;
    --*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) if [ -z "$name" ]; then name="$arg"; else description="$arg"; fi ;;
  esac
done

if [ -z "$name" ]; then
  echo "usage: new-project.sh <name> [description] [--public] [--local]" >&2
  exit 2
fi
# Repo/dir names: letters, digits, dot, underscore, hyphen.
if ! printf '%s' "$name" | grep -qE '^[A-Za-z0-9._-]+$'; then
  echo "invalid name '$name' — use letters, digits, . _ - only" >&2
  exit 2
fi

base="${PROJECTS_DIR:-$HOME/projects}"
target="$base/$name"
if [ -e "$target" ]; then
  echo "already exists: $target" >&2
  exit 1
fi

if [ "$remote" -eq 1 ]; then
  command -v gh >/dev/null || { echo "gh not found; install it or pass --local" >&2; exit 1; }
  gh auth status >/dev/null 2>&1 || { echo "gh not authenticated; run 'gh auth login' or pass --local" >&2; exit 1; }
fi

mkdir -p "$target"
cd "$target"
git -c init.defaultBranch=main init -q

if [ -n "$description" ]; then
  printf '# %s\n\n%s\n' "$name" "$description" > README.md
else
  printf '# %s\n\n_One line on what this is and why you would want it._\n' "$name" > README.md
fi

git add README.md
git -c commit.gpgsign=false commit -qm "Initial commit"

if [ "$remote" -eq 0 ]; then
  echo "created (local only): $target"
  exit 0
fi

owner=$(gh api user -q .login)
# Create the empty remote repo, then wire up an HTTPS remote and push via gh.
gh repo create "$name" "$visibility" >/dev/null
git remote add origin "https://github.com/$owner/$name.git"
git -c credential.helper='!gh auth git-credential' push -qu origin main

echo "created: $target"
echo "github:  https://github.com/$owner/$name  ($(printf '%s' "$visibility" | tr -d '-'))"

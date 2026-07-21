---
name: new-project
description: "Scaffold a new project — folder, git, GitHub repo, README."
---

# New Project

Start a fresh project. Creates a folder in `~/projects`, `git init`s it on `main`,
makes a matching GitHub repo, and commits a starter README.

## Usage

```bash
skills/new-project/scripts/new-project.sh <name> [description] [--public] [--local]
```

- **name** — folder and repo name (letters, digits, `. _ -`).
- **description** — optional; becomes the README's one-liner. Omit and it leaves
  a placeholder line to fill in later.
- **--public** — public GitHub repo. Default is **private**; flip to public at
  ship time (see `launch-prep`), so a half-built project isn't world-readable.
- **--local** — skip GitHub; just folder + git + README.

Report back the local path and the GitHub URL the script prints.

## Notes

- Base dir is `~/projects`, overridable with `PROJECTS_DIR`. It is **not** the
  session's current directory — the script always targets `~/projects` so it
  works the same when called from any session.
- Pushes over HTTPS via the gh credential helper; SSH pushes fail in this
  environment.
- Needs `gh` authenticated (unless `--local`). The script checks and tells you
  if it isn't.
- The README is a stub on purpose. Run `launch-prep` when it's time to make it
  presentable and generate launch copy.

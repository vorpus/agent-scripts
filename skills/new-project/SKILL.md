---
name: new-project
description: "Scaffold a new project — folder, git, GitHub repo, README, agent config."
---

# New Project

Start a fresh project. Creates a folder in `~/projects`, `git init`s it on `main`,
makes a matching GitHub repo, and commits a starter scaffold:

- `README.md` — stub (fill in / run `launch-prep` later).
- `AGENTS.md` — canonical agent instructions, from `templates/AGENTS.md`.
- `CLAUDE.md` — points to `AGENTS.md` so Claude and Codex share one source.
- `docs/` — where all Markdown lives (PRDs, research, milestones, work logs).

## Usage

```bash
skills/new-project/scripts/new-project.sh <name> [description] [--public] [--local]
```

- **name** — folder and repo name (letters, digits, `. _ -`).
- **description** — optional; becomes the README's one-liner. Omit for a placeholder.
- **--public** — public GitHub repo. Default is **private**; flip to public at
  ship time (see `launch-prep`), so a half-built project isn't world-readable.
- **--local** — skip GitHub; just folder + git + files.

Report the local path and the GitHub URL the script prints.

## The templates

`templates/AGENTS.md` and `templates/CLAUDE.md` are copied into every new project
(`{{PROJECT}}` is replaced with the name). Edit the templates here to change what
future projects start with. What they currently encode:

- **Orchestration** — Fable 5 directs; delegate to subagents; pick each subagent's
  model to fit the task.
- **Docs** — everything Markdown goes in `docs/`; PRD at `docs/PRD.md`.
- **README** — kept current with build/run/setup.
- **Git** — push regularly; short commit titles/messages; no co-authors.

## Notes

- Base dir is `~/projects`, overridable with `PROJECTS_DIR`. It is **not** the
  session's current directory — the script always targets `~/projects` so it
  works the same called from any session.
- Pushes over HTTPS via the gh credential helper; SSH pushes fail in this
  environment.
- Needs `gh` authenticated unless `--local`. The script checks and tells you.

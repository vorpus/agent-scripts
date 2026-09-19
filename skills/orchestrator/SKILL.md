---
name: orchestrator
description: "Run a fleet of detached Claude worker sessions — spawn, inventory, retire."
---

# Orchestrator

The orchestrator is a long-lived session in `~/projects` that does no project work
itself. It spawns **detached** Claude sessions for individual repos, keeps track of
them, and retires them cleanly. The workers are driven from the phone over Remote
Control; the orchestrator is the terminal that starts and stops them.

The one hard rule: **never `tmux attach`.** Attaching pulls the worker into this
terminal and the orchestrator stops being an orchestrator. Look at sessions with
`tmux capture-pane`, never by attaching.

## Becoming the orchestrator

After a reboot, start a session in `~/projects` and invoke this skill. Two steps:

1. Name this session, so workers and `/resume` can address it. A running session
   can only be renamed from inside, and a model can type into its own pane:

   ```bash
   tmux send-keys -t "$(tmux display-message -p '#{session_name}'):0.0" "/rename orchestrator"
   # then, as a separate call:
   tmux send-keys -t "$(tmux display-message -p '#{session_name}'):0.0" Enter
   ```

2. Take inventory with `fleet.sh` and report what survived the reboot (usually
   nothing — tmux sessions do not persist across restarts).

## Usage

```bash
skills/orchestrator/scripts/spawn.sh  <name> <repo> [model] [effort]
skills/orchestrator/scripts/fleet.sh  [name ...]
skills/orchestrator/scripts/retire.sh <name> [name ...]
```

- **spawn** — launch a worker. `model` defaults to `fable`, `effort` to `high`.
  The tmux session name, the addressable session name, and the Remote Control
  name are all `<name>`. Prints the `claude.ai/code/...` link to hand the user.
- **fleet** — one block per session: liveness, registry name, model/effort, cwd,
  Remote Control link, and any **unsent draft**. Run this before answering "what
  is running?" — never answer from memory, sessions die on their own.
- **retire** — the safe kill. Saves the full scrollback to
  `~/.claude/retired/<timestamp>/<name>.txt`, prints the unsent draft and any
  uncommitted files in the worker's cwd, then kills. Report both to the user.

Equivalent spawn one-liner, if the script is unavailable:

```bash
tmux new-session -d -s <name> -c <abs-repo> \
  "claude --model fable --effort high --name <name> --remote-control <name>"
```

## Notes

Things that are not guessable and cost real work to learn:

- **`--name` is required for an addressable session.** Without it the peer name is
  *derived* from the repo (`all-roads-lead-home-2d`) no matter what
  `--remote-control` is given. Verify with `fleet.sh`: it flags `derived` names.
- **Always pass `--effort`.** Omitted, a worker inherits the user's default (often
  `xhigh`), which is rarely what was asked for.
- **Capture before you kill.** A session almost always has a draft the human typed
  and never submitted; killing loses it silently. `retire.sh` surfaces it. In
  practice this has caught one on nearly every session retired.
- **The input caret is `❯` + U+00A0**, a NO-BREAK SPACE. `grep '^❯ '` with an ASCII
  space never matches. `draft.py` handles it; don't rewrite it as grep.
- **A new/untrusted directory blocks on a trust prompt** and never registers or
  starts work. Do not guess at the prompt — a wrong keystroke exits the session.
  Trust the directory once by running `claude` in it interactively, then spawn.
- **Workers die on their own** — auth expiry, updates, crashes. When one dies its
  tmux session and registry file both vanish, so there is no error to find: `tmux
  ls` is the liveness check. Its files on disk survive, so check `git status` in
  its cwd and rescue uncommitted work.
- **One repo, one worker.** Several sessions sharing a working tree do collide —
  two have raced on a version bump and pushed past each other. Give them
  non-overlapping scopes, or a `git worktree` each.
- The session registry is `~/.claude/sessions/<pid>.json`: `name`, `nameSource`,
  `status`, `cwd`, `tmux`, `bridgeSessionId`. Keyed by pid, so finding a session
  by name means scanning the directory — that is what the scripts do.
- macOS ships **bash 3.2**: no `mapfile`, no associative arrays.

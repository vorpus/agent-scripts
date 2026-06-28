---
name: new-remote-session
description: "Start a detached tmux session running Claude Remote Control for a repo."
---

# New Remote Session

When the user asks to "create a new remote session in `<repo>`", launch Claude with
Remote Control in a **detached** tmux session for that repo. Do not attach — this
conversation keeps orchestrating while the new session is driven from the mobile app.

## Steps

1. Resolve `<repo>` to an absolute path (e.g. `~/projects/universal-timer`).
2. Run the helper:

   ```bash
   skills/new-remote-session/scripts/new-remote-session.sh <abs-repo-path>
   ```

   It names the tmux session after the repo basename, guards against an existing
   session of that name, and runs `claude --remote-control <name>` detached.

   Equivalent one-liner:

   ```bash
   tmux new-session -d -s <name> -c <abs-repo-path> "claude --remote-control <name>"
   ```

3. Report the session name. Never run `tmux attach` — attaching would pull this
   conversation into the new session.

## Notes

- `-d` makes the session detached; this is what keeps it out of the current terminal.
- Attach later (e.g. to debug) with `tmux attach -t <name>`.
- Remote Control surfaces the session in the Claude mobile app under `<name>`.

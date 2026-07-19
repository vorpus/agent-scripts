# Agent Instructions

Shared hard rules for Codex/Claude-style agents. Add rules below over time.

## Skills

New skills belong in `~/projects/agent-scripts/skills/<name>/SKILL.md`, committed to
that repo. Never write skills to `~/.claude/skills` or `~/.agents/skills` as loose
files — `~/.claude/skills` is a symlink into the repo, so anything written there
lands in git untracked or clobbers real work.

Front matter is required; keep `description` short, quoted, and generic (it is
routing text, not documentation):

```yaml
---
name: skill-name
description: "Short generic trigger phrase."
---
```

Third-party installers that offer to "install a skill" are writing into that
symlinked repo. Check where they write before running them, especially if they
`rmtree` a target directory on reinstall.

# Agent Scripts

Shared agent instructions, skills, and small portable helpers for my local workspaces.

This repo is the canonical place for:
- `AGENTS.MD`: shared hard rules for Codex/Claude-style agents
- `skills/`: reusable workflow skills, including repo-owned skills exposed by symlink
- `scripts/`: dependency-light helpers used across projects
- `hooks/`: local guardrails such as skill validation

## Skills

Skills are the main routing layer. Each `skills/<name>/SKILL.md` has YAML front matter:

```yaml
---
name: skill-name
description: "Short generic trigger phrase."
---
```

Rules:
- Keep descriptions short and generic; optimize for routing, not documentation.
- Keep skill bodies terse and operational.
- Prefer helper scripts under `skills/<name>/scripts/` when a workflow has repeatable commands.
- Quote `description` in front matter.

Global discovery usually points here:
- `~/.claude/skills -> ~/projects/agent-scripts/skills`
- `~/.codex/skills -> ~/projects/agent-scripts/skills`

Shared personal skills live as real folders in `skills/`. Repo-owned skills stay canonical in their own repo and are exposed here via tracked relative symlinks, for example:

```text
skills/<name> -> ../../<repo>/.agents/skills/<name>
```

## Agent Instructions

Shared hard rules live in `AGENTS.MD`.

Global setup:
- `~/.claude/CLAUDE.md -> ~/projects/agent-scripts/AGENTS.MD`
- `~/.claude/AGENTS.md -> ~/projects/agent-scripts/AGENTS.MD`
- `~/.codex/AGENTS.md -> ~/projects/agent-scripts/AGENTS.MD`

Downstream repos should use a pointer-style `AGENTS.MD`:

```text
READ ~/projects/agent-scripts/AGENTS.MD BEFORE ANYTHING (skip if missing).
```

Repo-specific rules go below that pointer. Do not copy the shared blocks into downstream repos.

## Helpers

Dependency-light helpers live under `scripts/`. Keep them portable: no repo-specific imports or path aliases.

## Syncing

Treat this repo as canonical for shared agent rules and portable helper scripts.

When syncing downstream repos:
- Pull latest here first.
- Ensure each target repo starts with the pointer-style `AGENTS.MD`.
- Preserve repo-local rules below the pointer.
- Copy helper changes both directions only when the helper is meant to stay byte-identical.
- Keep scripts dependency-free and portable; no repo-specific imports or path aliases.

For submodules, repeat the pointer check inside each subrepo, push those changes, then bump submodule SHAs in the parent repo.

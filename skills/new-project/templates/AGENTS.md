READ ~/projects/agent-scripts/AGENTS.MD BEFORE ANYTHING (skip if missing).

# {{PROJECT}} — Agent Instructions

Source of truth for this project's conventions, decisions, and constraints.
Keep it updated as they are set.

## Orchestration
- Fable 5 is the director/orchestrator. Delegate to subagents rather than doing
  everything in one context.
- Pick each subagent's model to fit the task: fast/cheap models for mechanical or
  well-scoped work, stronger models for hard reasoning or ambiguous design.

## Documentation
- `docs/` holds all Markdown: PRDs, research, milestones, work breakdowns, work
  logs. Keep it organized and current as the project evolves.
- Product requirements go in `docs/PRD.md` once written.

## README
- Maintain `README.md` at the root with build, run, and setup commands. Update it
  immediately when commands, dependencies, or setup steps change.

## Git
- Push regularly — don't leave finished work sitting local.
- Short commit titles and messages. No co-authors, no trailers.

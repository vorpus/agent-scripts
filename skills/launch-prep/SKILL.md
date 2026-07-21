---
name: launch-prep
description: "Check a product is ready to ship and generate its launch copy."
---

# Launch Prep

Run before shipping a project. Two parts: **audit** the thing is presentable,
then **generate** the copy to announce it. Ask the user for the target (a URL, a
repo path, or a GitHub slug) if they didn't give one.

## 1. Audit

Detect the target type and run the matching check.

### Website (a URL)

```bash
python3 skills/launch-prep/scripts/og-scan.py <url>
```

Reports which social/SEO meta tags are present. `XX` = critical tag missing (the
link will share badly — no title card, no preview image); `.` = nice-to-have.
Then eyeball the landing page itself for: a one-line value prop above the fold, a
clear primary CTA, and no lorem/placeholder text. Report what's missing; don't
fix unless asked.

### OSS repo (path or GitHub slug)

Read the README and judge it as a **visitor deciding whether to try this**, not
as its author. A good launch README leads with what it is and why you'd want it,
then a fast quickstart. Flag it if:

- It opens with architecture, internals, or a wall of config before saying what
  the thing *does*.
- There's no one-line description or no quickstart.
- It reads like dev notes (TODOs, "how I built this") rather than a pitch.

Report concrete fixes. The bar is "a stranger gets it in 10 seconds," not
completeness.

### Machine-local references (any repo)

Run on any repo before it goes public or gets a contributor:

```bash
python3 skills/launch-prep/scripts/local-refs.py [repo-path]
```

Flags references that only make sense on this machine:

- **HIGH** — absolute home paths (`/Users/you`, `/home/you`), your username. These
  are broken on anyone else's machine; strip them or make them relative/configurable.
- **MED** — `~/projects`, `~/.claude|.codex/skills`, the `agent-scripts` pointer,
  personal config dirs. Won't error but will confuse a contributor.
- **INFO** — `localhost`/loopback, email addresses. Usually fine; review in context.

Exits 1 if any HIGH finding, so it doubles as a pre-ship gate. It scans
git-tracked files (falling back to a tree walk) and detects your home/username at
runtime, so it's not hardcoded to one machine. Report findings and offer to fix;
don't rewrite paths unattended.

> Note: projects scaffolded by `new-project` carry `~/projects/agent-scripts/AGENTS.MD`
> in AGENTS.md — this will show up as MED. It's `(skip if missing)` so it degrades
> gracefully, but decide whether to keep it before open-sourcing.

## 2. Generate

Always produce both. These are drafts for the user to pick from — generate, show,
don't commit or post anything.

### 5 lines for the vorpus profile README

The profile README is `vorpus/vorpus` → `README.md` (renders at
github.com/vorpus). Its "Current Projects" list uses one exact format per entry:

```
- <emoji> **[name](url)** - punchy one-liner, lowercase-ish, concrete benefit
```

Match it. Study the existing entries first (`gh api repos/vorpus/vorpus/readme
-q .content | base64 -d`) so the voice fits — playful, specific, benefit-first,
no period at the end. Give 5 variants of the one-liner for the new project.

### 5 tweets

Describe the product for launch. Vary the angle across the five — e.g. the
problem it kills, a "you can now X" hook, a concrete before/after, the demo
one-liner, the technical flex. Keep each under 280 chars, no hashtag soup, at
most one link. These are drafts — the user posts them (see `twitter-read`; this
skill never posts).

## Notes

- `og-scan.py` is stdlib-only and portable; keep it dependency-free.
- Generation output is per-session — never write drafts to the repo.

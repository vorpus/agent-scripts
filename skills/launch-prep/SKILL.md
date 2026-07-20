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

---
name: imagegen
description: "Generate raster images (PNG/JPEG/WebP) from a text prompt."
---

# imagegen

Minimal single-file, stdlib-only Python CLI that generates images with the
user's ChatGPT subscription via the Codex backend
(`chatgpt.com/backend-api/codex/responses`, `image_generation` tool). It reuses
the OAuth token `codex login` writes to `~/.codex/auth.json` — no API key.

Trimmed-down rewrite of [leeguooooo/chatgpt-imagegen](https://github.com/leeguooooo/chatgpt-imagegen)
(MIT): no browser backend, no style gallery, no update checks, no telemetry.
The only endpoints it ever contacts are `chatgpt.com` and `auth.openai.com`.

## Invoke

Run the script by absolute path next to this SKILL.md:

```bash
"<skill-dir>/imagegen" "<prompt>" -o path/to/out.png [options]
```

| Flag | Notes |
| --- | --- |
| `-o PATH` | Output file. Without it: `<prompt-slug>.png` in cwd, auto-numbered. With it: overwrites silently. |
| `--size` | `auto` (default), `1024x1024`, `1536x1024` (landscape), `1024x1536` (portrait) |
| `--format` | `png` (default), `jpeg`, `webp` |
| `-i IMG, --ref IMG` | Reference image (path or URL) for image-to-image; repeatable |
| `--model` | Default `gpt-5.5` (or `$IMAGEGEN_MODEL`) |
| `--timeout` / `--stall-timeout` | Total budget 300s / max backend silence 120s |
| `-q, --quiet` | Silence stderr progress; stdout is always just the saved path |

stdout carries exactly the saved path, so `OUT=$("$CLI" "..." -q)` works.

## Rules

- **Every call bills the metered Codex-usage bucket** of the user's ChatGPT
  plan (shared with their own Codex use). Don't loop generating variants; if an
  image is wrong, change the prompt once and regenerate.
- Save into the workspace (repo assets dir or wherever the user said), never
  `/tmp` or `$HOME`. Echo the final path back to the user.
- Keep parallel runs ≤ 4 — more can trip the account rate limiter.
- A single image takes ~15–60 s (occasionally 2–3 min for large/detailed ones).

## Errors

| Symptom | Fix |
| --- | --- |
| `~/.codex/auth.json not found` / `no OAuth access_token` | User must run `codex login` (needs `npm i -g @openai/codex`) |
| `HTTP 401/403` once | Auto-refreshed and retried — no action |
| `token refresh failed` | User must run `codex login` again |
| `HTTP 429` | Rate-limited — wait a few minutes, don't retry in a loop |
| `stalled` / `timed out` | Retry; for very large images raise `--timeout` |
| `no image returned` | Model skipped the tool — rephrase the prompt to name the image explicitly |

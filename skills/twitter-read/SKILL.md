---
name: twitter-read
description: "Read Twitter/X — home timeline, tweets, threads, user posts."
---

# Twitter Read

Read-only Twitter/X access via `twitter-cli`. **Drafting is allowed; posting is not.**

## Read-only rule

Never run these subcommands, even if they would satisfy the request:

```
post  reply  quote  delete  like  retweet  follow  unfollow  bookmark  unbookmark
```

The session authenticates as the user's **main** account, so these are live and
irreversible. `twitter --help` lists them alongside the read commands — the tool
does not gate them behind extra config. Draft to a file the user names and let
them publish; ask for the destination rather than inventing one.

## Commands

Global flags go **before** the subcommand (`twitter -c feed`, not `twitter feed -c`):

```bash
twitter -c feed -n 20              # home timeline — most stable
twitter -c tweet URL_OR_ID         # single tweet + replies
twitter -c user-posts @user -n 20  # user timeline
twitter -c article URL_OR_ID       # long-form / X Article
twitter -c user @user              # profile
twitter status                     # auth check — "ok: true" when good
```

`-c` is compact/LLM-friendly output. Use it by default.

## Notes

- **`search` is unreliable** in 0.8.5 (observed HTTP 503). X changes GraphQL
  endpoints often and the pinned version is from 2026-03-17. Retry once; if it
  persists, route around it with `feed` or `user-posts`.
- **Auth needs no setup.** `twitter-cli` bundles `browser_cookie3` and reads
  `auth_token` + `ct0` from the browser at call time (order: arc, chrome, edge,
  firefox, brave). Nothing is written to disk — do not extract or store cookies.
- **Don't run from a VPS/datacenter IP.** `followers`/`following` especially are
  ban-flagged. Local only.
- Cookie-session reads are against X's automation policy on paper; enforcement
  targets posting. Keep volume low and don't automate on a schedule.

## Install

```bash
pipx install 'twitter-cli==0.8.5'
```

Pin the version — upstream is unpinned by default and X-facing clients break often.

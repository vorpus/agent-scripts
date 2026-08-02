---
name: asc-release
description: "App Store Connect release operations: metadata, screenshots, build attach, submit for review."
---

# ASC release operations

Drive App Store Connect (metadata edits, screenshot uploads, attaching a
build to a version, submitting for App Review) via the audited fork at
`~/projects/app-store-release-agent` (fork of dragosroua/app-store-release-agent,
Apache 2.0). This covers the **post-upload** half of a release; building and
uploading the IPA stays in each app repo's own tooling.

## Setup (once per machine)

Credentials live outside every repo in `~/.asc-workspace/` (mode 700):

```
source ~/.asc-workspace/env.sh   # ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH, ASC_WORKSPACE_DIR
```

If `env.sh` still has `FILL_ME` placeholders, stop and ask the operator to
generate an ASC API key (App Store Connect → Users and Access → Integrations
→ Team Keys, role **App Manager**) and drop the `.p8` in
`~/.asc-workspace/keys/`. Never copy the `.p8` or the ids into any repo,
prompt, or log.

Toolkit venv: `~/projects/app-store-release-agent/.venv` (create with
`python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`).

## Commands

Run from `~/projects/app-store-release-agent`, with env sourced, using
`.venv/bin/python`:

```
src/smoke_test.py                      # list all apps + live versions; run first
src/fetch_metadata.py                  # mirror every app's live metadata into $ASC_WORKSPACE_DIR
src/patch_metadata.py --app <slug> --locale en-US --field keywords --file <f>   # metadata PATCH
src/patch_metadata.py --app <slug> --upload-screenshots DIR --display-type APP_IPHONE_65
src/patch_metadata.py --app <slug> --attach-build BUILD_ID
src/patch_metadata.py --app <slug> --submit-for-review
```

App slugs are derived from the ASC app name (one folder per app under
`$ASC_WORKSPACE_DIR`) — the toolkit is multi-app; never hardcode one app.

## Rules

- Every mutating command is **dry-run by default**; run the dry-run, show the
  operator the diff/endpoint output, and only then re-run with `--apply`.
- `--submit-for-review --apply` is the point of no return — always get an
  explicit operator confirmation for that specific invocation, even in an
  otherwise autonomous session.
- After any applied mutation, prepend an entry to
  `$ASC_WORKSPACE_DIR/<slug>/changelog.md` (template:
  `templates/changelog.example.md` in the toolkit repo). Failed attempts get
  entries too — no silent failures.
- After a manual change made in the ASC web UI, run `fetch_metadata.py` to
  re-sync the mirror, and backfill a changelog entry for what was done.
- Metadata files in the mirror are the drafting surface: edit the file, PATCH
  from it, keep it as the canonical copy.

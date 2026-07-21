#!/usr/bin/env python3
"""Scan a repo for machine-local references that won't make sense to contributors.

Finds absolute home paths, personal config dirs, local-skill/agent-scripts
pointers, and other things that exist only on the author's machine. Meant to run
before a repo goes public or gets its first contributor.

Dependency-free (stdlib only). Scans git-tracked files when in a git repo,
otherwise walks the tree skipping the usual junk.

Usage: local-refs.py [repo-path]   (defaults to cwd)
Exit:  1 if any HIGH findings, else 0. 2 on usage error.
"""
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")
USER = os.environ.get("USER") or os.path.basename(HOME)

# (severity, label, regex). HIGH = definitely won't exist elsewhere.
PATTERNS = [
    ("HIGH", "your home path", re.compile(re.escape(HOME))),
    ("HIGH", "macOS user dir", re.compile(r"/Users/[A-Za-z0-9._-]+")),
    ("HIGH", "linux home dir", re.compile(r"/home/[A-Za-z0-9._-]+")),
    ("HIGH", "your username", re.compile(r"\b%s\b" % re.escape(USER)) if USER not in ("", "user", "root") else None),
    ("MED", "agent-scripts pointer", re.compile(r"agent-scripts")),
    ("MED", "local skills dir", re.compile(r"\.(claude|codex)/skills")),
    ("MED", "personal config dir", re.compile(r"~/\.(claude|codex|config|ssh|aws|agent-reach|nvm)\b")),
    ("MED", "~/projects reference", re.compile(r"~/projects\b")),
    ("INFO", "localhost/loopback", re.compile(r"\b(localhost|127\.0\.0\.1|0\.0\.0\.0)\b")),
    ("INFO", "email address", re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")),
]
PATTERNS = [p for p in PATTERNS if p[2] is not None]

SKIP_EXT = {
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".icns", ".webp", ".pdf",
    ".zip", ".gz", ".tar", ".woff", ".woff2", ".ttf", ".otf", ".mp4", ".mov",
    ".lock", ".min.js", ".map",
}
SKIP_DIR = {".git", "node_modules", ".venv", "venv", "dist", "build", "__pycache__", ".next"}
MAX_BYTES = 512 * 1024
MAX_FINDINGS = 300


def list_files(root):
    try:
        out = subprocess.run(
            ["git", "-C", root, "ls-files", "-z"],
            capture_output=True, text=True, timeout=30,
        )
        if out.returncode == 0 and out.stdout:
            return [os.path.join(root, p) for p in out.stdout.split("\0") if p]
    except Exception:
        pass
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIR]
        for fn in filenames:
            files.append(os.path.join(dirpath, fn))
    return files


def scan_file(path):
    _, ext = os.path.splitext(path)
    if ext.lower() in SKIP_EXT:
        return []
    try:
        if os.path.getsize(path) > MAX_BYTES:
            return []
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except (OSError, UnicodeDecodeError):
        return []  # binary or unreadable

    order = {"HIGH": 0, "MED": 1, "INFO": 2}
    hits = []
    for i, line in enumerate(lines, 1):
        matched = [(sev, label) for sev, label, rx in PATTERNS if rx.search(line)]
        if not matched:
            continue
        # One finding per line: highest severity, all reasons joined.
        best = min((sev for sev, _ in matched), key=lambda s: order[s])
        labels = ", ".join(dict.fromkeys(label for _, label in matched))
        hits.append((best, labels, i, line.strip()[:100]))
    return hits


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    if not os.path.isdir(root):
        print("no such directory: %s" % root, file=sys.stderr)
        return 2
    root = os.path.abspath(root)

    order = {"HIGH": 0, "MED": 1, "INFO": 2}
    findings = []
    for path in list_files(root):
        rel = os.path.relpath(path, root)
        for sev, label, ln, snippet in scan_file(path):
            findings.append((order[sev], sev, label, rel, ln, snippet))

    findings.sort(key=lambda f: (f[0], f[3], f[4]))
    truncated = len(findings) > MAX_FINDINGS
    findings = findings[:MAX_FINDINGS]

    counts = {"HIGH": 0, "MED": 0, "INFO": 0}
    cur = None
    for _, sev, label, rel, ln, snippet in findings:
        counts[sev] += 1
        if sev != cur:
            print("\n== %s ==" % sev)
            cur = sev
        print("  %s:%d  [%s]  %s" % (rel, ln, label, snippet))

    print("\n%d HIGH, %d MED, %d INFO%s"
          % (counts["HIGH"], counts["MED"], counts["INFO"],
             "  (truncated)" if truncated else ""))
    print("(scanned as user '%s', home '%s')" % (USER, HOME))
    return 1 if counts["HIGH"] else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Print the unsent draft sitting in a Claude session's input box, if any.

Reads a `tmux capture-pane` dump on stdin. The input box is the last line
beginning with the prompt caret U+276F. Note the caret is followed by a
NO-BREAK SPACE (U+00A0), not an ASCII space — which is why grep patterns
written with a normal space silently never match.

Submitted prompts also render with a caret in the scrollback, but the input box
is always the bottom-most one, so the last match is the right one. An empty box
yields nothing.
"""
import sys

CARET = "❯"

draft = ""
for line in sys.stdin.read().splitlines():
    if line.startswith(CARET):
        draft = line[len(CARET):].strip("  \t")

if draft:
    print(draft)

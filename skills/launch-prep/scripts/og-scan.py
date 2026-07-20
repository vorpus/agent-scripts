#!/usr/bin/env python3
"""Scan a landing page for the meta tags that make it share well.

Dependency-free (stdlib only). Fetches URL, reports which social/SEO meta
tags are present, prints found values truncated. Exit 0 always unless the
fetch itself fails (then exit 2), so callers can read the checklist either way.

Usage: og-scan.py <url>
"""
import sys
import urllib.request
from html.parser import HTMLParser

# (key, human label, critical?) — critical ones are what break a shared link
CHECKS = [
    ("title", "<title>", True),
    ("description", "meta description", True),
    ("og:title", "og:title", True),
    ("og:description", "og:description", True),
    ("og:image", "og:image", True),
    ("og:url", "og:url", False),
    ("og:type", "og:type", False),
    ("twitter:card", "twitter:card", True),
    ("twitter:title", "twitter:title", False),
    ("twitter:description", "twitter:description", False),
    ("twitter:image", "twitter:image", False),
    ("canonical", "canonical link", False),
    ("favicon", "favicon", False),
]


class MetaParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.found = {}
        self._in_title = False

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "title":
            self._in_title = True
        elif tag == "meta":
            key = a.get("property") or a.get("name")
            content = a.get("content")
            if key and content and key not in self.found:
                self.found[key] = content
        elif tag == "link":
            rel = (a.get("rel") or "").lower()
            if "canonical" in rel and "canonical" not in self.found:
                self.found["canonical"] = a.get("href", "")
            if "icon" in rel and "favicon" not in self.found:
                self.found["favicon"] = a.get("href", "")

    def handle_data(self, data):
        if self._in_title and data.strip() and "title" not in self.found:
            self.found["title"] = data.strip()

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False


def fetch(url):
    if not url.startswith(("http://", "https://")):
        url = "https://" + url
    req = urllib.request.Request(
        url, headers={"User-Agent": "Mozilla/5.0 (launch-prep og-scan)"}
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        return resp.read().decode(charset, errors="replace"), resp.geturl()


def main():
    if len(sys.argv) != 2:
        print("usage: og-scan.py <url>", file=sys.stderr)
        return 2
    try:
        html, final_url = fetch(sys.argv[1])
    except Exception as e:
        print("FETCH FAILED: %s" % e, file=sys.stderr)
        return 2

    p = MetaParser()
    p.feed(html)
    f = p.found

    print("Scanned: %s\n" % final_url)
    missing_critical = []
    for key, label, critical in CHECKS:
        val = f.get(key)
        mark = "OK " if val else ("XX " if critical else " . ")
        tag = " (critical)" if critical and not val else ""
        shown = (val[:70] + "…") if val and len(val) > 70 else (val or "MISSING")
        print("  [%s] %-22s %s%s" % (mark.strip() or ".", label, shown, tag))
        if critical and not val:
            missing_critical.append(label)

    print()
    if missing_critical:
        print("MISSING CRITICAL: " + ", ".join(missing_critical))
    else:
        print("All critical share tags present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Static checks for a wireframe folder: broken local links and lo-fi style slips.

Usage: python3 check.py <prototype-dir>
Exit code 1 when broken links are found. Style findings are for review: codes and
product swatches are legitimate exceptions. Script errors and layout still need a
browser pass.
"""
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

ACRONYMS = {"FAQS", "NZBN", "SKUS", "GA4"}


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "a" and a.get("href"):
            self.hrefs.append(a["href"])


def is_colour(value: str) -> bool:
    """True when a hex or rgb() value is not a grey (its channels differ noticeably)."""
    if value.startswith("#"):
        h = value[1:]
        if len(h) == 3:
            h = "".join(c * 2 for c in h)
        if len(h) != 6:
            return False
        ch = [int(h[i:i + 2], 16) for i in (0, 2, 4)]
    else:
        ch = [int(x) for x in re.findall(r"\d+", value)[:3]]
        if len(ch) < 3:
            return False
    return max(ch) - min(ch) > 24


def main(root: Path) -> int:
    pages = sorted(root.glob("*.html"))
    assets = root / "assets"
    files = pages + (sorted(assets.glob("*.js")) + sorted(assets.glob("*.css")) if assets.exists() else [])
    broken, style = [], []

    for page in pages:
        p = Links()
        p.feed(page.read_text(encoding="utf-8"))
        for h in p.hrefs:
            if h.startswith(("#", "http:", "https:", "mailto:", "tel:", "javascript:")) or "${" in h:
                continue
            target = h.split("#")[0].split("?")[0]
            if target and not (root / target).exists():
                broken.append(f"{page.name} -> {h}")

    for f in files:
        text = re.sub(r"<title>.*?</title>", "", f.read_text(encoding="utf-8"), flags=re.S)
        for n, line in enumerate(text.splitlines(), 1):
            if "—" in line and "document.title" not in line and not re.search(r">\s*—\s*<|'—'|\"—\"|`—`", line):
                style.append(f"{f.name}:{n} em dash")
            if re.search(r"text-transform:\s*uppercase", line):
                style.append(f"{f.name}:{n} uppercase transform")
            if re.search(r"border-left-width|border-left:\s*[3-9]px", line):
                style.append(f"{f.name}:{n} thick left accent border")
            if f.suffix in (".html", ".css") and "note" not in line:
                for v in re.findall(r"(?<![\w-])#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?(?![\w-])|rgba?\([^)]*\)", line):
                    if is_colour(v):
                        style.append(f"{f.name}:{n} colour {v}")
            for chunk in re.findall(r">[^<]+<", line):
                for w in re.findall(r"\b[A-Z]{4,}\b", chunk):
                    if w not in ACRONYMS:
                        style.append(f"{f.name}:{n} all-caps '{w}'")

    print(f"{len(pages)} pages checked")
    print(f"broken links: {len(broken)}")
    for b in broken:
        print("  " + b)
    print(f"style findings: {len(style)} (codes and product swatches are expected exceptions)")
    for s in style:
        print("  " + s)
    return 1 if broken else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sys.exit(main(Path(sys.argv[1])))

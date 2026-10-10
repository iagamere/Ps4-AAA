#!/usr/bin/env python3
"""errors.txt = every line containing the word 'error' (case-insensitive) with 3 lines of context
before and after; overlapping windows are merged. Usage: extract_errors.py build.log errors.txt"""
import re, sys

src, dst = sys.argv[1], sys.argv[2]
try:
    lines = open(src, encoding="utf-8", errors="replace").read().splitlines()
except OSError:
    lines = []
pat = re.compile(r"\berror\b", re.I)
hits = [i for i, l in enumerate(lines) if pat.search(l)]

out, last_end = [], -1
for i in hits:
    a, b = max(0, i - 3), min(len(lines) - 1, i + 3)
    if a <= last_end:
        a = last_end + 1
    elif out:
        out.append("-----")
    out.extend(lines[a:b + 1])
    last_end = max(last_end, b)

if not out:
    out = ["(no line containing 'error' was found; see build.log)"]
open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")

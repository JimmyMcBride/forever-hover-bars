#!/usr/bin/env python3
"""Run standalone checks from any working directory."""
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
lua_files = sorted(str(path.relative_to(ROOT)) for path in ROOT.glob("*.lua"))
lua_files += ["tests/run.lua"]
subprocess.run(["luac5.1", "-p", *lua_files], cwd=ROOT, check=True)
subprocess.run(["lua5.1", "tests/run.lua"], cwd=ROOT, check=True)

for path in [*ROOT.glob("*.lua"), *ROOT.glob("*.toc"), *ROOT.glob("*.md"),
             *ROOT.glob("docs/*.md"), *ROOT.glob("tests/*.lua"), *ROOT.glob("tools/*.py")]:
    text = path.read_text(encoding="utf-8")
    assert text.endswith("\n"), f"Missing final newline: {path.name}"
    assert all(line == line.rstrip() for line in text.splitlines()), f"Trailing whitespace: {path.name}"
    if path.suffix == ".md":
        for link in re.findall(r"\]\(([^)]+)\)", text):
            if "://" not in link and not link.startswith("#"):
                assert (path.parent / link.split("#")[0]).exists(), f"Broken link: {link}"
print("Syntax, behavior, mocked integration, Markdown links, and whitespace checks passed.")

#!/usr/bin/env python3
"""Build and verify a deterministic, installable ZIP without development files."""
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
toc = ROOT / "ForeverHoverBars.toc"
text = toc.read_text(encoding="utf-8")
version = re.search(r"^## Version: ([0-9]+\.[0-9]+\.[0-9]+)$", text, re.MULTILINE).group(1)
runtime = [line.strip() for line in text.splitlines() if line.strip() and not line.startswith("#")]
assert runtime == ["Config.lua", "Visibility.lua", "Options.lua", "Core.lua"], "Unexpected TOC load order"
files = [toc.name, *runtime, "README.md"]
output = ROOT / "dist" / f"ForeverHoverBars-{version}.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(output, "w", compression=ZIP_DEFLATED) as archive:
    for name in files:
        entry = ZipInfo("ForeverHoverBars/" + name, date_time=(1980, 1, 1, 0, 0, 0))
        entry.compress_type = ZIP_DEFLATED
        entry.external_attr = 0o100644 << 16
        archive.writestr(entry, (ROOT / name).read_bytes())
with ZipFile(output) as archive:
    assert archive.testzip() is None, "Corrupt ZIP entry"
    assert set(archive.namelist()) == {"ForeverHoverBars/" + name for name in files}
    for name in files:
        assert archive.read("ForeverHoverBars/" + name) == (ROOT / name).read_bytes()
print(output)
print(f"Verified {len(files)} files under one ForeverHoverBars/ directory.")

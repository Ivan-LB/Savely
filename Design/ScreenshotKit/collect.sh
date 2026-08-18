#!/bin/bash
# Renames the XCTest attachments exported by `xcresulttool export attachments`
# into the slugs compose.swift expects.
#   collect.sh <exported-attachments-dir> <captures-out-dir>
set -euo pipefail
IN="${1:?usage: collect.sh <attachments-dir> <out-dir>}"
OUT="${2:?usage: collect.sh <attachments-dir> <out-dir>}"
mkdir -p "$OUT"
python3 - "$IN" "$OUT" <<'PY'
import json, os, shutil, sys
src, out = sys.argv[1], sys.argv[2]
manifest = json.load(open(os.path.join(src, "manifest.json")))
for test in manifest:
    for att in test.get("attachments", []):
        name = att.get("suggestedHumanReadableName", "")
        if name[:2].isdigit():
            slug = name.split("_")[0]
            shutil.copy(os.path.join(src, att["exportedFileName"]), os.path.join(out, slug + ".png"))
            print(slug)
PY

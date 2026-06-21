#!/usr/bin/env python3
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
path = root / "scripts/field/room_visual_renderer.gd"
text = path.read_text(encoding="utf-8")
pattern = re.compile(r"(?m)^func\s+([A-Za-z0-9_]+)\s*\(")
starts = [(m.start(), m.group(1)) for m in pattern.finditer(text)]
functions = []
bodies = []
for index, (start, name) in enumerate(starts):
    end = starts[index + 1][0] if index + 1 < len(starts) else len(text)
    body = text[start:end].rstrip()
    if "wall" not in name.lower():
        continue
    start_line = text.count("\n", 0, start) + 1
    end_line = text.count("\n", 0, end) + 1
    functions.append({"name": name, "start_line": start_line, "end_line": end_line, "loc": end_line - start_line + 1})
    bodies.append(body)

(root / "docs/wall_renderer_inventory.tmp.json").write_text(json.dumps(functions, indent=2), encoding="utf-8")
(root / "docs/wall_renderer_functions.tmp.txt").write_text("\n\n".join(bodies), encoding="utf-8")
print(f"wall functions: {len(functions)}")

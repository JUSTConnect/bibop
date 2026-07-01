#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / "scripts/game/cooling/active_cooling_box_service.gd"
text = path.read_text(encoding="utf-8") if path.exists() else ""

checks = [
    ("service exists", path.exists() and "class_name ActiveCoolingBoxService" in text),
    ("side enum", "VALID_OUTPUT_SIDES" in text and all(side in text for side in ["NE", "SE", "SW", "NW"])),
    ("legacy flags", "LEGACY_OUTPUT_FLAGS" in text and "result.erase(str(flag_name))" in text),
    ("output normalization", 'result["output_side"] = output_side' in text),
    ("read only preview", '"read_only": true' in text and '"mutates_target": false' in text),
    ("stable target codes", "CODE_TARGET_BROKEN" in text and "CODE_TARGET_DAMAGED" in text),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    raise SystemExit(1)

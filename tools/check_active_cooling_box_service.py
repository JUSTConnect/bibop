#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
service_path = root / "scripts/game/cooling/active_cooling_box_service.gd"
service = service_path.read_text(encoding="utf-8") if service_path.exists() else ""

checks = [
    ("active cooling service exists", service_path.exists() and "class_name ActiveCoolingBoxService" in service),
    ("stable output sides are defined", 'VALID_OUTPUT_SIDES: Array[String] = ["NE", "SE", "SW", "NW"]' in service),
    ("legacy output flags are removed", "LEGACY_OUTPUT_FLAGS" in service and "result.erase(str(flag_name))" in service),
    ("normalization emits one output_side", 'result["output_side"] = output_side' in service and 'result["cooling_output_side"] = output_side' in service),
    ("preview is read only", '"read_only": true' in service and '"mutates_target": false' in service),
    ("damaged and broken targets are not repaired", "CODE_TARGET_BROKEN" in service and "CODE_TARGET_DAMAGED" in service),
    ("passive route fields are not stored", all(token in service for token in ["flow_state", "blocked_state", "linked_cooling_ids"])),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    raise SystemExit(1)

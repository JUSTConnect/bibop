#!/usr/bin/env python3
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
errors = []
store = ROOT / "scripts/world/world_state_store.gd"
manager = ROOT / "scripts/game/mission_manager.gd"
workflow = ROOT / ".github/workflows/godot-parser-gate.yml"
if not store.exists(): errors.append("WorldStateStore file is missing")
text = store.read_text() if store.exists() else ""
for needle in ["class_name WorldStateStore", "_objects_by_id", "_object_order", "_floor_object_ids_by_cell", "_item_ids_by_cell", "_wall_mount_ids_by_cell", "validate_consistency"]:
    if needle not in text: errors.append(f"WorldStateStore missing {needle}")
if re.search(r"^var\s+[^_].*ids_by_cell", text, re.M):
    errors.append("WorldStateStore index containers must remain private")
mt = manager.read_text()
for needle in ["WorldStateStoreRef", "var world_state_store: WorldStateStore", "world_state_store.get_all_objects()", "world_state_store.get_floor_lookup_snapshot()", "world_state_store.get_cell_items_snapshot()"]:
    if needle not in mt: errors.append(f"MissionManager missing store integration: {needle}")
for retired in [
    r"var\s+mission_world_objects\s*[:=].*\[\]",
    r"var\s+world_objects_by_cell\s*[:=].*\{\}",
    r"var\s+wall_mounted_objects_by_cell\s*[:=].*\{\}",
    r"var\s+cell_items\s*[:=].*\{\}",
]:
    if re.search(retired, mt): errors.append(f"retired mutable field remains: {retired}")
for func in ["set_world_object_at_cell", "remove_world_object_at_cell", "add_item_at_cell", "remove_first_item_at_cell"]:
    m = re.search(rf"func\s+{func}\b[\s\S]*?(?=\nfunc\s|\Z)", mt)
    if not m or "world_state_store" not in m.group(0): errors.append(f"{func} does not delegate to WorldStateStore")
for path in (ROOT / "scripts").rglob("*.gd"):
    if path == store: continue
    rel = path.relative_to(ROOT).as_posix()
    t = path.read_text()
    if re.search(r"\._(floor_object_ids_by_cell|item_ids_by_cell|wall_mount_ids_by_cell|objects_by_id|object_order)\b", t):
        errors.append(f"external private store index access in {rel}")
if workflow.exists():
    wt = workflow.read_text()
    if "python tools/check_world_state_store.py" not in wt: errors.append("CI does not run static WorldStateStore audit")
    if "check_world_state_store.gd" not in wt: errors.append("CI does not run executable WorldStateStore gate")
else:
    errors.append("workflow missing")
if errors:
    print("World state store audit failed:")
    for e in errors: print(f"- {e}")
    sys.exit(1)
print("World state store static audit passed.")

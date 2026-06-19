#!/usr/bin/env python3
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
errors = []
store_path = ROOT / "scripts/world/world_state_store.gd"
manager_path = ROOT / "scripts/game/mission_manager.gd"
workflow_path = ROOT / ".github/workflows/godot-parser-gate.yml"
store = store_path.read_text() if store_path.exists() else ""
manager = manager_path.read_text() if manager_path.exists() else ""
if not store_path.exists(): errors.append("WorldStateStore file is missing")
for needle in ["class_name WorldStateStore", "_objects_by_id", "_object_order", "_primary_object_id_by_cell", "_surface_ids_by_cell", "_platform_ids_by_cell", "_occupant_ids_by_cell", "_route_ids_by_cell", "_item_ids_by_cell", "_wall_mount_ids_by_cell_and_side", "_visual_ids_by_cell", "validate_structural_placement", "validate_consistency"]:
    if needle not in store: errors.append(f"WorldStateStore missing {needle}")
if "func _objects_for_ids" not in store or "duplicate(true)" not in re.search(r"func\s+_objects_for_ids\b[\s\S]*?(?=\nfunc\s|\Z)", store).group(0):
    errors.append("object array read helper must return isolated copies")
if "func get_object_by_id" not in store or "duplicate(true)" not in re.search(r"func\s+get_object_by_id\b[\s\S]*?(?=\nfunc\s|\Z)", store).group(0):
    errors.append("get_object_by_id must return isolated copies")
move = re.search(r"func\s+move_object\b[\s\S]*?(?=\nfunc\s|\Z)", store)
if not move or "object_id_is_immutable" not in move.group(0): errors.append("move_object must reject id changes")
if "object_id_key_mismatch" not in store: errors.append("validate_consistency must check key/field id equality")
if re.search(r"^var\s+[^_].*(ids_by_cell|object_id_by_cell)", store, re.M): errors.append("derived indexes must remain private")
for prop in ["mission_world_objects", "world_objects_by_cell", "wall_mounted_objects_by_cell", "cell_items"]:
    m = re.search(rf"var\s+{prop}\b[\s\S]*?(?=\nvar\s|\nfunc\s|\Z)", manager)
    if not m: errors.append(f"MissionManager missing compatibility getter {prop}")
    elif re.search(r"\n\s*set\s*\(", m.group(0)): errors.append(f"{prop} compatibility property must not define a setter")
if "_rebuild_store_from_compatibility_snapshots" in manager: errors.append("silent compatibility rebuild helper must be absent")
for needle in ["WorldStateStoreRef", "var world_state_store: WorldStateStore", "replace_world_state_snapshot", "try_set_world_object_at_cell", "validate_structural_placement"]:
    if needle not in manager: errors.append(f"MissionManager missing store integration: {needle}")
try_set = re.search(r"func\s+try_set_world_object_at_cell\b[\s\S]*?(?=\nfunc\s|\Z)", manager)
if not try_set or "get_world_object_at_cell" in try_set.group(0) or "remove_object_by_id" in try_set.group(0):
    errors.append("try_set_world_object_at_cell must not delete a generic selected object before placement")
for retired in [r"mission_world_objects\s*=", r"cell_items\s*=", r"world_objects_by_cell\s*=", r"wall_mounted_objects_by_cell\s*=", r"mission_world_objects\.(append|erase|remove_at|clear)", r"cell_items\[[^\]]+\]\s*=", r"world_objects_by_cell\[[^\]]+\]\s*="]:
    if re.search(retired, manager): errors.append(f"retired container mutation remains: {retired}")
# Narrow structural-write audit: allow producers/normalizers/builders and the store itself.
allowlist = [
    "scripts/world/world_state_store.gd", "scripts/world/world_object_catalog.gd", "scripts/game/mission_content_catalog.gd", "scripts/game/task_test_world_builder.gd", "scripts/game/map_constructor_service.gd", "scripts/game/map_constructor_prefab_catalog.gd", "scripts/game/mission_manager.gd", "scripts/bipob/bipob_inventory_controller.gd", "scripts/bipob/bipob_controller.gd", "scripts/game/bipob_terminal_control_execution_service.gd", "scripts/game/bipob_targeting_service.gd", "scripts/game/bipob_platform_control_execution_service.gd", "scripts/game/map_constructor_link_read_model_service.gd", "scripts/game/map_constructor_object_link_layer_service_v2.gd", "scripts/game/platform/platform_occupancy_service.gd", "scripts/game/platform/platform_types.gd", "scripts/game/platform/platform_mechanism_service.gd", "scripts/game/wall/breachable_wall_service.gd", "scripts/game/wall/wall_mounted_placement_rules_service.gd", "scripts/ui/game_ui.gd", "scripts/field/room_visual_renderer.gd",
]
pattern = re.compile(r'\["(id|position|object_group|object_type|mount|wall_side|mount_side|surface|placement_mode|placement|is_wall_mounted|platform_id|on_platform|platform_cell)"\]\s*=')
for path in (ROOT / "scripts").rglob("*.gd"):
    rel = path.relative_to(ROOT).as_posix()
    if rel in allowlist: continue
    text = path.read_text()
    if pattern.search(text): errors.append(f"review structural field write outside allowlist: {rel}")
if workflow_path.exists():
    workflow = workflow_path.read_text()
    if "python tools/check_world_state_store.py" not in workflow: errors.append("CI does not run static WorldStateStore audit")
    if "check_world_state_store.gd" not in workflow: errors.append("CI does not run executable WorldStateStore gate")
else:
    errors.append("workflow missing")
if errors:
    print("World state store audit failed:")
    for e in errors: print(f"- {e}")
    sys.exit(1)
print("World state store static audit passed.")

#!/usr/bin/env python3
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
store = (root / "scripts/world/world_state_store.gd").read_text()
reel = (root / "scripts/game/power_cable_reel_service.gd").read_text()
migration = (root / "scripts/world/versioned_snapshot_migration_service.gd").read_text()
power = (root / "scripts/world/power_system.gd").read_text()
cable = (root / "scripts/game/bipob_cable_runtime_service.gd").read_text()
binding = (root / "scripts/world/world_binding_store_contract.gd").read_text()
mission = (root / "scripts/game/mission_manager.gd").read_text()
task_validation = (root / "scripts/game/task_test_acceptance_validation_service.gd").read_text()
workflow = (root / ".github/workflows/canonical-runtime-ownership-gate.yml").read_text()

legacy_reel_aliases = ["end_1_state", "end_1_target_id", "end_2_state", "end_2_target_id", "cable_path_cells"]
legacy_source_fields = ["power_source_id", "physical_connection_source_id"]

legacy_candidate_callers = []
for path in (root / "scripts").rglob("*.gd"):
    text = path.read_text()
    if "BindingStoreContractRef.legacy_candidates(" in text:
        legacy_candidate_callers.append(path.relative_to(root).as_posix())
legacy_candidate_callers.sort()

runtime_feed_callers = []
for path in (root / "scripts").rglob("*.gd"):
    relative = path.relative_to(root).as_posix()
    if relative in ["scripts/world/world_binding_store_contract.gd", "scripts/world/versioned_snapshot_migration_service.gd"]:
        continue
    text = path.read_text()
    if '"runtime_power_feed"' in text and ("create_binding" in text or "replace_binding" in text or "upsert_binding" in text):
        runtime_feed_callers.append(relative)

renderer_importers = []
for root_name in ["scripts/game", "scripts/world", "scripts/bipob"]:
    for path in (root / root_name).rglob("*.gd"):
        text = path.read_text()
        if any(token in text for token in ["room_visual_renderer.gd", "visual/renderer/object_renderer.gd", "visual/renderer/route_renderer.gd"]):
            renderer_importers.append(path.relative_to(root).as_posix())

power_assignments = []
for relative, text in [("scripts/world/power_system.gd", power), ("scripts/game/bipob_cable_runtime_service.gd", cable)]:
    for field in legacy_source_fields:
        if re.search(rf'\["{re.escape(field)}"\]\s*=', text):
            power_assignments.append(f"{relative}:{field}")

message_inference = []
for pattern in [
    r'issue\.get\("message"[^\n]*\.begins_with\(',
    r'issue\.get\("message"[^\n]*\.contains\(',
    r'issue\.get\("message"[^\n]*\.ends_with\(',
    r'message[^\n]*\.begins_with\(',
    r'message[^\n]*\.contains\(',
]:
    if re.search(pattern, task_validation):
        message_inference.append(pattern)

checks = [
    ("WorldStateStore accepts exact current format", 'snapshot.get("format_version", -1)' in store and 'source_version != WORLD_SNAPSHOT_FORMAT_VERSION' in store),
    ("WorldStateStore has no objects fallback", 'snapshot.get("objects"' not in store),
    ("WorldStateStore has no legacy binding migration", "migrate_legacy_bindings" not in store and "legacy_candidates" not in store and "strip_legacy_logical_links" not in store),
    ("WorldStateStore serializes exact runtime entities", "BindingStoreContractRef.strip_legacy_logical_links" not in store),
    ("legacy binding extraction has one runtime caller", legacy_candidate_callers == ["scripts/world/versioned_snapshot_migration_service.gd"]),
    ("reel migration helper exists", "static func migrate_legacy_reel" in reel),
    ("normal reel canonicalizer is nested-only", "_canonical_endpoint(result.get(END_1, {}))" in reel and "_canonical_endpoint(result.get(END_2, {}))" in reel),
    ("reel runtime never syncs aliases", "_sync_legacy_aliases" not in reel),
    ("reel runtime never assigns aliases", not any(re.search(rf'\["{alias}"\]\s*=', reel) for alias in legacy_reel_aliases)),
    ("versioned loader owns reel alias migration", "PowerCableReelServiceRef.migrate_legacy_reel" in migration),
    ("power runtime has no legacy source assignments", not power_assignments),
    ("power runtime has no virtual main net fallback", "main_power_net" not in power),
    ("power runtime writes resolved source", all(token in power for token in ["resolved_source_id", "resolved_circuit_id"]) and all(token in cable for token in ["resolved_source_id", "resolved_circuit_id"])),
    ("physical runtime feed is never created as binding", not runtime_feed_callers),
    ("BindingStore still rejects physical roles", '"runtime_power_feed"' in binding and '"physical_relation_forbidden"' in binding),
    ("MissionManager loads through versioned service", "VersionedSnapshotMigrationServiceRef.migrate_document" in mission),
    ("TASK TEST validation does not parse messages", not message_inference),
    ("gameplay truth layers do not import renderers", not renderer_importers),
    ("static gate wired", "python tools/check_canonical_runtime_ownership_v2.py" in workflow),
    ("behavior gate wired", "check_canonical_runtime_ownership.gd" in workflow),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if legacy_candidate_callers != ["scripts/world/versioned_snapshot_migration_service.gd"]:
    print("legacy_candidates callers:", legacy_candidate_callers)
if power_assignments:
    print("legacy source assignments:", power_assignments)
if runtime_feed_callers:
    print("physical binding callers:", runtime_feed_callers)
if message_inference:
    print("message inference patterns:", message_inference)
if renderer_importers:
    print("renderer imports in gameplay layers:", renderer_importers)
if failed:
    sys.exit(1)

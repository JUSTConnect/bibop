#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
service_path = root / "scripts/world/versioned_snapshot_migration_service.gd"
world_path = root / "scripts/world/world_state_store.gd"
mission_path = root / "scripts/game/mission_manager.gd"
preset_path = root / "scripts/game/map_constructor_preset_service.gd"
workflow_path = root / ".github/workflows/versioned-migration-contract-gate.yml"

service = service_path.read_text() if service_path.exists() else ""
world = world_path.read_text() if world_path.exists() else ""
mission = mission_path.read_text() if mission_path.exists() else ""
preset = preset_path.read_text() if preset_path.exists() else ""
workflow = workflow_path.read_text() if workflow_path.exists() else ""

load_start = mission.find("func replace_world_state_serialized_snapshot(")
load_end = mission.find("func get_world_state_serializable_snapshot(", load_start)
load_block = mission[load_start:load_end] if load_start >= 0 and load_end > load_start else ""
save_start = mission.find("func get_world_state_serializable_snapshot(")
save_end = mission.find("func _upsert_world_state_object(", save_start)
save_block = mission[save_start:save_end] if save_start >= 0 and save_end > save_start else ""

required_codes = [
    "migrated",
    "already_current",
    "unsupported_newer_version",
    "invalid_document",
    "binding_physical_relation_removed",
    "binding_unsupported_role_removed",
    "binding_duplicate_removed",
    "details_snapshot_invalid",
    "legacy_field_remaining",
]
required_steps = [
    "v0_to_v1_envelope_and_bindings",
    "v1_to_v2_canonical_entities_and_currency",
]

checks = [
    ("migration service exists", service_path.exists() and "class_name VersionedSnapshotMigrationService" in service),
    ("current document format is v2", "CURRENT_FORMAT_VERSION: int = 2" in service and "WORLD_SNAPSHOT_FORMAT_VERSION: int = 2" in world),
    ("sequential migration steps", all(step in service for step in required_steps)),
    ("stable migration codes", all(f'\"{code}\"' in service for code in required_codes)),
    ("preview is pure entry point", "static func preview_migration" in service and "source_document.duplicate(true)" in service),
    ("logical bindings migrate before field cleanup", "BindingStoreContractRef.legacy_candidates" in service and "strip_legacy_logical_links" in service),
    ("physical bindings excluded", "PHYSICAL_RELATION_ROLES" in service and "CODE_BINDING_PHYSICAL_REMOVED" in service),
    ("Details migration centralized", "DetailsCurrencyServiceRef.migrate_world_pickups" in service and "migrate_legacy_parts" in service),
    ("reel migration centralized", "PowerCableReelServiceRef.canonicalize_reel" in service),
    ("movable migration centralized", "MovableActionServiceRef.normalize_movable_contract" in service),
    ("passive route migration centralized", "PassiveRouteServiceRef.normalize_segment" in service),
    ("no proximity inference", "nearest" not in service.lower() and "distance_to" not in service),
    ("MissionManager migrates before commit", "VersionedSnapshotMigrationServiceRef.migrate_document" in load_block and load_block.find("migrate_document") < load_block.find("world_state_store.replace_serialized_snapshot")),
    ("failed migration returns before commit", "if not bool(migration.get(\"success\", false))" in load_block),
    ("save writes canonical v2 envelope", all(token in save_block for token in ['\"format_version\"', '\"details_currency\"', '\"inventory_state\"', '\"center_storage\"'])),
    ("WorldStateStore serializes entities and bindings", '\"entities\"' in world and '\"bindings\"' in world),
    ("preset service is versioned", "SCHEMA_VERSION: int = 2" in preset and "VersionedSnapshotMigrationServiceRef" in preset),
    ("static gate wired", "python tools/check_versioned_snapshot_migration.py" in workflow),
    ("behavior gate wired", "check_versioned_snapshot_migration.gd" in workflow),
    ("MissionManager gate wired", "check_versioned_snapshot_migration_mission_manager.gd" in workflow),
    ("preset gate wired", "check_versioned_map_constructor_preset.gd" in workflow),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    sys.exit(1)

#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
service_path = root / "scripts/world/versioned_snapshot_migration_service.gd"
service = service_path.read_text(encoding="utf-8") if service_path.exists() else ""

checks = [
    ("versioned migration service exists", service_path.exists() and "class_name VersionedSnapshotMigrationService" in service),
    ("machine legacy logical field list exists", "LEGACY_MACHINE_LOGICAL_FIELDS" in service),
    ("linked_object_ids is treated as legacy", '"linked_object_ids"' in service),
    ("canonicalization strips machine logical links", "_strip_machine_logical_links" in service and "entity = _strip_machine_logical_links(entity)" in service),
    ("current format validation rejects machine legacy links", "fields.append_array(LEGACY_MACHINE_LOGICAL_FIELDS)" in service),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    raise SystemExit(1)

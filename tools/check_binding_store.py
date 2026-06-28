#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
wss_path = root / "scripts/world/world_state_store.gd"
contract_path = root / "scripts/world/world_binding_store_contract.gd"
workflow_path = root / ".github/workflows/godot-parser-gate.yml"
mission_path = root / "scripts/game/mission_manager.gd"
prefab_path = root / "scripts/game/map_constructor_prefab_catalog.gd"

wss = wss_path.read_text() if wss_path.exists() else ""
contract = contract_path.read_text() if contract_path.exists() else ""
workflow = workflow_path.read_text() if workflow_path.exists() else ""
mission = mission_path.read_text() if mission_path.exists() else ""
prefab = prefab_path.read_text() if prefab_path.exists() else ""

required_roles = [
    "control_terminal",
    "access_terminal",
    "access_item",
    "preferred_power_source",
    "light_controller",
    "platform_controller",
]
required_codes = [
    "valid",
    "missing",
    "source_missing",
    "target_missing",
    "wrong_type",
    "inactive",
    "capacity_exceeded",
    "duplicate",
    "cycle",
    "unsupported_role",
    "physical_relation_forbidden",
    "invalid_format_version",
]
required_methods = [
    "func create_binding(",
    "func replace_binding(",
    "func remove_binding(",
    "func get_binding_by_id(",
    "func get_bindings_by_source_id(",
    "func get_bindings_by_target_id(",
    "func get_bindings_by_role(",
    "func validate_binding(",
    "func get_binding_status(",
    "func get_binding_diagnostics(",
    "func migrate_legacy_bindings(",
    "func replace_serialized_snapshot(",
    "func get_serializable_snapshot(",
]
owner_fields = [
    "var _bindings_by_id: Dictionary",
    "var _binding_ids_by_source_id: Dictionary",
    "var _binding_ids_by_target_id: Dictionary",
    "var _binding_ids_by_role: Dictionary",
]
canonical_fields = ["id", "role", "source_id", "target_id", "parameters", "format_version"]
physical_exclusions = [
    "power_cable_segment",
    "runtime_power_feed",
    "power_cable_reel",
    "duct_adjacency",
    "pipe_adjacency",
    "path_cells",
    "endpoint_a_id",
    "endpoint_b_id",
]

checks = [
    ("BindingStore contract exists", contract_path.exists() and "class_name WorldBindingStoreContract" in contract),
    ("WorldStateStore owns binding dictionaries", all(token in wss for token in owner_fields)),
    ("helper remains stateless", "var _bindings_by_id" not in contract and "var _binding_ids_by_" not in contract),
    ("canonical record fields declared", all(f'"{field}"' in contract for field in canonical_fields)),
    ("required logical roles declared", all(f'"{role}"' in contract for role in required_roles)),
    ("stable result codes declared", all(f'"{code}"' in contract for code in required_codes)),
    ("CRUD and query API declared", all(token in wss for token in required_methods)),
    ("deterministic reverse indexes rebuilt", "static func rebuild_indexes" in contract and "ids.sort()" in contract),
    ("bindings serialize separately", '"entities"' in wss and '"bindings"' in wss and "WORLD_SNAPSHOT_FORMAT_VERSION" in wss),
    ("legacy migration strips logical fields", "legacy_candidates" in contract and "strip_legacy_logical_links" in contract and "migrate_legacy_bindings" in wss),
    ("deletion policy explicit", all(token in wss for token in ["BINDING_POLICY_PRESERVE", "BINDING_POLICY_REMOVE_RELATED", "BINDING_POLICY_REJECT_IF_BOUND"])),
    ("physical topology is excluded", all(f'"{token}"' in contract for token in physical_exclusions)),
    ("no proximity inference", "distance_to" not in contract and "nearest" not in contract.lower()),
    ("no parallel MissionManager binding store", "_bindings_by_id" not in mission and "ROLE_REGISTRY" not in mission),
    ("no parallel Map Constructor binding store", "_bindings_by_id" not in prefab and "ROLE_REGISTRY" not in prefab),
    ("static gate wired", "python tools/check_binding_store.py" in workflow),
    ("Godot gate wired", "check_binding_store.gd" in workflow),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    raise SystemExit(1)

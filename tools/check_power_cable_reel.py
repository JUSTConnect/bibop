#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
service_path = root / "scripts/game/power_cable_reel_service.gd"
facade_path = root / "scripts/game/bipob_cable_runtime_service.gd"
mission_path = root / "scripts/game/mission_manager.gd"
catalog_path = root / "scripts/world/world_object_catalog.gd"
binding_path = root / "scripts/world/world_binding_store_contract.gd"
workflow_path = root / ".github/workflows/godot-parser-gate.yml"

service = service_path.read_text() if service_path.exists() else ""
facade = facade_path.read_text() if facade_path.exists() else ""
mission = mission_path.read_text() if mission_path.exists() else ""
catalog = catalog_path.read_text() if catalog_path.exists() else ""
binding = binding_path.read_text() if binding_path.exists() else ""
workflow = workflow_path.read_text() if workflow_path.exists() else ""

canonical_fields = ["end_1", "end_2", "path_cells", "connection_state"]
end_states = ["on_reel", "held", "connected"]
connection_states = ["disconnected", "partial", "complete", "invalid", "broken"]
actions = ["hold_end", "release_end", "connect_end", "disconnect_end", "set_path", "damage", "repair", "reconnect"]
codes = [
    "socket_unpowered",
    "socket_source_missing",
    "path_empty",
    "path_invalid",
    "path_blocked",
    "path_too_long",
    "reel_broken",
    "reconnect_required",
    "endpoint_occupied",
    "target_incompatible",
]
facade_methods = [
    "preview_power_cable_reel_action(",
    "apply_power_cable_reel_action(",
    "recalculate_power_cable_reel(",
    "recalculate_power_cable_reels_for_socket(",
]

checks = [
    ("reel service exists", service_path.exists() and "class_name PowerCableReelService" in service),
    ("canonical physical fields declared", all(f'"{field}"' in service for field in canonical_fields)),
    ("end states declared", all(f'"{state}"' in service for state in end_states)),
    ("connection states declared", all(f'"{state}"' in service for state in connection_states)),
    ("runtime actions declared", all(f'"{action}"' in service for action in actions)),
    ("stable result codes declared", all(f'"{code}"' in service for code in codes)),
    ("main circuit fixed", 'CIRCUIT_MAIN := "main"' in service),
    ("explicit target opt-in", "runtime_reel_feed" in service and "accepts_runtime_power_reel" in service),
    ("path validation explicit", all(token in service for token in ["_validate_path_shape", "_validate_complete_path", "_adjacent"])),
    ("facade exposes reel API", all(method in facade for method in facade_methods)),
    ("MissionManager exposes scoped reel API", all(method in mission for method in facade_methods)),
    ("catalog has canonical reel contract", '"entity_subtype":"power_cable_reel"' in catalog and '"runtime_power_profile":"power_cable_reel"' in catalog),
    ("catalog keeps reel out of BindingStore", '"binding_profile":"none"' in catalog and '"bindings":false' in catalog),
    ("catalog declares nested reel state", all(f'"{field}"' in catalog for field in canonical_fields)),
    ("reel service does not create bindings", "create_binding(" not in service and "runtime_power_feed" not in binding),
    ("reel feed does not mutate canonical intent", 'target["intent_state"] =' not in service and 'target["operational_state"] =' not in service and 'target["preferred_source_id"] =' not in service),
    ("autonomous resolver emits no popup", '"notification_event": {}' in service),
    ("static gate wired", "python tools/check_power_cable_reel.py" in workflow),
    ("Godot gate wired", "check_power_cable_reel.gd" in workflow),
    ("MissionManager gate wired", "check_power_cable_reel_mission_manager.gd" in workflow),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    raise SystemExit(1)

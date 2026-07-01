#!/usr/bin/env python3
from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        if new in text:
            return text
        raise SystemExit(f"missing anchor: {label}")
    return text.replace(old, new, 1)

fixture_path = Path("scripts/world/entity_contract_fixtures.gd")
fixture = fixture_path.read_text(encoding="utf-8")
fixture = replace_once(
    fixture,
    '"object_standard":{"allowed_entity_types":["object"], "required_capabilities":["state"], "fixture_ids":["status_object_standard"]}, "item_standard"',
    '"object_standard":{"allowed_entity_types":["object"], "required_capabilities":["state"], "fixture_ids":["status_object_standard"]}, "object_thermal":{"allowed_entity_types":["object"], "required_capabilities":["state", "health", "overheat"], "fixture_ids":["status_object_thermal"]}, "item_standard"',
    "object thermal profile",
)
fixture = replace_once(
    fixture,
    '"light_standard":{"allowed_entity_types":["light"], "required_capabilities":["state"], "fixture_ids":["status_light_standard"]}',
    '"light_standard":{"allowed_entity_types":["light"], "required_capabilities":["state", "health", "overheat"], "fixture_ids":["status_light_standard"]}',
    "light profile",
)
fixture = replace_once(
    fixture,
    '"cable_standard":{"allowed_entity_types":["cable"], "required_capabilities":["state"], "fixture_ids":["status_cable_standard"]}',
    '"cable_standard":{"allowed_entity_types":["cable"], "required_capabilities":["state", "health"], "fixture_ids":["status_cable_standard"]}',
    "cable profile",
)
fixture = replace_once(
    fixture,
    '\t"status_object_standard":["status_profile", "object_standard", "object", ["state"], [], "type", ["state", "health"]],\n\t"status_item_standard"',
    '\t"status_object_standard":["status_profile", "object_standard", "object", ["state"], [], "type", ["state", "health"]],\n\t"status_object_thermal":["status_profile", "object_thermal", "object", ["state", "health", "overheat"], [], "type", ["state", "health", "thermal"]],\n\t"status_item_standard"',
    "object thermal fixture",
)
fixture = replace_once(
    fixture,
    '"status_light_standard":["status_profile", "light_standard", "light", ["state"], [], "type", ["state"]]',
    '"status_light_standard":["status_profile", "light_standard", "light", ["state", "health", "overheat"], [], "type", ["state", "health", "thermal"]]',
    "light fixture",
)
fixture = replace_once(
    fixture,
    '"status_cable_standard":["status_profile", "cable_standard", "cable", ["state"], [], "type", ["state", "routing"]]',
    '"status_cable_standard":["status_profile", "cable_standard", "cable", ["state", "health"], [], "type", ["state", "health", "routing", "mount"]]',
    "cable fixture",
)
fixture_path.write_text(fixture, encoding="utf-8")

evaluator_path = Path("scripts/world/entity_status_evaluator.gd")
evaluator = evaluator_path.read_text(encoding="utf-8")
evaluator = replace_once(
    evaluator,
    '\t"light_standard":["intent", "operational"],',
    '\t"light_standard":["intent", "health", "thermal", "operational"],',
    "light evaluator axes",
)
evaluator = replace_once(
    evaluator,
    '\t"cable_standard":["operational"],',
    '\t"cable_standard":["health", "operational"],',
    "cable evaluator axes",
)
evaluator_path.write_text(evaluator, encoding="utf-8")

contract_path = Path("scripts/world/entity_definition_contract.gd")
contract = contract_path.read_text(encoding="utf-8")
contract = re.sub(
    r'\n\t"power_cable":\[[\s\S]*?\n\t\],\n\t"power_socket":\[[\s\S]*?\n\t\],',
    "",
    contract,
    count=1,
)
if '"power_cable":[' in contract.split("const LEGACY_LIBRARY_EXCEPTIONS", 1)[1].split("}", 1)[0]:
    raise SystemExit("power_cable legacy exception remains")
contract_path.write_text(contract, encoding="utf-8")

resolver_path = Path("scripts/world/power_control_resolver.gd")
resolver = resolver_path.read_text(encoding="utf-8")
old_routes = '''\tif object_type in ["fuse_box", "fuse_box_empty", "fuse_block"]:
		return not (bool(object_data.get("fuse_installed", false)) or state in ["installed", "ok", "active"] or object_type == "fuse_box_installed")
	if object_type in ["circuit_breaker", "power_breaker", "power_knife_switch", "power_switcher"]:
		return state in ["off", "switch_off", "open"] or not bool(object_data.get("is_on", state in ["on", "switch_on", "active", "ok"]))'''
new_routes = '''\tif object_type in ["fuse_box", "fuse_box_empty", "fuse_block"]:
		var has_fuse: bool = bool(object_data.get("has_fuse", object_data.get("fuse_present", object_data.get("fuse_installed", state in ["installed", "ok", "active"] or object_type == "fuse_box_installed"))))
		return not has_fuse
	if object_type in ["circuit_switch", "circuit_breaker", "power_breaker", "power_knife_switch", "power_switcher"]:
		var intent: String = str(object_data.get("intent_state", "")).strip_edges().to_lower()
		if intent in ["on", "off"]:
			return intent == "off"
		return state in ["off", "switch_off", "open"] or not bool(object_data.get("is_on", state in ["on", "switch_on", "active", "ok"]))'''
resolver = replace_once(resolver, old_routes, new_routes, "canonical fuse/switch topology")
resolver_path.write_text(resolver, encoding="utf-8")

consistency_path = Path("tools/ci/check_entity_contract_consistency.gd")
consistency = consistency_path.read_text(encoding="utf-8")
consistency = replace_once(
    consistency,
    '\t_assert(_has_warning(socket_report, "entity_contract.legacy_semantic_exception", "connected_device_ids"), "power socket endpoint compatibility warning missing")\n\t_assert(_report_diagnostics_have_shape(socket_report), "power socket warnings have incomplete diagnostic shape")',
    '\t_assert(not _has_warning(socket_report, "entity_contract.legacy_semantic_exception"), "migrated power socket still reports a legacy semantic exception")\n\t_assert(not WorldObjectCatalog.get_constructor_prefab_definition("power_socket").has("legacy_semantic_exceptions"), "migrated power socket definition still declares #1181 exceptions")\n\t_assert(_report_diagnostics_have_shape(socket_report), "power socket diagnostics have incomplete diagnostic shape")',
    "power socket migrated expectation",
)
consistency_path.write_text(consistency, encoding="utf-8")

workflow_path = Path(".github/workflows/godot-parser-gate.yml")
workflow = workflow_path.read_text(encoding="utf-8")
workflow = replace_once(
    workflow,
    "          godot --headless --path . --script res://tools/ci/check_power_control_runtime_service.gd\n",
    "          godot --headless --path . --script res://tools/ci/check_power_control_runtime_service.gd\n          godot --headless --path . --script res://tools/ci/check_stationary_power_migration.gd\n",
    "stationary migration gate wiring",
)
workflow_path.write_text(workflow, encoding="utf-8")

print("SEMANTIC_1181_PATCH: OK")

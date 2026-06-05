extends Node

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const ScanSystemRef = preload("res://scripts/world/scan_system.gd")
const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const PowerSystemRef = preload("res://scripts/world/power_system.gd")
const MissionContentCatalogRef = preload("res://scripts/game/mission_content_catalog.gd")
const TaskTestWorldBuilderRef = preload("res://scripts/game/task_test_world_builder.gd")
const MapConstructorServiceRef = preload("res://scripts/game/map_constructor_service.gd")
const MapConstructorValidationServiceRef = preload("res://scripts/game/map_constructor_validation_service.gd")
const CableTopologyServiceRef = preload("res://scripts/game/cable_topology_service.gd")
const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")
const PlatformControlServiceRef = preload("res://scripts/game/platform/platform_control_service.gd")
const PlatformVisualServiceRef = preload("res://scripts/game/platform/platform_visual_service.gd")
const PlatformMotionServiceRef = preload("res://scripts/game/platform/platform_motion_service.gd")
const PlatformRotationServiceRef = preload("res://scripts/game/platform/platform_rotation_service.gd")
const BipobCableRuntimeServiceRef = preload("res://scripts/game/bipob_cable_runtime_service.gd")
const BipobAirflowRuntimeServiceRef = preload("res://scripts/game/bipob_airflow_runtime_service.gd")
const BreachableWallServiceRef = preload("res://scripts/game/wall/breachable_wall_service.gd")
const DEVICE_INTERACTION_FLOW_STATES: Array[String] = ["no_target", "unknown", "scanned", "diagnosed", "ready", "blocked", "executed_unavailable"]

const ISO_PLACEHOLDER_ASSET_PATHS: Dictionary = {
	"floor_concrete": "res://assets/visual/isometric/floor/floor_concrete_01.png",
	"floor_steel": "res://assets/visual/isometric/floor/floor_steel_01.png",
	"floor_titan": "res://assets/visual/isometric/floor/floor_titan_01.png",
	"platform_floor": "res://assets/visual/isometric/floor/floor_platform_01.png",
	"floor_default": "res://assets/visual/isometric/floor/floor_concrete_01.png",
	"floor_stepped": "res://assets/visual/isometric/floor/floor_concrete_01.png",
	"floor_clean_lab": "res://assets/visual/isometric/placeholders/iso_floor_clean_lab.svg",
	"floor_dark_service": "res://assets/visual/isometric/placeholders/iso_floor_dark_service.svg",
	"floor_hazard": "res://assets/visual/isometric/placeholders/iso_floor_hazard.svg",
	"floor_power": "res://assets/visual/isometric/placeholders/iso_floor_power.svg",
	"floor_damaged": "res://assets/visual/isometric/placeholders/iso_floor_damaged.svg",
	"floor_reinforced": "res://assets/visual/isometric/placeholders/iso_floor_reinforced.svg",
	"floor_diagnostic": "res://assets/visual/isometric/placeholders/iso_floor_diagnostic.svg",
	"floor_door_underlay": "res://assets/visual/isometric/placeholders/iso_floor_door_underlay.svg",
	"wall_default": "res://assets/visual/isometric/wall/concrete/wall_concrete_mid_01.png",
	"wall_outer": "res://assets/visual/isometric/wall/outerwall/wall_outerwall_mid_01.png",
	"wall_brick": "res://assets/visual/isometric/wall/brick/wall_brick_mid_01.png",
	"wall_concrete": "res://assets/visual/isometric/wall/concrete/wall_concrete_mid_01.png",
	"wall_grate": "res://assets/visual/isometric/wall/grate/wall_grate_mid_01.png",
	"wall_damaged": "res://assets/visual/isometric/wall/concrete/wall_concrete_mid_01.png",
	"wall_concrete_damaged": "res://assets/visual/isometric/wall/concrete/wall_concrete_mid_01.png",
	"wall_brick_damaged": "res://assets/visual/isometric/wall/brick/wall_brick_mid_01.png",
	"wall_steel": "res://assets/visual/isometric/wall/steel/wall_steel_mid_01.png",
	"wall_reinforced_steel": "res://assets/visual/isometric/wall/reinforce_steel/wall_reinforcesteel_mid_01.png",
	"wall_titan": "res://assets/visual/isometric/wall/titan/wall_titan_mid_01.png",
	"wall_energy": "res://assets/visual/isometric/wall/reinforce_steel/wall_reinforcesteel_mid_01.png",
	"object_door": "res://assets/visual/isometric/placeholders/iso_object_door.svg",
	"object_terminal": "res://assets/visual/isometric/placeholders/iso_object_terminal.svg",
	"object_key": "res://assets/visual/isometric/placeholders/iso_object_key.svg",
	"object_component": "res://assets/visual/isometric/placeholders/iso_object_component.svg",
	"object_socket": "res://assets/visual/isometric/placeholders/iso_object_socket.svg",
	"object_cable": "res://assets/visual/isometric/placeholders/iso_object_cable.svg",
	"object_generic": "res://assets/visual/isometric/placeholders/iso_object_generic.svg",
	"object_fuse": "res://assets/visual/isometric/placeholders/iso_object_fuse.svg",
	"object_repair_kit": "res://assets/visual/isometric/placeholders/iso_object_repair_kit.svg",
	"object_keycard": "res://assets/visual/isometric/placeholders/iso_object_keycard.svg",
	"object_access_code": "res://assets/visual/isometric/placeholders/iso_object_access_code.svg",
	"object_cable_reel": "res://assets/visual/isometric/placeholders/iso_object_cable_reel.svg",
	"cable_reel_01": "res://assets/visual/isometric/objects/cable_reel_01.png",
	"cable_reel_02": "res://assets/visual/isometric/objects/cable_reel_02.png",
	"fuse_box_in_01": "res://assets/visual/isometric/objects/fuse_box_in_01.png",
	"fuse_box_out_01": "res://assets/visual/isometric/objects/fuse_box_out_01.png",
	"fuse_box_in_wall_01": "res://assets/visual/isometric/objects/fuse_box_in_wall_01.png",
	"fuse_box_out_wall_01": "res://assets/visual/isometric/objects/fuse_box_out_wall_01.png",
	"light_01": "res://assets/visual/isometric/objects/light_01.png",
	"power_source_01": "res://assets/visual/isometric/objects/power_source_01.png",
	"power_switcher_off_01": "res://assets/visual/isometric/objects/power_switcher_off_01.png",
	"power_switcher_off_wall_01": "res://assets/visual/isometric/objects/power_switcher_off_wall_01.png",
	"power_switcher_on_01": "res://assets/visual/isometric/objects/power_switcher_on_01.png",
	"power_switcher_on_wall_01": "res://assets/visual/isometric/objects/power_switcher_on_wall_01.png",
	"radiator_01": "res://assets/visual/isometric/objects/radiator_01.png",
	"terminal_01": "res://assets/visual/isometric/objects/terminal_01.png",
	"barrel_01": "res://assets/visual/isometric/moovable/barrel_01.png",
	"case_01": "res://assets/visual/isometric/objects/case_01.png",
	"steel_box_01": "res://assets/visual/isometric/moovable/steel_box_01.png",
	"fire_barrel_01": "res://assets/visual/isometric/moovable/fire_barrel_01.png",
	"object_button": "res://assets/visual/isometric/placeholders/iso_object_button.svg",
	"object_switch": "res://assets/visual/isometric/placeholders/iso_object_switch.svg"
}

const FLOOR_TEXTURE_ASSET_ALIASES: Dictionary = {
	"default_floor": "floor_concrete",
	"floor_default": "floor_concrete",
	"concrete": "floor_concrete",
	"concrete_floor": "floor_concrete",
	"steel": "floor_steel",
	"steel_floor": "floor_steel",
	"titan": "floor_titan",
	"titan_floor": "floor_titan",
	"titanium": "floor_titan",
	"titanium_floor": "floor_titan",
	"clean_lab_floor": "floor_steel",
	"dark_service_floor": "floor_concrete",
	"hazard_floor": "floor_concrete",
	"power_floor": "floor_steel",
	"damaged_floor": "floor_concrete",
	"reinforced_floor": "floor_steel",
	"diagnostic_floor": "floor_steel"
}

const WALL_TEXTURE_ASSET_ALIASES: Dictionary = {
	"default_wall": "wall_default",
	"wall_default_metal": "wall_concrete",
	"wall_clean_lab": "wall_concrete",
	"wall_dark_service": "wall_grate",
	"wall_orange_hazard": "wall_concrete_damaged",
	"wall_damaged_red": "wall_brick_damaged",
	"wall_reinforced": "wall_steel",
	"wall_power_room": "wall_reinforced_steel",
	"wall_diagnostic_blue": "wall_brick",
	"wall_concrete": "wall_concrete",
	"wall_concrete_default": "wall_concrete",
	"wall_steel": "wall_steel",
	"wall_brick": "wall_brick",
	"wall_brick_damage": "wall_brick_damaged",
	"wall_brick_damaged": "wall_brick_damaged",
	"wall_concrete_damage": "wall_concrete_damaged",
	"wall_concrete_damaged": "wall_concrete_damaged",
	"wall_reinforced_steel": "wall_reinforced_steel",
	"wall_titan": "wall_titan",
	"wall_titanium": "wall_titan",
	"wall_outer": "wall_outer",
	"wall_outerwall": "wall_outer",
	"wall_grate": "wall_grate",
	"wall_boundary": "wall_outer",
	"industrial_panel": "wall_brick",
	"wall_industrial_panel": "wall_brick",
	"wall_service_vent": "wall_grate",
	"outer": "wall_outer",
	"boundary": "wall_outer",
	"concrete": "wall_concrete",
	"brick": "wall_brick",
	"grate": "wall_grate",
	"vent": "wall_grate",
	"service": "wall_grate",
	"steel": "wall_steel",
	"reinforced": "wall_reinforced_steel",
	"titan": "wall_titan",
	"titanium": "wall_titan",
	"damaged": "wall_concrete_damaged",
	"red": "wall_brick_damaged",
	"broken": "wall_concrete_damaged",
	"energy": "wall_reinforced_steel",
	"powered": "wall_reinforced_steel"
}

const OBJECT_TEXTURE_ASSET_ALIASES: Dictionary = {
	"door_state_generic": "object_door",
	"terminal_state_generic": "object_terminal",
	"item_generic_marker": "object_generic",
	"cable_reel": "cable_reel_01",
	"cable_reel_01": "cable_reel_01",
	"power_cable_reel": "cable_reel_01",
	"fuse_box": "fuse_box_out_01",
	"Fuse_box": "fuse_box_out_01",
	"fuse_box_empty": "fuse_box_out_01",
	"fuse_box_installed": "fuse_box_in_01",
	"Fuse_box_in_01": "fuse_box_in_01",
	"Fuse_box_out_01": "fuse_box_out_01",
	"Fuse_box_in_wall_01": "fuse_box_in_wall_01",
	"Fuse_box_out_wall_01": "fuse_box_out_wall_01",
	"wall_fuse_box": "fuse_box_out_wall_01",
	"power_source": "power_source_01",
	"power_source_class_1": "power_source_01",
	"power_source_class_2": "power_source_01",
	"power_source_class_3": "power_source_01",
	"switcher": "power_switcher_off_01",
	"power_switcher": "power_switcher_off_01",
	"radiator": "radiator_01",
	"external_radiator": "radiator_01",
	"terminal": "terminal_01",
	"barrel": "barrel_01",
	"fire_barrel": "fire_barrel_01",
	"case": "case_01",
	"steel_box": "steel_box_01",
	"light": "light_01"
}

const VISUAL_TEXTURE_ASSET_ALIASES: Dictionary = {
	"default_floor": "floor_concrete",
	"floor_default": "floor_concrete",
	"concrete_floor": "floor_concrete",
	"steel_floor": "floor_steel",
	"titan_floor": "floor_titan",
	"titanium_floor": "floor_titan",
	"clean_lab_floor": "floor_steel",
	"dark_service_floor": "floor_concrete",
	"hazard_floor": "floor_concrete",
	"power_floor": "floor_steel",
	"damaged_floor": "floor_concrete",
	"reinforced_floor": "floor_steel",
	"diagnostic_floor": "floor_steel",
	"default_wall": "wall_default",
	"wall_default_metal": "wall_concrete",
	"wall_clean_lab": "wall_concrete",
	"wall_dark_service": "wall_grate",
	"wall_orange_hazard": "wall_concrete_damaged",
	"wall_damaged_red": "wall_brick_damaged",
	"wall_reinforced": "wall_steel",
	"wall_power_room": "wall_reinforced_steel",
	"wall_diagnostic_blue": "wall_brick",
	"wall_concrete_default": "wall_concrete",
	"wall_industrial_panel": "wall_brick",
	"wall_service_vent": "wall_grate",
	"wall_boundary": "wall_outer",
	"door_state_generic": "object_door",
	"terminal_state_generic": "object_terminal",
	"item_generic_marker": "object_generic"
}

var mission_world_objects: Array[Dictionary] = []
var world_objects_by_cell: Dictionary = {}
var generic_cable_runtime_report: Dictionary = {}
var generic_airflow_runtime_report: Dictionary = {}
var cell_items: Dictionary = {}
var last_threat_warning_ids: Dictionary = {}
var last_world_runtime_restore_warnings: Array[String] = []
var debug_world_logs := false
var enable_debug_seed := false
var debug_world_cooling_scenario_enabled: bool = false
var debug_platform_scenario_enabled: bool = false
var active_bipob_ref: Node = null
var grid_manager: Node = null
var platform_last_tick_action_index: int = -1
var runtime_inventory_state := {
	"pocket_items": [],
	"manipulator_hold": "",
	"digital_buffer": [],
	"digital_storage": [],
	"box_storage": [],
	"item_amounts": {},
	"consumed_item_ids": [],
	"collected_key_ids": [],
	"world_item_runtime": {}
}
# Accessed by MapConstructorService when allocating runtime-only constructor IDs.
@warning_ignore("unused_private_class_variable")
var _map_constructor_runtime_object_seq: int = 1
var map_constructor_service: MapConstructorService = null
var map_constructor_validation_service: MapConstructorValidationService = null
var _task_test_constructor_base_tiles: Dictionary = {}
var _map_constructor_last_cleanup_snapshot: Dictionary = {}
var _map_constructor_last_autofix_snapshot: Dictionary = {}
var _map_constructor_last_patch_snapshot: Dictionary = {}
var _map_constructor_last_batch_snapshot: Dictionary = {}
var _map_constructor_wall_material_overrides: Dictionary = {}
var _map_constructor_floor_material_overrides: Dictionary = {}
var map_constructor_door_visual_preset_overrides: Dictionary = {}
var map_constructor_terminal_visual_preset_overrides: Dictionary = {}
var _map_constructor_change_history: Array[Dictionary] = []
var _map_constructor_change_history_seq: int = 1
var current_mission_id: String = ""
var active_runtime_mode_id: String = RUNTIME_MODE_UNKNOWN
var constructor_map_width: int = 16
var constructor_map_height: int = 10
var constructor_start_marker: Dictionary = {}
var constructor_exit_marker: Dictionary = {}
const RUNTIME_MODE_LEGACY_STORY := "legacy_story"
const RUNTIME_MODE_TASK_TEST := "task_test"
const RUNTIME_MODE_UNKNOWN := "unknown"
const RETIRED_LEGACY_MISSION_INDEXES: Array[int] = [7, 8]
const TASK_TEST_LAYOUT_ID := "task_test"
const TASK_TEST_MISSION_ID := "mission_10"

const MAP_CONSTRUCTOR_PRESET_DIR: String = "user://constructor_presets"

const MAP_CONSTRUCTOR_MISSION_PATCH_DIR: String = "user://constructor_mission_patches"
const MAP_CONSTRUCTOR_PATCH_SCHEMA_VERSION: int = 1

func get_task_test_mission_id() -> String:
	return TASK_TEST_MISSION_ID

func get_task_test_layout_id() -> String:
	return TASK_TEST_LAYOUT_ID

func has_task_test_catalog_layout() -> bool:
	var catalog := MissionContentCatalogRef.new()
	if not catalog.has_mission_layout(TASK_TEST_LAYOUT_ID):
		return false
	return not catalog.get_mission_layout(TASK_TEST_LAYOUT_ID).is_empty()

func get_task_test_source_id() -> String:
	return TASK_TEST_LAYOUT_ID

func get_task_test_sandbox_layout_id() -> String:
	return get_task_test_layout_id()

func get_task_test_sandbox_source_id() -> String:
	return get_task_test_source_id()

func normalize_task_test_source_id(source_id: String) -> String:
	var normalized: String = str(source_id).strip_edges()
	if normalized == TASK_TEST_MISSION_ID or normalized == TASK_TEST_LAYOUT_ID:
		return TASK_TEST_LAYOUT_ID
	return normalized

func is_task_test_mission_id(mission_id: String) -> bool:
	var normalized: String = str(mission_id).strip_edges()
	return normalized == TASK_TEST_MISSION_ID or normalized == TASK_TEST_LAYOUT_ID

func resolve_task_test_catalog_id(mission_id: String) -> String:
	var normalized: String = str(mission_id).strip_edges()
	if normalized == TASK_TEST_LAYOUT_ID or normalized == TASK_TEST_MISSION_ID:
		return TASK_TEST_LAYOUT_ID
	return normalized

const MAP_CONSTRUCTOR_WALL_SIDE_DELTAS: Array[Dictionary] = [
	{"side":"north", "delta": Vector2i(0, -1)},
	{"side":"east", "delta": Vector2i(1, 0)},
	{"side":"south", "delta": Vector2i(0, 1)},
	{"side":"west", "delta": Vector2i(-1, 0)}
]

const MAP_CONSTRUCTOR_WALL_MOUNTED_PREFABS: Dictionary = {
	"light": true,
	"light_switch": true,
	"circuit_breaker": true,
	"fuse_box": true,
	"firewall": true
}

# Compatibility-only inventory of historic constructor solids. Runtime placement
# resolves solidity through WorldObjectCatalogRef.is_constructor_solid_prefab().
const MAP_CONSTRUCTOR_SOLID_PREFABS: Array[String] = [
	"outer_wall","brick_wall","concrete_wall","steel_wall","grate_wall",
	"steel_door","reinforced_steel_door","titanium_door","energy_door","grid_door",
	"mechanical_door","digital_door","powered_gate"
]

# region Typed world-object access wrappers
func _wo_id(object_data: Dictionary) -> String:
	return str(object_data.get("id", ""))

func _wo_group(object_data: Dictionary) -> String:
	return str(object_data.get("object_group", ""))

func _wo_type(object_data: Dictionary) -> String:
	return str(object_data.get("object_type", ""))

func _wo_pos(object_data: Dictionary, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	return Vector2i(object_data.get("position", fallback))
# endregion

# region Lifecycle / setup
func _ready() -> void:
	if enable_debug_seed:
		_seed_debug_world_objects()


func validate_mission_content_catalog() -> Array[String]:
	var catalog := MissionContentCatalogRef.new()
	return catalog.validate_mission_catalog()

func get_mission_content_catalog_validation_text() -> String:
	var catalog := MissionContentCatalogRef.new()
	return catalog.get_mission_catalog_validation_text()

func get_mission_definition(mission_id: String) -> Dictionary:
	var catalog := MissionContentCatalogRef.new()
	return catalog.get_mission_definition(resolve_task_test_catalog_id(mission_id))

func get_mission_title(mission_id: String) -> String:
	var catalog := MissionContentCatalogRef.new()
	return catalog.get_mission_title(resolve_task_test_catalog_id(mission_id))

func get_mission_display_name(mission_id: String) -> String:
	var catalog := MissionContentCatalogRef.new()
	return catalog.get_mission_display_name(resolve_task_test_catalog_id(mission_id))

func get_current_mission_id() -> String:
	return current_mission_id

func get_mission_goal_text(mission_id: String) -> String:
	var catalog := MissionContentCatalogRef.new()
	return catalog.get_mission_goal_text(resolve_task_test_catalog_id(mission_id))

func get_mission_objective_hint(mission_id: String) -> String:
	var catalog := MissionContentCatalogRef.new()
	return catalog.get_mission_objective_hint(resolve_task_test_catalog_id(mission_id))

func get_task_test_goal_text() -> String:
	var catalog: MissionContentCatalog = MissionContentCatalogRef.new()
	var goal_text: String = catalog.get_mission_goal_text(TASK_TEST_LAYOUT_ID)
	if not goal_text.is_empty():
		return goal_text
	return catalog.get_mission_goal_text(TASK_TEST_MISSION_ID)

func get_task_test_objective_hint() -> String:
	var catalog: MissionContentCatalog = MissionContentCatalogRef.new()
	var objective_hint: String = catalog.get_mission_objective_hint(TASK_TEST_LAYOUT_ID)
	if not objective_hint.is_empty():
		return objective_hint
	return catalog.get_mission_objective_hint(TASK_TEST_MISSION_ID)

func get_current_mission_objective_view_model() -> Dictionary:
	return get_mission_objective_view_model()

func get_mission_objective_view_model(mission_id: String = "") -> Dictionary:
	var resolved_mission_id: String = mission_id.strip_edges()
	if resolved_mission_id.is_empty():
		resolved_mission_id = current_mission_id.strip_edges()
	if resolved_mission_id.is_empty():
		return _make_mission_objective_view_model("", "", "No active objective", "")
	var catalog := MissionContentCatalogRef.new()
	var catalog_mission_id: String = resolve_task_test_catalog_id(resolved_mission_id)
	if not catalog.has_mission(catalog_mission_id):
		return _make_mission_objective_view_model(resolved_mission_id, "Unknown mission", "Objective unavailable.", "")
	var title: String = catalog.get_mission_display_name(catalog_mission_id)
	if title.is_empty():
		title = catalog.get_mission_title(catalog_mission_id)
	if title.is_empty():
		title = "Unknown mission"
	var goal_text: String = catalog.get_mission_goal_text(catalog_mission_id)
	var objective_hint: String = catalog.get_mission_objective_hint(catalog_mission_id)
	if goal_text.is_empty() and not objective_hint.contains("legacy BipobController logic"):
		goal_text = objective_hint
	if goal_text.is_empty():
		goal_text = "Objective unavailable."
	return _make_mission_objective_view_model(resolved_mission_id, title, goal_text, objective_hint)

func validate_current_mission_objective_view_model() -> Array[String]:
	var warnings: Array[String] = []
	var view_model: Dictionary = get_current_mission_objective_view_model()
	for required_field in ["mission_id", "title", "goal_text", "objective_hint", "progress_text", "status", "is_completed", "is_failed", "steps"]:
		if not view_model.has(required_field):
			warnings.append("Mission objective ViewModel is missing '%s'." % required_field)
	if not current_mission_id.is_empty():
		if str(view_model.get("title", "")).strip_edges().is_empty():
			warnings.append("Active mission objective ViewModel title must not be empty.")
		if str(view_model.get("goal_text", "")).strip_edges().is_empty() and str(view_model.get("objective_hint", "")).strip_edges().is_empty():
			warnings.append("Active mission objective ViewModel must provide goal_text or objective_hint.")
	return warnings

func _make_mission_objective_view_model(mission_id: String, title: String, goal_text: String, objective_hint: String) -> Dictionary:
	return {
		"mission_id": mission_id,
		"title": title,
		"goal_title": "Goal",
		"goal_text": goal_text,
		"objective_hint": objective_hint,
		"progress_text": "",
		"status": "active",
		"is_completed": false,
		"is_failed": false,
		"steps": []
	}

func get_mission_start_cell(mission_id: String) -> Vector2i:
	var catalog := MissionContentCatalogRef.new()
	return catalog.get_mission_start_cell(resolve_task_test_catalog_id(mission_id))

func get_mission_exit_cells(mission_id: String) -> Array[Vector2i]:
	var catalog := MissionContentCatalogRef.new()
	return catalog.get_mission_exit_cells(resolve_task_test_catalog_id(mission_id))

func apply_catalog_mission_layout_to_grid(mission_id: String) -> bool:
	if grid_manager == null:
		return false
	if not grid_manager.has_method("apply_mission_layout"):
		return false
	var catalog := MissionContentCatalogRef.new()
	var catalog_mission_id: String = resolve_task_test_catalog_id(mission_id)
	if not catalog.has_mission_layout(catalog_mission_id):
		return false
	var catalog_layout: Array = catalog.get_mission_layout(catalog_mission_id)
	if catalog_layout.is_empty():
		return false
	return bool(grid_manager.call("apply_mission_layout", catalog_layout.duplicate(true)))

func validate_task_test_catalog_layout_runtime_source() -> Array[String]:
	var warnings: Array[String] = []
	var catalog := MissionContentCatalogRef.new()
	var task_test_catalog_id: String = resolve_task_test_catalog_id(TASK_TEST_LAYOUT_ID)
	if not catalog.has_mission_layout(task_test_catalog_id):
		warnings.append("task_test_catalog_layout_missing_task_test")
		return warnings
	var task_test_layout: Array = catalog.get_mission_layout(TASK_TEST_LAYOUT_ID)
	if task_test_layout.is_empty():
		warnings.append("task_test_catalog_layout_empty")
	if not catalog.has_mission_layout(TASK_TEST_MISSION_ID):
		warnings.append("task_test_catalog_layout_missing_mission_10_alias")
	else:
		var mission10_layout: Array = catalog.get_mission_layout(TASK_TEST_MISSION_ID)
		if mission10_layout.is_empty():
			warnings.append("task_test_catalog_layout_mission_10_alias_empty")
		elif var_to_str(task_test_layout) != var_to_str(mission10_layout):
			warnings.append("task_test_catalog_layout_mission_10_alias_mismatch")
	var layout_size: Vector2i = catalog.get_mission_layout_size(task_test_catalog_id)
	if layout_size.x != 16 or layout_size.y != 10:
		warnings.append("task_test_catalog_layout_expected_16x10_got_%dx%d" % [layout_size.x, layout_size.y])
	if catalog.get_mission_exit_cells(task_test_catalog_id).is_empty():
		warnings.append("task_test_catalog_layout_missing_exit_tile")
	if grid_manager != null and not grid_manager.has_method("apply_mission_layout"):
		warnings.append("task_test_catalog_runtime_grid_missing_apply_mission_layout")
	return warnings

func validate_architecture_contracts() -> Dictionary:
	var sections: Array[Dictionary] = []
	sections.append(_make_architecture_validation_section("object_registry", "Object Registry", WorldObjectCatalogRef.validate_object_registry_contract()))
	sections.append(_make_architecture_validation_section("door_contract", "Door Contract", _validate_current_door_contracts()))
	sections.append(_make_architecture_validation_section("legacy_boundary", "Legacy Compatibility Boundary", _validate_legacy_compatibility_boundary()))
	var constructor_validation_service: MapConstructorValidationService = MapConstructorValidationServiceRef.new(self)
	sections.append(_make_architecture_validation_section("constructor_palette", "Constructor Palette", constructor_validation_service.validate_constructor_palette_contract()))
	sections.append(_make_architecture_validation_section("task_test_objects", "TASK TEST Objects", _validate_task_test_object_contracts()))
	sections.append(_make_architecture_validation_section("inventory_storage", "Inventory Storage", validate_runtime_inventory_storage_contract()))
	sections.append(_validate_runtime_action_view_model_section())
	sections.append(_validate_device_diagnostics_section())
	sections.append(_validate_device_interaction_flow_section())
	sections.append(_validate_device_interaction_state_flow_section())
	sections.append(_make_architecture_validation_section("mission_objective", "Mission Objective", _validate_architecture_mission_objective_contract()))
	var warnings: Array[String] = []
	var contract_breaking_count: int = 0
	for section in sections:
		var section_warnings: Array = section.get("warnings", [])
		for warning_variant in section_warnings:
			warnings.append("%s: %s" % [str(section.get("id", "unknown")), str(warning_variant)])
		if not bool(section.get("ok", false)):
			contract_breaking_count += section_warnings.size()
	var report_ok: bool = contract_breaking_count == 0
	var summary: String = "All architecture contracts passed."
	if not report_ok:
		summary = "Architecture contract validation found %d contract-breaking warning(s)." % contract_breaking_count
	elif not warnings.is_empty():
		summary = "Architecture contracts passed with %d informational warning(s)." % warnings.size()
	return {"ok": report_ok, "summary": summary, "sections": sections, "warnings": warnings, "error_count": 0, "warning_count": warnings.size()}

func build_architecture_stabilization_final_report() -> Dictionary:
	var validation_read_only_section: Dictionary = _build_final_validation_read_only_section()
	var architecture_snapshot: Dictionary = validate_architecture_contracts()
	var architecture_sections: Dictionary = _index_architecture_validation_sections(architecture_snapshot)
	var sections: Array[Dictionary] = []
	sections.append(_make_final_verification_section("syntax_gate_reference", "Syntax Gate Reference", [], ["Run git diff --check, python tools/check_gdscript_safety_patterns.py, python tools/check_map_constructor_sections.py, and godot --headless --path . --quit when the Godot CLI is available."]))
	sections.append(_build_final_object_registry_section(architecture_sections))
	sections.append(_build_final_constructor_prefabs_section(architecture_sections))
	sections.append(_build_final_reused_section("task_test_objects", "TASK TEST Objects", architecture_sections, "task_test_objects"))
	sections.append(_build_final_door_contract_section(architecture_sections))
	sections.append(_build_final_inventory_contract_section(architecture_sections))
	sections.append(_build_final_runtime_action_contract_section(architecture_sections))
	sections.append(_build_final_mission_goal_binding_section(architecture_sections))
	sections.append(validation_read_only_section)
	sections.append(_build_final_legacy_boundary_section(architecture_sections))
	sections.append(_build_final_ui_backend_consistency_section())
	var manual_smoke_checklist: Array[String] = _get_architecture_stabilization_manual_smoke_checklist()
	sections.append(_make_final_verification_section("final_smoke_checklist", "Final Smoke Checklist", [], ["Manual Godot runtime smoke checklist emitted with %d step(s)." % manual_smoke_checklist.size()]))
	var error_count: int = 0
	var warning_count: int = 0
	for section in sections:
		error_count += Array(section.get("errors", [])).size()
		warning_count += Array(section.get("warnings", [])).size()
	var report_ok: bool = error_count == 0
	var summary: String = "Architecture stabilization checks passed."
	if not report_ok:
		summary = "Architecture stabilization checks found %d error(s) and %d warning(s)." % [error_count, warning_count]
	elif warning_count > 0:
		summary = "Architecture stabilization checks passed with %d informational warning(s)." % warning_count
	return {
		"ok": report_ok,
		"summary": summary,
		"sections": sections,
		"error_count": error_count,
		"warning_count": warning_count,
		"manual_smoke_checklist": manual_smoke_checklist,
		"checks": {
			"syntax_gate": ["git diff --check", "python tools/check_gdscript_safety_patterns.py", "python tools/check_map_constructor_sections.py", "godot --headless --path . --quit"],
			"contract_validation": [str(architecture_snapshot.get("summary", "Architecture contract validation unavailable."))],
			"runtime_smoke": manual_smoke_checklist.duplicate()
		}
	}

func _index_architecture_validation_sections(report: Dictionary) -> Dictionary:
	var indexed_sections: Dictionary = {}
	for section_variant in Array(report.get("sections", [])):
		if typeof(section_variant) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_variant
		indexed_sections[str(section.get("id", ""))] = section
	return indexed_sections

func _make_final_verification_section(section_id: String, title: String, errors: Array, warnings: Array = []) -> Dictionary:
	var copied_errors: Array[String] = []
	var copied_warnings: Array[String] = []
	for error_variant in errors:
		copied_errors.append(str(error_variant))
	for warning_variant in warnings:
		copied_warnings.append(str(warning_variant))
	return {"id": section_id, "title": title, "ok": copied_errors.is_empty(), "errors": copied_errors, "warnings": copied_warnings}

func _build_final_reused_section(section_id: String, title: String, architecture_sections: Dictionary, source_section_id: String) -> Dictionary:
	var source_variant: Variant = architecture_sections.get(source_section_id, {})
	if typeof(source_variant) != TYPE_DICTIONARY:
		return _make_final_verification_section(section_id, title, ["missing_reused_validation_section_%s" % source_section_id])
	var source: Dictionary = source_variant
	var source_warnings: Array = source.get("warnings", [])
	if bool(source.get("ok", false)):
		return _make_final_verification_section(section_id, title, [], source_warnings)
	return _make_final_verification_section(section_id, title, source_warnings)

func _build_final_object_registry_section(architecture_sections: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var registry_section: Dictionary = _build_final_reused_section("object_registry", "Object Registry", architecture_sections, "object_registry")
	for error_variant in Array(registry_section.get("errors", [])):
		errors.append(str(error_variant))
	for object_variant in mission_world_objects:
		if typeof(object_variant) != TYPE_DICTIONARY:
			errors.append("runtime_world_object_not_dictionary")
			continue
		var object_data: Dictionary = object_variant
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		var object_type: String = str(object_data.get("object_type", "")).strip_edges().to_lower()
		var object_group: String = str(object_data.get("object_group", "")).strip_edges().to_lower()
		if object_id.is_empty():
			errors.append("runtime_world_object_missing_id")
		if object_type.is_empty() or not WorldObjectCatalogRef.OBJECT_LIBRARY.has(object_type):
			errors.append("runtime_world_object_unknown_object_type_%s_%s" % [object_id, object_type])
		if WorldObjectCatalogRef.is_legacy_prefab_alias(object_type):
			errors.append("runtime_world_object_legacy_object_type_%s_%s" % [object_id, object_type])
		if object_group.is_empty():
			errors.append("runtime_world_object_missing_object_group_%s" % object_id)
	return _make_final_verification_section("object_registry", "Object Registry", errors, Array(registry_section.get("warnings", [])))

func _build_final_constructor_prefabs_section(architecture_sections: Dictionary) -> Dictionary:
	return _build_final_reused_section("constructor_prefabs", "Constructor Prefabs", architecture_sections, "constructor_palette")

func _build_final_door_contract_section(architecture_sections: Dictionary) -> Dictionary:
	var reused_section: Dictionary = _build_final_reused_section("door_contract", "Door Contract", architecture_sections, "door_contract")
	var errors: Array[String] = []
	var warnings: Array[String] = []
	for error_variant in Array(reused_section.get("errors", [])):
		errors.append(str(error_variant))
	for warning_variant in Array(reused_section.get("warnings", [])):
		warnings.append(str(warning_variant))
	var door_count: int = 0
	for object_variant in mission_world_objects:
		if typeof(object_variant) != TYPE_DICTIONARY:
			continue
		var door: Dictionary = object_variant
		if str(door.get("object_group", "")).strip_edges().to_lower() != "door":
			continue
		door_count += 1
		var door_id: String = str(door.get("id", "unnamed_door"))
		var door_type: String = str(door.get("door_type", "")).strip_edges().to_lower()
		var material: String = str(door.get("material", "")).strip_edges().to_lower()
		var access_type: String = str(door.get("access_type", "")).strip_edges().to_lower()
		if door_type not in WorldObjectCatalogRef.DOOR_TYPES:
			errors.append("door_type_unknown_%s_%s" % [door_id, door_type])
		if material not in WorldObjectCatalogRef.DOOR_MATERIALS:
			errors.append("door_material_unknown_%s_%s" % [door_id, material])
		if access_type not in WorldObjectCatalogRef.ACCESS_TYPES:
			errors.append("door_access_type_unknown_%s_%s" % [door_id, access_type])
		if not door.has("state") or str(door.get("state", "")).strip_edges().is_empty():
			errors.append("door_missing_state_%s" % door_id)
		if access_type == WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY and not str(door.get("required_key_id", "")).strip_edges().is_empty():
			errors.append("no_key_door_requires_key_%s" % door_id)
		if door_type == WorldObjectCatalogRef.DOOR_TYPE_POWERED:
			var power_behavior: String = str(door.get("power_behavior", "")).strip_edges().to_lower()
			if power_behavior not in WorldObjectCatalogRef.POWER_BEHAVIORS:
				errors.append("powered_door_power_behavior_unknown_%s_%s" % [door_id, power_behavior])
		if material == door_type:
			errors.append("door_material_used_as_door_type_%s_%s" % [door_id, material])
	if door_count == 0:
		warnings.append("current_mission_has_no_doors")
	return _make_final_verification_section("door_contract", "Door Contract", errors, warnings)

func _build_final_inventory_contract_section(architecture_sections: Dictionary) -> Dictionary:
	var reused_section: Dictionary = _build_final_reused_section("inventory_contract", "Inventory Contract", architecture_sections, "inventory_storage")
	var errors: Array = Array(reused_section.get("errors", [])).duplicate()
	var warnings: Array = Array(reused_section.get("warnings", [])).duplicate()
	if active_bipob_ref != null and is_instance_valid(active_bipob_ref) and active_bipob_ref.has_method("get_available_manipulator_slots") and active_bipob_ref.has_method("get_runtime_manipulator_items"):
		var slot_count: int = int(active_bipob_ref.call("get_available_manipulator_slots"))
		var items_variant: Variant = active_bipob_ref.call("get_runtime_manipulator_items")
		if typeof(items_variant) != TYPE_ARRAY:
			errors.append("runtime_manipulator_items_not_array")
		elif Array(items_variant).size() != slot_count:
			errors.append("runtime_manipulator_slot_count_mismatch_%d_%d" % [Array(items_variant).size(), slot_count])
	else:
		warnings.append("runtime_manipulator_slot_count_unavailable")
	return _make_final_verification_section("inventory_contract", "Inventory Contract", errors, warnings)

func _build_final_runtime_action_contract_section(architecture_sections: Dictionary) -> Dictionary:
	var reused_section: Dictionary = _build_final_reused_section("runtime_action_contract", "Runtime Action Contract", architecture_sections, "runtime_action_view_model")
	var errors: Array = Array(reused_section.get("errors", [])).duplicate()
	var warnings: Array = Array(reused_section.get("warnings", [])).duplicate()
	for source_section_id in ["device_diagnostics", "device_interaction_flow", "device_interaction_state_flow"]:
		var diagnostics_section: Dictionary = _build_final_reused_section("runtime_action_contract", "Runtime Action Contract", architecture_sections, source_section_id)
		for error_variant in Array(diagnostics_section.get("errors", [])):
			errors.append("%s:%s" % [source_section_id, str(error_variant)])
		for warning_variant in Array(diagnostics_section.get("warnings", [])):
			warnings.append("%s:%s" % [source_section_id, str(warning_variant)])
	if active_bipob_ref == null or not is_instance_valid(active_bipob_ref) or not active_bipob_ref.has_method("get_facing_world_action_target"):
		warnings.append("runtime_action_target_unavailable")
		return _make_final_verification_section("runtime_action_contract", "Runtime Action Contract", errors, warnings)
	var facing_variant: Variant = active_bipob_ref.call("get_facing_world_action_target")
	if typeof(facing_variant) != TYPE_DICTIONARY:
		errors.append("runtime_action_target_not_dictionary")
		return _make_final_verification_section("runtime_action_contract", "Runtime Action Contract", errors, warnings)
	var facing: Dictionary = facing_variant
	var target_variant: Variant = facing.get("target_object", {})
	var selected_action: String = str(active_bipob_ref.get("selected_world_action")).strip_edges()
	if typeof(target_variant) != TYPE_DICTIONARY or target_variant.is_empty():
		if not selected_action.is_empty():
			errors.append("stale_selected_world_action_without_target_%s" % selected_action)
		warnings.append("runtime_target_missing_or_empty")
		return _make_final_verification_section("runtime_action_contract", "Runtime Action Contract", errors, warnings)
	var target: Dictionary = target_variant
	var normalized_target: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(target)
	var view_model_variant: Variant = facing.get("action_view_model", {})
	if typeof(view_model_variant) != TYPE_DICTIONARY:
		errors.append("runtime_action_view_model_missing")
	else:
		var view_model: Dictionary = view_model_variant
		var model_target_variant: Variant = view_model.get("target", {})
		if typeof(model_target_variant) != TYPE_DICTIONARY:
			errors.append("runtime_action_view_model_target_missing")
		elif str(Dictionary(model_target_variant).get("object_type", "")) != str(normalized_target.get("object_type", "")):
			errors.append("runtime_action_view_model_target_not_normalized_%s" % str(target.get("id", "unnamed_target")))
	return _make_final_verification_section("runtime_action_contract", "Runtime Action Contract", errors, warnings)

func _build_final_mission_goal_binding_section(architecture_sections: Dictionary) -> Dictionary:
	var reused_section: Dictionary = _build_final_reused_section("mission_goal_binding", "Mission Goal Binding", architecture_sections, "mission_objective")
	var errors: Array = Array(reused_section.get("errors", [])).duplicate()
	var warnings: Array = Array(reused_section.get("warnings", [])).duplicate()
	var view_model: Dictionary = get_current_mission_objective_view_model()
	if view_model.is_empty():
		errors.append("active_mission_objective_view_model_missing")
	else:
		var goal_text: String = str(view_model.get("goal_text", "")).strip_edges()
		var objective_hint: String = str(view_model.get("objective_hint", "")).strip_edges()
		if goal_text.is_empty() and objective_hint.is_empty():
			errors.append("active_mission_objective_text_missing")
		if not current_mission_id.is_empty():
			var catalog_goal_text: String = get_mission_goal_text(current_mission_id).strip_edges()
			if not catalog_goal_text.is_empty() and goal_text != catalog_goal_text:
				errors.append("active_mission_goal_not_bound_to_catalog_%s" % current_mission_id)
	return _make_final_verification_section("mission_goal_binding", "Mission Goal Binding", errors, warnings)

func _build_final_validation_read_only_section() -> Dictionary:
	var errors: Array[String] = []
	var world_objects_snapshot: String = var_to_str(mission_world_objects)
	var inventory_snapshot: String = var_to_str(runtime_inventory_state)
	validate_architecture_contracts()
	if world_objects_snapshot != var_to_str(mission_world_objects):
		errors.append("validation_mutated_runtime_state:mission_world_objects")
	if inventory_snapshot != var_to_str(runtime_inventory_state):
		errors.append("validation_mutated_runtime_state:runtime_inventory_state")
	return _make_final_verification_section("validation_read_only", "Validation Read-only", errors)

func _build_final_legacy_boundary_section(architecture_sections: Dictionary) -> Dictionary:
	var reused_section: Dictionary = _build_final_reused_section("legacy_boundary", "Legacy Boundary", architecture_sections, "legacy_boundary")
	var errors: Array = Array(reused_section.get("errors", [])).duplicate()
	var warnings: Array = Array(reused_section.get("warnings", [])).duplicate()
	for legacy_key_type in ["mechanical_key", "mechanical_keycard", "keycard"]:
		if WorldObjectCatalogRef.normalize_key_item_type(legacy_key_type) != WorldObjectCatalogRef.KEY_ITEM_TYPE_KEY_CARD:
			errors.append("legacy_key_type_does_not_normalize_to_key_card_%s" % legacy_key_type)
	return _make_final_verification_section("legacy_boundary", "Legacy Boundary", errors, warnings)

func _build_final_ui_backend_consistency_section() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if not has_method("get_current_mission_objective_view_model"):
		errors.append("mission_goal_ui_backend_helper_missing")
	if not has_method("get_inventory_state"):
		errors.append("inventory_ui_backend_helper_missing")
	if active_bipob_ref == null or not is_instance_valid(active_bipob_ref):
		warnings.append("active_bipob_ui_backend_unavailable")
	elif not active_bipob_ref.has_method("get_runtime_manipulator_items") or not active_bipob_ref.has_method("get_available_manipulator_slots"):
		errors.append("manipulator_ui_backend_helper_missing")
	return _make_final_verification_section("ui_backend_consistency", "UI Backend Consistency", errors, warnings)

func _get_architecture_stabilization_manual_smoke_checklist() -> Array[String]:
	return [
		"Start TASK TEST.",
		"Output does not spam errors.",
		"GOAL panel shows mission objective.",
		"Empty cell in front of Bipob has no Action pulse.",
		"Fuse pickup goes to manipulator.",
		"Fuse moves manipulator ↔ pocket.",
		"Key-card pickup goes to keychain and displays as K.",
		"Key-card does not occupy manipulator.",
		"Mechanical no_key door opens/closes.",
		"Mechanical key_card door opens with key-card and free manipulator.",
		"Mechanical key_card door does not open when manipulator occupied.",
		"Digital door opens through digital_key/access_code/terminal depending on setup.",
		"Powered door follows power_behavior.",
		"Map Constructor palette contains door presets.",
		"Placed constructor door works like TASK TEST door.",
		"Preset save/load does not create unknown object_type.",
		"Runtime storage rejects physical item in digital storage.",
		"Manipulator UI shows only real manipulator slots.",
		"Key strip shows compact K/empty cells.",
		"No stale selected pulse after pickup/action/move/turn."
	]

func get_architecture_contract_validation_text() -> String:
	var report: Dictionary = validate_architecture_contracts()
	var lines: Array[String] = ["Architecture Contract Validation:", str(report.get("summary", ""))]
	for section_variant in Array(report.get("sections", [])):
		if typeof(section_variant) != TYPE_DICTIONARY:
			continue
		var section: Dictionary = section_variant
		var section_warnings: Array = section.get("warnings", [])
		var status: String = "OK" if bool(section.get("ok", false)) else "WARN"
		lines.append("[%s] %s" % [status, str(section.get("title", section.get("id", "Unknown")))])
		for warning_variant in section_warnings:
			lines.append("- %s" % str(warning_variant))
	return "\n".join(lines)

func _make_architecture_validation_section(section_id: String, title: String, warnings: Array, warnings_are_blocking: bool = true) -> Dictionary:
	var copied_warnings: Array[String] = []
	for warning_variant in warnings:
		copied_warnings.append(str(warning_variant))
	return {"id": section_id, "title": title, "ok": copied_warnings.is_empty() or not warnings_are_blocking, "warnings": copied_warnings}

func _validate_current_door_contracts() -> Array[String]:
	var warnings: Array[String] = []
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")).strip_edges().to_lower() != "door":
			continue
		var object_id: String = str(object_data.get("id", "unnamed_door"))
		for required_field in ["object_group", "door_type", "material", "access_type", "door_class", "state", "is_open", "is_locked", "blocks_movement"]:
			if not object_data.has(required_field) or str(object_data.get(required_field, "")).strip_edges().is_empty():
				warnings.append("door_missing_%s_%s" % [required_field, object_id])
		var access_type: String = WorldObjectCatalogRef.normalize_access_type(object_data.get("access_type", object_data.get("lock_type", "")))
		if access_type not in WorldObjectCatalogRef.ACCESS_TYPES:
			warnings.append("door_access_type_unknown_%s_%s" % [object_id, access_type])
		if access_type == WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY and not str(object_data.get("required_key_id", "")).strip_edges().is_empty():
			warnings.append("no_key_door_requires_key_%s" % object_id)
		if str(object_data.get("door_type", "")).strip_edges().to_lower() == WorldObjectCatalogRef.DOOR_TYPE_POWERED:
			var power_behavior: String = str(object_data.get("power_behavior", "")).strip_edges().to_lower()
			if power_behavior not in WorldObjectCatalogRef.POWER_BEHAVIORS:
				warnings.append("powered_door_power_behavior_unknown_%s_%s" % [object_id, power_behavior])
	return warnings

func _validate_legacy_compatibility_boundary() -> Array[String]:
	var warnings: Array[String] = []
	for object_data in mission_world_objects:
		var object_id: String = str(object_data.get("id", "unnamed_object"))
		var object_type: String = str(object_data.get("object_type", "")).strip_edges().to_lower()
		if WorldObjectCatalogRef.is_legacy_door_object_type(object_type):
			warnings.append("legacy_runtime_object_type_%s_%s" % [object_id, object_type])
		if str(object_data.get("access_type", "")).strip_edges().to_lower() == "none":
			warnings.append("legacy_access_type_none_%s" % object_id)
		if object_data.has("lock_type") and not object_data.has("access_type"):
			warnings.append("legacy_lock_type_without_access_type_%s" % object_id)
		if str(object_data.get("object_group", "")).strip_edges().to_lower() == "door" and WorldObjectCatalogRef.is_material_named_door_object_type(object_type) and str(object_data.get("door_type", "")).strip_edges().is_empty():
			warnings.append("material_named_door_missing_mechanism_%s_%s" % [object_id, object_type])
		for field_variant in object_data.keys():
			var field_name: String = str(field_variant)
			if field_name in WorldObjectCatalogRef.LEGACY_SOURCE_METADATA_FIELDS:
				continue
			var field_value: Variant = object_data.get(field_variant)
			if field_value is String and WorldObjectCatalogRef.is_legacy_prefab_alias(str(field_value)) and field_name != "object_type":
				warnings.append("legacy_prefab_id_outside_metadata_%s_%s_%s" % [object_id, field_name, str(field_value)])
	return warnings

func _validate_task_test_object_contracts() -> Array[String]:
	var warnings: Array[String] = validate_task_test_catalog_layout_runtime_source()
	var task_test_snapshot: Dictionary = build_task_test_sandbox_world_objects_for_validation()
	var has_requires_power_to_open_door: bool = false
	for build_warning_variant in Array(task_test_snapshot.get("warnings", [])):
		warnings.append(str(build_warning_variant))
	for object_variant in Array(task_test_snapshot.get("objects", [])):
		if typeof(object_variant) != TYPE_DICTIONARY:
			warnings.append("task_test_object_not_dictionary")
			continue
		var object_data: Dictionary = object_variant
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		if object_id.is_empty():
			warnings.append("task_test_object_missing_id")
			object_id = "unnamed_object"
		var object_type: String = str(object_data.get("object_type", ""))
		if not WorldObjectCatalogRef.OBJECT_LIBRARY.has(object_type):
			warnings.append("task_test_object_unknown_catalog_type_%s_%s" % [object_id, object_type])
		if str(object_data.get("object_group", "")) == "door":
			var normalized_door: Dictionary = WorldObjectCatalogRef.normalize_door_contract(object_data)
			var power_behavior: String = str(normalized_door.get("power_behavior", "")).strip_edges().to_lower()
			if power_behavior == WorldObjectCatalogRef.POWER_BEHAVIOR_REQUIRES_POWER_TO_OPEN:
				has_requires_power_to_open_door = true
			elif power_behavior not in WorldObjectCatalogRef.POWER_BEHAVIORS:
				warnings.append("task_test_door_power_behavior_unknown_%s_%s" % [object_id, power_behavior])
			for required_field in ["door_type", "material", "access_type", "door_class", "state", "is_open", "is_locked", "blocks_movement"]:
				if not normalized_door.has(required_field) or str(normalized_door.get(required_field, "")).strip_edges().is_empty():
					warnings.append("task_test_door_missing_%s_%s" % [required_field, object_id])
	if not has_requires_power_to_open_door:
		warnings.append("task_test_requires_power_to_open_door_missing")
	var items_by_cell: Dictionary = task_test_snapshot.get("items_by_cell", {})
	for cell_variant in items_by_cell.keys():
		for item_variant in Array(items_by_cell.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_data: Dictionary = item_variant
			var item_id: String = str(item_data.get("id", "unnamed_item"))
			var expected_class: String = ""
			if "fuse" in item_id:
				expected_class = WorldObjectCatalogRef.ITEM_STORAGE_CLASS_PHYSICAL
			elif "mechanical_keycard" in item_id:
				expected_class = WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD
			elif "digital_key" in item_id or "access_code" in item_id or "data_file" in item_id:
				expected_class = WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL
			if expected_class.is_empty():
				continue
			var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item_data)
			if storage_class != expected_class:
				warnings.append("task_test_item_storage_class_mismatch_%s_%s_%s" % [item_id, expected_class, storage_class])
	return warnings

func _validate_runtime_action_view_model_section() -> Dictionary:
	if active_bipob_ref == null or not is_instance_valid(active_bipob_ref) or not active_bipob_ref.has_method("get_facing_world_action_target"):
		return _make_architecture_validation_section("runtime_action_view_model", "Runtime Action ViewModel", ["runtime_target_missing_or_empty"], false)
	var facing_result_variant: Variant = active_bipob_ref.call("get_facing_world_action_target")
	if typeof(facing_result_variant) != TYPE_DICTIONARY:
		return _make_architecture_validation_section("runtime_action_view_model", "Runtime Action ViewModel", ["runtime_target_missing_or_empty"], false)
	var facing_result: Dictionary = facing_result_variant
	var target_variant: Variant = facing_result.get("target_object", {})
	if typeof(target_variant) != TYPE_DICTIONARY or target_variant.is_empty():
		return _make_architecture_validation_section("runtime_action_view_model", "Runtime Action ViewModel", ["runtime_target_missing_or_empty"], false)
	var view_model_variant: Variant = facing_result.get("action_view_model", {})
	if typeof(view_model_variant) != TYPE_DICTIONARY:
		return _make_architecture_validation_section("runtime_action_view_model", "Runtime Action ViewModel", ["runtime_action_view_model_missing"], true)
	var view_model: Dictionary = view_model_variant
	var warnings: Array[String] = []
	for required_field in ["target", "actions", "available_action_ids", "primary_action_id", "primary_action_label", "has_available_action", "disabled_reason"]:
		if not view_model.has(required_field):
			warnings.append("runtime_action_view_model_missing_%s" % required_field)
	if active_bipob_ref.has_method("validate_runtime_action_view_model"):
		for warning_variant in Array(active_bipob_ref.call("validate_runtime_action_view_model", view_model)):
			warnings.append(str(warning_variant))
	else:
		warnings.append("validation_helper_missing_validate_runtime_action_view_model")
	var target: Dictionary = target_variant
	if str(target.get("object_group", "")) == "door" and Array(view_model.get("actions", [])).is_empty() and str(view_model.get("disabled_reason", "")).strip_edges().is_empty():
		warnings.append("canonical_door_has_no_action_or_reason_%s" % str(target.get("id", "unnamed_door")))
	return _make_architecture_validation_section("runtime_action_view_model", "Runtime Action ViewModel", warnings)

func _validate_device_diagnostics_section() -> Dictionary:
	if active_bipob_ref == null or not is_instance_valid(active_bipob_ref) or not active_bipob_ref.has_method("get_facing_world_action_target"):
		return _make_architecture_validation_section("device_diagnostics", "Device Diagnostics", ["diagnostic_target_missing_or_empty"], false)
	var facing_result_variant: Variant = active_bipob_ref.call("get_facing_world_action_target")
	if typeof(facing_result_variant) != TYPE_DICTIONARY:
		return _make_architecture_validation_section("device_diagnostics", "Device Diagnostics", ["diagnostic_target_missing_or_empty"], false)
	var facing_result: Dictionary = facing_result_variant
	var target_variant: Variant = facing_result.get("target_object", {})
	if typeof(target_variant) != TYPE_DICTIONARY or Dictionary(target_variant).is_empty():
		return _make_architecture_validation_section("device_diagnostics", "Device Diagnostics", ["diagnostic_target_missing_or_empty"], false)
	var target: Dictionary = Dictionary(target_variant)
	var target_snapshot: String = var_to_str(target)
	var target_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(facing_result.get("target_position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var diagnostic: Dictionary = build_device_diagnostic_result(target, target_cell)
	var warnings: Array[String] = []
	for required_field in ["ok", "target_id", "target_name", "target_group", "target_type", "target_cell", "is_scanned", "state", "requirements", "capabilities", "missing", "available_actions", "blocked_actions", "summary", "warnings"]:
		if not diagnostic.has(required_field):
			warnings.append("diagnostic_result_missing_%s" % required_field)
	var requirements_variant: Variant = diagnostic.get("requirements", {})
	if typeof(requirements_variant) != TYPE_DICTIONARY:
		warnings.append("diagnostic_requirements_not_dictionary")
	else:
		var requirements: Dictionary = requirements_variant
		for obsolete_key in ["interface_level", "cpu_level", "required_interface_level", "required_cpu_level"]:
			if requirements.has(obsolete_key):
				warnings.append("diagnostic_obsolete_requirement_key_%s" % obsolete_key)
	for missing_variant in Array(diagnostic.get("missing", [])):
		if typeof(missing_variant) != TYPE_DICTIONARY:
			warnings.append("diagnostic_missing_requirement_not_dictionary")
			continue
		var missing_item: Dictionary = missing_variant
		if str(missing_item.get("id", "")).strip_edges().is_empty() or str(missing_item.get("label", "")).strip_edges().is_empty():
			warnings.append("diagnostic_missing_requirement_unstable")
	if str(diagnostic.get("summary", "")).strip_edges().is_empty():
		warnings.append("diagnostic_summary_missing")
	if target_snapshot != var_to_str(target):
		warnings.append("diagnostic_builder_mutated_target")
	return _make_architecture_validation_section("device_diagnostics", "Device Diagnostics", warnings)

func _validate_device_interaction_flow_section() -> Dictionary:
	if active_bipob_ref == null or not is_instance_valid(active_bipob_ref) or not active_bipob_ref.has_method("get_facing_world_action_target"):
		return _make_architecture_validation_section("device_interaction_flow", "Device Interaction Flow", ["device_interaction_target_missing_or_empty"], false)
	var facing_result_variant: Variant = active_bipob_ref.call("get_facing_world_action_target")
	if typeof(facing_result_variant) != TYPE_DICTIONARY:
		return _make_architecture_validation_section("device_interaction_flow", "Device Interaction Flow", ["device_interaction_target_missing_or_empty"], false)
	var facing_result: Dictionary = facing_result_variant
	var target_variant: Variant = facing_result.get("target_object", {})
	if typeof(target_variant) != TYPE_DICTIONARY or Dictionary(target_variant).is_empty():
		return _make_architecture_validation_section("device_interaction_flow", "Device Interaction Flow", ["device_interaction_target_missing_or_empty"], false)
	var target: Dictionary = Dictionary(target_variant)
	var target_snapshot: String = var_to_str(target)
	var target_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(facing_result.get("target_position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var view_model_variant: Variant = facing_result.get("action_view_model", {})
	var primary_action_id: String = ""
	if typeof(view_model_variant) == TYPE_DICTIONARY:
		primary_action_id = str(Dictionary(view_model_variant).get("primary_action_id", ""))
	var preflight: Dictionary = build_device_interaction_preflight(target, target_cell, primary_action_id)
	var warnings: Array[String] = []
	for required_field in ["success", "action_id", "target_id", "target_name", "diagnostic", "preflight_ok", "blocked_reason", "message", "state_changed"]:
		if not preflight.has(required_field):
			warnings.append("device_interaction_preflight_missing_%s" % required_field)
	if target_snapshot != var_to_str(target):
		warnings.append("device_interaction_preflight_mutated_target")
	if not primary_action_id.is_empty() and str(preflight.get("action_id", "")) != primary_action_id:
		warnings.append("device_interaction_primary_action_preflight_missing")
	if not bool(preflight.get("preflight_ok", false)):
		if str(preflight.get("blocked_reason", "")).strip_edges().is_empty():
			warnings.append("device_interaction_blocked_reason_missing")
		if str(preflight.get("message", "")).strip_edges().is_empty():
			warnings.append("device_interaction_blocked_message_missing")
	var message: String = str(preflight.get("message", ""))
	if message.find("Interface") >= 0 or message.find("CPU") >= 0:
		warnings.append("device_interaction_obsolete_label_in_message")
	return _make_architecture_validation_section("device_interaction_flow", "Device Interaction Flow", warnings)

func _validate_device_interaction_state_flow_section() -> Dictionary:
	var no_target_flow: Dictionary = build_device_interaction_state_flow({}, Vector2i(-1, -1))
	var warnings: Array[String] = []
	for required_field in ["target_id", "target_name", "target_cell", "state", "next_step_id", "next_step_label", "message", "diagnostic", "preflight", "can_execute", "warnings"]:
		if not no_target_flow.has(required_field):
			warnings.append("device_interaction_state_flow_missing_%s" % required_field)
	if str(no_target_flow.get("state", "")) != "no_target" or bool(no_target_flow.get("can_execute", false)):
		warnings.append("device_interaction_state_flow_no_target_not_informational")
	if active_bipob_ref == null or not is_instance_valid(active_bipob_ref) or not active_bipob_ref.has_method("get_facing_world_action_target"):
		return _make_architecture_validation_section("device_interaction_state_flow", "Device Interaction State Flow", warnings, false)
	var facing_result_variant: Variant = active_bipob_ref.call("get_facing_world_action_target")
	if typeof(facing_result_variant) != TYPE_DICTIONARY:
		return _make_architecture_validation_section("device_interaction_state_flow", "Device Interaction State Flow", warnings, false)
	var facing_result: Dictionary = facing_result_variant
	var target_variant: Variant = facing_result.get("target_object", {})
	if typeof(target_variant) != TYPE_DICTIONARY or Dictionary(target_variant).is_empty():
		return _make_architecture_validation_section("device_interaction_state_flow", "Device Interaction State Flow", warnings, false)
	var target: Dictionary = Dictionary(target_variant)
	var target_snapshot: String = var_to_str(target)
	var target_cell: Vector2i = WorldObjectCatalogRef.to_world_cell(facing_result.get("target_position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var view_model_variant: Variant = facing_result.get("action_view_model", {})
	var primary_action_id: String = ""
	if typeof(view_model_variant) == TYPE_DICTIONARY:
		primary_action_id = str(Dictionary(view_model_variant).get("primary_action_id", ""))
	var flow: Dictionary = build_device_interaction_state_flow(target, target_cell, primary_action_id)
	for required_field in ["target_id", "target_name", "target_cell", "state", "next_step_id", "next_step_label", "message", "diagnostic", "preflight", "can_execute", "warnings"]:
		if not flow.has(required_field):
			warnings.append("device_interaction_state_flow_missing_%s" % required_field)
	var state: String = str(flow.get("state", ""))
	if state not in DEVICE_INTERACTION_FLOW_STATES:
		warnings.append("device_interaction_state_flow_unknown_state_%s" % state)
	if state == "blocked" and (str(flow.get("message", "")).strip_edges().is_empty() or str(flow.get("next_step_id", "")).strip_edges().is_empty()):
		warnings.append("device_interaction_state_flow_blocked_guidance_missing")
	if state == "ready" and not bool(flow.get("can_execute", false)):
		warnings.append("device_interaction_state_flow_ready_not_executable")
	var preflight_variant: Variant = flow.get("preflight", {})
	if bool(flow.get("can_execute", false)) and (typeof(preflight_variant) != TYPE_DICTIONARY or not bool(Dictionary(preflight_variant).get("preflight_ok", false))):
		warnings.append("device_interaction_state_flow_execute_without_preflight")
	var message: String = str(flow.get("message", ""))
	if message.find("Interface") >= 0 or message.find("CPU") >= 0:
		warnings.append("device_interaction_state_flow_obsolete_label_in_message")
	if target_snapshot != var_to_str(target):
		warnings.append("device_interaction_state_flow_builder_mutated_target")
	return _make_architecture_validation_section("device_interaction_state_flow", "Device Interaction State Flow", warnings)

func _validate_architecture_mission_objective_contract() -> Array[String]:
	var warnings: Array[String] = validate_current_mission_objective_view_model()
	for warning_variant in validate_mission_content_catalog():
		warnings.append(str(warning_variant))
	if get_mission_goal_text(TASK_TEST_MISSION_ID).strip_edges().is_empty():
		warnings.append("mission_10_catalog_goal_text_missing")
	return warnings

func setup_world_objects_for_mission(mission_id: String) -> void:
	if is_task_test_mission_id(mission_id):
		setup_task_test_sandbox_world()
		return
	current_mission_id = mission_id
	active_runtime_mode_id = _get_runtime_mode_id_for_mission_id(mission_id)
	_clear_world_object_runtime_state()
	if mission_id != "mission_1":
		return
	var objects: Array[Dictionary] = WorldObjectCatalogRef.create_test_set()
	var placements := {
		"door_a1": Vector2i(2, 1),
		"door_e1": Vector2i(6, 2),
		"terminal_t1": Vector2i(5, 2),
		"wall_b1": Vector2i(2, 2),
		"wall_d1": Vector2i(3, 2),
		"power_src_1": Vector2i(1, 5),
		"cable_a": Vector2i(2, 5),
		"breaker_1": Vector2i(3, 5),
		"fuse_box_1": Vector2i(4, 5),
		"fuse_box_empty_1": Vector2i(5, 5),
		"crate_n_1": Vector2i(4, 3),
		"crate_h_1": Vector2i(4, 4),
		"barrel_1": Vector2i(1, 4),
		"debris_1": Vector2i(6, 5),
		"turret_1": Vector2i(7, 1)
	}
	objects.append(WorldObjectCatalogRef.create_world_object("turret", "turret_1"))
	for object_data in objects:
		var object_id := _wo_id(object_data)
		if object_id == "terminal_t1":
			object_data["id"] = "door_terminal_1"
			object_data["controls"] = ["steel_door_1"]
		if object_id == "wall_b1":
			object_data["hidden_content"] = ["power_cable"]
		if object_id == "wall_d1":
			object_data["hidden_content"] = ["secret_passage"]
		if object_id == "door_e1":
			object_data["id"] = "steel_door_1"
			object_data["state"] = "locked"
		if _should_assign_main_power_network(object_data):
			object_data["power_network_id"] = "power_net_A"
		elif object_id == "fuse_box_empty_1":
			object_data["power_network_id"] = "power_net_broken_test"
		else:
			object_data.erase("power_network_id")
		if placements.has(object_id):
			set_world_object_at_cell(placements[object_id], object_data)
		elif _wo_group(object_data) == "item":
			match object_id:
				"keycard_a1":
					add_item_at_cell(Vector2i(1, 3), object_data)
				"digikey_a1":
					add_item_at_cell(Vector2i(5, 1), object_data)
				"fuse_item_1":
					add_item_at_cell(Vector2i(4, 1), object_data)
				"datafile_enc_1":
					add_item_at_cell(Vector2i(3, 4), object_data)
				_:
					add_item_at_cell(Vector2i(1, 3), object_data)
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	if debug_world_cooling_scenario_enabled:
		seed_world_cooling_debug_scenario()
	if debug_platform_scenario_enabled:
		seed_platform_debug_scenario()
	last_threat_warning_ids.clear()
	if debug_world_logs:
		var scenario_warnings := validate_world_object_scenario()
		if not scenario_warnings.is_empty():
			for warning in scenario_warnings:
				push_warning("[WorldScenario] %s" % warning)
# endregion

func _clear_world_object_runtime_state() -> void:
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()
	_map_constructor_wall_material_overrides.clear()
	_map_constructor_floor_material_overrides.clear()
	generic_cable_runtime_report.clear()
	generic_airflow_runtime_report.clear()
	if grid_manager != null and grid_manager.has_method("clear_floor_visual_states"):
		grid_manager.call("clear_floor_visual_states")

func setup_task_test_sandbox_world() -> void:
	current_mission_id = get_task_test_sandbox_source_id()
	active_runtime_mode_id = RUNTIME_MODE_TASK_TEST
	_clear_world_object_runtime_state()
	_capture_task_test_constructor_base_tiles()
	var validation_data: Dictionary = TaskTestWorldBuilderRef.build_validation_world_objects()
	var objects: Array[Dictionary] = _safe_dictionary_array(validation_data.get("objects", []))
	var items_by_cell: Dictionary = validation_data.get("items_by_cell", {})
	for obj in objects:
		set_world_object_at_cell(Vector2i(obj.get("position", Vector2i.ZERO)), obj)
	for cell_variant in items_by_cell.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item in Array(items_by_cell.get(cell_variant, [])):
			add_item_at_cell(cell, Dictionary(item).duplicate(true))
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power_main")
	refresh_generic_cable_runtime_state()
	refresh_world_cooling_received()

func _setup_task_test_mission_world() -> void:
	setup_task_test_sandbox_world()

func _capture_task_test_constructor_base_tiles() -> void:
	_task_test_constructor_base_tiles.clear()
	if grid_manager == null or not grid_manager.has_method("get_width") or not grid_manager.has_method("get_height") or not grid_manager.has_method("get_tile"):
		return
	var width: int = int(grid_manager.call("get_width"))
	var height: int = int(grid_manager.call("get_height"))
	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			_task_test_constructor_base_tiles["%d,%d" % [x, y]] = int(grid_manager.call("get_tile", cell))

func _serialize_cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _deserialize_cell_key(cell_key: String) -> Vector2i:
	var parts: PackedStringArray = cell_key.split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))

func _deserialize_cell_variant(cell_value: Variant) -> Vector2i:
	if cell_value is Vector2i:
		return Vector2i(cell_value)
	if cell_value is String:
		return _deserialize_cell_key(str(cell_value))
	if cell_value is Dictionary:
		var cell_dict: Dictionary = Dictionary(cell_value)
		if cell_dict.has("x") and cell_dict.has("y"):
			return Vector2i(int(cell_dict.get("x", -1)), int(cell_dict.get("y", -1)))
	return Vector2i(-1, -1)

func _is_valid_grid_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false
	if grid_manager != null and grid_manager.has_method("get_width") and grid_manager.has_method("get_height"):
		var width: int = int(grid_manager.call("get_width"))
		var height: int = int(grid_manager.call("get_height"))
		return cell.x < width and cell.y < height
	return true

func get_runtime_mode_id() -> String:
	var normalized_mission_id: String = current_mission_id.strip_edges()
	if normalized_mission_id.begins_with("mission_") and RETIRED_LEGACY_MISSION_INDEXES.has(int(normalized_mission_id.trim_prefix("mission_"))):
		return RUNTIME_MODE_UNKNOWN

	var normalized_runtime_mode_id: String = active_runtime_mode_id.strip_edges()
	if not normalized_runtime_mode_id.is_empty() and normalized_runtime_mode_id != RUNTIME_MODE_UNKNOWN:
		return normalized_runtime_mode_id
	return _get_runtime_mode_id_for_mission_id(current_mission_id)

func _get_runtime_mode_id_for_mission_id(mission_id: String) -> String:
	var normalized_mission_id: String = str(mission_id).strip_edges()
	if is_task_test_mission_id(normalized_mission_id):
		return RUNTIME_MODE_TASK_TEST
	if normalized_mission_id.begins_with("mission_"):
		var mission_index: int = int(normalized_mission_id.trim_prefix("mission_"))
		if mission_index >= 1 and mission_index <= 9 and not RETIRED_LEGACY_MISSION_INDEXES.has(mission_index):
			return RUNTIME_MODE_LEGACY_STORY
	return RUNTIME_MODE_UNKNOWN

func is_task_test_mode_active() -> bool:
	return get_runtime_mode_id() == RUNTIME_MODE_TASK_TEST

func is_sandbox_mode_active() -> bool:
	return is_task_test_mode_active()

func is_legacy_story_mission_active() -> bool:
	return get_runtime_mode_id() == RUNTIME_MODE_LEGACY_STORY

func _is_task_test_constructor_context() -> bool:
	return is_sandbox_mode_active()

func normalize_map_constructor_wall_material_id(material_id: String) -> String:
	var normalized_id: String = material_id.to_lower().strip_edges()
	var legacy_aliases: Dictionary = {
		"default_metal": "concrete",
		"clean_lab": "concrete",
		"dark_service": "grate",
		"orange_hazard": "concrete_damage",
		"damaged_red": "brick_damage",
		"breachable_concrete": "breachable_concrete",
		"breachable_brick": "breachable_brick",
		"reinforced": "steel",
		"power_room": "reinforced_steel",
		"diagnostic_blue": "brick",
		"outer_wall": "outerwall",
		"wall_outer": "outerwall"
	}
	if legacy_aliases.has(normalized_id):
		return str(legacy_aliases.get(normalized_id, normalized_id))
	return normalized_id

func _is_known_map_constructor_wall_material_id(material_id: String) -> bool:
	var normalized_id: String = normalize_map_constructor_wall_material_id(material_id)
	if normalized_id.is_empty():
		return false
	var catalog: Dictionary = get_map_constructor_wall_material_catalog()
	for row_variant in Array(catalog.get("materials", [])):
		var row: Dictionary = Dictionary(row_variant)
		if str(row.get("id", "")).to_lower().strip_edges() == normalized_id:
			return true
	return false

func _format_map_constructor_cell(cell: Vector2i) -> String:
	return "(%d, %d)" % [cell.x, cell.y]

func _record_map_constructor_change(action_type: String, payload: Dictionary = {}) -> void:
	if not _is_task_test_constructor_context():
		return
	var action: String = action_type.strip_edges().to_lower()
	if action.is_empty():
		action = "unknown"
	var entity_kind: String = str(payload.get("entity_kind", "")).strip_edges()
	var entity_id: String = str(payload.get("entity_id", "")).strip_edges()
	var object_type: String = str(payload.get("object_type", payload.get("prefab_id", ""))).strip_edges()
	var cell: Vector2i = _map_constructor_cell_from_variant(payload.get("cell", Vector2i(-1, -1)))
	var summary: String = str(payload.get("summary", "")).strip_edges()
	if summary.is_empty():
		summary = "Map constructor change: %s" % action
	var details: Dictionary = Dictionary(payload.get("details", {})).duplicate(true)
	var undo_hint: String = str(payload.get("undo_hint", "")).strip_edges()
	var row: Dictionary = {
		"seq": _map_constructor_change_history_seq,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"action_type": action,
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"object_type": object_type,
		"cell": cell,
		"summary": summary,
		"details": details,
		"undo_hint": undo_hint
	}
	_map_constructor_change_history_seq += 1
	_map_constructor_change_history.append(row)
	while _map_constructor_change_history.size() > 200:
		_map_constructor_change_history.remove_at(0)

func get_map_constructor_change_history(limit: int = 50) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Change history is available only in TASK TEST constructor mode.", "history": [], "total_count": 0}
	var total_count: int = _map_constructor_change_history.size()
	var safe_limit: int = maxi(1, limit)
	var start: int = maxi(0, total_count - safe_limit)
	var rows: Array[Dictionary] = []
	for i in range(start, total_count):
		rows.append(Dictionary(_map_constructor_change_history[i]).duplicate(true))
	return {"ok": true, "message": "Change history ready.", "history": rows, "total_count": total_count}

func clear_map_constructor_change_history() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Change history clear is available only in TASK TEST constructor mode.", "cleared_count": 0}
	var cleared_count: int = _map_constructor_change_history.size()
	_map_constructor_change_history.clear()
	return {"ok": true, "message": "Change history cleared.", "cleared_count": cleared_count}

func _get_map_constructor_overview_tile_kind(tile_type: int) -> String:
	if tile_type == GridManager.TILE_FLOOR or tile_type == GridManager.TILE_STEPPED_FLOOR:
		return "floor"
	if tile_type == GridManager.TILE_WALL:
		return "wall"
	if tile_type == GridManager.TILE_DOOR or tile_type == GridManager.TILE_DIGITAL_DOOR:
		return "door"
	if tile_type == GridManager.TILE_POWERED_GATE:
		return "gate"
	return "unknown"

func _map_constructor_overview_object_matches_tags(object_data: Dictionary, tags: Array[String]) -> bool:
	var values: Array[String] = [
		str(object_data.get("object_group", "")).to_lower(),
		str(object_data.get("category", "")).to_lower(),
		str(object_data.get("object_type", "")).to_lower(),
		str(object_data.get("map_constructor_prefab_id", "")).to_lower(),
		str(object_data.get("prefab_id", "")).to_lower()
	]
	for value in values:
		if value.is_empty():
			continue
		for tag in tags:
			if value == tag or value.find(tag) >= 0:
				return true
	return false

func _safe_array(value: Variant) -> Array:
	var result: Array = []
	if value is Array:
		for item in value:
			result.append(item)
	return result

func _safe_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}

func _safe_dictionary_array(value: Variant, duplicate_rows: bool = false) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not (value is Array):
		return rows
	for row_variant in value:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = _safe_dictionary(row_variant)
		rows.append(row.duplicate(true) if duplicate_rows else row)
	return rows

func _normalize_map_constructor_floor_visual_state_row(row: Dictionary) -> Dictionary:
	var cell: Vector2i = _map_constructor_cell_from_variant(row.get("cell", Vector2i(-1, -1)))
	return {
		"cell": cell,
		"family": str(row.get("family", GridManager.FLOOR_FAMILY_METAL)).strip_edges().to_lower(),
		"wear": str(row.get("wear", GridManager.FLOOR_WEAR_NONE)).strip_edges().to_lower(),
		"base_variant": int(row.get("base_variant", -1)),
		"overlay_variant": int(row.get("overlay_variant", -1)),
		"mirror_h": bool(row.get("mirror_h", false)),
		"mirror_v": bool(row.get("mirror_v", false)),
		"floor_height": normalize_floor_height_level(str(row.get("floor_height", row.get("floor_visual_height", row.get("ground_height", "default"))))),
	}

func _serialize_map_constructor_floor_visual_state_row(row: Dictionary) -> Dictionary:
	var normalized: Dictionary = _normalize_map_constructor_floor_visual_state_row(row)
	var serialized: Dictionary = normalized.duplicate(true)
	serialized["cell"] = _serialize_cell_key(Vector2i(normalized.get("cell", Vector2i(-1, -1))))
	return serialized

func _get_map_constructor_floor_visual_state_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if grid_manager == null or not grid_manager.has_method("get_floor_visual_state_overrides"):
		return rows
	for row_variant in Array(grid_manager.call("get_floor_visual_state_overrides")):
		if not (row_variant is Dictionary):
			continue
		rows.append(_serialize_map_constructor_floor_visual_state_row(_safe_dictionary(row_variant)))
	return rows

func _apply_map_constructor_floor_visual_state_row(row: Dictionary) -> bool:
	if grid_manager == null or not grid_manager.has_method("set_floor_visual_state"):
		return false
	var normalized: Dictionary = _normalize_map_constructor_floor_visual_state_row(row)
	var cell: Vector2i = Vector2i(normalized.get("cell", Vector2i(-1, -1)))
	if not _is_valid_grid_cell(cell):
		return false
	grid_manager.call("set_floor_visual_state", cell, normalized)
	return true

func get_map_constructor_overview_data(options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Overview is available only in TASK TEST constructor mode.", "map_size": Vector2i.ZERO, "cells": [], "markers": [], "summary": {}, "legend": []}
	if grid_manager == null or not grid_manager.has_method("get_width") or not grid_manager.has_method("get_height") or not grid_manager.has_method("get_tile"):
		return {"ok": false, "message": "Grid unavailable.", "map_size": Vector2i.ZERO, "cells": [], "markers": [], "summary": {}, "legend": []}
	var width: int = int(grid_manager.call("get_width"))
	var height: int = int(grid_manager.call("get_height"))
	var cells: Array[Dictionary] = []
	var markers: Array[Dictionary] = []
	var selected_keys: Dictionary = {}
	for row_variant in _safe_array(options.get("selected_entities", [])):
		var row: Dictionary = _safe_dictionary(row_variant)
		var sk: String = "%s|%s" % [str(row.get("entity_kind", "")), str(row.get("entity_id", ""))]
		if not sk.ends_with("|"):
			selected_keys[sk] = true
	var sid: String = str(options.get("selected_entity_id", ""))
	var skind: String = str(options.get("selected_entity_kind", ""))
	if not sid.is_empty():
		selected_keys["%s|%s" % [skind, sid]] = true
	var issues: Array[Dictionary] = []
	if bool(options.get("include_validation", true)):
		issues = _safe_dictionary_array(get_map_constructor_validation_issues())
	var include_power: bool = bool(options.get("include_power", true))
	var include_items: bool = bool(options.get("include_items", true))
	var include_wall_mounted: bool = bool(options.get("include_wall_mounted", true))
	var issue_by_cell: Dictionary = {}
	for iv in issues:
		var issue: Dictionary = _safe_dictionary(iv)
		var c: Vector2i = Vector2i(issue.get("cell", Vector2i(-1, -1)))
		var key: String = _serialize_cell_key(c)
		if not issue_by_cell.has(key):
			issue_by_cell[key] = []
		issue_by_cell[key].append(issue)
		var sev: String = str(issue.get("severity", "error"))
		markers.append({"id":"issue_%s" % str(issue.get("id", key)), "kind":"warning" if sev == "warning" else "validation_issue", "label":str(issue.get("code", sev)), "cell":c, "entity_kind":str(issue.get("entity_kind", "")), "entity_id":str(issue.get("entity_id", "")), "status":"warning" if sev == "warning" else "error", "message":str(issue.get("message", ""))})
	var object_count: int = 0
	var item_count: int = 0
	var wall_mounted_count: int = 0
	var selected_count: int = 0
	var visible_cells: int = 0
	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			var cell_key: String = _serialize_cell_key(cell)
			var tile_type: int = int(grid_manager.call("get_tile", cell))
			var objects_here: Array = _safe_array(world_objects_by_cell.get(cell, []))
			var items_here: Array = _safe_array(cell_items.get(cell, []))
			var has_wall_mounted: bool = false
			var has_power: bool = false
			var has_terminal: bool = false
			var has_door: bool = false
			var has_selected: bool = false
			for ov in objects_here:
				if not (ov is Dictionary):
					continue
				var od: Dictionary = _safe_dictionary(ov)
				var oid: String = str(od.get("id", ""))
				if bool(od.get("is_wall_mounted", false)):
					has_wall_mounted = true
				var og: String = str(od.get("object_group", "")).to_lower()
				if og == "power" or _map_constructor_overview_object_matches_tags(od, ["power", "fuse", "breaker", "cable"]):
					has_power = true
				if og == "terminal" or _map_constructor_overview_object_matches_tags(od, ["terminal", "console"]):
					has_terminal = true
				if og == "door" or _map_constructor_overview_object_matches_tags(od, ["door", "gate"]):
					has_door = true
				if selected_keys.has("world_object|%s" % oid):
					has_selected = true
					markers.append({"id":"selected_world_%s" % oid, "kind":"selected", "label":"Selected object", "cell":cell, "entity_kind":"world_object", "entity_id":oid, "status":"info", "message":"Selected object."})
			for it in items_here:
				if not (it is Dictionary):
					continue
				var item_row: Dictionary = _safe_dictionary(it)
				var iid: String = str(item_row.get("id", ""))
				if selected_keys.has("item|%s" % iid):
					has_selected = true
					markers.append({"id":"selected_item_%s" % iid, "kind":"selected", "label":"Selected item", "cell":cell, "entity_kind":"item", "entity_id":iid, "status":"info", "message":"Selected item."})
			var cell_issues: Array = _safe_array(issue_by_cell.get(cell_key, []))
			var has_warning: bool = false
			var has_error: bool = false
			for iv in cell_issues:
				var issue_row: Dictionary = _safe_dictionary(iv)
				var sev: String = str(issue_row.get("severity", "error"))
				has_warning = has_warning or sev == "warning"
				has_error = has_error or sev != "warning"
			var has_expected_invalid: bool = false
			for ov2 in objects_here:
				var od2: Dictionary = _safe_dictionary(ov2)
				var oid2: String = str(od2.get("id", ""))
				if not oid2.is_empty() and is_task_test_expected_invalid_object_id(oid2):
					has_expected_invalid = true
					markers.append({"id":"expected_%s" % oid2, "kind":"expected_invalid", "label":"Expected invalid", "cell":cell, "entity_kind":"world_object", "entity_id":oid2, "status":"expected_invalid", "message":"Expected invalid object."})
			var visible: bool = grid_manager.has_method("is_cell_visible") and bool(grid_manager.call("is_cell_visible", cell))
			if not has_door:
				var tile_kind: String = _get_map_constructor_overview_tile_kind(tile_type)
				has_door = tile_kind == "door" or tile_kind == "gate"
			visible_cells += 1 if visible else 0
			var density: int = objects_here.size() + items_here.size()
			cells.append({"cell":cell, "tile_type":tile_type, "tile_kind":_get_map_constructor_overview_tile_kind(tile_type), "visible":visible, "object_count":objects_here.size(), "item_count":items_here.size(), "has_world_object":objects_here.size() > 0, "has_item":items_here.size() > 0, "has_wall_mounted":has_wall_mounted, "has_power":has_power, "has_terminal":has_terminal, "has_door":has_door, "has_validation_issue":has_error, "has_warning":has_warning, "has_expected_invalid":has_expected_invalid, "has_selected":has_selected, "density":density})
			object_count += objects_here.size(); item_count += items_here.size()
			if has_wall_mounted:
				wall_mounted_count += 1
				if include_wall_mounted:
					markers.append({"id":"wall_mounted_%s" % cell_key, "kind":"wall_mounted", "label":"Wall-mounted", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Wall-mounted object in cell."})
			if has_selected: selected_count += 1
			if objects_here.size() > 0:
				markers.append({"id":"object_%s" % cell_key, "kind":"object", "label":"Object", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Object in cell."})
			if include_items and items_here.size() > 0:
				markers.append({"id":"item_%s" % cell_key, "kind":"item", "label":"Item", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Item in cell."})
			if include_power and has_power:
				markers.append({"id":"power_%s" % cell_key, "kind":"power", "label":"Power", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Power object in cell."})
			if has_terminal: markers.append({"id":"terminal_%s" % cell_key, "kind":"terminal", "label":"Terminal", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Terminal in cell."})
			if has_door:
				markers.append({"id":"door_%s" % cell_key, "kind":"door", "label":"Door/Gate", "cell":cell, "entity_kind":"", "entity_id":"", "status":"info", "message":"Door or gate in cell."})
	if bool(options.get("include_history", true)):
		var history: Array = _safe_array(get_map_constructor_change_history(int(options.get("max_history_markers", 20))).get("history", []))
		for rowv in history:
			var row: Dictionary = _safe_dictionary(rowv)
			var hcell: Vector2i = Vector2i(row.get("cell", Vector2i(-1, -1)))
			if hcell.x >= 0 and hcell.y >= 0:
				markers.append({"id":"history_%s" % str(row.get("seq", "")), "kind":"history", "label":str(row.get("action_type", "change")), "cell":hcell, "entity_kind":str(row.get("entity_kind", "")), "entity_id":str(row.get("entity_id", "")), "status":"info", "message":str(row.get("summary", ""))})
	var readiness: Dictionary = get_map_constructor_mission_readiness_report()
	var readiness_summary: Dictionary = _safe_dictionary(readiness.get("summary", {}))
	var summary: Dictionary = {"width":width, "height":height, "visible_cells":visible_cells, "object_count":object_count, "item_count":item_count, "wall_mounted_count":wall_mounted_count, "validation_issue_count":issues.size(), "error_count":int(readiness_summary.get("error_count", 0)), "warning_count":int(readiness_summary.get("warning_count", 0)), "expected_invalid_count":0, "selected_count":selected_count}
	for m in markers:
		var marker_row: Dictionary = _safe_dictionary(m)
		if str(marker_row.get("kind", "")) == "expected_invalid":
			summary["expected_invalid_count"] = int(summary.get("expected_invalid_count", 0)) + 1
	return {"ok": true, "message": "Overview ready.", "map_size": Vector2i(width, height), "cells": cells, "markers": markers, "summary": summary, "legend": [{"symbol":".","kind":"floor"},{"symbol":"#","kind":"wall"},{"symbol":"D","kind":"door"},{"symbol":"T","kind":"terminal"},{"symbol":"P","kind":"power"},{"symbol":"I","kind":"item"},{"symbol":"W","kind":"wall_mounted"},{"symbol":"!","kind":"error"},{"symbol":"?","kind":"warning"},{"symbol":"*","kind":"selected"},{"symbol":"X","kind":"expected_invalid"}]}

func _map_constructor_is_protected_id(entity_id: String) -> bool:
	var normalized: String = entity_id.strip_edges().to_lower()
	return normalized == "bipob" or normalized == "start_marker" or normalized == "exit_marker"

func _map_constructor_cell_from_variant(cell_variant: Variant) -> Vector2i:
	if cell_variant is Vector2i:
		return Vector2i(cell_variant)
	if cell_variant is Dictionary:
		var cell_dict: Dictionary = cell_variant
		if cell_dict.has("x") and cell_dict.has("y"):
			return Vector2i(int(cell_dict.get("x", -1)), int(cell_dict.get("y", -1)))
	if cell_variant is Array:
		var arr: Array = cell_variant
		if arr.size() >= 2:
			return Vector2i(int(arr[0]), int(arr[1]))
	if cell_variant is String:
		var text: String = str(cell_variant).strip_edges()
		if text.begins_with("(") and text.ends_with(")"):
			text = text.substr(1, text.length() - 2)
		var parts: PackedStringArray = text.split(",")
		if parts.size() == 2:
			return Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))
	return Vector2i(-1, -1)

func export_map_constructor_runtime_patch() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Runtime patch export works only in TASK TEST constructor mode.", "patch": {}, "json": "", "object_count": 0, "item_count": 0, "tile_edit_count": 0}
	var task_test_source_id: String = get_task_test_source_id()
	var patch: Dictionary = {"schema_version": MAP_CONSTRUCTOR_PATCH_SCHEMA_VERSION, "mission_id": task_test_source_id, "source_mission_id": task_test_source_id, "created_at_runtime": str(Time.get_unix_time_from_system()), "source": "task_test_map_constructor", "objects": [], "items": [], "tile_edits": [], "floor_visual_states": [], "links": [], "metadata": {"source_mission_id": task_test_source_id}}
	for object_data in mission_world_objects:
		if not bool(object_data.get("created_by_map_constructor", false)):
			continue
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		if object_id.is_empty() or _map_constructor_is_protected_id(object_id):
			continue
		var row: Dictionary = Dictionary(object_data).duplicate(true)
		row["position"] = _serialize_cell_key(Vector2i(row.get("position", Vector2i(-1, -1))))
		patch["objects"].append(row)
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if not (item_variant is Dictionary):
				continue
			var item: Dictionary = _safe_dictionary(item_variant)
			if not bool(item.get("created_by_map_constructor", false)):
				continue
			var item_id: String = str(item.get("id", "")).strip_edges()
			if item_id.is_empty() or _map_constructor_is_protected_id(item_id):
				continue
			var item_row: Dictionary = item.duplicate(true)
			item_row["cell"] = _serialize_cell_key(cell)
			patch["items"].append(item_row)
	patch["floor_visual_states"] = _get_map_constructor_floor_visual_state_rows()
	for link_object_variant in mission_world_objects:
		if not (link_object_variant is Dictionary):
			continue
		var door_data: Dictionary = Dictionary(link_object_variant)
		var door_id: String = str(door_data.get("id", "")).strip_edges()
		var key_id: String = str(door_data.get("required_key_id", "")).strip_edges()
		if not door_id.is_empty() and not key_id.is_empty():
			patch["links"].append({"type":"key_door", "key_id":key_id, "door_id":door_id, "source_id":key_id, "target_id":door_id})
	var json_text: String = JSON.stringify(patch, "\t")
	return {"ok": true, "message": "Runtime patch exported.", "patch": patch, "json": json_text, "object_count": Array(patch.get("objects", [])).size(), "item_count": Array(patch.get("items", [])).size(), "tile_edit_count": 0}

func parse_map_constructor_patch_json(patch_json: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(patch_json)
	if not (parsed is Dictionary):
		return {"ok": false, "message": "Invalid patch JSON.", "patch": {}, "warnings": []}
	var patch: Dictionary = Dictionary(parsed).duplicate(true)
	if int(patch.get("schema_version", 0)) != MAP_CONSTRUCTOR_PATCH_SCHEMA_VERSION:
		return {"ok": false, "message": "Unsupported patch schema_version.", "patch": {}, "warnings": []}
	var patch_mission_id: String = str(patch.get("mission_id", "")).strip_edges()
	if patch_mission_id.is_empty():
		patch_mission_id = str(patch.get("source_mission_id", "")).strip_edges()
	var current_source_id: String = str(current_mission_id).strip_edges()
	if is_task_test_mission_id(patch_mission_id) and is_task_test_mission_id(current_source_id):
		patch["mission_id"] = normalize_task_test_source_id(patch_mission_id)
		patch["source_mission_id"] = normalize_task_test_source_id(patch_mission_id)
	elif patch_mission_id != current_source_id:
		return {"ok": false, "message": "Patch mission_id mismatch.", "patch": {}, "warnings": []}
	for row_variant in Array(patch.get("objects", [])):
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			row["position"] = _map_constructor_cell_from_variant(row.get("position", Vector2i(-1, -1)))
			row["anchor_floor_cell"] = _map_constructor_cell_from_variant(row.get("anchor_floor_cell", Vector2i(-1, -1)))
			row["attached_wall_cell"] = _map_constructor_cell_from_variant(row.get("attached_wall_cell", Vector2i(-1, -1)))
	for row_variant_item in Array(patch.get("items", [])):
		if row_variant_item is Dictionary:
			var row_item: Dictionary = row_variant_item
			row_item["cell"] = _map_constructor_cell_from_variant(row_item.get("cell", Vector2i(-1, -1)))
	for floor_state_variant in Array(patch.get("floor_visual_states", [])):
		if floor_state_variant is Dictionary:
			var floor_state_row: Dictionary = floor_state_variant
			floor_state_row["cell"] = _map_constructor_cell_from_variant(floor_state_row.get("cell", Vector2i(-1, -1)))
	return {"ok": true, "message": "Patch parsed.", "patch": patch, "warnings": []}

func _collect_map_constructor_patch_field_changes(current: Dictionary, incoming: Dictionary, entity_kind: String) -> Array[Dictionary]:
	var fields: Array[String] = [
		"object_type", "item_type", "object_group", "state", "position", "cell", "placement_mode", "wall_side",
		"anchor_floor_cell", "attached_wall_cell", "power_network_id", "target_door_id", "target_platform_id",
		"linked_terminal_id", "control_source_id", "connected_device_ids", "required_key_id", "map_constructor_prefab_id"
	]
	if entity_kind == "item":
		fields.erase("position")
	var changes: Array[Dictionary] = []
	for field_name in fields:
		var current_value: Variant = current.get(field_name, null)
		var incoming_value: Variant = incoming.get(field_name, null)
		if field_name == "position" or field_name == "cell" or field_name == "anchor_floor_cell" or field_name == "attached_wall_cell":
			if _map_constructor_cell_from_variant(current_value) == _map_constructor_cell_from_variant(incoming_value):
				continue
		if current_value == incoming_value:
			continue
		changes.append({"field": field_name, "current": current_value, "incoming": incoming_value})
	return changes

func compare_map_constructor_patch(patch: Dictionary) -> Dictionary:
	var diffs: Array[Dictionary] = []
	var warnings: Array[String] = []
	var conflicts: Array[Dictionary] = []
	var will_add: int = 0
	var will_update: int = 0
	var unchanged: int = 0
	for entity_kind in ["world_object", "item"]:
		var patch_rows: Array = Array(patch.get("objects" if entity_kind == "world_object" else "items", []))
		for row_variant in patch_rows:
			if not (row_variant is Dictionary):
				continue
			var row: Dictionary = Dictionary(row_variant)
			var entity_id: String = str(row.get("id", "")).strip_edges()
			if entity_kind == "world_object":
				row["position"] = _map_constructor_cell_from_variant(row.get("position", Vector2i(-1, -1)))
			else:
				row["cell"] = _map_constructor_cell_from_variant(row.get("cell", Vector2i(-1, -1)))
			if entity_id.is_empty() or _map_constructor_is_protected_id(entity_id):
				conflicts.append({"change_type":"conflict", "entity_kind":entity_kind, "id":entity_id, "message":"Missing/protected id."})
				continue
			var current_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
			if not bool(current_info.get("ok", false)):
				if entity_kind == "item":
					var incoming_cell: Vector2i = _map_constructor_cell_from_variant(row.get("cell", Vector2i(-1, -1)))
					if incoming_cell != Vector2i(-1, -1) and not Array(cell_items.get(incoming_cell, [])).is_empty():
						warnings.append("Item id %s not found; cell %s already contains items." % [entity_id, _serialize_cell_key(incoming_cell)])
				diffs.append({"change_type":"add", "entity_kind":entity_kind, "id":entity_id, "cell":row.get("position" if entity_kind == "world_object" else "cell", Vector2i(-1, -1)), "field_changes":[], "message":"Will add %s." % ("object" if entity_kind == "world_object" else "item")})
				will_add += 1
				continue
			var current: Dictionary = Dictionary(current_info.get("data", {}))
			if current.is_empty():
				current = Dictionary(current_info.get("entity", {}))
			if not bool(current.get("created_by_map_constructor", false)):
				conflicts.append({"change_type":"conflict", "entity_kind":entity_kind, "id":entity_id, "message":"ID belongs to non-constructor %s." % ("object" if entity_kind == "world_object" else "item")})
				continue
			if entity_kind == "item":
				current["cell"] = Vector2i(current_info.get("cell", Vector2i(-1, -1)))
			var field_changes: Array[Dictionary] = _collect_map_constructor_patch_field_changes(current, row, entity_kind)
			if field_changes.is_empty():
				unchanged += 1
				diffs.append({"change_type":"unchanged", "entity_kind":entity_kind, "id":entity_id, "cell":row.get("position" if entity_kind == "world_object" else "cell", Vector2i(-1, -1)), "field_changes":[], "message":"No changes."})
			else:
				will_update += 1
				diffs.append({"change_type":"update", "entity_kind":entity_kind, "id":entity_id, "cell":row.get("position" if entity_kind == "world_object" else "cell", Vector2i(-1, -1)), "field_changes":field_changes, "message":"Will update %s." % ("object" if entity_kind == "world_object" else "item")})
	for floor_state_variant in Array(patch.get("floor_visual_states", [])):
		if not (floor_state_variant is Dictionary):
			continue
		var floor_state_row: Dictionary = _normalize_map_constructor_floor_visual_state_row(_safe_dictionary(floor_state_variant))
		var floor_cell: Vector2i = Vector2i(floor_state_row.get("cell", Vector2i(-1, -1)))
		if not _is_valid_grid_cell(floor_cell):
			conflicts.append({"change_type":"conflict", "entity_kind":"floor_visual_state", "id":_serialize_cell_key(floor_cell), "message":"Invalid floor visual state cell."})
			continue
		var current_floor_state: Dictionary = {}
		if grid_manager != null and grid_manager.has_method("get_floor_visual_state"):
			current_floor_state = _safe_dictionary(grid_manager.call("get_floor_visual_state", floor_cell))
		var floor_changes: Array[Dictionary] = []
		for field_name in ["family", "wear", "base_variant", "overlay_variant", "mirror_h", "mirror_v", "floor_height"]:
			if current_floor_state.get(field_name, null) != floor_state_row.get(field_name, null):
				floor_changes.append({"field": field_name, "current": current_floor_state.get(field_name, null), "incoming": floor_state_row.get(field_name, null)})
		if floor_changes.is_empty():
			unchanged += 1
			diffs.append({"change_type":"unchanged", "entity_kind":"floor_visual_state", "id":_serialize_cell_key(floor_cell), "cell":floor_cell, "field_changes":[], "message":"No floor visual changes."})
		else:
			will_update += 1
			diffs.append({"change_type":"update", "entity_kind":"floor_visual_state", "id":_serialize_cell_key(floor_cell), "cell":floor_cell, "field_changes":floor_changes, "message":"Will update floor visual state."})
	var summary: Dictionary = {"will_add": will_add, "will_update": will_update, "will_delete": 0, "unchanged": unchanged, "conflicts": conflicts.size(), "warnings": warnings.size()}
	return {"ok": true, "message": "Patch compare complete.", "summary": summary, "diffs": diffs, "warnings": warnings, "conflicts": conflicts}

func preview_apply_map_constructor_patch(patch: Dictionary) -> Dictionary:
	var cmp: Dictionary = compare_map_constructor_patch(patch)
	return {"ok": bool(cmp.get("ok", false)), "message": str(cmp.get("message", "")), "can_apply": Array(cmp.get("conflicts", [])).is_empty(), "diffs": Array(cmp.get("diffs", [])), "warnings": Array(cmp.get("warnings", [])), "conflicts": Array(cmp.get("conflicts", [])), "summary": Dictionary(cmp.get("summary", {}))}

func apply_map_constructor_patch(patch: Dictionary, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Patch apply works only in TASK TEST constructor mode.", "applied_count": 0, "added_count": 0, "updated_count": 0, "deleted_count": 0, "warnings": [], "conflicts": [], "patch_id": ""}
	var preview: Dictionary = preview_apply_map_constructor_patch(patch)
	if not bool(preview.get("ok", false)):
		return {"ok": false, "message": str(preview.get("message", "Preview failed.")), "applied_count": 0, "added_count": 0, "updated_count": 0, "deleted_count": 0, "warnings": [], "conflicts": Array(preview.get("conflicts", [])), "patch_id": ""}
	var warnings: Array[String] = Array(preview.get("warnings", [])).duplicate()
	if not bool(options.get("allow_conflicts", false)) and not bool(preview.get("can_apply", false)):
		return {"ok": false, "message": "Patch has conflicts.", "applied_count": 0, "added_count": 0, "updated_count": 0, "deleted_count": 0, "warnings": warnings, "conflicts": Array(preview.get("conflicts", [])), "patch_id": ""}
	_map_constructor_last_patch_snapshot = {"patch_id":"patch_%d" % int(Time.get_unix_time_from_system()), "mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true), "floor_visual_states": _get_map_constructor_floor_visual_state_rows()}
	var added_count: int = 0
	var updated_count: int = 0
	var allow_adds: bool = bool(options.get("allow_adds", true))
	var allow_updates: bool = bool(options.get("allow_updates", true))
	for diff_variant in Array(preview.get("diffs", [])):
		if not (diff_variant is Dictionary):
			continue
		var diff: Dictionary = Dictionary(diff_variant)
		var change_type: String = str(diff.get("change_type", ""))
		if change_type == "add" and not allow_adds:
			warnings.append("Skipped add for %s %s: allow_adds=false" % [str(diff.get("entity_kind", "entity")), str(diff.get("id", ""))])
			continue
		if change_type == "update" and not allow_updates:
			warnings.append("Skipped update for %s %s: allow_updates=false" % [str(diff.get("entity_kind", "entity")), str(diff.get("id", ""))])
			continue
		if change_type != "add" and change_type != "update":
			continue
		var entity_kind: String = str(diff.get("entity_kind", ""))
		var entity_id: String = str(diff.get("id", "")).strip_edges()
		if entity_kind == "floor_visual_state":
			var target_cell: Vector2i = _map_constructor_cell_from_variant(diff.get("cell", Vector2i(-1, -1)))
			var applied_floor_state: bool = false
			for floor_state_variant in Array(patch.get("floor_visual_states", [])):
				if floor_state_variant is Dictionary and _map_constructor_cell_from_variant(Dictionary(floor_state_variant).get("cell", Vector2i(-1, -1))) == target_cell:
					applied_floor_state = _apply_map_constructor_floor_visual_state_row(_safe_dictionary(floor_state_variant))
					break
			if applied_floor_state:
				updated_count += 1
			else:
				warnings.append("Skipped floor visual state at %s." % _serialize_cell_key(target_cell))
			continue
		if entity_id.is_empty() or _map_constructor_is_protected_id(entity_id):
			continue
		var source_rows: Array = Array(patch.get("objects" if entity_kind == "world_object" else "items", []))
		var incoming_row: Dictionary = {}
		for row_variant in source_rows:
			if row_variant is Dictionary and str(Dictionary(row_variant).get("id", "")).strip_edges() == entity_id:
				incoming_row = Dictionary(row_variant).duplicate(true)
				break
		if incoming_row.is_empty():
			warnings.append("Skipped %s %s: source row missing." % [entity_kind, entity_id])
			continue
		if entity_kind == "world_object":
			var pos: Vector2i = _map_constructor_cell_from_variant(incoming_row.get("position", Vector2i(-1, -1)))
			incoming_row["position"] = pos
			if change_type == "update":
				_remove_map_constructor_entity_by_id("world_object", entity_id)
				updated_count += 1
			else:
				added_count += 1
			set_world_object_at_cell(pos, incoming_row)
		elif entity_kind == "item":
			var cell: Vector2i = _map_constructor_cell_from_variant(incoming_row.get("cell", Vector2i(-1, -1)))
			if change_type == "update":
				_remove_map_constructor_entity_by_id("item", entity_id)
				updated_count += 1
			else:
				added_count += 1
			incoming_row.erase("cell")
			add_item_at_cell(cell, incoming_row)
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power_main")
	refresh_generic_cable_runtime_state()
	refresh_world_cooling_received()
	var patch_id: String = str(_map_constructor_last_patch_snapshot.get("patch_id", ""))
	var summary_data: Dictionary = Dictionary(preview.get("summary", {}))
	_record_map_constructor_change("patch_apply", {"summary":"Applied patch: +%d / ~%d / -0" % [added_count, updated_count], "details":{"patch_id":patch_id, "added_count":added_count, "updated_count":updated_count, "summary":summary_data}, "undo_hint":"Use Rollback Last Patch."})
	return {"ok": true, "message": "Patch applied.", "applied_count": added_count + updated_count, "added_count": added_count, "updated_count": updated_count, "deleted_count": 0, "warnings": warnings, "conflicts": Array(preview.get("conflicts", [])), "patch_id": patch_id}

func rollback_last_map_constructor_patch() -> Dictionary:
	if _map_constructor_last_patch_snapshot.is_empty():
		return {"ok": false, "message": "No patch to rollback."}
	mission_world_objects = Array(_map_constructor_last_patch_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_patch_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_patch_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	if grid_manager != null and grid_manager.has_method("clear_floor_visual_states"):
		grid_manager.call("clear_floor_visual_states")
	for floor_state_variant in Array(_map_constructor_last_patch_snapshot.get("floor_visual_states", [])):
		if floor_state_variant is Dictionary:
			_apply_map_constructor_floor_visual_state_row(_safe_dictionary(floor_state_variant))
	_map_constructor_last_patch_snapshot.clear()
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power_main")
	refresh_generic_cable_runtime_state()
	refresh_world_cooling_received()
	_record_map_constructor_change("patch_rollback", {"summary":"Rolled back last patch", "undo_hint":"Apply patch again if needed."})
	return {"ok": true, "message": "Last patch rolled back."}

func create_map_constructor_empty_map(width: int, height: int) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Constructor map build works only in TASK TEST constructor mode."}
	constructor_map_width = maxi(6, width)
	constructor_map_height = maxi(6, height)
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()
	constructor_start_marker.clear()
	constructor_exit_marker.clear()
	if grid_manager != null and grid_manager.has_method("clear_floor_visual_states"):
		grid_manager.call("clear_floor_visual_states")
	if grid_manager != null and grid_manager.has_method("build_constructor_map"):
		var grid_result: Dictionary = grid_manager.call("build_constructor_map", constructor_map_width, constructor_map_height)
		constructor_map_width = int(grid_result.get("width", constructor_map_width))
		constructor_map_height = int(grid_result.get("height", constructor_map_height))
	if grid_manager != null and grid_manager.has_method("enforce_boundary_walls"):
		grid_manager.call("enforce_boundary_walls")
	if grid_manager != null and grid_manager.has_method("request_visual_refresh"):
		grid_manager.call("request_visual_refresh")
	return {"ok": true, "message": "Constructor map created.", "width": constructor_map_width, "height": constructor_map_height}

func get_inside_cell_for_boundary_marker(cell: Vector2i) -> Dictionary:
	if grid_manager == null or not grid_manager.has_method("is_boundary_cell"):
		return {"ok": false, "inside_cell": Vector2i(-1, -1), "side": "", "message": "Grid is unavailable."}
	if not bool(grid_manager.call("is_boundary_cell", cell)):
		return {"ok": false, "inside_cell": Vector2i(-1, -1), "side": "", "message": "Marker cell must be on map boundary."}
	var width: int = int(grid_manager.call("get_width"))
	var height: int = int(grid_manager.call("get_height"))
	if (cell.x == 0 or cell.x == width - 1) and (cell.y == 0 or cell.y == height - 1):
		return {"ok": false, "inside_cell": Vector2i(-1, -1), "side": "", "message": "corner markers are not supported yet"}
	if cell.x == 0:
		return {"ok": true, "inside_cell": Vector2i(1, cell.y), "side": "west", "message": "Start marker set."}
	if cell.x == width - 1:
		return {"ok": true, "inside_cell": Vector2i(width - 2, cell.y), "side": "east", "message": "Start marker set."}
	if cell.y == 0:
		return {"ok": true, "inside_cell": Vector2i(cell.x, 1), "side": "north", "message": "Start marker set."}
	return {"ok": true, "inside_cell": Vector2i(cell.x, height - 2), "side": "south", "message": "Start marker set."}

func _set_constructor_marker(marker_type: String, cell: Vector2i) -> Dictionary:
	var inside_info: Dictionary = get_inside_cell_for_boundary_marker(cell)
	if not bool(inside_info.get("ok", false)):
		return {"ok": false, "message": str(inside_info.get("message", "Marker placement failed."))}
	var inside_cell: Vector2i = Vector2i(inside_info.get("inside_cell", Vector2i(-1, -1)))
	if grid_manager == null or int(grid_manager.call("get_tile", inside_cell)) == GridManager.TILE_WALL:
		return {"ok": false, "message": "Inside marker cell is invalid."}
	var marker: Dictionary = {"cell": _serialize_cell_key(cell), "inside_cell": _serialize_cell_key(inside_cell), "side": str(inside_info.get("side", ""))}
	if marker_type == "start":
		constructor_start_marker = marker
		return {"ok": true, "message": "Start marker set.", "marker": marker}
	constructor_exit_marker = marker
	return {"ok": true, "message": "Exit marker set.", "marker": marker}

func set_map_constructor_start_marker(cell: Vector2i) -> Dictionary:
	return _set_constructor_marker("start", cell)

func set_map_constructor_exit_marker(cell: Vector2i) -> Dictionary:
	return _set_constructor_marker("exit", cell)

func clear_map_constructor_start_marker() -> Dictionary:
	constructor_start_marker.clear()
	return {"ok": true, "message": "Start marker cleared."}

func clear_map_constructor_exit_marker() -> Dictionary:
	constructor_exit_marker.clear()
	return {"ok": true, "message": "Exit marker cleared."}

func get_map_constructor_mission_markers() -> Dictionary:
	return {"start": Dictionary(constructor_start_marker).duplicate(true), "exit": Dictionary(constructor_exit_marker).duplicate(true)}

func _sanitize_map_constructor_preset_name(raw_name: String) -> String:
	var value: String = raw_name.strip_edges().to_lower().replace(" ", "_")
	var result: String = ""
	for i in range(value.length()):
		var ch: String = value.substr(i, 1)
		if ch.unicode_at(0) >= 97 and ch.unicode_at(0) <= 122:
			result += ch
		elif ch.unicode_at(0) >= 48 and ch.unicode_at(0) <= 57:
			result += ch
		elif ch == "_" or ch == "-":
			result += ch
	if result.is_empty():
		return "preset"
	return result

func _get_map_constructor_preset_path(preset_name: String) -> String:
	return "%s/%s.json" % [MAP_CONSTRUCTOR_PRESET_DIR, _sanitize_map_constructor_preset_name(preset_name)]

func _get_map_constructor_mission_patch_path(patch_name: String) -> String:
	return "%s/%s.json" % [MAP_CONSTRUCTOR_MISSION_PATCH_DIR, _sanitize_map_constructor_preset_name(patch_name)]

func get_map_constructor_mission_patch_data(patch_name: String = "") -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(patch_name)
	var preset_data: Dictionary = get_map_constructor_preset_data()
	var validation_overlay: Dictionary = get_map_constructor_validation_overlay()
	var summary: Dictionary = Dictionary(validation_overlay.get("summary", {}))
	var audit_summary: Dictionary = {}
	if has_method("get_map_constructor_audit_summary"):
		audit_summary = get_map_constructor_audit_summary()
	summary["audit"] = audit_summary
	var validation: Dictionary = {
		"ok": bool(validation_overlay.get("ok", false)),
		"summary": summary
	}
	var final_name: String = sanitized_name
	if final_name.is_empty():
		final_name = "patch"
	return {
		"version": 1,
		"patch_type": "task_test_constructor_mission_patch",
		"source_mission_id": get_task_test_source_id(),
		"patch_name": final_name,
		"created_at_unix": int(Time.get_unix_time_from_system()),
		"world_objects": Array(preset_data.get("world_objects", [])),
		"cell_items": Array(preset_data.get("cell_items", [])),
		"map": Dictionary(preset_data.get("map", {})).duplicate(true),
		"mission_markers": Dictionary(preset_data.get("mission_markers", {})).duplicate(true),
		"grid_tiles": Array(preset_data.get("grid_tiles", [])).duplicate(true),
		"grid_overrides": Array(preset_data.get("grid_overrides", [])),
		"floor_visual_states": Array(preset_data.get("floor_visual_states", [])),
		"validation": validation,
		"notes": "TASK TEST constructor mission patch export"
	}

func export_map_constructor_mission_patch(patch_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(patch_name)
	var path: String = _get_map_constructor_mission_patch_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Mission patch export works only in TASK TEST constructor mode.", "path": path, "patch_name": sanitized_name}
	var dir_result: Error = DirAccess.make_dir_recursive_absolute(MAP_CONSTRUCTOR_MISSION_PATCH_DIR)
	if dir_result != OK and dir_result != ERR_ALREADY_EXISTS:
		return {"ok": false, "message": "Mission patch export failed: cannot create patch directory.", "path": path, "patch_name": sanitized_name}
	var patch_data: Dictionary = get_map_constructor_mission_patch_data(sanitized_name)
	var validation: Dictionary = Dictionary(patch_data.get("validation", {}))
	var validation_summary: Dictionary = Dictionary(validation.get("summary", {}))
	var validation_error_count: int = int(validation_summary.get("error_count", 0))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Mission patch export failed: cannot open file.", "path": path, "patch_name": sanitized_name}
	file.store_string(JSON.stringify(patch_data, "	"))
	file.close()
	var message: String = "Mission patch '%s' exported." % sanitized_name
	if validation_error_count > 0:
		message = "%s Exported with validation errors: %d" % [message, validation_error_count]
	return {"ok": true, "message": message, "path": path, "patch_name": sanitized_name}

func list_map_constructor_mission_patches() -> Array[Dictionary]:
	var patches: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(MAP_CONSTRUCTOR_MISSION_PATCH_DIR)
	if dir == null:
		return patches
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".json"):
			var patch_entry_name: String = file_name.substr(0, file_name.length() - 5)
			var full_path: String = "%s/%s" % [MAP_CONSTRUCTOR_MISSION_PATCH_DIR, file_name]
			patches.append({"name": patch_entry_name, "path": full_path, "modified_unix": int(FileAccess.get_modified_time(full_path))})
		file_name = dir.get_next()
	dir.list_dir_end()
	patches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return patches

func delete_map_constructor_mission_patch(patch_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(patch_name)
	var path: String = _get_map_constructor_mission_patch_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Mission patch delete works only in TASK TEST constructor mode.", "patch_name": sanitized_name}
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "Mission patch delete failed: file not found.", "patch_name": sanitized_name}
	var dir: DirAccess = DirAccess.open(MAP_CONSTRUCTOR_MISSION_PATCH_DIR)
	if dir == null:
		return {"ok": false, "message": "Mission patch delete failed: directory unavailable.", "patch_name": sanitized_name}
	var err: Error = dir.remove("%s.json" % sanitized_name)
	if err != OK:
		return {"ok": false, "message": "Mission patch delete failed.", "patch_name": sanitized_name}
	return {"ok": true, "message": "Mission patch '%s' deleted." % sanitized_name, "patch_name": sanitized_name}

func get_map_constructor_preset_data() -> Dictionary:
	var world_objects_export: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if object_data is Dictionary:
			var serialized_object: Dictionary = Dictionary(object_data).duplicate(true)
			var object_cell: Vector2i = _deserialize_cell_variant(serialized_object.get("position", Vector2i(-1, -1)))
			serialized_object["position"] = _serialize_cell_key(object_cell)
			world_objects_export.append(serialized_object)
	var cell_items_export: Array[Dictionary] = []
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		cell_items_export.append({
			"cell": _serialize_cell_key(cell),
			"items": get_items_at_cell(cell)
		})
	var grid_tiles: Array[Dictionary] = []
	var grid_overrides: Array[Dictionary] = []
	if grid_manager != null and grid_manager.has_method("get_width") and grid_manager.has_method("get_height") and grid_manager.has_method("get_tile"):
		constructor_map_width = int(grid_manager.call("get_width"))
		constructor_map_height = int(grid_manager.call("get_height"))
		for y in range(constructor_map_height):
			for x in range(constructor_map_width):
				var tile_cell: Vector2i = Vector2i(x, y)
				var tile_type: int = int(grid_manager.call("get_tile", tile_cell))
				grid_tiles.append({"cell": _serialize_cell_key(tile_cell), "tile_type": tile_type})
				var expected_type: int = GridManager.TILE_WALL if bool(grid_manager.call("is_boundary_cell", tile_cell)) else GridManager.TILE_FLOOR
				if tile_type != expected_type:
					grid_overrides.append({"cell": _serialize_cell_key(tile_cell), "tile_type": tile_type})
	return {
		"version": 1,
		"mission_id": get_task_test_source_id(),
		"source_mission_id": get_task_test_source_id(),
		"saved_at_unix": Time.get_unix_time_from_system(),
		"world_objects": world_objects_export,
		"cell_items": cell_items_export,
		"map": {"width": constructor_map_width, "height": constructor_map_height, "boundary_wall_type": "outer_wall"},
		"mission_markers": get_map_constructor_mission_markers(),
		"grid_tiles": grid_tiles,
		"grid_overrides": grid_overrides,
		"floor_visual_states": _get_map_constructor_floor_visual_state_rows(),
		"notes": "TASK TEST constructor preset",
		"warnings": []
	}

func _validate_constructor_marker(marker: Dictionary, marker_name: String) -> Dictionary:
	if marker.is_empty():
		return {"ok": false, "message": "%s marker missing." % marker_name.capitalize()}
	var marker_cell: Vector2i = _deserialize_cell_variant(marker.get("cell", "-1,-1"))
	var inside_cell: Vector2i = _deserialize_cell_variant(marker.get("inside_cell", "-1,-1"))
	if grid_manager == null or not grid_manager.has_method("is_boundary_cell"):
		return {"ok": false, "message": "%s marker validation failed: grid unavailable." % marker_name.capitalize()}
	if not bool(grid_manager.call("is_boundary_cell", marker_cell)):
		return {"ok": false, "message": "%s marker not boundary: %s." % [marker_name.capitalize(), _serialize_cell_key(marker_cell)]}
	var inside_info: Dictionary = get_inside_cell_for_boundary_marker(marker_cell)
	if not bool(inside_info.get("ok", false)):
		return {"ok": false, "message": "%s inside cell invalid: %s." % [marker_name.capitalize(), str(inside_info.get("message", "invalid marker"))]}
	var expected_inside: Vector2i = Vector2i(inside_info.get("inside_cell", Vector2i(-1, -1)))
	if expected_inside != inside_cell:
		return {"ok": false, "message": "%s inside cell invalid: expected %s, got %s." % [marker_name.capitalize(), _serialize_cell_key(expected_inside), _serialize_cell_key(inside_cell)]}
	if int(grid_manager.call("get_tile", inside_cell)) == GridManager.TILE_WALL:
		return {"ok": false, "message": "%s inside cell invalid: %s is wall." % [marker_name.capitalize(), _serialize_cell_key(inside_cell)]}
	return {"ok": true, "message": ""}

func save_map_constructor_preset(preset_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(preset_name)
	var path: String = _get_map_constructor_preset_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Preset save works only in TASK TEST constructor mode.", "path": path, "preset_name": sanitized_name}
	var dir_result: Error = DirAccess.make_dir_recursive_absolute(MAP_CONSTRUCTOR_PRESET_DIR)
	if dir_result != OK and dir_result != ERR_ALREADY_EXISTS:
		return {"ok": false, "message": "Preset save failed: cannot create preset directory.", "path": path, "preset_name": sanitized_name}
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Preset save failed: cannot open file.", "path": path, "preset_name": sanitized_name}
	file.store_string(JSON.stringify(get_map_constructor_preset_data(), "\t"))
	file.close()
	return {"ok": true, "message": "Preset '%s' saved." % sanitized_name, "path": path, "preset_name": sanitized_name}

func list_map_constructor_presets() -> Array[Dictionary]:
	var presets: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(MAP_CONSTRUCTOR_PRESET_DIR)
	if dir == null:
		return presets
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".json"):
			var preset_entry_name: String = file_name.substr(0, file_name.length() - 5)
			var full_path: String = "%s/%s" % [MAP_CONSTRUCTOR_PRESET_DIR, file_name]
			presets.append({"name": preset_entry_name, "path": full_path, "modified_unix": int(FileAccess.get_modified_time(full_path))})
		file_name = dir.get_next()
	dir.list_dir_end()
	presets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return presets

func load_map_constructor_preset(preset_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(preset_name)
	var path: String = _get_map_constructor_preset_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Preset load works only in TASK TEST constructor mode.", "preset_name": sanitized_name}
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "Preset load failed: file not found.", "preset_name": sanitized_name}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Preset load failed: cannot open file.", "preset_name": sanitized_name}
	var parse_result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parse_result is Dictionary):
		return {"ok": false, "message": "Preset load failed: invalid JSON.", "preset_name": sanitized_name}
	var preset: Dictionary = Dictionary(parse_result)
	if int(preset.get("version", 0)) != 1:
		return {"ok": false, "message": "Preset load failed: unsupported version.", "preset_name": sanitized_name}
	var imported_source_id: String = str(preset.get("mission_id", "")).strip_edges()
	if imported_source_id.is_empty():
		imported_source_id = str(preset.get("source_mission_id", "")).strip_edges()
	if not is_task_test_mission_id(imported_source_id):
		return {"ok": false, "message": "Preset load failed: mission mismatch.", "preset_name": sanitized_name}
	var preset_source_id: String = normalize_task_test_source_id(imported_source_id)
	preset["mission_id"] = preset_source_id
	preset["source_mission_id"] = preset_source_id
	var warnings: Array[String] = []
	var map_data: Dictionary = Dictionary(preset.get("map", {}))
	var map_width: int = int(map_data.get("width", constructor_map_width))
	var map_height: int = int(map_data.get("height", constructor_map_height))
	create_map_constructor_empty_map(map_width, map_height)
	mission_world_objects.clear()
	world_objects_by_cell.clear()
	cell_items.clear()
	for object_variant in Array(preset.get("world_objects", [])):
		if not (object_variant is Dictionary):
			continue
		var object_data: Dictionary = _safe_dictionary(object_variant).duplicate(true)
		var object_id: String = str(object_data.get("id", "<unknown>"))
		var object_cell: Vector2i = _deserialize_cell_variant(object_data.get("position", "-1,-1"))
		if not _is_valid_grid_cell(object_cell):
			warnings.append("Skipped world object %s: invalid cell '%s'." % [object_id, str(object_data.get("position", "-1,-1"))])
			continue
		object_data["position"] = object_cell
		set_world_object_at_cell(object_cell, object_data)
	for cell_entry_variant in Array(preset.get("cell_items", [])):
		if not (cell_entry_variant is Dictionary):
			continue
		var cell_entry: Dictionary = Dictionary(cell_entry_variant)
		var cell_raw: Variant = cell_entry.get("cell", "-1,-1")
		var cell: Vector2i = _deserialize_cell_variant(cell_raw)
		if not _is_valid_grid_cell(cell):
			warnings.append("Skipped cell items entry: invalid cell '%s'." % str(cell_raw))
			continue
		for item_variant in Array(cell_entry.get("items", [])):
			if item_variant is Dictionary:
				add_item_at_cell(cell, _safe_dictionary(item_variant).duplicate(true))
	var loaded_grid_tiles: Array = Array(preset.get("grid_tiles", []))
	for tile_variant in loaded_grid_tiles:
		if not (tile_variant is Dictionary):
			continue
		var tile_row: Dictionary = Dictionary(tile_variant)
		var tile_cell: Vector2i = _deserialize_cell_variant(tile_row.get("cell", "-1,-1"))
		if not _is_valid_grid_cell(tile_cell):
			continue
		if grid_manager != null and grid_manager.has_method("set_tile"):
			grid_manager.call("set_tile", tile_cell, int(tile_row.get("tile_type", GridManager.TILE_FLOOR)))
	for floor_state_variant in Array(preset.get("floor_visual_states", [])):
		if not (floor_state_variant is Dictionary):
			continue
		if not _apply_map_constructor_floor_visual_state_row(_safe_dictionary(floor_state_variant)):
			warnings.append("Skipped floor visual state: invalid row.")
	if grid_manager != null and grid_manager.has_method("enforce_boundary_walls"):
		grid_manager.call("enforce_boundary_walls")
	var mission_markers: Dictionary = Dictionary(preset.get("mission_markers", {}))
	constructor_start_marker = Dictionary(mission_markers.get("start", {})).duplicate(true)
	constructor_exit_marker = Dictionary(mission_markers.get("exit", {})).duplicate(true)
	PowerSystemRef.recalculate_network(mission_world_objects, "task_test_power_main")
	var networks: Dictionary = {}
	for object_data_variant in mission_world_objects:
		if not (object_data_variant is Dictionary):
			continue
		var network_id: String = str(Dictionary(object_data_variant).get("power_network_id", "")).strip_edges()
		if not network_id.is_empty():
			networks[network_id] = true
	for network_id_variant in networks.keys():
		PowerSystemRef.recalculate_network(mission_world_objects, str(network_id_variant))
	refresh_world_cooling_received()
	return {"ok": true, "message": "Preset '%s' loaded." % sanitized_name, "preset_name": sanitized_name, "warnings": warnings}

func delete_map_constructor_preset(preset_name: String) -> Dictionary:
	var sanitized_name: String = _sanitize_map_constructor_preset_name(preset_name)
	var path: String = _get_map_constructor_preset_path(sanitized_name)
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Preset delete works only in TASK TEST constructor mode.", "preset_name": sanitized_name}
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "Preset delete failed: file not found.", "preset_name": sanitized_name}
	var dir: DirAccess = DirAccess.open(MAP_CONSTRUCTOR_PRESET_DIR)
	if dir == null:
		return {"ok": false, "message": "Preset delete failed: directory unavailable.", "preset_name": sanitized_name}
	var err: Error = dir.remove("%s.json" % sanitized_name)
	if err != OK:
		return {"ok": false, "message": "Preset delete failed.", "preset_name": sanitized_name}
	return {"ok": true, "message": "Preset '%s' deleted." % sanitized_name, "preset_name": sanitized_name}

func build_task_test_sandbox_world_objects_for_validation() -> Dictionary:
	return TaskTestWorldBuilderRef.build_validation_world_objects()

func build_task_test_mission_world_objects_for_validation() -> Dictionary:
	return build_task_test_sandbox_world_objects_for_validation()

func set_grid_manager_ref(value: Node) -> void:
	grid_manager = value

# region Scenario validation
func validate_world_object_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var ids := {}
	var occupied_cells := {}
	var turret_1: Dictionary = {}
	for object_data in mission_world_objects:
		var scanned_object_id := _wo_id(object_data)
		if not scanned_object_id.is_empty():
			ids[scanned_object_id] = true
		if scanned_object_id == "turret_1":
			turret_1 = object_data
	for object_data in mission_world_objects:
		var object_id := _wo_id(object_data)
		var pos := _wo_pos(object_data)
		if _wo_group(object_data) != "item":
			if occupied_cells.has(pos):
				warnings.append("Two world objects occupy %s." % str(pos))
			occupied_cells[pos] = object_id
		var controls: Array = object_data.get("controls", [])
		if object_data.has("controls") and controls.is_empty():
			warnings.append("Object %s has empty controls list." % object_id)
		for controlled_id in controls:
			if not ids.has(str(controlled_id)):
				warnings.append("Object %s controls missing id %s." % [object_id, str(controlled_id)])
		if object_data.has("power_network_id"):
			var network_id := str(object_data.get("power_network_id", ""))
			if network_id.is_empty():
				warnings.append("Object %s has empty power network id." % object_id)
		if bool(object_data.get("heavy_claw_movable", false)):
			if not bool(object_data.get("blocks_movement", false)):
				warnings.append("Heavy Claw object %s must block movement." % object_id)
			if not WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data):
				warnings.append("Heavy Claw object %s has an unsupported movable contract." % object_id)
	for required_id in ["steel_door_1", "door_terminal_1", "turret_1"]:
		if not ids.has(required_id):
			warnings.append("Required scenario id missing: %s." % required_id)
	if not turret_1.is_empty():
		if str(turret_1.get("object_group", "")) != "threat":
			warnings.append("turret_1 must use object_group threat.")
		if int(turret_1.get("detection_range", 0)) <= 0:
			warnings.append("turret_1 must have detection_range > 0.")
		var extraction_cell := Vector2i(7, 7)
		var turret_cell := _wo_pos(turret_1)
		if turret_cell == extraction_cell:
			warnings.append("turret_1 cannot be placed on extraction cell %s." % str(extraction_cell))
		var main_route := [
			Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
			Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(7, 2),
			Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(7, 7)
		]
		if main_route.has(turret_cell):
			warnings.append("turret_1 overlaps basic mission route at %s." % str(turret_cell))
	for cell in cell_items.keys():
		var seen := {}
		for item in cell_items[cell]:
			var item_id := str(item.get("id", ""))
			if seen.has(item_id):
				warnings.append("Duplicate item id %s at cell %s." % [item_id, str(cell)])
			seen[item_id] = true
	return warnings
# endregion

func _should_assign_main_power_network(object_data: Dictionary) -> bool:
	var object_type := _wo_type(object_data)
	var object_group := _wo_group(object_data)
	if object_type in [
		"power_source_class_1",
		"power_cable",
		"circuit_breaker",
		"fuse_box_installed",
		"door_terminal",
		"energy_wall",
		"light"
	]:
		return true
	if object_group == "door" and (str(object_data.get("material", "")) == WorldObjectCatalogRef.DOOR_MATERIAL_ENERGY or str(object_data.get("power_behavior", "none")) != WorldObjectCatalogRef.POWER_BEHAVIOR_NONE):
		return true
	if object_group in ["terminal", "power"]:
		return object_type != "fuse_box_empty"
	return false

func _seed_debug_world_objects() -> void:
	mission_world_objects = WorldObjectCatalogRef.create_test_set()
	for object_data in mission_world_objects:
		if object_data.get("id", "") in ["wall_b1", "wall_d1"]:
			object_data["scan_level"] = 3
	if mission_world_objects.size() > 0:
		mission_world_objects[0]["power_network_id"] = "power_net_A"
	for object_data in mission_world_objects:
		if object_data.get("object_group", "") in ["door", "terminal", "power"]:
			object_data["power_network_id"] = "power_net_A"
		if object_data.get("object_type", "") == "energy_wall":
			object_data["power_network_id"] = "power_net_A"
		if object_data.get("id", "") == "fuse_box_empty_1":
			object_data["power_network_id"] = ""
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	if debug_world_cooling_scenario_enabled:
		seed_world_cooling_debug_scenario()
	if debug_platform_scenario_enabled:
		seed_platform_debug_scenario()
	if debug_world_logs:
		_debug_world_summary()

func _place_debug_world_object(object_type: String, object_id: String, cell: Vector2i, overrides: Dictionary = {}) -> Dictionary:
	if object_type.is_empty() or object_id.is_empty():
		return {}
	var existing := get_world_object_by_id(object_id)
	if not existing.is_empty():
		var existing_cell := Vector2i(existing.get("position", cell))
		world_objects_by_cell.erase(existing_cell)
		mission_world_objects.erase(existing)
	var object_data := WorldObjectCatalogRef.create_world_object(object_type, object_id)
	if object_data.is_empty():
		return {}
	object_data["id"] = object_id
	object_data["position"] = cell
	for key in overrides.keys():
		object_data[key] = overrides[key]
	var replaced := get_world_object_at_cell(cell)
	if not replaced.is_empty() and str(replaced.get("id", "")) == object_id:
		mission_world_objects.erase(replaced)
	world_objects_by_cell[cell] = object_data
	if not mission_world_objects.has(object_data):
		mission_world_objects.append(object_data)
	return object_data

func seed_world_cooling_debug_scenario(origin: Vector2i = Vector2i(8, 8)) -> void:
	_place_debug_world_object("terminal", "terminal_c2_radiator", origin + Vector2i(0, 0), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_radiator", "cooling_radiator_a", origin + Vector2i(1, 0))
	_place_debug_world_object("terminal", "terminal_c2_radiator_metal", origin + Vector2i(0, 2), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_radiator", "cooling_radiator_b", origin + Vector2i(1, 2))
	_place_debug_world_object("metal_cooling_block", "cooling_metal_block_b", origin + Vector2i(2, 2))
	_place_debug_world_object("terminal", "terminal_c2_air", origin + Vector2i(0, 4), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_direct_c", origin + Vector2i(-1, 4), {"facing_dir": "right"})
	_place_debug_world_object("terminal", "terminal_c2_water", origin + Vector2i(0, 6), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_water_pipe", "cooling_water_d", origin + Vector2i(1, 6))
	_place_debug_world_object("terminal", "terminal_c2_duct", origin + Vector2i(3, 8), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_duct_e", origin + Vector2i(0, 8), {"facing_dir": "right"})
	_place_debug_world_object("external_air_duct", "cooling_air_duct_e1", origin + Vector2i(1, 8))
	_place_debug_world_object("external_air_duct", "cooling_air_duct_e2", origin + Vector2i(2, 8))
	_place_debug_world_object("terminal", "terminal_c2_air_water", origin + Vector2i(0, 10), {"terminal_class": 2, "working_heat": 2, "current_heat": 2, "overheat_threshold": 3, "hack_heat": 1})
	_place_debug_world_object("external_air_cooler", "cooling_air_combo_f", origin + Vector2i(-1, 10), {"facing_dir": "right"})
	_place_debug_world_object("external_water_pipe", "cooling_water_combo_f", origin + Vector2i(0, 11))
	_place_debug_world_object("power_source_class_3", "power_source_c3_cooled", origin + Vector2i(0, 12), {"working_heat": 3, "current_heat": 3, "overheat_threshold": 3, "state": "active"})
	_place_debug_world_object("external_water_pipe", "cooling_water_g", origin + Vector2i(1, 12))
	refresh_world_cooling_received()
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()

func validate_world_cooling_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	# Manual validation checklist:
	# 1) Class 2 terminal without cooling should fail hack due to temporary overheat.
	# 2) Class 2 terminal with cooling 1+ should be safe from terminal temporary overheat.
	# 3) CPU internal overheat is separate and may still fail hack first.
	var expected := {
		"terminal_c2_radiator": 1,
		"terminal_c2_radiator_metal": 2,
		"terminal_c2_air": 2,
		"terminal_c2_water": 2,
		"terminal_c2_duct": 2,
		"terminal_c2_air_water": 4
	}
	for object_id in expected.keys():
		var object_data := get_world_object_by_id(str(object_id))
		if object_data.is_empty():
			warnings.append("Missing debug object: %s." % str(object_id))
			continue
		var received := int(object_data.get("cooling_received", -1))
		var target := int(expected[object_id])
		if received != target:
			warnings.append("%s cooling_received expected %d, got %d." % [str(object_id), target, received])
	var power_source := get_world_object_by_id("power_source_c3_cooled")
	if power_source.is_empty():
		warnings.append("Missing debug object: power_source_c3_cooled.")
	else:
		if str(power_source.get("state", "")) != "active":
			warnings.append("power_source_c3_cooled state expected active, got %s." % str(power_source.get("state", "")))
		var current_heat := int(power_source.get("current_heat", 999))
		var threshold := int(power_source.get("overheat_threshold", 0))
		if current_heat >= threshold:
			warnings.append("power_source_c3_cooled current_heat must be below threshold (%d >= %d)." % [current_heat, threshold])
	return warnings

func _debug_world_summary() -> void:
	for object_data in mission_world_objects:
		var scan_text := ScanSystemRef.get_scan_display_text(object_data, "visor")
		print("[WorldObject] %s (%s) state=%s" % [object_data.get("display_name", "Unknown"), object_data.get("object_type", ""), object_data.get("state", "")])
		print("[Scan] %s" % scan_text)

func debug_try_action(target_id: String, action_type: String, module_id: String = "") -> Dictionary:
	var target := _find_object(target_id)
	if target.is_empty():
		return {"success": false, "message": "Target not found.", "effects": []}
	var actor := {
		"processor_level": 1,
		"connector_level": 1,
		"manipulator_level": 1,
		"wired_connector_level": 1,
		"optical_connector_level": 1,
		"wireless_connector_level": 1,
		"high_bandwidth_connector_level": 1,
		"firewall_module_v1": false,
		"manipulator_occupied": false,
		"pocket_full": false,
		"power_class": "scout",
		"magnetic_path_blocked": false,
		"target_is_grate": false
	}
	var module := {"id": module_id}
	var result := InteractionSystemRef.apply_action(actor, module, target, action_type)
	if debug_world_logs:
		print("[Interact] %s -> %s: %s" % [target_id, action_type, result.get("message", "")])
	return result

func _find_object(target_id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if object_data.get("id", "") == target_id:
			return object_data
	return {}

func _get_world_object_cell_from_data(object_data: Dictionary) -> Vector2i:
	var position_cell: Vector2i = _deserialize_cell_variant(object_data.get("position", Vector2i(-1, -1)))
	if position_cell.x >= 0 and position_cell.y >= 0:
		return position_cell
	var cell_value: Vector2i = _deserialize_cell_variant(object_data.get("cell", Vector2i(-1, -1)))
	if cell_value.x >= 0 and cell_value.y >= 0:
		return cell_value
	var grid_cell: Vector2i = _deserialize_cell_variant(object_data.get("grid_cell", Vector2i(-1, -1)))
	return grid_cell

func is_visual_only_floor_ground_object(object_data: Dictionary) -> bool:
	var object_group: String = str(object_data.get("object_group", "")).strip_edges().to_lower()
	var object_type: String = str(object_data.get("object_type", "")).strip_edges().to_lower()
	var category: String = str(object_data.get("category", object_data.get("object_category", ""))).strip_edges().to_lower()
	var texture_asset_id: String = str(object_data.get("texture_asset_id", object_data.get("visual_texture_asset_id", object_data.get("visual_asset_id", object_data.get("asset_id", ""))))).strip_edges().to_lower()
	var floor_height_level: String = str(object_data.get("floor_height_level", object_data.get("floor_visual_height", object_data.get("ground_height", object_data.get("height_level", ""))))).strip_edges().to_lower()
	var visual_only_groups: Array[String] = ["floor", "ground", "floor_visual", "visual_floor", "floor_height", "raised_ground"]
	if object_group in visual_only_groups:
		return true
	if category in visual_only_groups:
		return true
	if object_type in ["stepped_floor", "raised_ground", "ground_low", "ground_halflow", "ground_low_01", "ground_halflow_01", "floor_stepped", "step_1", "step_2"]:
		return true
	if object_type.begins_with("floor_") or object_type.begins_with("ground_"):
		return true
	if texture_asset_id in ["ground_low_01", "ground_low_01.png", "ground_low", "ground_halflow_01", "ground_halflow_01.png", "ground_halflow", "floor_stepped"]:
		return true
	return floor_height_level in ["step_1", "step_2", "ground_low", "ground_halflow", "low", "halflow"]

func _get_world_object_lookup_priority(object_data: Dictionary) -> int:
	if is_visual_only_floor_ground_object(object_data):
		return -1000
	var object_group: String = str(object_data.get("object_group", "")).to_lower()
	var object_type: String = str(object_data.get("object_type", "")).to_lower()
	var score: int = 0
	if object_group != "visual":
		score += 10
	if CableTopologyServiceRef.is_cable_object(object_data):
		score -= 8
	if object_type.find("door") != -1 or object_type.find("gate") != -1 or object_type.find("terminal") != -1 or object_type.find("device") != -1:
		score += 5
	return score

func _select_world_object_for_cell(cell: Vector2i) -> Dictionary:
	var selected_object: Dictionary = {}
	var selected_score: int = -1
	for object_data_variant in mission_world_objects:
		var object_data: Dictionary = Dictionary(object_data_variant)
		if str(object_data.get("object_group", "")).to_lower() == "item":
			continue
		if is_visual_only_floor_ground_object(object_data):
			continue
		var object_cell: Vector2i = _get_world_object_cell_from_data(object_data)
		if object_cell != cell:
			continue
		var object_score: int = _get_world_object_lookup_priority(object_data)
		if selected_object.is_empty() or object_score > selected_score:
			selected_object = object_data
			selected_score = object_score
	if not selected_object.is_empty():
		return selected_object
	var by_cell: Dictionary = Dictionary(world_objects_by_cell.get(cell, {}))
	if str(by_cell.get("object_group", "")).to_lower() == "item":
		return {}
	if is_visual_only_floor_ground_object(by_cell):
		return {}
	return by_cell

func refresh_generic_cable_runtime_state(network_filter: String = "") -> Dictionary:
	generic_cable_runtime_report = BipobCableRuntimeServiceRef.apply_generic_power_runtime(mission_world_objects, network_filter)
	return generic_cable_runtime_report.duplicate(true)


func get_generic_cable_runtime_report() -> Dictionary:
	return generic_cable_runtime_report.duplicate(true)


func refresh_generic_airflow_runtime_state(network_filter: String = "") -> Dictionary:
	generic_airflow_runtime_report = BipobAirflowRuntimeServiceRef.apply_generic_airflow_runtime(mission_world_objects, network_filter)
	for object_data in mission_world_objects:
		if bool(object_data.get("generic_airflow_runtime", false)) and bool(object_data.get("cooling_required", false)):
			WorldObjectCatalogRef.update_world_object_heat_state(object_data)
	return generic_airflow_runtime_report.duplicate(true)


func get_generic_airflow_runtime_report() -> Dictionary:
	return generic_airflow_runtime_report.duplicate(true)


func is_world_object_cooled(object_id: String) -> bool:
	var object_data: Dictionary = get_world_object_by_id(object_id.strip_edges())
	if object_data.is_empty():
		return false
	return bool(object_data.get("is_cooled", false))


func get_world_object_cooling_state(object_id: String) -> Dictionary:
	var normalized_object_id: String = object_id.strip_edges()
	var object_data: Dictionary = get_world_object_by_id(normalized_object_id)
	if object_data.is_empty():
		return {"ok": false, "object_id": normalized_object_id, "is_cooled": false, "cooling_required": false, "cooling_received": 0, "cooling_state": "missing"}
	return {
		"ok": true,
		"object_id": str(object_data.get("id", "")),
		"is_cooled": bool(object_data.get("is_cooled", false)),
		"cooling_required": bool(object_data.get("cooling_required", false)),
		"cooling_received": int(object_data.get("cooling_received", 0)),
		"cooling_state": str(object_data.get("cooling_state", "uncooled")),
		"airflow_network_id": str(object_data.get("airflow_network_id", "")),
		"fan_object_id": str(object_data.get("fan_object_id", object_data.get("cooled_by_fan_id", ""))),
		"cooling_source_ids": Array(object_data.get("cooling_source_ids", [])).duplicate(),
	}


func is_world_object_powered(object_id: String) -> bool:
	var object_data: Dictionary = get_world_object_by_id(object_id.strip_edges())
	if object_data.is_empty():
		return false
	return bool(object_data.get("is_powered", false))


func get_world_object_power_state(object_id: String) -> Dictionary:
	var normalized_object_id: String = object_id.strip_edges()
	var object_data: Dictionary = get_world_object_by_id(normalized_object_id)
	if object_data.is_empty():
		return {"ok": false, "object_id": normalized_object_id, "is_powered": false, "power_state": "missing", "power_required": false, "power_received": 0}
	var is_powered_value: bool = bool(object_data.get("is_powered", false))
	var default_power_state: String = "unpowered"
	if is_powered_value:
		default_power_state = "powered"
	var resolved_power_state: String = str(object_data.get("power_state", default_power_state))
	var source_object_id: String = str(object_data.get("source_object_id", object_data.get("power_source_id", "")))
	return {
		"ok": true,
		"object_id": str(object_data.get("id", "")),
		"is_powered": is_powered_value,
		"power_state": resolved_power_state,
		"power_required": bool(object_data.get("power_required", false)),
		"power_received": int(object_data.get("power_received", 0)),
		"power_network_id": str(object_data.get("power_network_id", "")),
		"connection_id": str(object_data.get("connection_id", "")),
		"source_object_id": source_object_id,
		"socket_id": str(object_data.get("socket_id", ""))
	}


func get_world_object_at_cell(cell: Vector2i, include_lookup_metadata: bool = false) -> Dictionary:
	var selected_object: Dictionary = _select_world_object_for_cell(cell)
	if not include_lookup_metadata:
		return selected_object
	if selected_object.is_empty():
		return {
			"ok": false,
			"id": "",
			"object_id": "",
			"object_type": "",
			"object_group": "",
			"position": cell,
			"data": {}
		}
	var object_id: String = str(selected_object.get("id", "")).strip_edges()
	var object_type: String = str(selected_object.get("object_type", "")).strip_edges()
	var object_group: String = str(selected_object.get("object_group", "")).strip_edges()
	var position: Vector2i = _get_world_object_cell_from_data(selected_object)
	if position.x < 0 or position.y < 0:
		position = cell
	return {
		"ok": true,
		"id": object_id,
		"object_id": object_id,
		"object_type": object_type,
		"object_group": object_group,
		"position": position,
		"data": selected_object.duplicate(true)
	}


func get_runtime_cell_state(cell: Vector2i) -> Dictionary:
	var state: Dictionary = {
		"cell": cell,
		"in_bounds": false,
		"tile_type": -1,
		"tile_name": "",
		"static_walkable": false,
		"is_door_object": false,
		"is_door_tile": false,
		"is_door_cell": false,
		"has_object": false,
		"object_id": "",
		"object_type": "",
		"object_group": "",
		"display_name": "",
		"state": "",
		"is_open": false,
		"is_locked": false,
		"is_powered": false,
		"blocks_movement": false,
		"requires_key": false,
		"required_key_id": "",
		"lock_type": "",
		"power_network_id": "",
		"control_source_id": "",
		"is_passable": false,
		"block_reason": "out_of_bounds",
		"visual_profile": ""
	}
	if grid_manager == null or not grid_manager.has_method("is_in_bounds") or not bool(grid_manager.call("is_in_bounds", cell)):
		return state

	state["in_bounds"] = true
	state["block_reason"] = ""
	if grid_manager.has_method("get_tile"):
		var tile_type: int = int(grid_manager.call("get_tile", cell))
		state["tile_type"] = tile_type
		if grid_manager.has_method("get_tile_name"):
			state["tile_name"] = str(grid_manager.call("get_tile_name", tile_type))
	if grid_manager.has_method("is_walkable"):
		state["static_walkable"] = bool(grid_manager.call("is_walkable", cell))

	var object_data: Dictionary = get_world_object_at_cell(cell)
	if not object_data.is_empty():
		state["has_object"] = true
		state["object_id"] = str(object_data.get("id", ""))
		state["object_type"] = str(object_data.get("object_type", ""))
		state["object_group"] = str(object_data.get("object_group", ""))
		state["display_name"] = str(object_data.get("display_name", ""))
		state["state"] = str(object_data.get("state", "")).to_lower()
		state["is_open"] = bool(object_data.get("is_open", false))
		state["is_locked"] = bool(object_data.get("is_locked", false)) or bool(object_data.get("locked", false))
		state["is_powered"] = bool(object_data.get("is_powered", false))
		state["blocks_movement"] = bool(object_data.get("blocks_movement", false))
		state["requires_key"] = bool(object_data.get("requires_key", false))
		state["required_key_id"] = str(object_data.get("required_key_id", ""))
		state["lock_type"] = str(object_data.get("lock_type", ""))
		state["power_network_id"] = str(object_data.get("power_network_id", ""))
		state["control_source_id"] = str(object_data.get("control_source_id", object_data.get("linked_terminal_id", object_data.get("controller_id", ""))))
		state["visual_profile"] = str(object_data.get("visual_profile", ""))
		var object_group_value: String = str(state.get("object_group", "")).to_lower()
		var object_type_value: String = str(state.get("object_type", "")).to_lower()
		var lock_type_value: String = str(state.get("lock_type", ""))
		var has_door_class: bool = object_data.has("door_class")
		state["is_door_object"] = object_group_value == "door" or object_type_value.find("door") >= 0 or not lock_type_value.is_empty() or has_door_class

	var tile_type_value: int = int(state.get("tile_type", -1))
	var tile_is_wall: bool = tile_type_value == GridManager.TILE_WALL
	var tile_is_door: bool = tile_type_value == GridManager.TILE_DOOR or tile_type_value == GridManager.TILE_DIGITAL_DOOR or tile_type_value == GridManager.TILE_POWERED_GATE
	state["is_door_tile"] = tile_is_door
	state["is_door_cell"] = tile_is_door or bool(state.get("is_door_object", false))
	var object_state: String = str(state.get("state", ""))
	var is_open_state: bool = object_state == "open" or object_state == "opened"
	var canonical_open: bool = bool(state.get("is_open", false)) or is_open_state
	if bool(state.get("is_door_cell", false)):
		if canonical_open:
			state["is_passable"] = true
			state["block_reason"] = ""
			return state
		state["is_passable"] = false
		if object_state == "locked" or bool(state.get("is_locked", false)):
			state["block_reason"] = "door_locked"
		elif object_state == "unpowered":
			state["block_reason"] = "door_unpowered"
		elif object_state == "damaged" or object_state == "broken" or object_state == "destroyed":
			state["block_reason"] = "door_damaged"
		else:
			state["block_reason"] = "door_closed"
		return state
	if tile_is_wall:
		state["is_passable"] = false
		state["block_reason"] = "wall"
		return state
	if bool(state.get("has_object", false)) and bool(state.get("blocks_movement", false)):
		state["is_passable"] = false
		state["block_reason"] = "blocked_by_object"
		return state
	state["is_passable"] = bool(state.get("static_walkable", false))
	if not bool(state.get("is_passable", false)):
		state["block_reason"] = "tile_blocked"
	return state

func is_runtime_cell_passable(cell: Vector2i) -> bool:
	var state: Dictionary = get_runtime_cell_state(cell)
	return bool(state.get("is_passable", false))

func get_runtime_cell_block_reason(cell: Vector2i) -> String:
	var state: Dictionary = get_runtime_cell_state(cell)
	return str(state.get("block_reason", ""))

func set_world_object_at_cell(cell: Vector2i, object_data: Dictionary) -> void:
	if object_data.is_empty():
		return
	object_data = WorldObjectCatalogRef.normalize_door_state_fields(WorldObjectCatalogRef.normalize_world_object_contract(object_data))
	object_data["position"] = cell
	var incoming_group: String = str(object_data.get("object_group", "")).to_lower()
	var incoming_id: String = str(object_data.get("id", ""))
	for index in range(mission_world_objects.size() - 1, -1, -1):
		var existing: Dictionary = mission_world_objects[index]
		var existing_group: String = str(existing.get("object_group", "")).to_lower()
		var same_id: bool = not incoming_id.is_empty() and str(existing.get("id", "")) == incoming_id
		var conflicting_primary: bool = incoming_group in ["door", "terminal"] and existing_group in ["door", "terminal"] and _get_world_object_cell_from_data(existing) == cell
		if same_id or conflicting_primary:
			var existing_cell: Vector2i = _get_world_object_cell_from_data(existing)
			if existing_cell != cell and str(Dictionary(world_objects_by_cell.get(existing_cell, {})).get("id", "")) == str(existing.get("id", "")):
				world_objects_by_cell.erase(existing_cell)
			mission_world_objects.remove_at(index)
	var incoming_is_cable_layer: bool = CableTopologyServiceRef.is_cable_object(object_data)
	var current_lookup: Dictionary = Dictionary(world_objects_by_cell.get(cell, {}))
	if not incoming_is_cable_layer or current_lookup.is_empty() or CableTopologyServiceRef.is_cable_object(current_lookup):
		world_objects_by_cell[cell] = object_data
	mission_world_objects.append(object_data)
	refresh_generic_cable_runtime_state(str(object_data.get("power_network_id", "")))
	refresh_world_cooling_received()

func remove_world_object_at_cell(cell: Vector2i) -> void:
	var object_data := get_world_object_at_cell(cell)
	if not object_data.is_empty():
		mission_world_objects.erase(object_data)
	world_objects_by_cell.erase(cell)
	refresh_generic_cable_runtime_state()
	refresh_world_cooling_received()

func get_items_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var raw_items: Array = Array(cell_items.get(cell, []))
	for item_variant in raw_items:
		if item_variant is Dictionary:
			result.append(_safe_dictionary(item_variant))
	return result

func add_item_at_cell(cell: Vector2i, item_data: Dictionary) -> void:
	item_data = WorldObjectCatalogRef.normalize_item_contract(WorldObjectCatalogRef.normalize_world_object_contract(item_data))
	item_data["position"] = cell
	# cell_items is the authoritative pickup lookup. A dropped inventory snapshot
	# must remain an item even if old save data carried a stale world-object group.
	item_data["object_group"] = "item"
	if str(item_data.get("object_type", "")).strip_edges().is_empty():
		item_data["object_type"] = "item"
	if not item_data.has("can_pickup"):
		item_data["can_pickup"] = true
	var items: Array[Dictionary] = get_items_at_cell(cell)
	items.append(item_data)
	cell_items[cell] = items
	_sync_world_item_record(item_data)

func _sync_world_item_record(item_data: Dictionary) -> void:
	var item_id: String = str(item_data.get("id", "")).strip_edges()
	if item_id.is_empty():
		return
	for index in range(mission_world_objects.size()):
		var object_data: Dictionary = mission_world_objects[index]
		if str(object_data.get("id", "")) != item_id:
			continue
		mission_world_objects[index] = item_data
		return
	mission_world_objects.append(item_data)

func _remove_world_item_record(item_id: String) -> void:
	if item_id.strip_edges().is_empty():
		return
	for index in range(mission_world_objects.size() - 1, -1, -1):
		var object_data: Dictionary = mission_world_objects[index]
		if str(object_data.get("id", "")) == item_id:
			mission_world_objects.remove_at(index)

func _remove_world_item_from_lookup_tables(item_id: String, item_data: Dictionary = {}) -> void:
	var normalized_id: String = item_id.strip_edges()
	if normalized_id.is_empty():
		return
	for cell_variant in cell_items.keys():
		var original_items: Array = Array(cell_items.get(cell_variant, []))
		var remaining_items: Array[Dictionary] = []
		var removed := false
		for item_variant in original_items:
			if item_variant is Dictionary and str(Dictionary(item_variant).get("id", "")).strip_edges() == normalized_id:
				removed = true
				continue
			if item_variant is Dictionary:
				remaining_items.append(Dictionary(item_variant))
		if removed:
			if remaining_items.is_empty():
				cell_items.erase(cell_variant)
			else:
				cell_items[cell_variant] = remaining_items
			break
	var item_cell := WorldObjectCatalogRef.to_world_cell(item_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	for cell_variant in world_objects_by_cell.keys():
		var object_variant: Variant = world_objects_by_cell.get(cell_variant)
		if object_variant is Dictionary and str(Dictionary(object_variant).get("id", "")).strip_edges() == normalized_id:
			world_objects_by_cell.erase(cell_variant)
			break
	if item_cell != Vector2i(-1, -1):
		var item_cell_object_variant: Variant = world_objects_by_cell.get(item_cell)
		if item_cell_object_variant is Dictionary and str(Dictionary(item_cell_object_variant).get("id", "")).strip_edges() == normalized_id:
			world_objects_by_cell.erase(item_cell)
	_remove_world_item_record(normalized_id)

func remove_first_item_at_cell(cell: Vector2i) -> Dictionary:
	var items: Array[Dictionary] = get_items_at_cell(cell)
	if items.is_empty():
		return {}
	var item: Dictionary = items.pop_front()
	if items.is_empty():
		cell_items.erase(cell)
	else:
		cell_items[cell] = items
	_remove_world_item_record(str(item.get("id", "")))
	return item

func _get_world_object_template(prefab_id: String) -> Dictionary:
	var normalized_prefab_id: String = prefab_id.strip_edges()
	if normalized_prefab_id.is_empty():
		return {}
	var canonical_prefab_id: String = WorldObjectCatalogRef.canonical_object_type(normalized_prefab_id)
	if WorldObjectCatalogRef.OBJECT_LIBRARY.has(canonical_prefab_id):
		return Dictionary(WorldObjectCatalogRef.OBJECT_LIBRARY[canonical_prefab_id]).duplicate(true)
	return {}

func get_map_constructor_prefab_catalog() -> Array[Dictionary]:
	# Palette rows come from WorldObjectCatalog so authoring cannot drift.
	# Legacy item shortcuts remain hidden load/import aliases only.
	var entries: Array[Dictionary] = []
	var seen_prefab_ids: Dictionary = {}
	for entry in entries:
		seen_prefab_ids[str(entry.get("id", ""))] = true
	for row in WorldObjectCatalogRef.get_constructor_palette_rows():
		var prefab_id: String = str(row.get("prefab_id", ""))
		if prefab_id.is_empty() or seen_prefab_ids.has(prefab_id):
			continue
		var catalog_row: Dictionary = row.duplicate(true)
		catalog_row["id"] = prefab_id
		entries.append(catalog_row)
		seen_prefab_ids[prefab_id] = true
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		var prefab_id: String = str(entry.get("id", ""))
		var object_template: Dictionary = _get_world_object_template(prefab_id)
		entry["label"] = str(entry.get("display_name", object_template.get("name", prefab_id.replace("_", " ").capitalize())))
		entry["placement_mode"] = str(entry.get("placement_mode", object_template.get("placement_mode", "floor")))
		entries[index] = entry
	return entries

func _get_map_constructor_prefab_metadata_catalog() -> Dictionary:
	var metadata: Dictionary = {
		"floor": {"display_name":"Floor","category":"Structural","subcategory":"Configurable Floor","placement_mode":"object","system_roles":["navigation"],"tags":["floor","walkable","structural","configurable","archetype"],"description":"Configurable Floor archetype. Choose material, covering, visual style, and state properties in the inspector.","placement_hint":"Place the base Floor, then configure properties.","requires_wall":false,"requires_floor":false,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"stepped_floor": {"display_name":"Stepped Floor","category":"Structural","subcategory":"Floor","placement_mode":"tile","system_roles":["navigation"],"tags":["floor","walkable","elevation"],"description":"Walkable stepped floor tile.","placement_hint":"Use for alternate floor visuals.","requires_wall":false,"requires_floor":false,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"external_wall": {"display_name":"External Wall","category":"Structural","subcategory":"Wall","placement_mode":"object","system_roles":["blocking"],"tags":["wall","solid","boundary","fixed_archetype"],"description":"Fixed external structural wall. Gameplay parameters are not editable.","placement_hint":"Place the fixed external wall archetype.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"wall": {"display_name":"Wall","category":"Structural","subcategory":"Wall","placement_mode":"object","system_roles":["blocking"],"tags":["wall","obstacle","configurable","archetype"],"description":"Configurable internal wall. Choose material in the inspector.","placement_hint":"Place Wall, then configure its canonical material property.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"door": {"display_name":"Door","category":"Door","subcategory":"Configurable","placement_mode":"object","system_roles":["navigation","access_control"],"tags":["door","configurable","archetype"],"description":"Configurable door archetype. Choose material, access, power, control, and state properties in the inspector.","placement_hint":"Place the base Door, then configure properties.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"terminal": {"display_name":"Terminal","category":"Terminal","subcategory":"Configurable","placement_mode":"object","system_roles":["terminal_interaction","signal_control"],"tags":["terminal","configurable","archetype"],"description":"Configurable terminal archetype. Choose role, target, class, power, control, status, and links in the inspector.","placement_hint":"Place the base Terminal, then configure properties.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"item": {"display_name":"Item","category":"Item","subcategory":"Configurable","placement_mode":"item","system_roles":["item"],"tags":["item","configurable","archetype"],"description":"Configurable Item archetype. Choose item class, storage route, state, and optional door link in the inspector.","placement_hint":"Place the base Item, then configure properties.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{}},
		"firewall": {"display_name":"Firewall Node","category":"Wall-mounted","subcategory":"Security","placement_mode":"wall_mounted","system_roles":["signal_control"],"tags":["firewall","security","wall"],"description":"Wall-mounted digital security node.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"power_source_class_1": {"display_name":"Power Source C1","category":"Power","subcategory":"Source","placement_mode":"object","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Primary local power source.","placement_hint":"Set power_network_id in inspector after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"state":"on","power_mode":"internal","control_mode":"internal","is_powered":true,"power_source_class":1,"outlet_capacity":4}},
		"power_source_class_2": {"display_name":"Power Source C2","category":"Power","subcategory":"Source","placement_mode":"object","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Class 2 power source.","placement_hint":"Place beside wires/outlets.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"state":"on","power_mode":"internal","control_mode":"internal","is_powered":true,"power_source_class":2,"outlet_capacity":5}},
		"power_source_class_3": {"display_name":"Power Source C3","category":"Power","subcategory":"Source","placement_mode":"object","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Class 3 power source.","placement_hint":"Place beside wires/outlets.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"state":"on","power_mode":"internal","control_mode":"internal","is_powered":true,"power_source_class":3,"outlet_capacity":6}},
		"power_socket": {"display_name":"Power Socket","category":"Power","subcategory":"Connector","placement_mode":"object","system_roles":["power_network","power_consumer"],"tags":["power","socket","connector"],"description":"Power connector point for devices.","placement_hint":"Set power_network_id in inspector after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"power_cable": {"display_name":"Power Cable","category":"Power","subcategory":"Network","placement_mode":"object","system_roles":["power_network"],"tags":["power","cable","network"],"description":"Cable segment for power routing.","placement_hint":"Set power_network_id in inspector after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"circuit_switch": {"display_name":"Circuit Switch","category":"Control","subcategory":"Power","placement_mode":"object","system_roles":["signal_control","power_network"],"tags":["switch","circuit","control"],"description":"Switch controlling power state.","placement_hint":"Configure links in inspector after placement.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"circuit_breaker": {"display_name":"Circuit Breaker","category":"Power","subcategory":"Protection","placement_mode":"wall_mounted","system_roles":["power_network","signal_control"],"tags":["breaker","power","wall"],"description":"Wall-mounted power safety breaker.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"light": {"display_name":"Light","category":"Power","subcategory":"Lighting","placement_mode":"wall_mounted","system_roles":["lighting","power_consumer"],"tags":["light","lighting","wall"],"description":"Wall light linked logically to a power source.","placement_hint":"Can be wall-mounted or placed stationary.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{"brightness":"1.0","color":"#ffffff"}},
		"light_switch": {"display_name":"Light Switch","category":"Control","subcategory":"Lighting","placement_mode":"wall_mounted","system_roles":["signal_control","power_consumer"],"tags":["switch","light","wall"],"description":"Wall-mounted switch for lights/devices.","placement_hint":"Requires a valid adjacent wall side.","requires_wall":true,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"power_switcher": {"display_name":"Power Switcher","category":"Power","subcategory":"Control","placement_mode":"object","system_roles":["signal_control","power_network"],"tags":["switch","power","configurable"],"description":"Logical power switcher. Configure mount=floor/wall and switch_state=on/off in the inspector.","placement_hint":"Place on floor by default; set mount to wall for wall art and wall-mounted behavior.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{"mount":"floor","switch_state":"off","state":"switch_off","is_on":false}},
		"fuse_box": {"display_name":"Fuse Box","category":"Power","subcategory":"Protection","placement_mode":"object","system_roles":["power_network","power_consumer"],"tags":["fuse","power","configurable"],"description":"Logical fuse box. Configure mount=floor/wall and fuse_present=true/false in the inspector.","placement_hint":"Place on floor by default; set mount to wall for wall art and wall-mounted behavior.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{"mount":"floor","fuse_present":true,"fuse_installed":true}},
		"barrel": {"display_name":"Barrel","category":"Objects","subcategory":"Movable","placement_mode":"object","system_roles":["movable"],"tags":["barrel","movable","configurable"],"description":"Movable barrel. Configure variant=normal/fire in the inspector.","placement_hint":"Place on a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{"variant":"normal"}},
		"steel_box": {"display_name":"Steel Box","category":"Objects","subcategory":"Movable","placement_mode":"object","system_roles":["movable"],"tags":["steel","box","movable"],"description":"Heavy movable steel box.","placement_hint":"Place on a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"case": {"display_name":"Case","category":"Objects","subcategory":"Prop","placement_mode":"object","system_roles":["prop"],"tags":["case","object"],"description":"Simple placeable case object.","placement_hint":"Place on a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"power_source": {"display_name":"Power Source","category":"Power","subcategory":"Source","placement_mode":"object","system_roles":["power_source","power_network"],"tags":["power","source"],"description":"Logical power source using the unified object asset.","placement_hint":"Place on a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"state":"on","is_powered":true}},
		"radiator": {"display_name":"Radiator","category":"Objects","subcategory":"Cooling","placement_mode":"object","system_roles":["cooling"],"tags":["radiator","cooling"],"description":"External floor radiator.","placement_hint":"Place on a floor cell.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"power_cable_reel": {"display_name":"Cable Reel","category":"Power","subcategory":"Power Utility","placement_mode":"object","system_roles":["power_network"],"tags":["power","cable","reel","floor","wall","utility"],"description":"Cable reel utility node. Use the inspector mount parameter to choose floor or wall visual mode.","placement_hint":"Place the unified Cable Reel, then choose Floor or Wall in the inspector.","requires_wall":false,"requires_floor":true,"is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"mount":"floor","install_mode":"floor","cable_install_mode":"floor"}},
	}
	return metadata


func _build_map_constructor_prefab_fallback_metadata(prefab_id: String, catalog_entry: Dictionary = {}) -> Dictionary:
	var id: String = prefab_id.strip_edges()
	var category: String = str(catalog_entry.get("category", catalog_entry.get("group", ""))).strip_edges()
	if category.is_empty():
		category = "Utility"
	var placement_mode: String = str(catalog_entry.get("placement_mode", "")).strip_edges()
	if placement_mode.is_empty():
		placement_mode = "floor"
	var display_name: String = str(catalog_entry.get("label", id)).strip_edges()
	if display_name.is_empty():
		display_name = id
	var hint: String = str(catalog_entry.get("hint", "")).strip_edges()
	var expected_invalid: bool = id.find("expected_invalid") >= 0 or category.to_lower().find("expected_invalid") >= 0
	var requires_floor: bool = placement_mode != "tile"
	var fallback_tags: Array[String] = [id, category, placement_mode]
	return {
		"id": id,
		"display_name": display_name,
		"category": category,
		"subcategory": "",
		"placement_mode": placement_mode,
		"system_roles": [],
		"tags": fallback_tags,
		"description": "Constructor prefab.",
		"placement_hint": hint,
		"requires_wall": placement_mode == "wall_mounted",
		"requires_floor": requires_floor,
		"is_destructive": false,
		"is_diagnostic": false,
		"is_expected_invalid_tool": expected_invalid,
		"can_have_power_network": false,
		"can_have_links": false,
		"default_state": catalog_entry.get("default_state", {}),
		"canonical_object_type": str(catalog_entry.get("canonical_object_type", id)),
		"object_group": str(catalog_entry.get("object_group", "")),
		"is_alias": bool(catalog_entry.get("is_alias", false)),
		"alias_source_id": str(catalog_entry.get("alias_source_id", "")),
		"door_type": str(catalog_entry.get("door_type", "")),
		"material": str(catalog_entry.get("material", "")),
		"access_type": str(catalog_entry.get("access_type", "")),
		"door_class": catalog_entry.get("door_class", ""),
		"power_behavior": str(catalog_entry.get("power_behavior", "")),
		"blocks_movement": bool(catalog_entry.get("blocks_movement", false))
	}

func get_map_constructor_prefab_metadata(prefab_id: String) -> Dictionary:
	var metadata_catalog: Dictionary = _get_map_constructor_prefab_metadata_catalog()
	var id: String = prefab_id.strip_edges()
	if metadata_catalog.has(id):
		var explicit_row: Dictionary = Dictionary(metadata_catalog[id]).duplicate(true)
		explicit_row["id"] = id
		return {"ok": true, "prefab": explicit_row, "message": "OK"}
	for entry in get_map_constructor_prefab_catalog():
		var catalog_entry: Dictionary = Dictionary(entry)
		if str(catalog_entry.get("id", "")).strip_edges() == id:
			return {"ok": true, "prefab": _build_map_constructor_prefab_fallback_metadata(id, catalog_entry), "message": "OK"}
	return {"ok": false, "prefab": {}, "message": "Unknown prefab id."}

func get_map_constructor_prefab_palette_rows(options: Dictionary = {}) -> Dictionary:
	var search: String = str(options.get("search", "")).strip_edges().to_lower()
	var category_filter: String = str(options.get("category", "All")).strip_edges()
	var role_filter: String = str(options.get("role", "All")).strip_edges()
	var placement_filter: String = str(options.get("placement_mode", "All")).strip_edges()
	var show_expected_invalid: bool = bool(options.get("show_expected_invalid", true))
	var show_diagnostics: bool = bool(options.get("show_diagnostics", true))
	var only_placeable: bool = bool(options.get("show_only_placeable_here", false))
	var selected_cell: Vector2i = _map_constructor_cell_from_variant(options.get("selected_cell", Vector2i(-1, -1)))
	var rows: Array[Dictionary] = []
	var categories: Array[String] = []
	var roles: Array[String] = []
	for entry in get_map_constructor_prefab_catalog():
		var catalog_entry: Dictionary = Dictionary(entry)
		var prefab_id: String = str(catalog_entry.get("id", "")).strip_edges()
		if prefab_id.is_empty():
			continue
		var meta_result: Dictionary = get_map_constructor_prefab_metadata(prefab_id)
		var meta: Dictionary = Dictionary(meta_result.get("prefab", {})).duplicate(true)
		var category: String = str(meta.get("category", ""))
		var placement_mode: String = str(meta.get("placement_mode", ""))
		var role_values: Array[String] = []
		for role in Array(meta.get("system_roles", [])):
			role_values.append(str(role))
			if not roles.has(str(role)):
				roles.append(str(role))
		if not categories.has(category):
			categories.append(category)
		if not show_expected_invalid and bool(meta.get("is_expected_invalid_tool", false)):
			continue
		if not show_diagnostics and bool(meta.get("is_diagnostic", false)):
			continue
		if category_filter != "All" and category != category_filter:
			continue
		if role_filter != "All" and not role_values.has(role_filter):
			continue
		if placement_filter != "All" and placement_mode != placement_filter:
			continue
		var haystack: String = "%s %s %s %s %s %s" % [str(meta.get("id", "")).to_lower(), str(meta.get("display_name", "")).to_lower(), category.to_lower(), " ".join(PackedStringArray(meta.get("tags", []))).to_lower(), " ".join(PackedStringArray(role_values)).to_lower(), str(meta.get("description", "")).to_lower()]
		if not search.is_empty() and haystack.find(search) < 0:
			continue
		var row: Dictionary = meta.duplicate(true)
		if selected_cell.x >= 0 and selected_cell.y >= 0:
			var place_check: Dictionary = can_place_map_constructor_prefab(str(meta.get("id", "")), selected_cell, "")
			row["placeability"] = place_check
			if only_placeable and not bool(place_check.get("ok", false)):
				continue
		rows.append(row)
	categories.sort()
	roles.sort()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("display_name", a.get("id", ""))) < str(b.get("display_name", b.get("id", ""))))
	return {"ok": true, "rows": rows, "categories": categories, "roles": roles, "message": "OK"}

func is_map_constructor_item_prefab(prefab_id: String) -> bool:
	var normalized_prefab_id: String = prefab_id.strip_edges().to_lower()
	if normalized_prefab_id == "item" or WorldObjectCatalogRef.LEGACY_ITEM_ALIAS_CONFIGS.has(normalized_prefab_id):
		return true
	var archetype_definition: Dictionary = WorldObjectCatalogRef.get_archetype_definition(normalized_prefab_id)
	return str(archetype_definition.get("object_group", "")) == "item" and str(archetype_definition.get("placement_mode", "")) == "item"

func _map_constructor_entity_kind(object_data: Dictionary) -> String:
	var object_group: String = str(object_data.get("object_group", "")).to_lower()
	var object_type: String = str(object_data.get("object_type", "")).to_lower()
	var prefab_id: String = str(object_data.get("map_constructor_prefab_id", object_type)).to_lower()
	var classifier: String = "%s|%s|%s" % [object_group, object_type, prefab_id]
	if "door" in classifier or "gate" in classifier:
		return "door"
	if "terminal" in classifier:
		return "terminal"
	if "power" in classifier or "socket" in classifier or "cable" in classifier or "switch" in classifier or "fuse" in classifier or "cool" in classifier or "control" in classifier:
		return "power_control_cooling"
	if object_group == "item" or object_type == "item" or is_map_constructor_item_prefab(prefab_id):
		return "item"
	return "generic"

func get_default_map_constructor_field_value(field_name: String, entity_kind: String, data: Dictionary) -> Variant:
	var normalized_field: String = field_name.strip_edges()
	for field_variant in WorldObjectCatalogRef.get_archetype_property_schema(str(data.get("archetype_id", ""))):
		var archetype_field: Dictionary = field_variant
		if str(archetype_field.get("field", "")) == normalized_field:
			return archetype_field.get("default")
	match normalized_field:
		"is_open":
			return false
		"is_closed":
			var state_text: String = str(data.get("state", "closed")).strip_edges().to_lower()
			return state_text in ["closed", "locked", "jammed", "damaged", ""]
		"is_locked":
			return false
		"is_powered":
			return true
		"requires_external_control":
			return false
		"requires_terminal_enabled":
			return false
		"requires_external_power":
			return false
		"damaged":
			return false
		"current_heat":
			return 0
		"working_heat":
			return 0
		"overheat_threshold":
			return 999999
		"required_connector_level":
			return 0
		"required_processor_level":
			return 0
		"item_type":
			if data.has("item_type"):
				return data.get("item_type")
			return "item"
	if normalized_field == "connected_device_ids":
		if entity_kind == "item":
			return null
		return []
	if normalized_field in ["state", "power_network_id", "circuit_id", "power_circuit_id", "network_id", "power_network_id", "chain_id", "link_group", "cable_group", "connected_circuit", "circuit_name", "required_key_id", "lock_type", "linked_terminal_id", "target_door_id", "target_platform_id", "control_source_id", "digital_state", "key_kind", "key_type", "display_name", "description", "custom_description", "linked_door_id", "power_mode", "power_source_id", "control_mode", "control_terminal_id", "access_type", "access_terminal_id", "access_code_value", "stored_key_ids", "route_surface", "physical_connection_source_id", "input_wire_id", "input_direction", "output_1_wire_id", "output_2_wire_id", "output_3_wire_id", "output_1_direction", "output_2_direction", "output_3_direction", "brightness", "color", "platform_mode", "mechanism_id", "mechanism_role", "activation_mode"]:
		return ""
	return null


func _is_wall_or_boundary_cell(cell: Vector2i) -> bool:
	if grid_manager == null or not grid_manager.has_method("get_tile"):
		return false
	if not _is_valid_grid_cell(cell):
		return false
	if grid_manager.has_method("is_boundary_cell") and bool(grid_manager.call("is_boundary_cell", cell)):
		return true
	return int(grid_manager.call("get_tile", cell)) == GridManager.TILE_WALL

func _get_map_constructor_wall_side_delta(side_id: String) -> Vector2i:
	match side_id.to_lower().strip_edges():
		"north":
			return Vector2i(0, -1)
		"east":
			return Vector2i(1, 0)
		"south":
			return Vector2i(0, 1)
		"west":
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO

func _get_map_constructor_wall_side_label(side_id: String) -> String:
	match side_id.to_lower().strip_edges():
		"north":
			return "North"
		"east":
			return "East"
		"south":
			return "South"
		"west":
			return "West"
		_:
			return side_id.capitalize()

func _serialize_wall_material_override_key(cell: Vector2i, side: String) -> String:
	var normalized_side: String = side.to_lower().strip_edges()
	return "%s|%s" % [_serialize_cell_key(cell), normalized_side]

func get_map_constructor_floor_material_catalog() -> Dictionary:
	var materials: Array[Dictionary] = [
		{"id":"concrete","display_name":"Concrete","description":"Concrete floor using the floor_concrete asset.","material":"concrete","coating":"default","tags":["concrete","floor"],"style":"concrete","texture_asset_id":"floor_concrete","fallback_color":Color(0.16, 0.16, 0.15, 0.97),"edge_color":Color(0.30, 0.30, 0.28, 0.95),"is_default":true},
		{"id":"steel","display_name":"Steel","description":"Steel floor using the floor_steel asset.","material":"steel","coating":"default","tags":["steel","floor"],"style":"steel","texture_asset_id":"floor_steel","fallback_color":Color(0.13, 0.17, 0.2, 0.97),"edge_color":Color(0.22, 0.28, 0.33, 0.95),"is_default":false},
		{"id":"titan","display_name":"Titan","description":"Titanium floor using the floor_titan asset.","material":"titan","coating":"default","tags":["titan","titanium","floor"],"style":"titan","texture_asset_id":"floor_titan","fallback_color":Color(0.15, 0.18, 0.22, 0.97),"edge_color":Color(0.31, 0.36, 0.42, 0.95),"is_default":false}
	]
	# Legacy ids stay valid for older constructor patches and room visual preset code,
	# but the editor presents only the canonical concrete/steel/titan material keys.
	materials.append_array([
		{"id":"steel_default","display_name":"Steel (legacy)","description":"Legacy steel/default floor id mapped to steel.","material":"steel","coating":"default","tags":["steel","floor","legacy"],"style":"steel","texture_asset_id":"floor_steel","fallback_color":Color(0.13, 0.17, 0.2, 0.97),"edge_color":Color(0.22, 0.28, 0.33, 0.95),"is_legacy":true},
		{"id":"concrete_default","display_name":"Concrete (legacy)","description":"Legacy concrete/default floor id mapped to concrete.","material":"concrete","coating":"default","tags":["concrete","floor","legacy"],"style":"concrete","texture_asset_id":"floor_concrete","fallback_color":Color(0.16, 0.16, 0.15, 0.97),"edge_color":Color(0.30, 0.30, 0.28, 0.95),"is_legacy":true},
		{"id":"titanium_default","display_name":"Titanium (legacy)","description":"Legacy titanium/default floor id mapped to titan.","material":"titan","coating":"default","tags":["titan","titanium","floor","legacy"],"style":"titan","texture_asset_id":"floor_titan","fallback_color":Color(0.15, 0.18, 0.22, 0.97),"edge_color":Color(0.31, 0.36, 0.42, 0.95),"is_legacy":true},
		{"id":"default_floor","display_name":"Default Floor (legacy)","description":"Legacy default floor id mapped to concrete.","material":"concrete","tags":["default","floor","legacy"],"style":"concrete","texture_asset_id":"floor_concrete","fallback_color":Color(0.16, 0.16, 0.15, 0.97),"edge_color":Color(0.30, 0.30, 0.28, 0.95),"is_legacy":true},
		{"id":"clean_lab_floor","display_name":"Clean Lab Floor (legacy)","description":"Legacy clean-lab id mapped to steel.","material":"steel","tags":["clean","lab","legacy"],"style":"steel","texture_asset_id":"floor_steel","fallback_color":Color(0.13, 0.17, 0.2, 0.97),"edge_color":Color(0.22, 0.28, 0.33, 0.95),"is_legacy":true},
		{"id":"dark_service_floor","display_name":"Dark Service Floor (legacy)","description":"Legacy dark-service id mapped to concrete.","material":"concrete","tags":["dark","service","legacy"],"style":"concrete","texture_asset_id":"floor_concrete","fallback_color":Color(0.16, 0.16, 0.15, 0.97),"edge_color":Color(0.30, 0.30, 0.28, 0.95),"is_legacy":true},
		{"id":"hazard_floor","display_name":"Hazard Floor (legacy)","description":"Legacy hazard id mapped to concrete.","material":"concrete","tags":["hazard","legacy"],"style":"concrete","texture_asset_id":"floor_concrete","fallback_color":Color(0.16, 0.16, 0.15, 0.97),"edge_color":Color(0.30, 0.30, 0.28, 0.95),"is_legacy":true},
		{"id":"power_floor","display_name":"Power Floor (legacy)","description":"Legacy power id mapped to steel.","material":"steel","tags":["power","legacy"],"style":"steel","texture_asset_id":"floor_steel","fallback_color":Color(0.13, 0.17, 0.2, 0.97),"edge_color":Color(0.22, 0.28, 0.33, 0.95),"is_legacy":true},
		{"id":"damaged_floor","display_name":"Damaged Floor (legacy)","description":"Legacy damaged id mapped to concrete.","material":"concrete","tags":["damaged","legacy"],"style":"concrete","texture_asset_id":"floor_concrete","fallback_color":Color(0.16, 0.16, 0.15, 0.97),"edge_color":Color(0.30, 0.30, 0.28, 0.95),"is_legacy":true},
		{"id":"reinforced_floor","display_name":"Reinforced Floor (legacy)","description":"Legacy reinforced id mapped to steel.","material":"steel","tags":["reinforced","legacy"],"style":"steel","texture_asset_id":"floor_steel","fallback_color":Color(0.13, 0.17, 0.2, 0.97),"edge_color":Color(0.22, 0.28, 0.33, 0.95),"is_legacy":true},
		{"id":"diagnostic_floor","display_name":"Diagnostic Floor (legacy)","description":"Legacy diagnostic id mapped to steel.","material":"steel","tags":["diagnostic","legacy"],"style":"steel","texture_asset_id":"floor_steel","fallback_color":Color(0.13, 0.17, 0.2, 0.97),"edge_color":Color(0.22, 0.28, 0.33, 0.95),"is_legacy":true}
	])
	return {"ok": true, "materials": materials, "message": "Floor material catalog ready."}
func _is_known_map_constructor_floor_material_id(material_id: String) -> bool:
	var normalized_id: String = material_id.to_lower().strip_edges()
	if normalized_id.is_empty():
		return false
	for row_variant in Array(get_map_constructor_floor_material_catalog().get("materials", [])):
		var row: Dictionary = Dictionary(row_variant)
		if str(row.get("id", "")).to_lower().strip_edges() == normalized_id:
			return true
	return false

func _is_floor_like_constructor_tile(tile_type: int) -> bool:
	return tile_type == GridManager.TILE_FLOOR or tile_type == GridManager.TILE_STEPPED_FLOOR

func _is_wall_mount_neighbor_tile_type(tile_type: int) -> bool:
	return (
		tile_type == GridManager.TILE_FLOOR
		or tile_type == GridManager.TILE_STEPPED_FLOOR
		or tile_type == GridManager.TILE_DOOR
		or tile_type == GridManager.TILE_DIGITAL_DOOR
		or tile_type == GridManager.TILE_POWERED_GATE
	)

func get_map_constructor_wall_height_catalog() -> Dictionary:
	return {"ok": true, "heights": [
		{"id":"", "display_name":"Auto", "description":"Use production wall height defaults; outer walls keep the depth-based gradient."},
		{"id":"tall", "display_name":"Tall", "description":"Use the tall production wall asset."},
		{"id":"halfmid", "display_name":"Half Mid", "description":"Use the half-mid production wall asset."},
		{"id":"mid", "display_name":"Mid", "description":"Use the mid production wall asset."},
		{"id":"halflow", "display_name":"Half Low", "description":"Use the half-low production wall asset."},
		{"id":"low", "display_name":"Low", "description":"Use the low production wall asset; grate normalizes low heights to mid."}
	], "message": "Wall height catalog ready."}

func normalize_map_constructor_wall_height(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "")
	normalized_value = normalized_value.replace("-", "")
	normalized_value = normalized_value.replace("_", "")
	match normalized_value:
		"", "auto", "default":
			return ""
		"highest", "tallest", "high", "tall":
			return "tall"
		"half", "halfmedium", "halfmid", "uppermid":
			return "halfmid"
		"medium", "middle", "mid":
			return "mid"
		"halflow", "halflowheight", "halfshort", "halflowest":
			return "halflow"
		"short", "lowest", "low":
			return "low"
	return ""

func normalize_breach_side(value: String) -> String:
	return BreachableWallServiceRef.normalize_breach_side(value)

func get_grid_side_for_breach_side(breach_side: String) -> String:
	# grid_to_iso projects +x as visual SE and +y as visual SW, so the
	# breach-side ids are visual iso sides mapped back to gameplay grid sides.
	match normalize_breach_side(breach_side):
		"sw":
			return "south"
		"se":
			return "east"
		"nw":
			return "west"
		"ne":
			return "north"
	return "south"

func get_cell_for_breach_side(wall_cell: Vector2i, breach_side: String) -> Vector2i:
	return wall_cell + _get_map_constructor_wall_side_delta(get_grid_side_for_breach_side(breach_side))

func is_bipob_on_breach_side(wall_cell: Vector2i, bipob_cell: Vector2i, breach_side: String) -> bool:
	return bipob_cell == get_cell_for_breach_side(wall_cell, breach_side)


func normalize_floor_height_level(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "")
	normalized_value = normalized_value.replace("-", "")
	normalized_value = normalized_value.replace("_", "")
	match normalized_value:
		"", "empty", "default", "flat", "normal":
			return "default"
		"1", "step1", "low", "groundlow":
			return "step_1"
		"2", "step2", "halflow", "groundhalflow":
			return "step_2"
	return "default"

func get_map_constructor_floor_height_catalog() -> Dictionary:
	return {"ok": true, "heights": [
		{"id":"default", "display_name":"Default", "description":"Normal flat floor with no raised ground base."},
		{"id":"step_1", "display_name":"1 Step", "description":"Raised low ground visual base below the floor material."},
		{"id":"step_2", "display_name":"2 Step", "description":"Raised half-low ground visual base below the floor material."}
	], "message": "Floor height catalog ready."}

func get_map_constructor_wall_material_catalog() -> Dictionary:
	var materials: Array[Dictionary] = [
		{"id":"concrete","display_name":"Concrete","description":"Concrete wall using production concrete height assets.","tags":["concrete","default"],"style":"concrete","texture_asset_id":"wall_concrete","fallback_color":Color(0.66, 0.72, 0.76, 0.98),"edge_color":Color(0.86, 0.9, 0.94, 1.0),"damage_level":0,"is_default":true},
		{"id":"concrete_damage","display_name":"Concrete damage","description":"Legacy damaged concrete id mapped to the production concrete wall assets.","tags":["concrete","damaged"],"style":"concrete_damage","texture_asset_id":"wall_concrete","fallback_color":Color(0.48, 0.31, 0.16, 0.98),"edge_color":Color(0.96, 0.57, 0.21, 1.0),"damage_level":2,"is_default":false,"is_legacy":true},
		{"id":"brick","display_name":"Brick","description":"Brick wall using production brick height assets.","tags":["brick"],"style":"brick","texture_asset_id":"wall_brick","fallback_color":Color(0.37, 0.21, 0.16, 0.98),"edge_color":Color(0.82, 0.72, 0.58, 1.0),"damage_level":0,"is_default":false},
		{"id":"breachable_concrete","display_name":"Breachable Concrete","description":"Breachable Wall / проламываемая стена using concrete wall visuals; Heavy Claw can remove it at mid, half-mid, or tall height.","tags":["concrete","breachable"],"style":"breachable_concrete","texture_asset_id":"wall_concrete","fallback_color":Color(0.62, 0.67, 0.7, 0.98),"edge_color":Color(1.0, 0.82, 0.32, 1.0),"damage_level":0,"is_default":false,"wall_archetype":"breachable","breach_tools":["heavy_claw"],"allowed_wall_heights":["mid","halfmid","tall"]},
		{"id":"breachable_brick","display_name":"Breachable Brick","description":"Breachable Wall / проламываемая стена using brick wall visuals; Heavy Claw can remove it at mid, half-mid, or tall height.","tags":["brick","breachable"],"style":"breachable_brick","texture_asset_id":"wall_brick","fallback_color":Color(0.44, 0.23, 0.17, 0.98),"edge_color":Color(1.0, 0.76, 0.28, 1.0),"damage_level":0,"is_default":false,"wall_archetype":"breachable","breach_tools":["heavy_claw"],"allowed_wall_heights":["mid","halfmid","tall"]},
		{"id":"brick_damage","display_name":"Brick damage","description":"Legacy damaged brick id mapped to the production brick wall assets.","tags":["brick","damaged"],"style":"brick_damage","texture_asset_id":"wall_brick","fallback_color":Color(0.42, 0.19, 0.2, 0.98),"edge_color":Color(0.84, 0.34, 0.37, 1.0),"damage_level":3,"is_default":false,"is_legacy":true},
		{"id":"grate","display_name":"Grate","description":"Grate wall using production grate mid/halfmid/tall assets; lower heights normalize to mid.","tags":["grate","service"],"style":"grate","texture_asset_id":"wall_grate","fallback_color":Color(0.18, 0.2, 0.24, 0.98),"edge_color":Color(0.32, 0.36, 0.41, 1.0),"damage_level":1,"is_default":false},
		{"id":"steel","display_name":"Steel","description":"Steel wall using production steel height assets.","tags":["steel"],"style":"steel","texture_asset_id":"wall_steel","fallback_color":Color(0.24, 0.27, 0.33, 0.98),"edge_color":Color(0.55, 0.61, 0.72, 1.0),"damage_level":0,"is_default":false},
		{"id":"reinforced_steel","display_name":"Reinforced Steel","description":"Reinforced steel wall using production reinforced steel height assets.","tags":["reinforced","steel"],"style":"reinforced_steel","texture_asset_id":"wall_reinforced_steel","fallback_color":Color(0.28, 0.3, 0.21, 0.98),"edge_color":Color(0.71, 0.81, 0.34, 1.0),"damage_level":0,"is_default":false},
		{"id":"titan","display_name":"Titan","description":"Titan wall using production titan height assets.","tags":["titan","titanium"],"style":"titan","texture_asset_id":"wall_titan","fallback_color":Color(0.22, 0.24, 0.31, 0.98),"edge_color":Color(0.58, 0.65, 0.78, 1.0),"damage_level":0,"is_default":false},
		{"id":"outerwall","display_name":"Outerwall","description":"Outer boundary wall material using the production depth-based height gradient.","tags":["outer","boundary"],"style":"outerwall","texture_asset_id":"wall_outer","fallback_color":Color(0.19, 0.2, 0.22, 0.98),"edge_color":Color(0.62, 0.67, 0.75, 1.0),"damage_level":0,"is_default":false}
	]
	return {"ok": true, "materials": materials, "message": "Wall material catalog ready."}

func normalize_visual_texture_asset_id(asset_id: String) -> String:
	var normalized_asset_id: String = asset_id.strip_edges()
	if normalized_asset_id.is_empty():
		return ""
	var lowercase_asset_id: String = normalized_asset_id.to_lower()
	if VISUAL_TEXTURE_ASSET_ALIASES.has(normalized_asset_id):
		return str(VISUAL_TEXTURE_ASSET_ALIASES.get(normalized_asset_id, normalized_asset_id))
	if OBJECT_TEXTURE_ASSET_ALIASES.has(normalized_asset_id):
		return str(OBJECT_TEXTURE_ASSET_ALIASES.get(normalized_asset_id, normalized_asset_id))
	if FLOOR_TEXTURE_ASSET_ALIASES.has(lowercase_asset_id):
		return str(FLOOR_TEXTURE_ASSET_ALIASES.get(lowercase_asset_id, lowercase_asset_id))
	if WALL_TEXTURE_ASSET_ALIASES.has(lowercase_asset_id):
		return str(WALL_TEXTURE_ASSET_ALIASES.get(lowercase_asset_id, lowercase_asset_id))
	if OBJECT_TEXTURE_ASSET_ALIASES.has(lowercase_asset_id):
		return str(OBJECT_TEXTURE_ASSET_ALIASES.get(lowercase_asset_id, lowercase_asset_id))
	if VISUAL_TEXTURE_ASSET_ALIASES.has(lowercase_asset_id):
		return str(VISUAL_TEXTURE_ASSET_ALIASES.get(lowercase_asset_id, lowercase_asset_id))
	return normalized_asset_id

func normalize_visual_texture_asset_id_for_context(asset_id: String, asset_context: String) -> String:
	var normalized_asset_id: String = asset_id.strip_edges()
	if normalized_asset_id.is_empty():
		return ""
	var lowercase_asset_id: String = normalized_asset_id.to_lower()
	var normalized_context: String = asset_context.strip_edges().to_lower()
	match normalized_context:
		"floor":
			if FLOOR_TEXTURE_ASSET_ALIASES.has(normalized_asset_id):
				return str(FLOOR_TEXTURE_ASSET_ALIASES.get(normalized_asset_id, normalized_asset_id))
		"wall":
			if WALL_TEXTURE_ASSET_ALIASES.has(normalized_asset_id):
				return str(WALL_TEXTURE_ASSET_ALIASES.get(normalized_asset_id, normalized_asset_id))
		"object", "door", "terminal", "item":
			if OBJECT_TEXTURE_ASSET_ALIASES.has(normalized_asset_id):
				return str(OBJECT_TEXTURE_ASSET_ALIASES.get(normalized_asset_id, normalized_asset_id))
			if OBJECT_TEXTURE_ASSET_ALIASES.has(lowercase_asset_id):
				return str(OBJECT_TEXTURE_ASSET_ALIASES.get(lowercase_asset_id, lowercase_asset_id))
	if VISUAL_TEXTURE_ASSET_ALIASES.has(lowercase_asset_id):
		return str(VISUAL_TEXTURE_ASSET_ALIASES.get(lowercase_asset_id, lowercase_asset_id))
	return normalize_visual_texture_asset_id(normalized_asset_id)

func normalize_floor_texture_asset_id(asset_id: String) -> String:
	return normalize_visual_texture_asset_id_for_context(asset_id, "floor")

func normalize_wall_texture_asset_id(asset_id: String) -> String:
	return normalize_visual_texture_asset_id_for_context(asset_id, "wall")

func normalize_object_texture_asset_id(asset_id: String) -> String:
	return normalize_visual_texture_asset_id_for_context(asset_id, "object")

func get_placeholder_asset_presence_report() -> Array[Dictionary]:
	var report: Array[Dictionary] = []
	var asset_keys: Array = ISO_PLACEHOLDER_ASSET_PATHS.keys()
	asset_keys.sort()
	for asset_key_variant in asset_keys:
		var asset_key: String = str(asset_key_variant)
		var placeholder_path: String = str(ISO_PLACEHOLDER_ASSET_PATHS.get(asset_key, ""))
		var exists: bool = false
		var loadable: bool = false
		if not placeholder_path.is_empty():
			exists = ResourceLoader.exists(placeholder_path)
			if exists:
				loadable = ResourceLoader.exists(placeholder_path, "Texture2D")
		report.append({"asset_key": asset_key, "path": placeholder_path, "exists": exists, "loadable": loadable, "optional": true})
	return report

func _append_placeholder_visual_texture_assets(assets: Array[Dictionary]) -> void:
	var existing_ids: Dictionary = {}
	for row_variant in assets:
		var row: Dictionary = Dictionary(row_variant)
		existing_ids[str(row.get("id", ""))] = true
	var asset_keys: Array = ISO_PLACEHOLDER_ASSET_PATHS.keys()
	asset_keys.sort()
	for asset_key_variant in asset_keys:
		var asset_key: String = str(asset_key_variant)
		if existing_ids.has(asset_key):
			continue
		var category: String = "placeholder"
		if asset_key.begins_with("floor_"):
			category = "floor"
		elif asset_key.begins_with("wall_"):
			category = "wall"
		elif asset_key.begins_with("object_"):
			category = "object"
		assets.append({"id": asset_key, "category": category, "display_name": "Placeholder / %s" % asset_key.capitalize(), "description": "BIP-Visual-011 placeholder SVG asset.", "texture_path": str(ISO_PLACEHOLDER_ASSET_PATHS.get(asset_key, "")), "atlas_region": Rect2i(0, 0, 0, 0), "fallback_style": "placeholder", "fallback_color": Color(0.72, 0.82, 0.9, 0.95), "tags": ["placeholder", category], "is_optional": true, "placeholder_asset_key": asset_key})

func _append_visual_texture_asset_alias_rows(assets: Array[Dictionary]) -> void:
	var existing_ids: Dictionary = {}
	for row_variant in assets:
		var row: Dictionary = Dictionary(row_variant)
		existing_ids[str(row.get("id", ""))] = true
	var alias_ids: Array = VISUAL_TEXTURE_ASSET_ALIASES.keys()
	alias_ids.sort()
	for alias_id_variant in alias_ids:
		var alias_id: String = str(alias_id_variant)
		if existing_ids.has(alias_id):
			continue
		var placeholder_key: String = normalize_visual_texture_asset_id(alias_id)
		var placeholder_path: String = str(ISO_PLACEHOLDER_ASSET_PATHS.get(placeholder_key, ""))
		assets.append({"id": alias_id, "category": "alias", "display_name": "Alias / %s" % alias_id.capitalize(), "description": "Backward-compatible visual texture asset alias.", "texture_path": placeholder_path, "atlas_region": Rect2i(0, 0, 0, 0), "fallback_style": "alias", "fallback_color": Color(0.72, 0.82, 0.9, 0.95), "tags": ["alias", placeholder_key], "is_optional": true, "placeholder_asset_key": placeholder_key})

func get_visual_texture_asset_catalog() -> Dictionary:
	var assets: Array[Dictionary] = [
		{"id":"wall_default_metal","category":"wall","display_name":"Wall / Default Metal","description":"Default wall material texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"default","fallback_color":Color(0.33, 0.37, 0.43, 0.98),"tags":["wall","default"],"is_optional":true},
		{"id":"wall_clean_lab","category":"wall","display_name":"Wall / Clean Lab","description":"Clean lab wall texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"clean","fallback_color":Color(0.66, 0.72, 0.76, 0.98),"tags":["wall","lab"],"is_optional":true},
		{"id":"wall_dark_service","category":"wall","display_name":"Wall / Dark Service","description":"Dark service wall texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"dark","fallback_color":Color(0.18, 0.2, 0.24, 0.98),"tags":["wall","service"],"is_optional":true},
		{"id":"wall_orange_hazard","category":"wall","display_name":"Wall / Orange Hazard","description":"Orange hazard wall texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"hazard","fallback_color":Color(0.48, 0.31, 0.16, 0.98),"tags":["wall","hazard"],"is_optional":true},
		{"id":"wall_damaged_red","category":"wall","display_name":"Wall / Damaged Red","description":"Damaged red wall texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"damaged","fallback_color":Color(0.42, 0.19, 0.2, 0.98),"tags":["wall","damaged"],"is_optional":true},
		{"id":"wall_reinforced","category":"wall","display_name":"Wall / Reinforced","description":"Reinforced wall texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"reinforced","fallback_color":Color(0.24, 0.27, 0.33, 0.98),"tags":["wall","reinforced"],"is_optional":true},
		{"id":"wall_power_room","category":"wall","display_name":"Wall / Power Room","description":"Power room wall texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"power","fallback_color":Color(0.28, 0.3, 0.21, 0.98),"tags":["wall","power"],"is_optional":true},
		{"id":"wall_diagnostic_blue","category":"wall","display_name":"Wall / Diagnostic Blue","description":"Diagnostic blue wall texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"diagnostic","fallback_color":Color(0.21, 0.3, 0.49, 0.98),"tags":["wall","diagnostic"],"is_optional":true},
		{"id":"door_state_generic","category":"door","display_name":"Door / Generic","description":"Door visual state texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"state_tint","fallback_color":Color(0.72, 0.78, 0.86, 0.95),"tags":["door","state"],"is_optional":true},
		{"id":"terminal_state_generic","category":"terminal","display_name":"Terminal / Generic","description":"Terminal visual state texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"state_tint","fallback_color":Color(0.78, 0.87, 0.96, 0.98),"tags":["terminal","state"],"is_optional":true},
		{"id":"item_generic_marker","category":"item","display_name":"Item / Marker","description":"Generic item marker texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"small_marker","fallback_color":Color(0.74, 0.84, 0.96, 0.95),"tags":["item"],"is_optional":true},
		{"id":"cable_reel_01","category":"object","display_name":"Cable Reel / Floor","description":"Floor cable reel object asset.","texture_path":"res://assets/visual/isometric/objects/cable_reel_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.74, 0.84, 0.96, 0.95),"tags":["object","cable_reel","floor"],"is_optional":true,"placeholder_asset_key":"object_cable_reel"},
		{"id":"cable_reel_02","category":"object","display_name":"Cable Reel / Wall","description":"Wall cable reel object asset selected by Cable Reel mount=wall.","texture_path":"res://assets/visual/isometric/objects/cable_reel_02.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.74, 0.84, 0.96, 0.95),"tags":["object","cable_reel","wall"],"is_optional":true,"placeholder_asset_key":"object_cable_reel"},
		{"id":"fuse_box_in_01","category":"object","display_name":"Floor Fuse Box / In","description":"Floor fuse box with fuse inserted.","texture_path":"res://assets/visual/isometric/objects/fuse_box_in_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.74, 0.84, 0.96, 0.95),"tags":["object","fuse_box"],"is_optional":true,"placeholder_asset_key":"object_component"},
		{"id":"fuse_box_out_01","category":"object","display_name":"Floor Fuse Box / Out","description":"Floor fuse box with fuse removed.","texture_path":"res://assets/visual/isometric/objects/fuse_box_out_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.74, 0.84, 0.96, 0.95),"tags":["object","fuse_box"],"is_optional":true,"placeholder_asset_key":"object_component"},
		{"id":"fuse_box_in_wall_01","category":"object","display_name":"Fuse Box / Wall / In","description":"Wall fuse box with fuse inserted.","texture_path":"res://assets/visual/isometric/objects/fuse_box_in_wall_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.74, 0.84, 0.96, 0.95),"tags":["object","fuse_box","wall"],"is_optional":true,"placeholder_asset_key":"object_component"},
		{"id":"fuse_box_out_wall_01","category":"object","display_name":"Fuse Box / Wall / Out","description":"Wall fuse box with fuse removed.","texture_path":"res://assets/visual/isometric/objects/fuse_box_out_wall_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.74, 0.84, 0.96, 0.95),"tags":["object","fuse_box","wall"],"is_optional":true,"placeholder_asset_key":"object_component"},
		{"id":"light_01","category":"object","display_name":"Light","description":"Wall light object asset.","texture_path":"res://assets/visual/isometric/objects/light_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.98, 0.94, 0.75, 0.99),"tags":["object","light"],"is_optional":true,"placeholder_asset_key":"object_button"},
		{"id":"power_source_01","category":"object","display_name":"Power Source","description":"Power source object asset.","texture_path":"res://assets/visual/isometric/objects/power_source_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.95, 0.88, 0.52, 0.99),"tags":["object","power"],"is_optional":true,"placeholder_asset_key":"object_component"},
		{"id":"power_switcher_off_01","category":"object","display_name":"Floor Power Switcher / Off","description":"Floor power switcher off.","texture_path":"res://assets/visual/isometric/objects/power_switcher_off_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.95, 0.88, 0.52, 0.99),"tags":["object","switch"],"is_optional":true,"placeholder_asset_key":"object_switch"},
		{"id":"power_switcher_off_wall_01","category":"object","display_name":"Power Switcher / Wall / Off","description":"Wall power switcher off.","texture_path":"res://assets/visual/isometric/objects/power_switcher_off_wall_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.95, 0.88, 0.52, 0.99),"tags":["object","switch","wall"],"is_optional":true,"placeholder_asset_key":"object_switch"},
		{"id":"power_switcher_on_01","category":"object","display_name":"Floor Power Switcher / On","description":"Floor power switcher on.","texture_path":"res://assets/visual/isometric/objects/power_switcher_on_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.95, 0.88, 0.52, 0.99),"tags":["object","switch"],"is_optional":true,"placeholder_asset_key":"object_switch"},
		{"id":"power_switcher_on_wall_01","category":"object","display_name":"Power Switcher / Wall / On","description":"Wall power switcher on.","texture_path":"res://assets/visual/isometric/objects/power_switcher_on_wall_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.95, 0.88, 0.52, 0.99),"tags":["object","switch","wall"],"is_optional":true,"placeholder_asset_key":"object_switch"},
		{"id":"radiator_01","category":"object","display_name":"Radiator","description":"External floor radiator object asset.","texture_path":"res://assets/visual/isometric/objects/radiator_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.7, 0.82, 0.9, 0.99),"tags":["object","radiator"],"is_optional":true,"placeholder_asset_key":"object_component"},
		{"id":"terminal_01","category":"object","display_name":"Terminal","description":"Floor terminal object asset.","texture_path":"res://assets/visual/isometric/objects/terminal_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.78, 0.87, 0.96, 0.98),"tags":["object","terminal"],"is_optional":true,"placeholder_asset_key":"object_terminal"},
		{"id":"barrel_01","category":"movable","display_name":"Barrel","description":"Movable barrel asset.","texture_path":"res://assets/visual/isometric/moovable/barrel_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.67, 0.55, 0.38, 0.99),"tags":["movable","barrel"],"is_optional":true,"placeholder_asset_key":"object_generic"},
		{"id":"case_01","category":"movable","display_name":"Case","description":"Movable case asset.","texture_path":"res://assets/visual/isometric/objects/case_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.5, 0.58, 0.66, 0.99),"tags":["movable","case"],"is_optional":true,"placeholder_asset_key":"object_generic"},
		{"id":"steel_box_01","category":"movable","display_name":"Steel Box","description":"Movable steel box asset.","texture_path":"res://assets/visual/isometric/moovable/steel_box_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.5, 0.58, 0.66, 0.99),"tags":["movable","steel_box"],"is_optional":true,"placeholder_asset_key":"object_generic"},
		{"id":"fire_barrel_01","category":"movable","display_name":"Fire Barrel","description":"Fire barrel variant asset.","texture_path":"res://assets/visual/isometric/moovable/fire_barrel_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"object","fallback_color":Color(0.9, 0.38, 0.18, 0.99),"tags":["movable","barrel","fire"],"is_optional":true,"placeholder_asset_key":"object_generic"},
		{"id":"overlay_constructor_debug","category":"overlay","display_name":"Overlay / Constructor","description":"Map constructor overlay slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"wireframe","fallback_color":Color(0.44, 0.69, 0.97, 1.0),"tags":["overlay","debug"],"is_optional":true},
		{"id":"floor_concrete","category":"floor","display_name":"Floor Concrete","description":"Concrete floor asset.","texture_path":"res://assets/visual/isometric/floor/floor_concrete_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"diamond_fill","fallback_color":Color(0.16, 0.16, 0.15, 0.97),"tags":["floor","concrete"],"is_optional":false,"placeholder_asset_key":"floor_concrete"},
		{"id":"floor_steel","category":"floor","display_name":"Floor Steel","description":"Steel floor asset.","texture_path":"res://assets/visual/isometric/floor/floor_steel_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"diamond_fill","fallback_color":Color(0.13, 0.17, 0.2, 0.97),"tags":["floor","steel"],"is_optional":false,"placeholder_asset_key":"floor_steel"},
		{"id":"floor_titan","category":"floor","display_name":"Floor Titan","description":"Titanium floor asset.","texture_path":"res://assets/visual/isometric/floor/floor_titan_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"diamond_fill","fallback_color":Color(0.15, 0.18, 0.22, 0.97),"tags":["floor","titan","titanium"],"is_optional":false,"placeholder_asset_key":"floor_titan"},
		{"id":"platform_floor","category":"floor","display_name":"Platform Floor","description":"Configurable platform floor asset.","texture_path":"res://assets/visual/isometric/floor/floor_platform_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"diamond_fill","fallback_color":Color(0.12, 0.14, 0.16, 0.97),"tags":["floor","platform"],"is_optional":false,"placeholder_asset_key":"platform_floor"},
		{"id":"floor_default","category":"floor","display_name":"Floor Default","description":"Default floor texture alias.","texture_path":"res://assets/visual/isometric/floor/floor_concrete_01.png","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"diamond_fill","fallback_color":Color(0.16, 0.16, 0.15, 0.97),"tags":["floor","concrete","alias"],"is_optional":true,"placeholder_asset_key":"floor_concrete"},
		{"id":"floor_clean_lab","category":"floor","display_name":"Floor Clean Lab","description":"Clean lab floor texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"clean","fallback_color":Color(0.18, 0.23, 0.26, 0.97),"tags":["floor","clean"],"is_optional":true},
		{"id":"floor_dark_service","category":"floor","display_name":"Floor Dark Service","description":"Dark service floor texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"dark","fallback_color":Color(0.1, 0.12, 0.15, 0.97),"tags":["floor","dark"],"is_optional":true},
		{"id":"floor_hazard","category":"floor","display_name":"Floor Hazard","description":"Hazard floor texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"hazard","fallback_color":Color(0.2, 0.16, 0.12, 0.97),"tags":["floor","hazard"],"is_optional":true},
		{"id":"floor_power","category":"floor","display_name":"Floor Power","description":"Power floor texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"power","fallback_color":Color(0.16, 0.19, 0.13, 0.97),"tags":["floor","power"],"is_optional":true},
		{"id":"floor_damaged","category":"floor","display_name":"Floor Damaged","description":"Damaged floor texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"damaged","fallback_color":Color(0.2, 0.12, 0.13, 0.97),"tags":["floor","damaged"],"is_optional":true},
		{"id":"floor_reinforced","category":"floor","display_name":"Floor Reinforced","description":"Reinforced floor texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"reinforced","fallback_color":Color(0.12, 0.15, 0.19, 0.97),"tags":["floor","reinforced"],"is_optional":true},
		{"id":"floor_diagnostic","category":"floor","display_name":"Floor Diagnostic","description":"Diagnostic floor texture slot.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"diagnostic","fallback_color":Color(0.11, 0.16, 0.23, 0.97),"tags":["floor","diagnostic"],"is_optional":true},
		{"id":"diagnostic_missing_texture","category":"diagnostic","display_name":"Diagnostic / Missing Texture","description":"Diagnostic placeholder for missing visual texture.","texture_path":"","atlas_region":Rect2i(0, 0, 0, 0),"fallback_style":"warning_marker","fallback_color":Color(1.0, 0.79, 0.21, 0.98),"tags":["diagnostic","missing"],"is_optional":true}
	]
	_append_placeholder_visual_texture_assets(assets)
	_append_visual_texture_asset_alias_rows(assets)
	return {"ok": true, "assets": assets, "placeholder_assets": get_placeholder_asset_presence_report(), "message": "Visual texture asset catalog ready."}

func resolve_visual_texture_asset(asset_id: String, asset_context: String = "") -> Dictionary:
	var requested_asset_id: String = asset_id.strip_edges()
	var normalized_asset_id: String = normalize_visual_texture_asset_id_for_context(requested_asset_id, asset_context)
	if normalized_asset_id.is_empty():
		return {"ok": false, "asset_id": normalized_asset_id, "requested_asset_id": requested_asset_id, "has_texture": false, "texture_path": "", "atlas_region": Rect2i(0, 0, 0, 0), "fallback_style": "default", "fallback_color": Color(1, 1, 1, 1), "message": "Asset id is empty."}
	var catalog: Dictionary = get_visual_texture_asset_catalog()
	for row_variant in Array(catalog.get("assets", [])):
		var row: Dictionary = Dictionary(row_variant)
		if str(row.get("id", "")) != normalized_asset_id and str(row.get("id", "")) != requested_asset_id:
			continue
		var texture_path: String = str(row.get("texture_path", "")).strip_edges()
		if texture_path.is_empty() and ISO_PLACEHOLDER_ASSET_PATHS.has(normalized_asset_id):
			texture_path = str(ISO_PLACEHOLDER_ASSET_PATHS.get(normalized_asset_id, ""))
		var has_texture: bool = false
		if not texture_path.is_empty():
			has_texture = ResourceLoader.exists(texture_path)
		var message: String = "Texture missing; fallback should be used."
		if has_texture:
			message = "Texture asset resolved."
		return {"ok": true, "asset_id": normalized_asset_id, "requested_asset_id": requested_asset_id, "has_texture": has_texture, "texture_path": texture_path, "atlas_region": Rect2i(row.get("atlas_region", Rect2i(0, 0, 0, 0))), "fallback_style": str(row.get("fallback_style", "default")), "fallback_color": Color(row.get("fallback_color", Color(1, 1, 1, 1))), "message": message, "is_optional": bool(row.get("is_optional", true)), "placeholder_asset_key": str(row.get("placeholder_asset_key", normalized_asset_id))}
	return {"ok": false, "asset_id": normalized_asset_id, "requested_asset_id": requested_asset_id, "has_texture": false, "texture_path": "", "atlas_region": Rect2i(0, 0, 0, 0), "fallback_style": "default", "fallback_color": Color(1, 1, 1, 1), "message": "Unknown visual texture asset id: %s" % requested_asset_id}

func get_visual_texture_asset_reference_diagnostics() -> Dictionary:
	var unknown_references: Array[String] = []
	var missing_optional: Array[String] = []
	var missing_required: Array[String] = []
	var seen_asset_ids: Dictionary = {}
	for wall_row_variant in Array(get_map_constructor_wall_material_catalog().get("materials", [])):
		var wall_row: Dictionary = Dictionary(wall_row_variant)
		var wall_asset_id: String = str(wall_row.get("texture_asset_id", "")).strip_edges()
		if wall_asset_id.is_empty():
			continue
		seen_asset_ids[wall_asset_id] = true
		var wall_resolved: Dictionary = resolve_visual_texture_asset(wall_asset_id, "wall")
		if not bool(wall_resolved.get("ok", false)):
			unknown_references.append(wall_asset_id)
			continue
		if not bool(wall_resolved.get("has_texture", false)):
			if bool(wall_resolved.get("is_optional", true)):
				missing_optional.append(wall_asset_id)
			else:
				missing_required.append(wall_asset_id)
	for floor_row_variant in Array(get_map_constructor_floor_material_catalog().get("materials", [])):
		var floor_row: Dictionary = Dictionary(floor_row_variant)
		var floor_asset_id: String = str(floor_row.get("texture_asset_id", "")).strip_edges()
		if floor_asset_id.is_empty():
			continue
		seen_asset_ids[floor_asset_id] = true
		var floor_resolved: Dictionary = resolve_visual_texture_asset(floor_asset_id, "floor")
		if not bool(floor_resolved.get("ok", false)):
			unknown_references.append(floor_asset_id)
			continue
		if not bool(floor_resolved.get("has_texture", false)):
			if bool(floor_resolved.get("is_optional", true)):
				missing_optional.append(floor_asset_id)
			else:
				missing_required.append(floor_asset_id)
	var known_door_asset_ids: Array[String] = ["door_state_generic"]
	for door_asset_id in known_door_asset_ids:
		var normalized_door_asset_id: String = door_asset_id.strip_edges()
		if normalized_door_asset_id.is_empty() or seen_asset_ids.has(normalized_door_asset_id):
			continue
		seen_asset_ids[normalized_door_asset_id] = true
		var door_resolved: Dictionary = resolve_visual_texture_asset(normalized_door_asset_id, "object")
		if not bool(door_resolved.get("ok", false)):
			unknown_references.append(normalized_door_asset_id)
			continue
		if not bool(door_resolved.get("has_texture", false)):
			if bool(door_resolved.get("is_optional", true)):
				missing_optional.append(normalized_door_asset_id)
			else:
				missing_required.append(normalized_door_asset_id)
	var known_terminal_asset_ids: Array[String] = ["terminal_state_generic"]
	for terminal_asset_id in known_terminal_asset_ids:
		var normalized_terminal_asset_id: String = terminal_asset_id.strip_edges()
		if normalized_terminal_asset_id.is_empty() or seen_asset_ids.has(normalized_terminal_asset_id):
			continue
		seen_asset_ids[normalized_terminal_asset_id] = true
		var terminal_resolved: Dictionary = resolve_visual_texture_asset(normalized_terminal_asset_id, "object")
		if not bool(terminal_resolved.get("ok", false)):
			unknown_references.append(normalized_terminal_asset_id)
			continue
		if not bool(terminal_resolved.get("has_texture", false)):
			if bool(terminal_resolved.get("is_optional", true)):
				missing_optional.append(normalized_terminal_asset_id)
			else:
				missing_required.append(normalized_terminal_asset_id)
	var ok: bool = unknown_references.is_empty() and missing_required.is_empty()
	var message: String = "Visual asset references resolved."
	if not ok:
		message = "Visual asset references have unknown or required-missing entries."
	return {
		"ok": ok,
		"unknown_references": unknown_references,
		"missing_optional": missing_optional,
		"missing_required": missing_required,
		"placeholder_assets": get_placeholder_asset_presence_report(),
		"message": message
	}

func _is_map_constructor_wall_cell(cell: Vector2i) -> bool:
	if grid_manager == null:
		return false
	if not grid_manager.has_method("is_in_bounds") or not bool(grid_manager.call("is_in_bounds", cell)):
		return false
	if grid_manager.has_method("get_tile"):
		return int(grid_manager.call("get_tile", cell)) == GridManager.TILE_WALL
	return false

func _resolve_wall_mounted_attachment(anchor_floor_cell: Vector2i, preferred_side: String = "") -> Dictionary:
	if grid_manager == null:
		return {"ok": false, "reason": "grid_unavailable", "message": "Blocked: grid unavailable."}
	var valid_attachments: Array[Dictionary] = []
	for side_entry in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
		var side: String = str(side_entry.get("side", ""))
		var delta: Vector2i = Vector2i(side_entry.get("delta", Vector2i.ZERO))
		var wall_cell: Vector2i = anchor_floor_cell + delta
		if _is_wall_or_boundary_cell(wall_cell):
			valid_attachments.append({"side": side, "attached_wall_cell": wall_cell})
	if valid_attachments.is_empty():
		return {"ok": false, "reason": "no_adjacent_wall", "message": "Blocked: no adjacent wall.", "anchor_floor_cell": anchor_floor_cell}
	var selected: Dictionary = valid_attachments[0]
	var normalized_preferred: String = preferred_side.to_lower().strip_edges()
	if not normalized_preferred.is_empty():
		for attachment in valid_attachments:
			if str(attachment.get("side", "")) == normalized_preferred:
				selected = attachment
				break
	var available_sides: Array[String] = []
	for attachment in valid_attachments:
		available_sides.append(str(attachment.get("side", "")))
	return {
		"ok": true,
		"anchor_floor_cell": anchor_floor_cell,
		"attached_wall_cell": Vector2i(selected.get("attached_wall_cell", Vector2i(-1, -1))),
		"wall_side": str(selected.get("side", "north")),
		"available_wall_sides": available_sides
	}

func is_breachable_wall_cell(cell: Vector2i) -> bool:
	var wall_data: Dictionary = get_breachable_wall_action_target_at_cell(cell)
	return not wall_data.is_empty()

func can_place_map_constructor_prefab(prefab_id: String, cell: Vector2i, preferred_wall_side: String = "", placement_mode_override: String = "") -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": "unsupported_prefab", "message": "Blocked: unsupported prefab.", "cell_state": get_runtime_cell_state(cell)}
	var is_supported: bool = false
	for entry in get_map_constructor_prefab_catalog():
		if str(entry.get("id", "")) == prefab_id:
			is_supported = true
			break
	var canonical_prefab_id: String = WorldObjectCatalogRef.canonical_object_type(prefab_id)
	if not is_supported:
		return result
	var cell_state: Dictionary = get_runtime_cell_state(cell)
	result["cell_state"] = cell_state
	var prefab_is_item: bool = is_map_constructor_item_prefab(prefab_id)
	var requested_mounting_mode: String = placement_mode_override.strip_edges().to_lower()
	var prefab_metadata: Dictionary = get_map_constructor_prefab_metadata(prefab_id)
	var prefab_metadata_row: Dictionary = _safe_dictionary(prefab_metadata.get("prefab", {}))
	var prefab_is_wall_mounted: bool = str(prefab_metadata_row.get("placement_mode", "")) == "wall_mounted" or bool(MAP_CONSTRUCTOR_WALL_MOUNTED_PREFABS.get(prefab_id, false))
	if requested_mounting_mode == "wall_mounted":
		prefab_is_wall_mounted = true
	elif requested_mounting_mode == "stationary":
		prefab_is_wall_mounted = false
	if not bool(cell_state.get("in_bounds", false)):
		result["reason"] = "wall_mounted_anchor_out_of_bounds" if prefab_is_wall_mounted else "out_of_bounds"
		result["message"] = "Cannot mount here: anchor floor cell is outside the map." if prefab_is_wall_mounted else "Blocked: out of bounds."
		return result
	var active_bipob_cell: Vector2i = Vector2i(-1, -1)
	if active_bipob_ref != null:
		var active_bipob_position_variant: Variant = active_bipob_ref.get("grid_position")
		if active_bipob_position_variant is Vector2i or active_bipob_position_variant is Vector2:
			active_bipob_cell = Vector2i(active_bipob_position_variant)
	if active_bipob_cell == cell:
		result["reason"] = "blocked_by_bipob" if prefab_is_wall_mounted else "occupied_by_bipob"
		result["message"] = "Cannot mount here: anchor cell is occupied by Bipob." if prefab_is_wall_mounted else "Blocked: existing object."
		return result
	var tile_type_value: int = int(cell_state.get("tile_type", -1))
	var tile_is_wall: bool = tile_type_value == GridManager.TILE_WALL
	var tile_is_door_or_gate: bool = tile_type_value == GridManager.TILE_DOOR or tile_type_value == GridManager.TILE_DIGITAL_DOOR or tile_type_value == GridManager.TILE_POWERED_GATE
	var tile_is_exit: bool = tile_type_value == GridManager.TILE_EXIT
	var tile_is_floor_like: bool = tile_type_value == GridManager.TILE_FLOOR or tile_type_value == GridManager.TILE_STEPPED_FLOOR
	var canonical_prefab_template: Dictionary = _get_world_object_template(canonical_prefab_id)
	var prefab_is_cable_layer: bool = canonical_prefab_id == "power_cable" or CableTopologyServiceRef.is_cable_object({"object_type": canonical_prefab_id})
	if prefab_is_cable_layer and is_breachable_wall_cell(cell):
		result["reason"] = "breachable_wall_blocks_cable"
		result["message"] = "Cannot route cables on a Breachable Wall."
		return result
	var prefab_is_wall: bool = str(canonical_prefab_template.get("group", "")) == "wall"
	var prefab_is_door_or_gate: bool = str(canonical_prefab_template.get("group", "")) == "door"
	var prefab_is_floor_replacement: bool = prefab_id == "floor" or prefab_id == "stepped_floor"
	if tile_is_exit and prefab_id != "powered_gate":
		result["reason"] = "exit_cell"
		result["message"] = "Blocked: exit cell."
		return result
	var has_static_wall_or_blocked_tile: bool = tile_is_wall or (not bool(cell_state.get("static_walkable", true)) and not tile_is_door_or_gate and not tile_is_exit)
	if has_static_wall_or_blocked_tile and not prefab_is_floor_replacement and not prefab_is_cable_layer:
		result["reason"] = "wall_or_static"
		result["message"] = "Blocked: wall/static obstacle."
		return result
	var prefab_can_replace_non_floor: bool = prefab_is_wall or prefab_is_door_or_gate or prefab_is_floor_replacement or prefab_is_cable_layer
	if not tile_is_floor_like and not tile_is_exit and not prefab_can_replace_non_floor:
		result["reason"] = "non_floor_tile"
		result["message"] = "Blocked: non-floor tile."
		return result
	if (prefab_is_wall or prefab_is_door_or_gate) and not tile_is_floor_like:
		result["reason"] = "non_floor_tile"
		result["message"] = "Blocked: non-floor tile."
		return result
	if prefab_is_floor_replacement and not (tile_is_wall or tile_is_door_or_gate or tile_is_floor_like):
		result["reason"] = "non_floor_tile"
		result["message"] = "Blocked: non-floor tile."
		return result
	var existing_object: Dictionary = get_world_object_at_cell(cell)
	var existing_object_is_cable_layer: bool = CableTopologyServiceRef.is_cable_object(existing_object)
	var allow_cable_layer_stack: bool = prefab_is_cable_layer or (existing_object_is_cable_layer and not prefab_is_item)
	if not prefab_is_item and not existing_object.is_empty() and not allow_cable_layer_stack:
		result["reason"] = "existing_object"
		result["message"] = "Blocked: existing object."
		return result
	if bool(cell_state.get("has_object", false)) and bool(cell_state.get("blocks_movement", false)) and WorldObjectCatalogRef.is_constructor_solid_prefab(prefab_id) and not prefab_is_cable_layer and not existing_object_is_cable_layer:
		result["reason"] = "wall_or_static"
		result["message"] = "Blocked: wall/static obstacle."
		return result
	if bool(cell_state.get("has_object", false)):
		var existing_data: Dictionary = get_world_object_at_cell(cell)
		if bool(existing_data.get("mission_exit", false)) or bool(existing_data.get("extraction", false)):
			result["reason"] = "exit_cell"
			result["message"] = "Blocked: exit cell."
			return result
	if canonical_prefab_id == "power_cable":
		var cable_preview: Dictionary = WorldObjectCatalogRef.create_world_object(prefab_id, "constructor_preview_cable")
		if cable_preview.is_empty():
			cable_preview = {"id": "constructor_preview_cable", "object_type": canonical_prefab_id}
		cable_preview["position"] = cell
		var cable_validation: Dictionary = CableTopologyServiceRef.validate_placement(cell, mission_world_objects, cable_preview)
		if not bool(cable_validation.get("ok", false)):
			result["reason"] = "invalid_cable_junction"
			result["message"] = str(cable_validation.get("message", CableTopologyServiceRef.ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH))
			result["cable_topology"] = cable_validation
			return result
	if prefab_is_wall_mounted:
		result["placement_mode"] = "wall_mounted"
		result["anchor_floor_cell"] = _serialize_cell_key(cell)
		result["attached_wall_cell"] = "-1,-1"
		var normalized_side: String = preferred_wall_side.to_lower().strip_edges()
		if not normalized_side.is_empty() and _get_map_constructor_wall_side_delta(normalized_side) == Vector2i.ZERO:
			result["reason"] = "wall_mounted_wrong_side"
			result["message"] = "Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(preferred_wall_side)
			return result
		var available_sides: Array[String] = []
		for side_entry in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
			var side_id: String = str(side_entry.get("side", ""))
			var wall_cell: Vector2i = cell + _get_map_constructor_wall_side_delta(side_id)
			if _is_map_constructor_wall_cell(wall_cell) and not is_breachable_wall_cell(wall_cell):
				available_sides.append(side_id)
		result["available_wall_sides"] = available_sides
		if available_sides.is_empty():
			result["reason"] = "wall_mounted_no_wall"
			result["message"] = "Cannot mount here: no adjacent wall around anchor cell."
			return result
		if normalized_side.is_empty():
			normalized_side = available_sides[0]
		if not available_sides.has(normalized_side):
			result["wall_side"] = normalized_side
			result["reason"] = "wall_mounted_wrong_side"
			result["message"] = "Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(normalized_side)
			return result
		var attached_wall_cell: Vector2i = cell + _get_map_constructor_wall_side_delta(normalized_side)
		if is_breachable_wall_cell(attached_wall_cell):
			result["reason"] = "breachable_wall_blocks_wall_mount"
			result["message"] = "Cannot mount on a Breachable Wall."
			return result
		result["attached_wall_cell"] = _serialize_cell_key(attached_wall_cell)
		result["wall_side"] = normalized_side
		for object_data in mission_world_objects:
			if str(object_data.get("placement_mode", "")) != "wall_mounted":
				continue
			if _deserialize_cell_variant(object_data.get("anchor_floor_cell", "")) == cell and str(object_data.get("wall_side", "")).to_lower() == normalized_side:
				result["reason"] = "wall_mounted_side_occupied"
				result["message"] = "Cannot mount on %s: wall side already has a mounted object." % _get_map_constructor_wall_side_label(normalized_side)
				return result
	if prefab_id != "powered_gate":
		var tile_name: String = str(cell_state.get("tile_name", "")).to_lower()
		if tile_name.find("exit") >= 0 or tile_name.find("extraction") >= 0:
			result["reason"] = "exit_cell"
			result["message"] = "Blocked: exit cell."
			return result
	result["ok"] = true
	result["reason"] = "ok"
	result["message"] = "OK"
	return result

func _ensure_map_constructor_service() -> MapConstructorService:
	if map_constructor_service == null:
		map_constructor_service = MapConstructorServiceRef.new(self)
	return map_constructor_service

func _ensure_map_constructor_validation_service() -> MapConstructorValidationService:
	if map_constructor_validation_service == null:
		map_constructor_validation_service = MapConstructorValidationServiceRef.new(self)
	return map_constructor_validation_service

func place_map_constructor_prefab(prefab_id: String, cell: Vector2i, preferred_wall_side: String = "", rotation_degrees: int = 0, placement_mode_override: String = "") -> Dictionary:
	return _ensure_map_constructor_service().place_map_constructor_prefab(prefab_id, cell, preferred_wall_side, rotation_degrees, placement_mode_override)

func _remove_map_constructor_entity_by_id(entity_kind: String, entity_id: String) -> Dictionary:
	return _ensure_map_constructor_service()._remove_map_constructor_entity_by_id(entity_kind, entity_id)

func move_map_constructor_entity_to_cell(entity_kind: String, entity_id: String, target_cell: Vector2i, preferred_wall_side: String = "") -> Dictionary:
	return _ensure_map_constructor_service().move_map_constructor_entity_to_cell(entity_kind, entity_id, target_cell, preferred_wall_side)

func duplicate_map_constructor_entity_to_cell(entity_kind: String, entity_id: String, target_cell: Vector2i, preferred_wall_side: String = "") -> Dictionary:
	return _ensure_map_constructor_service().duplicate_map_constructor_entity_to_cell(entity_kind, entity_id, target_cell, preferred_wall_side)

func _normalize_map_constructor_batch_offset(options: Dictionary) -> Vector2i:
	var offset_variant: Variant = options.get("offset", Vector2i.ZERO)
	if offset_variant is Vector2i:
		return Vector2i(offset_variant)
	if offset_variant is Dictionary:
		return Vector2i(int(offset_variant.get("x", 0)), int(offset_variant.get("y", 0)))
	return Vector2i.ZERO

func _is_map_constructor_batch_protected_entity(entity_id: String) -> bool:
	return entity_id in ["bipob_start", "mission_exit", "constructor_start_marker", "constructor_exit_marker"]

func preview_map_constructor_batch_operation(operation_type: String, entities: Array[Dictionary], options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "operation_type": operation_type, "message": "Batch tools available only in TASK TEST.", "affected_count": 0, "affected": [], "warnings": [], "conflicts": [], "can_apply": false}
	var op: String = operation_type.to_lower().strip_edges()
	var include_non_constructor: bool = bool(options.get("include_non_constructor", false))
	var offset: Vector2i = _normalize_map_constructor_batch_offset(options)
	var warnings: Array[String] = []
	var conflicts: Array[Dictionary] = []
	var affected: Array[Dictionary] = []
	var seen: Dictionary = {}
	for row in entities:
		var entity_kind: String = str(row.get("entity_kind", "")).to_lower()
		var entity_id: String = str(row.get("entity_id", ""))
		if entity_id.is_empty() or seen.has("%s|%s" % [entity_kind, entity_id]):
			continue
		seen["%s|%s" % [entity_kind, entity_id]] = true
		if _is_map_constructor_batch_protected_entity(entity_id):
			conflicts.append({"entity_id":entity_id, "reason":"protected_id"})
			continue
		var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		if not bool(entity.get("ok", false)):
			warnings.append("Skipped stale entity %s." % entity_id)
			continue
		var data: Dictionary = _safe_dictionary(entity.get("data", {}))
		if not include_non_constructor and not bool(data.get("created_by_map_constructor", false)):
			conflicts.append({"entity_id":entity_id, "reason":"non_constructor"})
			continue
		var from_cell: Vector2i = Vector2i(entity.get("cell", Vector2i(-1, -1)))
		var to_cell: Vector2i = from_cell + offset
		var op_row: Dictionary = {"entity_kind":entity_kind, "entity_id":entity_id, "object_type":str(data.get("object_type", data.get("item_type", ""))), "from_cell":from_cell, "to_cell":to_cell, "operation":"update", "field_changes":[], "message":"OK"}
		if op == "delete_selected":
			op_row["operation"] = "delete"
		elif op == "assign_power_network":
			op_row["operation"] = "update"
			if entity_kind != "world_object":
				warnings.append("Item %s skipped for power assignment." % entity_id)
				continue
			op_row["field_changes"] = [{"field":"power_network_id", "new":str(options.get("power_network_id", ""))}]
		elif op == "clear_broken_references":
			op_row["operation"] = "update"
		elif op == "move_selected" or op == "duplicate_selected":
			op_row["operation"] = "move" if op == "move_selected" else "duplicate"
			var prefab_id: String = str(data.get("map_constructor_prefab_id", data.get("object_type", "")))
			var check: Dictionary = can_place_map_constructor_prefab(prefab_id, to_cell, str(data.get("wall_side", "")))
			if not bool(check.get("ok", false)):
				conflicts.append({"entity_id":entity_id, "from_cell":from_cell, "to_cell":to_cell, "reason":str(check.get("reason", "blocked")), "message":str(check.get("message", "Blocked."))})
				continue
		else:
			return {"ok": false, "operation_type": operation_type, "message": "Unsupported operation.", "affected_count": 0, "affected": [], "warnings": [], "conflicts": [], "can_apply": false}
		affected.append(op_row)
	var allow_partial: bool = bool(options.get("allow_partial", false))
	var can_apply: bool = not affected.is_empty() and (conflicts.is_empty() or allow_partial)
	return {"ok": true, "operation_type": op, "message": "Preview ready.", "affected_count": affected.size(), "affected": affected, "warnings": warnings, "conflicts": conflicts, "can_apply": can_apply}

func apply_map_constructor_batch_operation(operation_type: String, entities: Array[Dictionary], options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var preview: Dictionary = preview_map_constructor_batch_operation(operation_type, entities, options)
	if not bool(preview.get("ok", false)) or not bool(preview.get("can_apply", false)):
		return {"ok": false, "message": str(preview.get("message", "Cannot apply.")), "applied_count": 0, "warnings": Array(preview.get("warnings", [])), "conflicts": Array(preview.get("conflicts", [])), "batch_id": ""}
	_map_constructor_last_batch_snapshot = {"batch_id":"batch_%d" % int(Time.get_unix_time_from_system()), "mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	var applied_count: int = 0
	for row_variant in Array(preview.get("affected", [])):
		var row: Dictionary = Dictionary(row_variant)
		var ek: String = str(row.get("entity_kind", ""))
		var eid: String = str(row.get("entity_id", ""))
		var to_cell: Vector2i = Vector2i(row.get("to_cell", Vector2i(-1, -1)))
		match str(preview.get("operation_type", "")):
			"delete_selected":
				if bool(_remove_map_constructor_entity_by_id(ek, eid).get("ok", false)): applied_count += 1
			"move_selected":
				if bool(move_map_constructor_entity_to_cell(ek, eid, to_cell, "").get("ok", false)): applied_count += 1
			"duplicate_selected":
				if bool(duplicate_map_constructor_entity_to_cell(ek, eid, to_cell, "").get("ok", false)): applied_count += 1
			"assign_power_network":
				var update: Dictionary = apply_map_constructor_property_update(ek, eid, "power_network_id", str(options.get("power_network_id", "")))
				if bool(update.get("ok", false)):
					applied_count += 1
			"clear_broken_references":
				if ek != "world_object":
					continue
				var world_ids: Dictionary = _map_constructor_collect_world_ids()
				var item_ids: Dictionary = _map_constructor_collect_item_ids()
				var entity_info: Dictionary = get_map_constructor_entity_by_id(ek, eid)
				if not bool(entity_info.get("ok", false)):
					continue
				var data: Dictionary = _safe_dictionary(entity_info.get("data", {}))
				var cleared_any: bool = false
				for ref_field in ["target_door_id", "target_platform_id", "linked_terminal_id", "control_source_id", "required_key_id"]:
					var ref_id: String = str(data.get(ref_field, "")).strip_edges()
					if ref_id.is_empty():
						continue
					var ref_valid: bool = world_ids.has(ref_id) or (ref_field == "required_key_id" and item_ids.has(ref_id))
					if ref_valid:
						continue
					var clear_result: Dictionary = apply_map_constructor_property_update(ek, eid, ref_field, "")
					if bool(clear_result.get("ok", false)):
						cleared_any = true
				var connected_ids: Array[String] = []
				var connected_valid_ids: Array[String] = []
				for connected_id_variant in Array(data.get("connected_device_ids", [])):
					var connected_id: String = str(connected_id_variant).strip_edges()
					if connected_id.is_empty():
						continue
					connected_ids.append(connected_id)
					if world_ids.has(connected_id) or item_ids.has(connected_id):
						connected_valid_ids.append(connected_id)
				if connected_valid_ids.size() != connected_ids.size():
					var connected_update: Dictionary = apply_map_constructor_property_update(ek, eid, "connected_device_ids", connected_valid_ids)
					if bool(connected_update.get("ok", false)):
						cleared_any = true
				if cleared_any:
					applied_count += 1
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("batch", {"summary":"Batch %s: %d affected" % [str(preview.get("operation_type", "")), applied_count], "details":{"operation_type":str(preview.get("operation_type", "")), "affected_count":applied_count}, "undo_hint":"Use Undo Last Batch."})
	return {"ok": true, "message": "Batch applied.", "applied_count": applied_count, "warnings": Array(preview.get("warnings", [])), "conflicts": Array(preview.get("conflicts", [])), "batch_id": str(_map_constructor_last_batch_snapshot.get("batch_id", ""))}

func undo_last_map_constructor_batch_operation() -> Dictionary:
	if _map_constructor_last_batch_snapshot.is_empty():
		return {"ok": false, "message": "No batch operation to undo."}
	mission_world_objects = Array(_map_constructor_last_batch_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_batch_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_batch_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_batch_snapshot.clear()
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("batch_undo", {"summary":"Undid last batch operation.", "undo_hint":"Re-apply batch manually if needed."})
	return {"ok": true, "message": "Last batch operation undone."}

func remove_map_constructor_object_at_cell(cell: Vector2i) -> Dictionary:
	return _ensure_map_constructor_service().remove_map_constructor_object_at_cell(cell)

func _get_map_constructor_wall_mounted_match_score(object_data: Dictionary, cell: Vector2i) -> int:
	if str(object_data.get("placement_mode", "")) != "wall_mounted":
		return -1
	var object_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
	if object_cell == cell:
		return 300
	var anchor_cell: Vector2i = _deserialize_cell_variant(object_data.get("anchor_floor_cell", ""))
	if anchor_cell == cell:
		return 200
	var attached_cell: Vector2i = _deserialize_cell_variant(object_data.get("attached_wall_cell", ""))
	if attached_cell == cell:
		return 100
	return -1

func _get_map_constructor_best_wall_mounted_entity_at_cell(cell: Vector2i) -> Dictionary:
	var best_score: int = -1
	var best_entity: Dictionary = {}
	for object_data in mission_world_objects:
		var score: int = _get_map_constructor_wall_mounted_match_score(object_data, cell)
		if score > best_score:
			best_score = score
			best_entity = object_data
	if best_score < 0 or best_entity.is_empty():
		return {"ok": false, "reason": "not_found"}
	return {
		"ok": true,
		"entity_kind": "world_object",
		"id": str(best_entity.get("id", "")),
		"cell": Vector2i(best_entity.get("position", cell)),
		"data": best_entity
	}

func get_map_constructor_editable_entity_at_cell(cell: Vector2i) -> Dictionary:
	var object_data: Dictionary = get_world_object_at_cell(cell)
	if not object_data.is_empty():
		return {"ok": true, "entity_kind": "world_object", "id": str(object_data.get("id", "")), "cell": cell, "data": object_data}
	var wall_mounted_entity: Dictionary = _get_map_constructor_best_wall_mounted_entity_at_cell(cell)
	if bool(wall_mounted_entity.get("ok", false)):
		return wall_mounted_entity
	var items: Array[Dictionary] = get_items_at_cell(cell)
	if not items.is_empty():
		var item_data: Dictionary = items[0]
		return {"ok": true, "entity_kind": "item", "id": str(item_data.get("id", "")), "cell": cell, "data": item_data}
	return {"ok": false, "reason": "empty_cell"}


func get_map_constructor_wall_mounted_status(entity_kind: String, entity_id: String) -> Dictionary:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "reason": "missing_entity", "message": "Wall-mounted object not found."}
	var data: Dictionary = _safe_dictionary(entity.get("data", {}))
	if str(data.get("placement_mode", "")) != "wall_mounted":
		return {"ok": true, "reason": "not_wall_mounted", "message": "Not a wall-mounted object."}
	var anchor: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", ""))
	var attached: Vector2i = _deserialize_cell_variant(data.get("attached_wall_cell", ""))
	var side: String = str(data.get("wall_side", "")).to_lower().strip_edges()
	var available: Array[String] = []
	for e in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
		var s: String = str(e.get("side", ""))
		if _is_map_constructor_wall_cell(anchor + _get_map_constructor_wall_side_delta(s)):
			available.append(s)
	var base := {"ok": true, "reason": "ok", "message": "Wall-mounted object is valid.", "anchor_floor_cell": anchor, "attached_wall_cell": attached, "wall_side": side, "available_wall_sides": available}
	if not _is_valid_grid_cell(anchor):
		base["ok"]=false; base["reason"]="wall_mounted_broken_anchor"; base["message"]="Wall-mounted object has broken anchor metadata."; return base
	if _get_map_constructor_wall_side_delta(side) == Vector2i.ZERO:
		base["ok"]=false; base["reason"]="wall_mounted_wrong_side"; base["message"]="Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(side); return base
	if anchor + _get_map_constructor_wall_side_delta(side) != attached:
		base["ok"]=false; base["reason"]="wall_mounted_broken_anchor"; base["message"]="Wall-mounted object has broken anchor metadata."; return base
	if not _is_map_constructor_wall_cell(attached):
		base["ok"]=false; base["reason"]="wall_mounted_attached_wall_missing"; base["message"]="Attached wall was removed. Choose another side, move the object, or delete it."; return base
	return base

func set_map_constructor_wall_mounted_side(entity_kind: String, entity_id: String, new_wall_side: String) -> Dictionary:
	var status: Dictionary = get_map_constructor_wall_mounted_status(entity_kind, entity_id)
	if not bool(status.get("ok", false)) and str(status.get("reason", "")) != "wall_mounted_attached_wall_missing":
		return status
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "reason": "missing_entity", "message": "Wall-mounted object not found."}
	var data: Dictionary = _safe_dictionary(entity.get("data", {}))
	if str(data.get("placement_mode", "")) != "wall_mounted" or not bool(data.get("created_by_map_constructor", false)):
		return {"ok": false, "reason": "not_wall_mounted", "message": "Not a wall-mounted object."}
	var side: String = new_wall_side.to_lower().strip_edges()
	if _get_map_constructor_wall_side_delta(side) == Vector2i.ZERO:
		return {"ok": false, "reason": "wall_mounted_wrong_side", "message": "Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(side)}
	var anchor: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", ""))
	var attached: Vector2i = anchor + _get_map_constructor_wall_side_delta(side)
	if not _is_map_constructor_wall_cell(attached):
		return {"ok": false, "reason": "wall_mounted_wrong_side", "message": "Cannot mount on %s: adjacent cell is not a wall." % _get_map_constructor_wall_side_label(side)}
	for object_data in mission_world_objects:
		if str(object_data.get("id", "")) == entity_id:
			continue
		if str(object_data.get("placement_mode", "")) != "wall_mounted":
			continue
		if _deserialize_cell_variant(object_data.get("anchor_floor_cell", "")) == anchor and str(object_data.get("wall_side", "")).to_lower() == side:
			return {"ok": false, "reason": "wall_mounted_side_occupied", "message": "Cannot mount on %s: wall side already has a mounted object." % _get_map_constructor_wall_side_label(side)}
	data["wall_side"] = side
	data["attached_wall_cell"] = _serialize_cell_key(attached)
	data["position"] = anchor
	set_world_object_at_cell(anchor, data)
	PowerSystemRef.recalculate_network(mission_world_objects, str(data.get("power_network_id", "")))
	refresh_world_cooling_received()
	_record_map_constructor_change("side_change", {"entity_kind":"world_object", "entity_id":entity_id, "object_type":str(data.get("object_type", "")), "cell":anchor, "summary":"Changed wall side on %s to %s" % [entity_id, side], "undo_hint":"Can undo by switching side again."})
	return {"ok": true, "message": "Wall side changed to %s." % _get_map_constructor_wall_side_label(side), "object_id": entity_id, "wall_side": side, "attached_wall_cell": attached}

func set_map_constructor_wall_material(cell: Vector2i, side: String, material_id: String) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall material overrides are available only in TASK TEST constructor mode."}
	var normalized_side: String = side.to_lower().strip_edges()
	var normalized_material_id: String = normalize_map_constructor_wall_material_id(material_id)
	if _get_map_constructor_wall_side_delta(normalized_side) == Vector2i.ZERO:
		return {"ok": false, "message": "Invalid wall side."}
	var attached_wall_cell: Vector2i = cell + _get_map_constructor_wall_side_delta(normalized_side)
	if not _is_wall_or_boundary_cell(attached_wall_cell):
		return {"ok": false, "message": "Selected side has no wall."}
	var catalog: Dictionary = get_map_constructor_wall_material_catalog()
	var known: bool = false
	for row_variant in Array(catalog.get("materials", [])):
		var row: Dictionary = Dictionary(row_variant)
		if str(row.get("id", "")).to_lower() == normalized_material_id:
			known = true
			break
	if not known:
		return {"ok": false, "message": "Unknown wall material id: %s" % material_id}
	var key: String = _serialize_wall_material_override_key(cell, normalized_side)
	var entry: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(key, {})).duplicate(true)
	var existing_height: String = normalize_map_constructor_wall_height(str(entry.get("wall_height", entry.get("wall_visual_height", ""))))
	if normalized_material_id in ["breachable_concrete", "breachable_brick"] and existing_height in ["low", "halflow"]:
		existing_height = "mid"
		entry["wall_height"] = existing_height
		entry.erase("wall_visual_height")
	if normalized_material_id in ["breachable_concrete", "breachable_brick"] and grid_manager != null and grid_manager.has_method("is_boundary_cell") and bool(grid_manager.call("is_boundary_cell", attached_wall_cell)):
		return {"ok": false, "message": "Breachable Wall cannot be assigned to boundary walls."}
	entry["cell"] = cell
	entry["side"] = normalized_side
	entry["material_id"] = normalized_material_id
	if normalized_material_id in ["breachable_concrete", "breachable_brick"]:
		entry["breach_side"] = normalize_breach_side(str(entry.get("breach_side", "sw")))
	else:
		entry.erase("breach_side")
	_map_constructor_wall_material_overrides[key] = entry
	_record_map_constructor_change("wall_material", {"cell":cell, "summary":"Set wall material %s at %s/%s" % [normalized_material_id, _format_map_constructor_cell(cell), normalized_side], "details":{"side":normalized_side, "material_id":normalized_material_id}})
	return {"ok": true, "message": "Wall material applied.", "override": entry}

func clear_map_constructor_wall_material(cell: Vector2i, side: String) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall material overrides are available only in TASK TEST constructor mode."}
	var normalized_side: String = side.to_lower().strip_edges()
	var key: String = _serialize_wall_material_override_key(cell, normalized_side)
	if not _map_constructor_wall_material_overrides.has(key):
		return {"ok": false, "message": "No wall material override to clear."}
	var entry: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(key, {})).duplicate(true)
	entry.erase("material_id")
	entry.erase("breach_side")
	if str(entry.get("wall_height", "")).strip_edges().is_empty():
		_map_constructor_wall_material_overrides.erase(key)
	else:
		_map_constructor_wall_material_overrides[key] = entry
	_record_map_constructor_change("wall_material_clear", {"cell":cell, "summary":"Cleared wall material at %s/%s" % [_format_map_constructor_cell(cell), normalized_side], "details":{"side":normalized_side}})
	return {"ok": true, "message": "Wall material override cleared."}

func get_map_constructor_wall_material(cell: Vector2i, side: String) -> Dictionary:
	var key: String = _serialize_wall_material_override_key(cell, side)
	if not _map_constructor_wall_material_overrides.has(key):
		return {"ok": false, "message": "No wall material override.", "override": {}}
	return {"ok": true, "message": "OK", "override": Dictionary(_map_constructor_wall_material_overrides.get(key, {})).duplicate(true)}

func set_map_constructor_wall_height(cell: Vector2i, side: String, wall_height: String) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall height overrides are available only in TASK TEST constructor mode."}
	var normalized_side: String = side.to_lower().strip_edges()
	if _get_map_constructor_wall_side_delta(normalized_side) == Vector2i.ZERO:
		return {"ok": false, "message": "Invalid wall side."}
	var attached_wall_cell: Vector2i = cell + _get_map_constructor_wall_side_delta(normalized_side)
	if not _is_wall_or_boundary_cell(attached_wall_cell):
		return {"ok": false, "message": "Selected side has no wall."}
	var normalized_height: String = normalize_map_constructor_wall_height(wall_height)
	if not wall_height.strip_edges().is_empty() and normalized_height.is_empty() and wall_height.strip_edges().to_lower() != "auto":
		return {"ok": false, "message": "Unknown wall height: %s" % wall_height}
	var key: String = _serialize_wall_material_override_key(cell, normalized_side)
	var entry: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(key, {})).duplicate(true)
	var existing_material_id: String = normalize_map_constructor_wall_material_id(str(entry.get("material_id", "")))
	if existing_material_id in ["breachable_concrete", "breachable_brick"] and normalized_height in ["low", "halflow"]:
		normalized_height = "mid"
	entry["cell"] = cell
	entry["side"] = normalized_side
	if normalized_height.is_empty():
		entry.erase("wall_height")
		entry.erase("wall_visual_height")
	else:
		entry["wall_height"] = normalized_height
	if str(entry.get("material_id", "")).strip_edges().is_empty() and str(entry.get("wall_height", "")).strip_edges().is_empty():
		_map_constructor_wall_material_overrides.erase(key)
	else:
		_map_constructor_wall_material_overrides[key] = entry
	_record_map_constructor_change("wall_height", {"cell":cell, "summary":"Set wall height %s at %s/%s" % [("auto" if normalized_height.is_empty() else normalized_height), _format_map_constructor_cell(cell), normalized_side], "details":{"side":normalized_side, "wall_height":normalized_height}})
	return {"ok": true, "message": "Wall height updated.", "override": entry}

func set_map_constructor_wall_breach_side(cell: Vector2i, side: String, breach_side: String) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Breach Side overrides are available only in TASK TEST constructor mode."}
	var normalized_side: String = side.to_lower().strip_edges()
	if _get_map_constructor_wall_side_delta(normalized_side) == Vector2i.ZERO:
		return {"ok": false, "message": "Invalid wall side."}
	var attached_wall_cell: Vector2i = cell + _get_map_constructor_wall_side_delta(normalized_side)
	if not _is_wall_or_boundary_cell(attached_wall_cell):
		return {"ok": false, "message": "Selected side has no wall."}
	var key: String = _serialize_wall_material_override_key(cell, normalized_side)
	var entry: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(key, {})).duplicate(true)
	var material_id: String = normalize_map_constructor_wall_material_id(str(entry.get("material_id", "")))
	if not (material_id in ["breachable_concrete", "breachable_brick"]):
		return {"ok": false, "message": "Breach Side is available only for Breachable Wall materials."}
	var normalized_breach_side: String = normalize_breach_side(breach_side)
	entry["cell"] = cell
	entry["side"] = normalized_side
	entry["material_id"] = material_id
	entry["breach_side"] = normalized_breach_side
	_map_constructor_wall_material_overrides[key] = entry
	_record_map_constructor_change("wall_breach_side", {"cell":cell, "summary":"Set breach side %s at %s/%s" % [normalized_breach_side.to_upper(), _format_map_constructor_cell(cell), normalized_side], "details":{"side":normalized_side, "breach_side":normalized_breach_side}})
	return {"ok": true, "message": "Breach Side updated.", "override": entry}

func get_map_constructor_wall_material_for_wall_cell(wall_cell: Vector2i) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall material overrides are available only in TASK TEST constructor mode.", "override": {}, "material": {}}
	var catalog_by_id: Dictionary = {}
	var catalog: Dictionary = get_map_constructor_wall_material_catalog()
	for row_variant in Array(catalog.get("materials", [])):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = Dictionary(row_variant)
		var row_id: String = str(row.get("id", "")).to_lower().strip_edges()
		if row_id.is_empty():
			continue
		catalog_by_id[row_id] = row
	var side_order: Array[String] = ["north", "east", "south", "west"]
	for side_id in side_order:
		for key_variant in _map_constructor_wall_material_overrides.keys():
			var entry: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(str(key_variant), {}))
			var override_side: String = str(entry.get("side", "")).to_lower().strip_edges()
			if override_side != side_id:
				continue
			var anchor_cell: Vector2i = _deserialize_cell_variant(entry.get("cell", Vector2i(-1, -1)))
			var attached_wall_cell: Vector2i = anchor_cell + _get_map_constructor_wall_side_delta(override_side)
			if attached_wall_cell != wall_cell:
				continue
			var material_id: String = normalize_map_constructor_wall_material_id(str(entry.get("material_id", "")))
			var normalized_height: String = normalize_map_constructor_wall_height(str(entry.get("wall_height", entry.get("wall_visual_height", ""))))
			var normalized_breach_side: String = normalize_breach_side(str(entry.get("breach_side", "sw")))
			if material_id.is_empty():
				var auto_material: Dictionary = Dictionary(catalog_by_id.get("concrete", {})).duplicate(true)
				auto_material["wall_height"] = normalized_height
				return {"ok": true, "message": "OK", "override": entry.duplicate(true), "material": auto_material}
			if not catalog_by_id.has(material_id):
				return {"ok": false, "message": "Unknown wall material id: %s" % material_id, "override": entry.duplicate(true), "material": {}}
			var material: Dictionary = Dictionary(catalog_by_id.get(material_id, {})).duplicate(true)
			material["wall_height"] = normalized_height
			if material_id in ["breachable_concrete", "breachable_brick"]:
				material["breach_side"] = normalized_breach_side
			return {"ok": true, "message": "OK", "override": entry.duplicate(true), "material": material}
	return {"ok": false, "message": "No wall material override.", "override": {}, "material": {}}


func _clear_map_constructor_wall_material_overrides_for_wall_cell(wall_cell: Vector2i) -> void:
	var keys_to_erase: Array[String] = []
	for key_variant in _map_constructor_wall_material_overrides.keys():
		var key: String = str(key_variant)
		var entry: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(key, {}))
		var side: String = str(entry.get("side", "")).to_lower().strip_edges()
		var anchor_cell: Vector2i = _deserialize_cell_variant(entry.get("cell", Vector2i(-1, -1)))
		if anchor_cell + _get_map_constructor_wall_side_delta(side) == wall_cell:
			keys_to_erase.append(key)
	for key in keys_to_erase:
		_map_constructor_wall_material_overrides.erase(key)

func get_breachable_wall_action_target_at_cell(cell: Vector2i) -> Dictionary:
	if grid_manager == null or not grid_manager.has_method("get_tile") or not grid_manager.has_method("is_in_bounds"):
		return {}
	if not bool(grid_manager.call("is_in_bounds", cell)) or int(grid_manager.call("get_tile", cell)) != GridManager.TILE_WALL:
		return {}
	if grid_manager.has_method("is_boundary_cell") and bool(grid_manager.call("is_boundary_cell", cell)):
		return {}
	var material_result: Dictionary = get_map_constructor_wall_material_for_wall_cell(cell)
	if not bool(material_result.get("ok", false)):
		return {}
	var material: Dictionary = Dictionary(material_result.get("material", {}))
	if str(material.get("wall_archetype", "")).to_lower().strip_edges() != "breachable":
		return {}
	var height: String = normalize_map_constructor_wall_height(str(material.get("wall_height", "")))
	if height.is_empty():
		height = "mid"
	if height == "low" or height == "halflow":
		height = "mid"
	var allowed_heights: Array = Array(material.get("allowed_wall_heights", ["mid", "halfmid", "tall"]))
	if not allowed_heights.has(height):
		return {}
	var material_id: String = normalize_map_constructor_wall_material_id(str(material.get("id", "")))
	var breach_side: String = BreachableWallServiceRef.normalize_breach_side(material.get("breach_side", "sw"))
	return BreachableWallServiceRef.build_runtime_wall_target(cell, material, height, breach_side)

func break_breachable_wall_at_cell(cell: Vector2i, tool_id: String = "heavy_claw", actor_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var wall_data: Dictionary = get_breachable_wall_action_target_at_cell(cell)
	if wall_data.is_empty():
		return {"ok": false, "message": "No Breachable Wall at target cell."}
	if not Array(wall_data.get("breach_tools", [])).has(tool_id):
		return {"ok": false, "message": "Heavy Claw required."}
	if actor_cell.x >= 0 and actor_cell.y >= 0 and not is_bipob_on_breach_side(cell, actor_cell, str(wall_data.get("breach_side", "sw"))):
		return {"ok": false, "message": "Break is available only from the selected Breach Side."}
	if grid_manager == null or not grid_manager.has_method("set_tile"):
		return {"ok": false, "message": "Grid is unavailable."}
	grid_manager.call("set_tile", cell, GridManager.TILE_FLOOR)
	_clear_map_constructor_wall_material_overrides_for_wall_cell(cell)
	_record_map_constructor_change("breach_wall", {"cell":cell, "summary":"Breachable Wall cleared at %s" % _format_map_constructor_cell(cell), "details":{"tool_id":tool_id}})
	return {"ok": true, "message": "Wall breached. Breachable Wall broken.", "cell": cell, "tool_id": tool_id}

func get_map_constructor_wall_material_overrides() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Wall material overrides are available only in TASK TEST constructor mode.", "overrides": []}
	var rows: Array[Dictionary] = []
	for key_variant in _map_constructor_wall_material_overrides.keys():
		rows.append(Dictionary(_map_constructor_wall_material_overrides.get(str(key_variant), {})).duplicate(true))
	return {"ok": true, "message": "OK", "overrides": rows}

func _get_map_constructor_floor_visual_state_for_material_id(material_id: String) -> Dictionary:
	var normalized_material_id: String = material_id.to_lower().strip_edges()
	var parsed: PackedStringArray = normalized_material_id.split("_", false)
	var material: String = parsed[0] if parsed.size() >= 1 else "steel"
	var coating: String = parsed[1] if parsed.size() >= 2 else "default"
	var legacy_map: Dictionary = {
		"default_floor": "concrete",
		"floor_default": "concrete",
		"steel_default": "steel",
		"concrete_default": "concrete",
		"titanium_default": "titan",
		"titan_default": "titan",
		"clean_lab_floor": "steel",
		"dark_service_floor": "concrete",
		"hazard_floor": "concrete",
		"power_floor": "steel",
		"damaged_floor": "concrete",
		"reinforced_floor": "steel",
		"diagnostic_floor": "steel",
		"grate_default": "steel",
		"grate": "steel"
	}
	if legacy_map.has(normalized_material_id):
		return _get_map_constructor_floor_visual_state_for_material_id(str(legacy_map[normalized_material_id]))
	var family: String = GridManager.FLOOR_FAMILY_CONCRETE
	match material:
		"steel", "titan", "titanium":
			family = GridManager.FLOOR_FAMILY_METAL
		_:
			family = GridManager.FLOOR_FAMILY_CONCRETE
	var wear: String = GridManager.FLOOR_WEAR_NONE
	var base_variant: int = -1
	var overlay_variant: int = -1
	var mirror_h: bool = false
	var mirror_v: bool = false
	match coating:
		"destroyed":
			wear = GridManager.FLOOR_WEAR_HEAVY
			overlay_variant = 1
		"dirty":
			wear = GridManager.FLOOR_WEAR_LIGHT
			overlay_variant = 1
		"water":
			wear = GridManager.FLOOR_WEAR_LIGHT
			overlay_variant = 3
			mirror_h = true
		"oil":
			wear = GridManager.FLOOR_WEAR_LIGHT
			overlay_variant = 5
			mirror_v = true
		_:
			wear = GridManager.FLOOR_WEAR_NONE
	if family == GridManager.FLOOR_FAMILY_GRATE and coating != "default":
		base_variant = maxi(1, overlay_variant)
	return {"family": family, "wear": wear, "base_variant": base_variant, "overlay_variant": overlay_variant, "mirror_h": mirror_h, "mirror_v": mirror_v}

func _sync_map_constructor_floor_visual_state(cell: Vector2i, material_id: String, floor_height: String = "default") -> void:
	if grid_manager == null or not grid_manager.has_method("set_floor_visual_state"):
		return
	var floor_state: Dictionary = _get_map_constructor_floor_visual_state_for_material_id(material_id)
	floor_state["floor_height"] = normalize_floor_height_level(floor_height)
	grid_manager.call("set_floor_visual_state", cell, floor_state)

func _clear_map_constructor_floor_visual_state(cell: Vector2i) -> void:
	if grid_manager == null or not grid_manager.has_method("clear_floor_visual_state"):
		return
	grid_manager.call("clear_floor_visual_state", cell)

func set_map_constructor_floor_material(cell: Vector2i, material_id: String, floor_height: String = "default") -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Floor material overrides are available only in TASK TEST constructor mode."}
	if not _is_valid_grid_cell(cell):
		return {"ok": false, "message": "Cell is out of bounds."}
	if grid_manager == null:
		return {"ok": false, "message": "Grid manager unavailable."}
	if not grid_manager.has_method("get_tile"):
		return {"ok": false, "message": "Grid manager missing get_tile."}
	var tile_type: int = int(grid_manager.call("get_tile", cell))
	if not _is_floor_like_constructor_tile(tile_type):
		return {"ok": false, "message": "Only floor cells can receive floor material overrides."}
	var normalized_material_id: String = material_id.to_lower().strip_edges()
	if not _is_known_map_constructor_floor_material_id(normalized_material_id):
		return {"ok": false, "message": "Unknown floor material id: %s" % material_id}
	var normalized_floor_height: String = normalize_floor_height_level(floor_height)
	var key: String = _serialize_cell_key(cell)
	var entry: Dictionary = {"cell": cell, "material_id": normalized_material_id, "floor_height": normalized_floor_height}
	_map_constructor_floor_material_overrides[key] = entry
	_sync_map_constructor_floor_visual_state(cell, normalized_material_id, normalized_floor_height)
	_record_map_constructor_change("floor_material", {"cell":cell, "summary":"Set floor material %s height %s at %s" % [normalized_material_id, normalized_floor_height, _format_map_constructor_cell(cell)], "details":{"material_id":normalized_material_id, "floor_height":normalized_floor_height}})
	return {"ok": true, "message": "Floor material applied.", "override": entry}

func clear_map_constructor_floor_material(cell: Vector2i) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Floor material overrides are available only in TASK TEST constructor mode."}
	var key: String = _serialize_cell_key(cell)
	if not _map_constructor_floor_material_overrides.has(key):
		return {"ok": false, "message": "No floor material override to clear."}
	_map_constructor_floor_material_overrides.erase(key)
	_clear_map_constructor_floor_visual_state(cell)
	_record_map_constructor_change("floor_material_clear", {"cell":cell, "summary":"Cleared floor material at %s" % _format_map_constructor_cell(cell)})
	return {"ok": true, "message": "Floor material override cleared."}

func get_map_constructor_floor_material(cell: Vector2i) -> Dictionary:
	var key: String = _serialize_cell_key(cell)
	if not _map_constructor_floor_material_overrides.has(key):
		return {"ok": false, "message": "No floor material override.", "override": {}}
	return {"ok": true, "message": "OK", "override": Dictionary(_map_constructor_floor_material_overrides.get(key, {})).duplicate(true)}

func get_map_constructor_floor_material_overrides() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Floor material overrides are available only in TASK TEST constructor mode.", "overrides": []}
	var rows: Array[Dictionary] = []
	for key_variant in _map_constructor_floor_material_overrides.keys():
		rows.append(Dictionary(_map_constructor_floor_material_overrides.get(str(key_variant), {})).duplicate(true))
	return {"ok": true, "message": "OK", "overrides": rows}

func get_map_constructor_floor_material_for_cell(cell: Vector2i) -> Dictionary:
	var override_row: Dictionary = Dictionary(get_map_constructor_floor_material(cell).get("override", {}))
	if override_row.is_empty():
		return {"ok": false, "message": "No floor material override.", "override": {}, "material": {}}
	var material_id: String = str(override_row.get("material_id", "")).to_lower().strip_edges()
	for row_variant in Array(get_map_constructor_floor_material_catalog().get("materials", [])):
		var row: Dictionary = Dictionary(row_variant)
		if str(row.get("id", "")).to_lower().strip_edges() == material_id:
			return {"ok": true, "message": "OK", "override": override_row.duplicate(true), "material": row.duplicate(true)}
	return {"ok": false, "message": "Unknown floor material id: %s" % material_id, "override": override_row.duplicate(true), "material": {}}

func get_map_constructor_floor_material_summary() -> Dictionary:
	var material_counts: Dictionary = {}
	var floor_height_counts: Dictionary = {}
	var affected_cells: Array[Vector2i] = []
	var preset_generated_floor_override_count: int = 0
	for key_variant in _map_constructor_floor_material_overrides.keys():
		var row: Dictionary = Dictionary(_map_constructor_floor_material_overrides.get(str(key_variant), {}))
		var material_id: String = str(row.get("material_id", "unknown")).to_lower().strip_edges()
		if material_id.is_empty():
			material_id = "unknown"
		material_counts[material_id] = int(material_counts.get(material_id, 0)) + 1
		var floor_height: String = normalize_floor_height_level(str(row.get("floor_height", row.get("floor_visual_height", row.get("ground_height", "default")))))
		floor_height_counts[floor_height] = int(floor_height_counts.get(floor_height, 0)) + 1
		if bool(row.get("created_by_room_visual_preset", false)):
			preset_generated_floor_override_count += 1
		var floor_cell: Vector2i = Vector2i(row.get("cell", _deserialize_cell_key(str(key_variant))))
		if floor_cell.x >= 0 and floor_cell.y >= 0:
			affected_cells.append(floor_cell)
	affected_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return {"override_count": _map_constructor_floor_material_overrides.size(), "material_counts": material_counts, "floor_height_counts": floor_height_counts, "preset_generated_floor_override_count": preset_generated_floor_override_count, "affected_cells": affected_cells}

func _resolve_floor_material_id_for_room_visual_preset(preset: Dictionary) -> String:
	var floor_style: String = str(preset.get("floor_style", "")).to_lower().strip_edges()
	match floor_style:
		"polished", "service_grid", "reinforced_plate":
			return "steel"
		"mixed_grid":
			return "titan"
		_:
			return "concrete"
func get_room_visual_preset_catalog() -> Dictionary:
	var presets: Array[Dictionary] = [
		{"id":"clean_lab","display_name":"Clean Lab","description":"Sterile lab look with neutral access cues.","wall_material_id":"clean_lab","door_visual_hint":"secure_clean","terminal_visual_hint":"diagnostic_clean","floor_style":"polished","overlay_tone":"cool_white","tags":["clean","lab"],"is_default":true},
		{"id":"dark_service_tunnel","display_name":"Dark Service Tunnel","description":"Low-light maintenance tunnel style.","wall_material_id":"dark_service","door_visual_hint":"maintenance_dark","terminal_visual_hint":"service_dim","floor_style":"grit","overlay_tone":"deep_gray","tags":["service","dark"],"is_default":false},
		{"id":"hazard_power_room","display_name":"Hazard Power Room","description":"High-voltage room with hazard accents.","wall_material_id":"orange_hazard","door_visual_hint":"power_hazard","terminal_visual_hint":"power_hot","floor_style":"striped_hazard","overlay_tone":"amber","tags":["hazard","power"],"is_default":false},
		{"id":"damaged_red_zone","display_name":"Damaged Red Zone","description":"Compromised zone with emergency warning tone.","wall_material_id":"damaged_red","door_visual_hint":"damaged_alert","terminal_visual_hint":"error_red","floor_style":"damaged","overlay_tone":"red_alert","tags":["damaged","alert"],"is_default":false},
		{"id":"diagnostic_bay","display_name":"Diagnostic Bay","description":"Service bay with diagnostic emphasis.","wall_material_id":"diagnostic_blue","door_visual_hint":"diag_access","terminal_visual_hint":"diag_blue","floor_style":"service_grid","overlay_tone":"blue_scan","tags":["diagnostic","service"],"is_default":false},
		{"id":"reinforced_security_room","display_name":"Reinforced Security Room","description":"Heavy security room with hardened materials.","wall_material_id":"reinforced","door_visual_hint":"security_reinforced","terminal_visual_hint":"security_hardened","floor_style":"reinforced_plate","overlay_tone":"steel","tags":["security","reinforced"],"is_default":false},
		{"id":"mixed_test_room","display_name":"Mixed Test Room","description":"Mixed-purpose test room balancing safety and diagnostics.","wall_material_id":"default_metal","door_visual_hint":"mixed_generic","terminal_visual_hint":"mixed_console","floor_style":"mixed_grid","overlay_tone":"neutral","tags":["mixed","test"],"is_default":false}
	]
	return {"ok": true, "presets": presets, "message": "OK"}

func _get_room_visual_preset_by_id(preset_id: String) -> Dictionary:
	var normalized_id: String = preset_id.to_lower().strip_edges()
	for preset_variant in Array(get_room_visual_preset_catalog().get("presets", [])):
		var preset: Dictionary = Dictionary(preset_variant)
		if str(preset.get("id", "")).to_lower().strip_edges() == normalized_id:
			return preset
	return {}

func get_map_constructor_placed_object_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for object_data_variant in mission_world_objects:
		if typeof(object_data_variant) != TYPE_DICTIONARY:
			continue
		var object_data: Dictionary = Dictionary(object_data_variant)
		var row_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
		var object_type: String = str(object_data.get("object_type", "object"))
		var prefab_id: String = str(object_data.get("map_constructor_prefab_id", object_type))
		var placement_mode: String = str(object_data.get("placement_mode", "floor"))
		var row: Dictionary = {
			"entity_kind": "world_object",
			"id": str(object_data.get("id", "")),
			"type_or_prefab": prefab_id,
			"cell": row_cell,
			"anchor_floor_cell": row_cell,
			"category_or_placement": str(object_data.get("category", placement_mode.capitalize())),
			"placement_mode": placement_mode,
			"attached_wall_cell": Vector2i(-1, -1),
			"wall_side": str(object_data.get("wall_side", ""))
		}
		for link_field in ["control_source_id", "linked_terminal_id", "controller_id", "target_door_id", "target_platform_id", "linked_object_id", "target_object_id", "required_key_id"]:
			if object_data.has(link_field):
				row[link_field] = object_data.get(link_field, "")
		var meta_result: Dictionary = get_map_constructor_prefab_metadata(prefab_id)
		if bool(meta_result.get("ok", false)):
			var prefab_meta: Dictionary = Dictionary(meta_result.get("prefab", {}))
			row["display_name"] = str(prefab_meta.get("display_name", prefab_id))
			row["metadata_category"] = str(prefab_meta.get("category", ""))
			row["metadata_roles"] = Array(prefab_meta.get("system_roles", []))
			row["metadata_tags"] = Array(prefab_meta.get("tags", []))
			row["is_expected_invalid_tool"] = bool(prefab_meta.get("is_expected_invalid_tool", false))
		if placement_mode == "wall_mounted":
			row["anchor_floor_cell"] = _deserialize_cell_variant(object_data.get("anchor_floor_cell", row_cell))
			row["attached_wall_cell"] = _deserialize_cell_variant(object_data.get("attached_wall_cell", Vector2i(-1, -1)))
		rows.append(row)
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_data: Dictionary = _safe_dictionary(item_variant)
			rows.append({
				"entity_kind": "item",
				"id": str(item_data.get("id", "")),
				"type_or_prefab": str(item_data.get("item_type", item_data.get("map_constructor_prefab_id", item_data.get("object_type", "item")))),
				"cell": cell,
				"anchor_floor_cell": cell,
				"category_or_placement": "item",
				"placement_mode": "item",
				"attached_wall_cell": Vector2i(-1, -1),
				"wall_side": "",
				"linked_door_id": str(item_data.get("linked_door_id", ""))
			})
			var meta_item: Dictionary = get_map_constructor_prefab_metadata(str(item_data.get("map_constructor_prefab_id", "")))
			if bool(meta_item.get("ok", false)):
				var meta: Dictionary = Dictionary(meta_item.get("prefab", {}))
				rows[rows.size() - 1]["display_name"] = str(meta.get("display_name", rows[rows.size() - 1].get("type_or_prefab", "item")))
				rows[rows.size() - 1]["metadata_category"] = str(meta.get("category", "Item"))
				rows[rows.size() - 1]["metadata_roles"] = Array(meta.get("system_roles", []))
				rows[rows.size() - 1]["metadata_tags"] = Array(meta.get("tags", []))
				rows[rows.size() - 1]["is_expected_invalid_tool"] = bool(meta.get("is_expected_invalid_tool", false))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ay: int = int(Vector2i(a.get("anchor_floor_cell", Vector2i.ZERO)).y)
		var by: int = int(Vector2i(b.get("anchor_floor_cell", Vector2i.ZERO)).y)
		if ay == by:
			var ax: int = int(Vector2i(a.get("anchor_floor_cell", Vector2i.ZERO)).x)
			var bx: int = int(Vector2i(b.get("anchor_floor_cell", Vector2i.ZERO)).x)
			if ax == bx:
				return str(a.get("id", "")) < str(b.get("id", ""))
			return ax < bx
		return ay < by
	)
	return rows

func get_map_constructor_entity_by_id(entity_kind: String, entity_id: String) -> Dictionary:
	return _ensure_map_constructor_service().get_map_constructor_entity_by_id(entity_kind, entity_id)

func get_map_constructor_cell_inspection_model(cell: Vector2i, preferred_entity_kind: String = "", preferred_entity_id: String = "") -> Dictionary:
	return _ensure_map_constructor_service().get_map_constructor_cell_inspection_model(cell, preferred_entity_kind, preferred_entity_id)

func get_normalized_map_constructor_circuit_id(data: Dictionary) -> String:
	return _ensure_map_constructor_service().get_normalized_map_constructor_circuit_id(data)

func get_map_constructor_circuit_summary(entity_kind: String, entity_id: String) -> Dictionary:
	return _ensure_map_constructor_service().get_map_constructor_circuit_summary(entity_kind, entity_id)

func get_map_constructor_circuit_options() -> Array[Dictionary]:
	return _ensure_map_constructor_service().get_map_constructor_circuit_options()

func get_map_constructor_same_circuit_entities(entity_kind: String, entity_id: String) -> Array[Dictionary]:
	return _ensure_map_constructor_service().get_map_constructor_same_circuit_entities(entity_kind, entity_id)

func assign_map_constructor_entity_to_circuit(entity_kind: String, entity_id: String, circuit_id: String, circuit_name: String = "") -> Dictionary:
	return _ensure_map_constructor_service().assign_map_constructor_entity_to_circuit(entity_kind, entity_id, circuit_id, circuit_name)

func create_map_constructor_circuit(entity_kind: String, entity_id: String, requested_id: String = "", circuit_name: String = "") -> Dictionary:
	return _ensure_map_constructor_service().create_map_constructor_circuit(entity_kind, entity_id, requested_id, circuit_name)

func rename_map_constructor_circuit(entity_kind: String, entity_id: String, circuit_name: String) -> Dictionary:
	return _ensure_map_constructor_service().rename_map_constructor_circuit(entity_kind, entity_id, circuit_name)

func _get_map_constructor_editable_field_schema() -> Dictionary:
	return {
		"state":"string","power_network_id":"string","circuit_id":"string","power_circuit_id":"string","network_id":"string","chain_id":"string","link_group":"string","cable_group":"string","connected_circuit":"string","circuit_name":"string","is_open":"bool","is_closed":"bool","is_locked":"bool","blocks_movement":"bool","is_powered":"bool","is_hidden":"bool","hidden_installation":"bool","fuse_installed":"bool","plugged":"bool",
		"required_key_id":"string","required_terminal_id":"string","required_access_code_id":"string","required_digital_key_id":"string","lock_type":"string","linked_terminal_id":"string","required_manipulator_level":"int","has_connector_jack":"bool","required_connector_level":"int","required_processor_level":"int",
		"door_type":"string","material":"string","covering":"string","visual_style":"string","door_class":"int","power_type":"string","control_type":"string","power_behavior":"string","allowed_states":"array_string",
		"terminal_type":"string","controlled_target_type":"string","terminal_class":"int","status":"string","allowed_statuses":"array_string","linked_object_ids":"array_string","linked_door_ids":"array_string","linked_cooling_ids":"array_string","linked_platform_ids":"array_string","linked_power_ids":"array_string","linked_lighting_ids":"array_string","chain_input_ids":"array_string","chain_output_ids":"array_string",
		"control_source_id":"string","connected_device_ids":"array_string","target_door_id":"string","target_platform_id":"string","requires_external_control":"bool","requires_terminal_enabled":"bool",
		"requires_external_power":"bool","current_heat":"int","working_heat":"int","overheat_threshold":"int","power_source_class":"int","source_class":"int","outlet_capacity":"int","active_output_index":"int",
		"item_class":"string","storage_route":"string","item_type":"string","digital_state":"string","key_kind":"string","key_type":"string","display_name":"string","description":"string","custom_description":"string","linked_door_id":"string","payload_id":"string","access_code":"string","damaged":"bool",
		"power_mode":"string","power_source_id":"string","control_mode":"string","control_terminal_id":"string","access_type":"string","access_terminal_id":"string","access_code_value":"string","stored_key_ids":"array_string","route_surface":"string","cable_install_mode":"string","install_mode":"string","cable_health_state":"string","health_state":"string","physical_connection_source_id":"string","input_wire_id":"string","input_direction":"string","output_1_wire_id":"string","output_2_wire_id":"string","output_3_wire_id":"string","output_1_direction":"string","output_2_direction":"string","output_3_direction":"string","brightness":"string","color":"string","mount":"string","switch_state":"string","fuse_present":"bool","variant":"string",
		"platform_mode":"string","platform_level":"int","max_level":"int","mechanism_id":"string","mechanism_role":"string","activation_mode":"string","activation_delay_turns":"int","control_cell_x":"int","control_cell_y":"int"
	}

func get_map_constructor_archetype_property_schema(entity_kind: String, entity_id: String) -> Array[Dictionary]:
	var entity_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		return []
	var data: Dictionary = _safe_dictionary(entity_info.get("data", {}))
	return WorldObjectCatalogRef.get_archetype_property_schema(str(data.get("archetype_id", "")))

func get_map_constructor_editable_fields_for_entity(entity_id: String, entity_kind: String = "") -> Array[Dictionary]:
	var fields: Array[Dictionary] = []
	var resolved_kind: String = entity_kind.strip_edges()
	if resolved_kind.is_empty():
		var world_entity: Dictionary = get_map_constructor_entity_by_id("world_object", entity_id)
		if bool(world_entity.get("ok", false)):
			resolved_kind = "world_object"
		else:
			resolved_kind = "item"
	var entity_info: Dictionary = get_map_constructor_entity_by_id(resolved_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		return fields
	var data: Dictionary = _safe_dictionary(entity_info.get("data", {}))
	var schema: Dictionary = _get_map_constructor_editable_field_schema()
	for field_name_variant in schema.keys():
		var field_name: String = str(field_name_variant)
		var value: Variant = data.get(field_name, get_default_map_constructor_field_value(field_name, resolved_kind, data))
		if value == null:
			continue
		fields.append({"name": field_name, "type": str(schema[field_name]), "value": value})
	return fields

func _convert_map_constructor_field_value(field_name: String, raw_value: Variant, target_type: String) -> Dictionary:
	if target_type == "bool":
		if typeof(raw_value) == TYPE_BOOL:
			return {"ok": true, "value": raw_value}
		var lower_text: String = str(raw_value).strip_edges().to_lower()
		if lower_text in ["1", "true", "yes", "on"]:
			return {"ok": true, "value": true}
		if lower_text in ["0", "false", "no", "off", ""]:
			return {"ok": true, "value": false}
		return {"ok": false, "message": "Invalid bool for %s." % field_name}
	if target_type == "int":
		if typeof(raw_value) == TYPE_INT:
			return {"ok": true, "value": int(raw_value)}
		var number_text: String = str(raw_value).strip_edges()
		if number_text.is_empty():
			number_text = "0"
		if not number_text.is_valid_int():
			return {"ok": false, "message": "Invalid int for %s." % field_name}
		return {"ok": true, "value": int(number_text)}
	if target_type == "array_string":
		var values: Array[String] = []
		var seen: Dictionary = {}
		if raw_value is Array:
			for value_variant in Array(raw_value):
				var entry: String = str(value_variant).strip_edges()
				if entry.is_empty() or seen.has(entry):
					continue
				seen[entry] = true
				values.append(entry)
		else:
			for value_text in str(raw_value).split(",", false):
				var entry: String = str(value_text).strip_edges()
				if entry.is_empty() or seen.has(entry):
					continue
				seen[entry] = true
				values.append(entry)
		return {"ok": true, "value": values}
	return {"ok": true, "value": str(raw_value)}

func apply_map_constructor_property_update(entity_kind: String, entity_id: String, field_name: String, raw_value: Variant) -> Dictionary:
	return _ensure_map_constructor_service().apply_map_constructor_property_update(entity_kind, entity_id, field_name, raw_value)

func _map_constructor_is_item_like_world_object(object_data: Dictionary) -> bool:
	var object_group: String = str(object_data.get("object_group", "")).to_lower()
	var object_type: String = str(object_data.get("object_type", "")).to_lower()
	return object_group == "item" or object_type.contains("key") or object_type.contains("access_code")

func get_platform_config_for_object(object_id: String) -> Dictionary:
	var object_data: Dictionary = get_world_object_by_id(object_id.strip_edges())
	if object_data.is_empty() or not PlatformTypesRef.is_platform_data(object_data):
		return {"ok": false, "object_id": object_id, "platform_data": {}, "message": "Platform not found."}
	return {"ok": true, "object_id": object_id, "platform_data": PlatformTypesRef.normalize_platform_config(object_data)}

func set_platform_config_field(object_id: String, field: String, value: Variant) -> Dictionary:
	var config: Dictionary = get_platform_config_for_object(object_id)
	if not bool(config.get("ok", false)):
		return config
	return apply_map_constructor_property_update("world_object", object_id, field, value)

func get_platform_mechanism_summary(mechanism_id: String) -> Dictionary:
	return PlatformMechanismServiceRef.get_mechanism_summary(mechanism_id, mission_world_objects)

func validate_platform_mechanism(mechanism_id: String) -> Dictionary:
	return PlatformMechanismServiceRef.validate_mechanism(mechanism_id, mission_world_objects)

func get_platform_control_actions(object_id: String) -> Dictionary:
	var config: Dictionary = get_platform_config_for_object(object_id)
	if not bool(config.get("ok", false)):
		return {"ok": false, "object_id": object_id, "actions": [], "message": "Platform not found."}
	var platform_data: Dictionary = Dictionary(config.get("platform_data", {}))
	return {"ok": true, "object_id": object_id, "actions": PlatformControlServiceRef.get_action_labels(platform_data), "schedule": PlatformControlServiceRef.get_activation_schedule_metadata(platform_data)}

func get_platform_visual_descriptor_for_object(object_id: String) -> Dictionary:
	var config: Dictionary = get_platform_config_for_object(object_id)
	if not bool(config.get("ok", false)):
		return {"ok": false, "object_id": object_id}
	var descriptor: Dictionary = PlatformVisualServiceRef.get_platform_draw_descriptor(Dictionary(config.get("platform_data", {})))
	descriptor["object_id"] = object_id
	return descriptor

func preview_platform_motion_for_object(object_id: String, action_id: String) -> Dictionary:
	var config: Dictionary = get_platform_config_for_object(object_id)
	if not bool(config.get("ok", false)):
		return {"ok": false, "object_id": object_id, "message": "Platform not found."}
	return PlatformMotionServiceRef.preview_level_after_action(Dictionary(config.get("platform_data", {})), action_id)

func preview_platform_rotation_for_object(object_id: String, action_id: String) -> Dictionary:
	var config: Dictionary = get_platform_config_for_object(object_id)
	if not bool(config.get("ok", false)):
		return {"ok": false, "object_id": object_id, "message": "Platform not found."}
	return {"ok": true, "object_id": object_id, "rotation_delta": PlatformRotationServiceRef.get_rotation_delta(action_id)}

func preview_room_visual_preset(preset_id: String, options: Dictionary = {}) -> Dictionary:
	var scope: String = str(options.get("scope", "task_test_room")).strip_edges()
	var result: Dictionary = {"ok": false, "preset_id": preset_id, "scope": scope, "affected_walls": [], "affected_doors": [], "affected_terminals": [], "affected_floors": [], "summary": {}, "can_apply": false, "message": "Preview failed."}
	if not _is_task_test_constructor_context():
		result["message"] = "Room visual presets are available only in TASK TEST constructor mode."
		return result
	if scope == "selected_area":
		result["message"] = "Selected area preview is not available yet."
		return result
	if scope != "task_test_room":
		result["message"] = "Unsupported preview scope: %s" % scope
		return result
	var preset: Dictionary = _get_room_visual_preset_by_id(preset_id)
	if preset.is_empty():
		result["message"] = "Unknown room visual preset id: %s" % preset_id
		return result
	var material_id: String = str(preset.get("wall_material_id", "")).to_lower().strip_edges()
	var include_walls: bool = bool(options.get("include_walls", true))
	var include_doors: bool = bool(options.get("include_doors", true))
	var include_terminals: bool = bool(options.get("include_terminals", true))
	var include_floors: bool = bool(options.get("include_floors", true))
	var walls: Array[Dictionary] = []
	var doors: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	var floors: Array[Dictionary] = []
	var floor_material_id: String = _resolve_floor_material_id_for_room_visual_preset(preset)
	if grid_manager != null and grid_manager.has_method("get_width") and grid_manager.has_method("get_height") and grid_manager.has_method("get_tile"):
		var width: int = int(grid_manager.call("get_width"))
		var height: int = int(grid_manager.call("get_height"))
		for y in range(height):
			for x in range(width):
				var cell: Vector2i = Vector2i(x, y)
				var tile_type: int = int(grid_manager.call("get_tile", cell))
				if include_floors and _is_floor_like_constructor_tile(tile_type):
					var current_floor_material_id: String = str(get_map_constructor_floor_material(cell).get("override", {}).get("material_id", "concrete"))
					floors.append({"cell": cell, "current_material_id": current_floor_material_id, "new_material_id": floor_material_id})
				if include_walls and tile_type == GridManager.TILE_WALL:
					for side_row in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
						var side: String = str(side_row.get("side", ""))
						var delta: Vector2i = Vector2i(side_row.get("delta", Vector2i.ZERO))
						var floor_cell: Vector2i = cell - delta
						if not _is_valid_grid_cell(floor_cell):
							continue
						var current_material_id: String = str(get_map_constructor_wall_material(floor_cell, side).get("override", {}).get("material_id", "default_metal"))
						walls.append({"cell": floor_cell, "side": side, "current_material_id": current_material_id, "new_material_id": material_id})
	if include_doors or include_terminals:
		for object_data in mission_world_objects:
			var row: Dictionary = Dictionary(object_data)
			var object_id: String = str(row.get("id", ""))
			var object_cell: Vector2i = Vector2i(row.get("position", Vector2i(-1, -1)))
			var object_type: String = str(row.get("object_type", "")).to_lower()
			if include_doors and (object_type.contains("door") or object_type.contains("gate") or str(row.get("object_group", "")).to_lower() == "door"):
				doors.append({"object_id": object_id, "cell": object_cell, "current_visual_hint": str(Dictionary(map_constructor_door_visual_preset_overrides.get(object_id, {})).get("visual_hint", "")), "new_visual_hint": str(preset.get("door_visual_hint", ""))})
			if include_terminals and (object_type.contains("terminal") or str(row.get("object_group", "")).to_lower() == "terminal"):
				terminals.append({"object_id": object_id, "cell": object_cell, "current_visual_hint": str(Dictionary(map_constructor_terminal_visual_preset_overrides.get(object_id, {})).get("visual_hint", "")), "new_visual_hint": str(preset.get("terminal_visual_hint", ""))})
	var can_apply: bool = _is_known_map_constructor_wall_material_id(material_id) and _is_known_map_constructor_floor_material_id(floor_material_id) and (not walls.is_empty() or not doors.is_empty() or not terminals.is_empty() or not floors.is_empty())
	result["ok"] = true
	result["affected_walls"] = walls
	result["affected_doors"] = doors
	result["affected_terminals"] = terminals
	result["affected_floors"] = floors
	result["can_apply"] = can_apply
	result["summary"] = {"affected_walls": walls.size(), "affected_doors": doors.size(), "affected_terminals": terminals.size(), "affected_floors": floors.size()}
	result["message"] = "Preview ready." if can_apply else "Preview has no applicable targets or preset wall material is unknown."
	return result

func apply_room_visual_preset(preset_id: String, options: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = preview_room_visual_preset(preset_id, options)
	if not bool(preview.get("ok", false)) or not bool(preview.get("can_apply", false)):
		return {"ok": false, "preset_id": preset_id, "applied_walls": 0, "applied_doors": 0, "applied_terminals": 0, "applied_floors": 0, "message": str(preview.get("message", "Cannot apply preset."))}
	var applied_walls: int = 0
	for wall_row_variant in Array(preview.get("affected_walls", [])):
		var wall_row: Dictionary = Dictionary(wall_row_variant)
		var wall_cell: Vector2i = Vector2i(wall_row.get("cell", Vector2i(-1, -1)))
		var wall_side: String = str(wall_row.get("side", ""))
		var wall_material_id: String = str(wall_row.get("new_material_id", ""))
		var key: String = _serialize_wall_material_override_key(wall_cell, wall_side)
		_map_constructor_wall_material_overrides[key] = {"cell": wall_cell, "side": wall_side, "material_id": wall_material_id, "created_by_room_visual_preset": true, "room_visual_preset_id": str(preset_id).to_lower().strip_edges()}
		applied_walls += 1
	var applied_doors: int = 0
	for door_row_variant in Array(preview.get("affected_doors", [])):
		var door_row: Dictionary = Dictionary(door_row_variant)
		var door_object_id: String = str(door_row.get("object_id", ""))
		if door_object_id.is_empty():
			continue
		map_constructor_door_visual_preset_overrides[door_object_id] = {"preset_id": str(preset_id).to_lower().strip_edges(), "visual_hint": str(door_row.get("new_visual_hint", "")), "created_by_room_visual_preset": true}
		applied_doors += 1
	var applied_terminals: int = 0
	for terminal_row_variant in Array(preview.get("affected_terminals", [])):
		var terminal_row: Dictionary = Dictionary(terminal_row_variant)
		var terminal_object_id: String = str(terminal_row.get("object_id", ""))
		if terminal_object_id.is_empty():
			continue
		map_constructor_terminal_visual_preset_overrides[terminal_object_id] = {"preset_id": str(preset_id).to_lower().strip_edges(), "visual_hint": str(terminal_row.get("new_visual_hint", "")), "created_by_room_visual_preset": true}
		applied_terminals += 1
	var applied_floors: int = 0
	for floor_row_variant in Array(preview.get("affected_floors", [])):
		var floor_row: Dictionary = Dictionary(floor_row_variant)
		var floor_cell: Vector2i = Vector2i(floor_row.get("cell", Vector2i(-1, -1)))
		var floor_material_id: String = str(floor_row.get("new_material_id", "default_floor"))
		var floor_result: Dictionary = set_map_constructor_floor_material(floor_cell, floor_material_id)
		if bool(floor_result.get("ok", false)):
			var floor_key: String = _serialize_cell_key(floor_cell)
			var floor_override: Dictionary = Dictionary(_map_constructor_floor_material_overrides.get(floor_key, {}))
			floor_override["created_by_room_visual_preset"] = true
			floor_override["room_visual_preset_id"] = str(preset_id).to_lower().strip_edges()
			_map_constructor_floor_material_overrides[floor_key] = floor_override
			applied_floors += 1
	return {"ok": true, "preset_id": preset_id, "applied_walls": applied_walls, "applied_doors": applied_doors, "applied_terminals": applied_terminals, "applied_floors": applied_floors, "message": "Room visual preset applied (runtime-only)."}

func clear_room_visual_preset_overrides(_options: Dictionary = {}) -> Dictionary:
	var cleared_walls: int = 0
	var wall_keys: Array = _map_constructor_wall_material_overrides.keys()
	for key_variant in wall_keys:
		var key: String = str(key_variant)
		var row: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(key, {}))
		if bool(row.get("created_by_room_visual_preset", false)):
			_map_constructor_wall_material_overrides.erase(key)
			cleared_walls += 1
	var cleared_floors: int = 0
	for floor_key_variant in _map_constructor_floor_material_overrides.keys():
		var floor_key: String = str(floor_key_variant)
		var floor_row: Dictionary = Dictionary(_map_constructor_floor_material_overrides.get(floor_key, {}))
		if bool(floor_row.get("created_by_room_visual_preset", false)):
			_map_constructor_floor_material_overrides.erase(floor_key)
			_clear_map_constructor_floor_visual_state(_deserialize_cell_key(floor_key))
			cleared_floors += 1
	var cleared_doors: int = map_constructor_door_visual_preset_overrides.size()
	var cleared_terminals: int = map_constructor_terminal_visual_preset_overrides.size()
	map_constructor_door_visual_preset_overrides.clear()
	map_constructor_terminal_visual_preset_overrides.clear()
	return {"ok": true, "cleared_walls": cleared_walls, "cleared_floors": cleared_floors, "cleared_doors": cleared_doors, "cleared_terminals": cleared_terminals, "message": "Room visual preset overrides cleared."}

func _map_constructor_make_link_target(target_id: String, label: String, target_kind: String, target_cell: Vector2i, status: String, reason: String) -> Dictionary:
	return {"id": target_id, "label": label, "kind": target_kind, "cell": target_cell, "status": status, "reason": reason}

func _map_constructor_add_none_target(targets: Array[Dictionary]) -> void:
	targets.append(_map_constructor_make_link_target("__none__", "<clear>", "none", Vector2i(-1, -1), "warning", "clear_value"))

func _map_constructor_token_is_key(value: String) -> bool:
	var token: String = value.strip_edges().to_lower()
	return token == "key" or token.begins_with("key_") or token.ends_with("_key") or token.contains("_key_") or token == "access_key" or token == "physical_key" or token == "digital_key"

func _map_constructor_metadata_says_key(data: Dictionary) -> bool:
	for field_name in ["prefab", "prefab_id", "category", "item_category", "metadata_category", "object_group", "item_group", "kind", "role"]:
		if _map_constructor_token_is_key(str(data.get(field_name, ""))):
			return true
	return false

func _map_constructor_is_door_data(data: Dictionary) -> bool:
	for field_name in ["object_type", "category", "object_group", "group", "prefab", "prefab_id", "metadata_category", "kind", "role"]:
		var token: String = str(data.get(field_name, "")).strip_edges().to_lower()
		if token in ["door", "gate", "locked_door", "mechanical_door", "digital_door", "powered_gate", "security_door", "blast_door", "airlock_door"]:
			return true
		if token.begins_with("door_") or token.ends_with("_door") or token.contains("_door_") or token.begins_with("gate_") or token.ends_with("_gate") or token.contains("_gate_"):
			return true
	var id_token: String = str(data.get("id", "")).strip_edges().to_lower()
	return id_token.contains("door") or id_token.contains("gate")

func _map_constructor_is_key_data(data: Dictionary) -> bool:
	if str(data.get("item_type", "")).strip_edges().to_lower() == "key":
		return true
	if not str(data.get("key_type", "")).strip_edges().is_empty() or not str(data.get("key_kind", "")).strip_edges().is_empty():
		return true
	if _map_constructor_metadata_says_key(data):
		return true
	var id_token: String = str(data.get("id", "")).strip_edges().to_lower()
	return _map_constructor_token_is_key(id_token)

func _format_world_item_reference_label(item_data: Dictionary, fallback_id: String, location: String) -> String:
	var label: String = str(item_data.get("display_name", item_data.get("name", fallback_id))).strip_edges()
	if label.is_empty():
		label = fallback_id
	if location == "inventory":
		return "%s (in inventory)" % label
	if location == "terminal":
		return "%s (in terminal)" % label
	return label

func resolve_world_item_reference(item_id: String) -> Dictionary:
	var normalized_id: String = item_id.strip_edges()
	var missing_result: Dictionary = {"exists": false, "ok": false, "location": "missing", "entity_kind": "item", "id": normalized_id, "cell": Vector2i(-1, -1), "item_data": {}, "data": {}, "label": _format_world_item_reference_label({}, normalized_id, "missing")}
	if normalized_id.is_empty():
		missing_result["label"] = ""
		return missing_result

	for cell_variant in cell_items.keys():
		var cell: Vector2i = _deserialize_cell_variant(cell_variant)
		for item_variant in _safe_array(cell_items.get(cell_variant, [])):
			var item_data: Dictionary = _safe_dictionary(item_variant)
			if str(item_data.get("id", "")).strip_edges() == normalized_id:
				return {"exists": true, "ok": true, "location": "map", "entity_kind": "item", "id": normalized_id, "cell": cell, "item_data": item_data, "data": item_data, "label": _format_world_item_reference_label(item_data, normalized_id, "map")}

	for object_variant in mission_world_objects:
		var world_data: Dictionary = _safe_dictionary(object_variant)
		if str(world_data.get("id", "")).strip_edges() != normalized_id:
			continue
		if _map_constructor_is_item_like_world_object(world_data):
			var world_cell: Vector2i = _deserialize_cell_variant(world_data.get("position", Vector2i(-1, -1)))
			return {"exists": true, "ok": true, "location": "map", "entity_kind": "world_object", "id": normalized_id, "cell": world_cell, "item_data": world_data, "data": world_data, "label": _format_world_item_reference_label(world_data, normalized_id, "map")}
		return {"exists": true, "ok": false, "reason": "not_item", "location": "map", "entity_kind": "world_object", "id": normalized_id, "cell": _deserialize_cell_variant(world_data.get("position", Vector2i(-1, -1))), "item_data": world_data, "data": world_data, "label": _format_world_item_reference_label(world_data, normalized_id, "map")}

	var runtime_map: Dictionary = _safe_dictionary(runtime_inventory_state.get("world_item_runtime", {}))
	var runtime_entry: Dictionary = _safe_dictionary(runtime_map.get(normalized_id, {}))
	var runtime_item_data: Dictionary = _safe_dictionary(runtime_entry.get("item_data", runtime_entry))
	if not runtime_item_data.is_empty():
		var runtime_location: String = str(runtime_entry.get("location", runtime_item_data.get("location", "inventory"))).strip_edges().to_lower()
		if runtime_location.is_empty() or runtime_location == "picked_up":
			runtime_location = "inventory"
		if runtime_location != "terminal":
			runtime_location = "inventory"
		return {"exists": true, "ok": true, "location": runtime_location, "entity_kind": "item", "id": normalized_id, "cell": _deserialize_cell_variant(runtime_item_data.get("position", Vector2i(-1, -1))), "item_data": runtime_item_data, "data": runtime_item_data, "label": _format_world_item_reference_label(runtime_item_data, normalized_id, runtime_location)}

	if has_collected_key(normalized_id):
		var collected_data: Dictionary = {"id": normalized_id, "item_type": "collected_key", "key_kind": "runtime_inventory"}
		return {"exists": true, "ok": true, "location": "inventory", "entity_kind": "item", "id": normalized_id, "cell": Vector2i(-1, -1), "item_data": collected_data, "data": collected_data, "label": _format_world_item_reference_label(collected_data, normalized_id, "inventory")}

	for terminal_variant in mission_world_objects:
		var terminal_data: Dictionary = _safe_dictionary(terminal_variant)
		var object_group: String = str(terminal_data.get("object_group", "")).strip_edges().to_lower()
		var object_type: String = str(terminal_data.get("object_type", "")).strip_edges().to_lower()
		if object_group != "terminal" and not object_type.contains("terminal"):
			continue
		var terminal_has_id: bool = false
		for field_name in ["stored_key_ids", "stored_access_ids", "stored_item_ids", "digital_key_ids", "access_code_ids"]:
			if _safe_array(terminal_data.get(field_name, [])).has(normalized_id):
				terminal_has_id = true
				break
		if not terminal_has_id:
			for field_name in ["stored_key_id", "access_key_id", "download_record_id"]:
				if str(terminal_data.get(field_name, "")).strip_edges() == normalized_id:
					terminal_has_id = true
					break
		if terminal_has_id:
			var terminal_item_data: Dictionary = {"id": normalized_id, "item_type": "terminal_stored_key", "key_kind": "digital", "terminal_id": str(terminal_data.get("id", "")).strip_edges()}
			return {"exists": true, "ok": true, "location": "terminal", "entity_kind": "item", "id": normalized_id, "cell": _deserialize_cell_variant(terminal_data.get("position", Vector2i(-1, -1))), "item_data": terminal_item_data, "data": terminal_item_data, "label": _format_world_item_reference_label(terminal_item_data, normalized_id, "terminal")}

	return missing_result

func find_map_constructor_key_item_by_id(key_id: String) -> Dictionary:
	var resolved: Dictionary = resolve_world_item_reference(key_id)
	if not bool(resolved.get("ok", false)):
		if bool(resolved.get("exists", false)):
			var existing_not_key: Dictionary = resolved.duplicate(true)
			existing_not_key["ok"] = false
			existing_not_key["reason"] = "not_key"
			return existing_not_key
		return resolved
	var item_data: Dictionary = _safe_dictionary(resolved.get("item_data", resolved.get("data", {})))
	if not _map_constructor_is_key_data(item_data):
		var not_key_result: Dictionary = resolved.duplicate(true)
		not_key_result["ok"] = false
		not_key_result["reason"] = "not_key"
		return not_key_result
	return resolved

func _map_constructor_get_linked_key_for_door(door_id: String) -> String:
	var normalized_door_id: String = door_id.strip_edges()
	if normalized_door_id.is_empty():
		return ""
	var door_entity: Dictionary = get_map_constructor_entity_by_id("world_object", normalized_door_id)
	if bool(door_entity.get("ok", false)):
		var door_data: Dictionary = _safe_dictionary(door_entity.get("data", {}))
		var required_key_id: String = str(door_data.get("required_key_id", "")).strip_edges()
		if not required_key_id.is_empty() and bool(find_map_constructor_key_item_by_id(required_key_id).get("ok", false)):
			return required_key_id
	for cell_variant in cell_items.keys():
		for item_variant in _safe_array(cell_items.get(cell_variant, [])):
			var item_data: Dictionary = _safe_dictionary(item_variant)
			if item_data.is_empty() or not _map_constructor_is_key_data(item_data):
				continue
			if str(item_data.get("linked_door_id", "")).strip_edges() == normalized_door_id:
				return str(item_data.get("id", "")).strip_edges()
	for object_variant in mission_world_objects:
		var world_data: Dictionary = _safe_dictionary(object_variant)
		if world_data.is_empty() or not _map_constructor_is_item_like_world_object(world_data) or not _map_constructor_is_key_data(world_data):
			continue
		if str(world_data.get("linked_door_id", "")).strip_edges() == normalized_door_id:
			return str(world_data.get("id", "")).strip_edges()
	return ""

func _map_constructor_format_door_link_label(door_data: Dictionary, door_cell: Vector2i) -> String:
	var door_id: String = str(door_data.get("id", "")).strip_edges()
	var display_name: String = str(door_data.get("display_name", door_data.get("name", ""))).strip_edges()
	if display_name.is_empty():
		display_name = "Door"
	return "%s — %s at (%d, %d)" % [display_name, door_id, door_cell.x, door_cell.y]

func get_map_constructor_key_door_link_candidates(entity_kind: String, entity_id: String) -> Dictionary:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "doors": [], "message": "Key item not found."}
	var data: Dictionary = _safe_dictionary(entity.get("data", {}))
	if not _map_constructor_is_key_data(data):
		return {"ok": false, "doors": [], "message": "Selected item is not a key."}
	var current_door_id: String = str(data.get("linked_door_id", "")).strip_edges()
	var key_kind: String = str(data.get("key_type", data.get("key_kind", data.get("item_type", "")))).strip_edges().to_lower()
	var all_door_count: int = 0
	var doors: Array[Dictionary] = []
	for object_variant in mission_world_objects:
		if not (object_variant is Dictionary):
			continue
		var door_data: Dictionary = _safe_dictionary(object_variant)
		if not _map_constructor_is_door_data(door_data):
			continue
		all_door_count += 1
		var door_id: String = str(door_data.get("id", "")).strip_edges()
		if door_id.is_empty():
			continue
		var access_type: String = WorldObjectCatalogRef.normalize_access_type(door_data.get("access_type", door_data.get("lock_type", "")))
		var key_access_type: String = WorldObjectCatalogRef.normalize_access_type(key_kind)
		if not key_kind.is_empty() and access_type != WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY and access_type != key_access_type:
			continue
		var linked_key_id: String = _map_constructor_get_linked_key_for_door(door_id)
		if not linked_key_id.is_empty() and linked_key_id != entity_id and door_id != current_door_id:
			continue
		var door_cell: Vector2i = Vector2i(door_data.get("position", Vector2i(-1, -1)))
		doors.append({"id": door_id, "label": _map_constructor_format_door_link_label(door_data, door_cell), "cell": door_cell, "current": door_id == current_door_id})
	var message: String = "Door candidates ready."
	if all_door_count <= 0:
		message = "No compatible doors placed on the map."
	elif doors.is_empty():
		message = "No unlinked compatible doors available."
	return {"ok": true, "doors": doors, "message": message, "current_door_id": current_door_id}

func get_map_constructor_link_targets_for_field(entity_kind: String, entity_id: String, field_name: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "field_name": field_name, "targets": [], "message": "Unsupported field."}
	var supported_fields: Array[String] = [
		"required_key_id", "linked_terminal_id", "target_door_id", "target_platform_id",
		"control_source_id", "connected_device_ids", "power_network_id", "power_source_id", "control_terminal_id", "access_terminal_id"
	]
	if not supported_fields.has(field_name):
		return result
	var targets: Array[Dictionary] = []
	var entity_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	var current_cell: Vector2i = Vector2i(entity_info.get("cell", Vector2i(-1, -1)))
	if field_name == "required_key_id":
		var ranked_items: Array[Dictionary] = []
		var other_items: Array[Dictionary] = []
		var seen_key_ids: Dictionary = {}
		for cell_variant in cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			for item_variant in Array(cell_items.get(cell_variant, [])):
				if typeof(item_variant) != TYPE_DICTIONARY:
					continue
				var item_data: Dictionary = _safe_dictionary(item_variant)
				var item_id: String = str(item_data.get("id", "")).strip_edges()
				if item_id.is_empty() or seen_key_ids.has(item_id):
					continue
				if not _map_constructor_is_key_data(item_data):
					continue
				seen_key_ids[item_id] = true
				var item_type: String = str(item_data.get("item_type", item_data.get("object_type", ""))).to_lower()
				var target: Dictionary = _map_constructor_make_link_target(item_id, item_id, "item", cell, "valid", "key_item")
				if item_type in ["key", "mechanical_keycard", "digital_key", "access_code"] or not str(item_data.get("key_type", item_data.get("key_kind", ""))).strip_edges().is_empty():
					ranked_items.append(target)
				else:
					other_items.append(target)
		for object_data in mission_world_objects:
			if typeof(object_data) != TYPE_DICTIONARY:
				continue
			var world_data: Dictionary = _safe_dictionary(object_data)
			if not _map_constructor_is_item_like_world_object(world_data):
				continue
			var world_id: String = str(world_data.get("id", "")).strip_edges()
			if world_id.is_empty() or seen_key_ids.has(world_id):
				continue
			seen_key_ids[world_id] = true
			var world_cell: Vector2i = Vector2i(world_data.get("position", Vector2i(-1, -1)))
			targets.append(_map_constructor_make_link_target(world_id, world_id, "world_object", world_cell, "valid", "item_like_object"))
		for collected_key_variant in Array(runtime_inventory_state.get("collected_key_ids", [])):
			var collected_key_id: String = str(collected_key_variant).strip_edges()
			if collected_key_id.is_empty() or seen_key_ids.has(collected_key_id):
				continue
			seen_key_ids[collected_key_id] = true
			ranked_items.append(_map_constructor_make_link_target(collected_key_id, "%s (inventory)" % collected_key_id, "item", Vector2i(-1, -1), "valid", "runtime_inventory_key"))
		ranked_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ac: Vector2i = Vector2i(a.get("cell", Vector2i.ZERO))
			var bc: Vector2i = Vector2i(b.get("cell", Vector2i.ZERO))
			var al: String = "%s|%04d|%04d|%s" % [str(a.get("label", "")), ac.y, ac.x, str(a.get("id", ""))]
			var bl: String = "%s|%04d|%04d|%s" % [str(b.get("label", "")), bc.y, bc.x, str(b.get("id", ""))]
			return al < bl
		)
		other_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ac: Vector2i = Vector2i(a.get("cell", Vector2i.ZERO))
			var bc: Vector2i = Vector2i(b.get("cell", Vector2i.ZERO))
			var al: String = "%s|%04d|%04d|%s" % [str(a.get("label", "")), ac.y, ac.x, str(a.get("id", ""))]
			var bl: String = "%s|%04d|%04d|%s" % [str(b.get("label", "")), bc.y, bc.x, str(b.get("id", ""))]
			return al < bl
		)
		targets.append_array(ranked_items)
		targets.append_array(other_items)
	elif field_name == "linked_terminal_id" or field_name == "control_terminal_id" or field_name == "access_terminal_id":
		for object_data in mission_world_objects:
			var data: Dictionary = _safe_dictionary(object_data)
			var object_type: String = str(data.get("object_type", "")).to_lower()
			var group_text: String = str(data.get("object_group", data.get("group", ""))).to_lower()
			if object_type.contains("terminal") or group_text.contains("terminal"):
				targets.append(_map_constructor_make_link_target(str(data.get("id", "")), str(data.get("id", "")), "world_object", Vector2i(data.get("position", Vector2i(-1, -1))), "valid", "terminal_candidate"))
	elif field_name == "target_door_id":
		for object_data in mission_world_objects:
			var data_door: Dictionary = _safe_dictionary(object_data)
			if _map_constructor_is_door_data(data_door) and _map_constructor_door_uses_external_terminal_control(data_door):
				targets.append(_map_constructor_make_link_target(str(data_door.get("id", "")), str(data_door.get("id", "")), "world_object", Vector2i(data_door.get("position", Vector2i(-1, -1))), "valid", "door_candidate"))
	elif field_name == "target_platform_id":
		for object_data in mission_world_objects:
			var data_platform: Dictionary = _safe_dictionary(object_data)
			var type_platform: String = str(data_platform.get("object_type", "")).to_lower()
			if type_platform.contains("platform") or data_platform.has("platform_id"):
				targets.append(_map_constructor_make_link_target(str(data_platform.get("id", "")), str(data_platform.get("id", "")), "world_object", Vector2i(data_platform.get("position", Vector2i(-1, -1))), "valid", "platform_candidate"))
	elif field_name == "control_source_id":
		for object_data in mission_world_objects:
			var data_control: Dictionary = _safe_dictionary(object_data)
			var control_id: String = str(data_control.get("id", ""))
			var type_control: String = str(data_control.get("object_type", "")).to_lower()
			if type_control.contains("switch") or type_control.contains("terminal") or type_control.contains("control") or control_id.contains("task_test_switch"):
				targets.append(_map_constructor_make_link_target(control_id, control_id, "world_object", Vector2i(data_control.get("position", Vector2i(-1, -1))), "valid", "control_candidate"))
	elif field_name == "connected_device_ids":
		for object_data in mission_world_objects:
			var data_connected: Dictionary = _safe_dictionary(object_data)
			var connected_id: String = str(data_connected.get("id", "")).strip_edges()
			if connected_id.is_empty() or connected_id == entity_id:
				continue
			var group_connected: String = str(data_connected.get("object_group", "")).to_lower()
			if group_connected == "item":
				continue
			targets.append(_map_constructor_make_link_target(connected_id, connected_id, "world_object", Vector2i(data_connected.get("position", Vector2i(-1, -1))), "valid", "device_candidate"))
	elif field_name == "power_source_id":
		for object_data in mission_world_objects:
			var source_data: Dictionary = _safe_dictionary(object_data)
			var source_id: String = str(source_data.get("id", "")).strip_edges()
			var source_type: String = str(source_data.get("object_type", "")).to_lower()
			if source_id.is_empty() or source_id == entity_id or not source_type.begins_with("power_source"):
				continue
			targets.append(_map_constructor_make_link_target(source_id, source_id, "world_object", Vector2i(source_data.get("position", Vector2i(-1, -1))), "valid", "power_source"))
	elif field_name == "power_network_id":
		targets.append_array(get_power_network_options())
	_map_constructor_add_none_target(targets)
	result["ok"] = true
	result["targets"] = targets
	result["message"] = "Targets ready for %s at %s." % [field_name, str(current_cell)]
	return result

func get_power_source_network_id(source_obj: Dictionary) -> String:
	var existing_network_id: String = str(source_obj.get("power_network_id", "")).strip_edges()
	if not existing_network_id.is_empty():
		return existing_network_id
	var source_id: String = str(source_obj.get("id", "power_source")).strip_edges()
	return "%s_net" % source_id if not source_id.is_empty() else "power_source_net"

func ensure_power_source_network_id(source_obj: Dictionary) -> String:
	var network_id: String = get_power_source_network_id(source_obj)
	if str(source_obj.get("power_network_id", "")).strip_edges().is_empty():
		source_obj["power_network_id"] = network_id
	return network_id

func get_power_network_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var seen_networks: Dictionary = {}
	var main_network_id: String = "main_power_net"
	seen_networks[main_network_id] = true
	options.append(_map_constructor_make_link_target(main_network_id, main_network_id, "power_network", Vector2i(-1, -1), "valid", "virtual_network"))
	for object_data in mission_world_objects:
		var source_data: Dictionary = _safe_dictionary(object_data)
		if not str(source_data.get("object_type", "")).strip_edges().to_lower().begins_with("power_source"):
			continue
		var network_id: String = get_power_source_network_id(source_data)
		if network_id.is_empty() or seen_networks.has(network_id):
			continue
		seen_networks[network_id] = true
		options.append(_map_constructor_make_link_target(network_id, network_id, "power_network", Vector2i(-1, -1), "valid", "source_owned_network"))
	# Retain legacy network ids only when existing objects still use them.
	for object_data in mission_world_objects:
		var legacy_network_id: String = str(Dictionary(object_data).get("power_network_id", "")).strip_edges()
		if legacy_network_id.is_empty() or seen_networks.has(legacy_network_id):
			continue
		seen_networks[legacy_network_id] = true
		options.append(_map_constructor_make_link_target(legacy_network_id, legacy_network_id, "power_network", Vector2i(-1, -1), "valid", "legacy_network"))
	return options

func _map_constructor_door_uses_external_terminal_control(door_data: Dictionary) -> bool:
	var control_type: String = str(door_data.get("control_type", door_data.get("control_mode", "internal"))).strip_edges().to_lower()
	return control_type in ["external", "terminal", "external_control", "external control"]

func _map_constructor_set_terminal_door_link(terminal_id: String, door_id: String) -> Dictionary:
	var terminal_data: Dictionary = get_world_object_by_id(terminal_id)
	if terminal_data.is_empty():
		return {"ok": false, "message": "Linked terminal not found."}
	if not door_id.is_empty():
		var requested_door: Dictionary = get_world_object_by_id(door_id)
		if requested_door.is_empty():
			return {"ok": false, "message": "Linked door not found."}
		if not _map_constructor_door_uses_external_terminal_control(requested_door):
			return {"ok": false, "message": "Door must use external terminal control before linking."}
	var old_door_ids: Array[String] = []
	for old_id_variant in Array(terminal_data.get("linked_door_ids", [])):
		var old_id: String = str(old_id_variant).strip_edges()
		if not old_id.is_empty() and not old_door_ids.has(old_id):
			old_door_ids.append(old_id)
	var old_target_door_id: String = str(terminal_data.get("target_door_id", "")).strip_edges()
	if not old_target_door_id.is_empty() and not old_door_ids.has(old_target_door_id):
		old_door_ids.append(old_target_door_id)
	for old_door_id in old_door_ids:
		if old_door_id == door_id:
			continue
		var old_door: Dictionary = get_world_object_by_id(old_door_id)
		if old_door.is_empty():
			continue
		if str(old_door.get("control_terminal_id", old_door.get("linked_terminal_id", ""))).strip_edges() == terminal_id:
			old_door["linked_terminal_id"] = ""
			old_door["required_terminal_id"] = ""
			old_door["control_terminal_id"] = ""
			old_door["control_source_id"] = ""
			update_world_object_by_id(old_door_id, old_door)
	terminal_data["target_door_id"] = door_id
	terminal_data["linked_door_ids"] = [] if door_id.is_empty() else [door_id]
	update_world_object_by_id(terminal_id, terminal_data)
	if door_id.is_empty():
		return {"ok": true, "message": "Door link cleared."}
	var door_data: Dictionary = get_world_object_by_id(door_id)
	if door_data.is_empty():
		return {"ok": false, "message": "Linked door not found."}
	var previous_terminal_id: String = str(door_data.get("control_terminal_id", door_data.get("linked_terminal_id", ""))).strip_edges()
	if not previous_terminal_id.is_empty() and previous_terminal_id != terminal_id:
		var previous_terminal: Dictionary = get_world_object_by_id(previous_terminal_id)
		if not previous_terminal.is_empty():
			previous_terminal["target_door_id"] = "" if str(previous_terminal.get("target_door_id", "")) == door_id else previous_terminal.get("target_door_id", "")
			var previous_door_ids: Array = Array(previous_terminal.get("linked_door_ids", [])).duplicate()
			previous_door_ids.erase(door_id)
			previous_terminal["linked_door_ids"] = previous_door_ids
			update_world_object_by_id(previous_terminal_id, previous_terminal)
	door_data["linked_terminal_id"] = terminal_id
	door_data["required_terminal_id"] = terminal_id
	door_data["control_terminal_id"] = terminal_id
	door_data["control_source_id"] = terminal_id
	update_world_object_by_id(door_id, door_data)
	return {"ok": true, "message": "Terminal and door link updated."}

func _map_constructor_sync_terminal_door_link(entity_id: String, field_name: String, target_id: String) -> Dictionary:
	if field_name == "target_door_id":
		return _map_constructor_set_terminal_door_link(entity_id, target_id)
	if not (field_name in ["linked_terminal_id", "control_terminal_id"]):
		return {"ok": true}
	var door_data: Dictionary = get_world_object_by_id(entity_id)
	if door_data.is_empty() or not _map_constructor_is_door_data(door_data):
		return {"ok": true}
	if not target_id.is_empty() and not _map_constructor_door_uses_external_terminal_control(door_data):
		return {"ok": false, "message": "Door must use external terminal control before linking."}
	var old_terminal_id: String = str(door_data.get("control_terminal_id", door_data.get("linked_terminal_id", ""))).strip_edges()
	if not old_terminal_id.is_empty() and old_terminal_id != target_id:
		_map_constructor_set_terminal_door_link(old_terminal_id, "")
	if target_id.is_empty():
		door_data["linked_terminal_id"] = ""
		door_data["required_terminal_id"] = ""
		door_data["control_terminal_id"] = ""
		door_data["control_source_id"] = ""
		update_world_object_by_id(entity_id, door_data)
		return {"ok": true, "message": "Terminal link cleared."}
	return _map_constructor_set_terminal_door_link(target_id, entity_id)

func apply_map_constructor_link_target(entity_kind: String, entity_id: String, field_name: String, target_id: String) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var result: Dictionary = {"ok": false, "message": "Link update failed.", "entity_id": entity_id, "field_name": field_name, "target_id": target_id}
	if field_name == "connected_device_ids":
		var entity_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		if not bool(entity_info.get("ok", false)):
			result["message"] = "Entity not found."
			return result
		var data: Dictionary = _safe_dictionary(entity_info.get("data", {}))
		var old_network_id: String = str(data.get("power_network_id", ""))
		var next_ids: Array[String] = []
		if target_id.is_empty() or target_id == "__none__":
			next_ids.clear()
		else:
			for value_variant in Array(data.get("connected_device_ids", [])):
				var existing_id: String = str(value_variant).strip_edges()
				if existing_id.is_empty() or next_ids.has(existing_id):
					continue
				next_ids.append(existing_id)
			if not next_ids.has(target_id):
				next_ids.append(target_id)
		data["connected_device_ids"] = next_ids
		if entity_kind == "world_object":
			update_world_object_by_id(entity_id, data)
		else:
			result["message"] = "connected_device_ids supports world_object only."
			return result
		PowerSystemRef.recalculate_network(mission_world_objects, old_network_id)
		PowerSystemRef.recalculate_network(mission_world_objects, str(data.get("power_network_id", "")))
		refresh_world_cooling_received()
		result["ok"] = true
		result["message"] = "Updated connected_device_ids."
		result["target_id"] = target_id
		_record_map_constructor_change("link_update", {"entity_kind":"world_object", "entity_id":entity_id, "object_type":str(data.get("object_type", "")), "cell":Vector2i(entity_info.get("cell", Vector2i(-1, -1))), "summary":"Updated connected_device_ids on %s" % entity_id, "details":{"field":"connected_device_ids","target_id":target_id}, "undo_hint":"Can undo by editing link field."})
		return result
	var applied_target: String = target_id
	if target_id.is_empty() or target_id == "__none__":
		applied_target = ""
	if entity_kind == "world_object" and field_name in ["target_door_id", "linked_terminal_id", "control_terminal_id"]:
		var sync_result: Dictionary = _map_constructor_sync_terminal_door_link(entity_id, field_name, applied_target)
		if not bool(sync_result.get("ok", false)):
			result["message"] = str(sync_result.get("message", "Link update failed."))
			return result
	var apply_result: Dictionary = apply_map_constructor_property_update(entity_kind, entity_id, field_name, applied_target)
	result["ok"] = bool(apply_result.get("ok", false))
	result["message"] = str(apply_result.get("message", "Link update failed."))
	result["target_id"] = applied_target
	if bool(result.get("ok", false)):
		var entity_after: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		var entity_after_data: Dictionary = _safe_dictionary(entity_after.get("data", {}))
		_record_map_constructor_change("link_update", {"entity_kind":str(entity_after.get("entity_kind", entity_kind)), "entity_id":entity_id, "object_type":str(entity_after_data.get("object_type", entity_after_data.get("item_type", ""))), "cell":Vector2i(entity_after.get("cell", Vector2i(-1, -1))), "summary":"Updated %s on %s" % [field_name, entity_id], "details":{"field":field_name, "target_id":applied_target}, "undo_hint":"Can undo by setting previous link target."})
	return result

func apply_map_constructor_state_preset(entity_kind: String, entity_id: String, preset: String) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var lower_preset: String = preset.strip_edges().to_lower()
	var updates: Array[Dictionary] = []
	match lower_preset:
		"active":
			updates.append({"field":"state", "value":"active"})
			updates.append({"field":"damaged", "value":false})
		"open":
			updates.append({"field":"state", "value":"open"})
			updates.append({"field":"is_open", "value":true})
			updates.append({"field":"is_closed", "value":false})
			updates.append({"field":"is_locked", "value":false})
		"closed":
			updates.append({"field":"state", "value":"closed"})
			updates.append({"field":"is_open", "value":false})
			updates.append({"field":"is_closed", "value":true})
			updates.append({"field":"is_locked", "value":false})
		"locked":
			updates.append({"field":"state", "value":"locked"})
			updates.append({"field":"is_open", "value":false})
			updates.append({"field":"is_closed", "value":true})
			updates.append({"field":"is_locked", "value":true})
		"unpowered":
			updates.append({"field":"state", "value":"unpowered"})
			updates.append({"field":"is_powered", "value":false})
		"damaged":
			updates.append({"field":"state", "value":"damaged"})
			updates.append({"field":"damaged", "value":true})
		"jammed":
			updates.append({"field":"state", "value":"jammed"})
		"overheated":
			updates.append({"field":"state", "value":"overheated"})
		_:
			return {"ok": false, "message": "Unknown preset.", "entity_id": entity_id, "preset": preset}
	var resolved_kind: String = entity_kind.strip_edges()
	if resolved_kind.is_empty():
		var world_entity: Dictionary = get_map_constructor_entity_by_id("world_object", entity_id)
		if bool(world_entity.get("ok", false)):
			resolved_kind = "world_object"
		else:
			resolved_kind = "item"
	var entity_info: Dictionary = get_map_constructor_entity_by_id(resolved_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		return {"ok": false, "message": "Entity not found.", "entity_id": entity_id, "preset": preset}
	var data: Dictionary = _safe_dictionary(entity_info.get("data", {}))
	var schema: Dictionary = _get_map_constructor_editable_field_schema()
	var converted_updates: Array[Dictionary] = []
	for update_entry in updates:
		var update_field: String = str(update_entry.get("field", ""))
		if update_field.is_empty() or not schema.has(update_field):
			return {"ok": false, "message": "Preset contains unsupported field.", "entity_id": entity_id, "preset": preset}
		var field_value: Variant = data.get(update_field, get_default_map_constructor_field_value(update_field, resolved_kind, data))
		if field_value == null:
			return {"ok": false, "message": "Preset contains unsupported field.", "entity_id": entity_id, "preset": preset}
		var converted: Dictionary = _convert_map_constructor_field_value(update_field, update_entry.get("value"), str(schema[update_field]))
		if not bool(converted.get("ok", false)):
			return {"ok": false, "message": str(converted.get("message", "Invalid value.")), "entity_id": entity_id, "preset": preset}
		converted_updates.append({"field": update_field, "value": converted.get("value")})
	var old_network_id: String = str(data.get("power_network_id", ""))
	for converted_entry in converted_updates:
		data[str(converted_entry.get("field", ""))] = converted_entry.get("value")
	if resolved_kind == "world_object":
		update_world_object_by_id(entity_id, data)
	elif resolved_kind == "item":
		var updated_item: bool = false
		for cell_variant in cell_items.keys():
			var cell: Vector2i = Vector2i(cell_variant)
			var items: Array[Dictionary] = get_items_at_cell(cell)
			for index in range(items.size()):
				var item_data: Dictionary = items[index]
				if str(item_data.get("id", "")) != entity_id:
					continue
				items[index] = data
				cell_items[cell] = items
				updated_item = true
				break
			if updated_item:
				break
		if not updated_item:
			return {"ok": false, "message": "Item not found.", "entity_id": entity_id, "preset": preset}
	else:
		return {"ok": false, "message": "Unsupported entity kind.", "entity_id": entity_id, "preset": preset}
	var needs_power_refresh: bool = false
	for converted_entry in converted_updates:
		var changed_field: String = str(converted_entry.get("field", ""))
		if changed_field == "power_network_id" or changed_field in ["is_powered", "requires_external_power", "power_mode", "power_source_id", "current_heat", "working_heat", "overheat_threshold"]:
			needs_power_refresh = true
			break
	if needs_power_refresh:
		PowerSystemRef.recalculate_network(mission_world_objects, old_network_id)
		PowerSystemRef.recalculate_network(mission_world_objects, str(data.get("power_network_id", "")))
	refresh_world_cooling_received()
	return {"ok": true, "message": "Preset %s applied." % lower_preset, "entity_id": entity_id, "preset": lower_preset}



func _map_constructor_matches_any_token(text: String, tokens: Array[String]) -> bool:
	var lower: String = text.to_lower()
	for token in tokens:
		if lower.contains(token):
			return true
	return false

func get_map_constructor_entity_type_group(entity_kind: String, entity_id: String) -> String:
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return "generic"
	var data: Dictionary = _safe_dictionary(entity.get("data", {}))
	var object_type: String = str(data.get("object_type", data.get("item_type", ""))).to_lower()
	var object_group: String = str(data.get("object_group", data.get("group", ""))).to_lower()
	var category: String = str(data.get("category", "")).to_lower()
	var placement_mode: String = str(data.get("placement_mode", "")).to_lower()
	var prefab_id: String = str(data.get("map_constructor_prefab_id", "")).to_lower()
	var join_text: String = "%s %s %s %s %s %s" % [object_type, object_group, category, placement_mode, prefab_id, entity_id.to_lower()]
	if _map_constructor_matches_any_token(join_text, ["outer_wall","brick_wall","concrete_wall","steel_wall","grate_wall"]): return "wall"
	if _map_constructor_matches_any_token(join_text, ["door","gate"]): return "door"
	if _map_constructor_matches_any_token(join_text, ["terminal"]): return "terminal"
	if _map_constructor_matches_any_token(join_text, ["power_source","power_socket","power_cable","circuit_switch","circuit_breaker","fuse_box"]): return "power"
	if _map_constructor_matches_any_token(join_text, ["control", "platform", "fan", "switch"]): return "control"
	if entity_kind == "item" or _map_constructor_matches_any_token(join_text, ["mechanical_key","digital_key","access_code","fuse","cable","datafile"]): return "item"
	return "generic"

func get_map_constructor_door_visual_state(object_id: String) -> Dictionary:
	var normalized_id: String = object_id.strip_edges()
	var fallback: Dictionary = {"ok": false, "object_id": normalized_id, "state": "unknown", "badges": [], "tint": Color(1.0, 1.0, 1.0, 1.0), "accent": Color(0.72, 0.78, 0.86, 0.95), "message": "Object not found."}
	if normalized_id.is_empty():
		fallback["message"] = "Object id is empty."
		return fallback
	var object_data: Dictionary = get_world_object_by_id(normalized_id)
	if object_data.is_empty():
		return fallback
	var object_type: String = str(object_data.get("object_type", "")).to_lower()
	var object_group: String = str(object_data.get("object_group", "")).to_lower()
	if not object_type.contains("door") and not object_type.contains("gate") and object_group != "door":
		fallback["message"] = "Object is not a door or gate."
		return fallback
	var badges: Array[String] = []
	var state: String = "closed"
	var message: String = "Door visual state resolved."
	var raw_state: String = str(object_data.get("state", "")).to_lower()
	var is_open: bool = bool(object_data.get("is_open", object_data.get("open", object_data.get("opened", false))))
	var has_key_req: bool = not str(object_data.get("required_key_id", object_data.get("required_key", object_data.get("access_code", "")))).strip_edges().is_empty()
	var is_locked: bool = bool(object_data.get("is_locked", object_data.get("locked", false))) or has_key_req or str(object_data.get("lock_type", "")).strip_edges() != ""
	var damage_level: int = int(object_data.get("damage_level", 0))
	var is_broken: bool = bool(object_data.get("broken", false)) or bool(object_data.get("is_broken", false)) or bool(object_data.get("damaged", false)) or damage_level > 0 or raw_state in ["broken", "damaged", "jammed", "destroyed"]
	var requires_power: bool = bool(object_data.get("requires_power", object_data.get("requires_external_power", false)))
	var has_power_network: bool = not str(object_data.get("power_network_id", "")).strip_edges().is_empty()
	var has_power_flag: bool = object_data.has("is_powered") or object_data.has("powered")
	var is_powered: bool = bool(object_data.get("is_powered", object_data.get("powered", false)))
	if is_broken:
		state = "broken"
		badges.append("broken")
	elif is_open or raw_state == "open":
		state = "open"
		badges.append("open")
	elif is_locked or raw_state == "locked":
		state = "locked"
		badges.append("locked")
	elif has_power_flag or requires_power or has_power_network:
		if is_powered:
			state = "powered"
			badges.append("powered")
		else:
			state = "unpowered"
			badges.append("unpowered")
	else:
		state = "closed"
	if requires_power:
		badges.append("requires_power")
	if has_power_network:
		badges.append("power_network:%s" % str(object_data.get("power_network_id", "")))
	var control_source_id: String = str(object_data.get("control_source_id", object_data.get("linked_terminal_id", object_data.get("controller_id", "")))).strip_edges()
	if not control_source_id.is_empty():
		badges.append("linked_control:%s" % control_source_id)
	if state == "unknown":
		message = "Door state is unknown."
	var tint: Color = Color(1.0, 1.0, 1.0, 1.0)
	var accent: Color = Color(0.72, 0.78, 0.86, 0.95)
	match state:
		"open":
			tint = Color(0.86, 0.95, 1.0, 0.75)
			accent = Color(0.58, 0.9, 0.98, 0.96)
		"locked":
			tint = Color(0.96, 0.88, 0.62, 0.96)
			accent = Color(1.0, 0.78, 0.2, 0.98)
		"powered":
			tint = Color(0.76, 0.94, 1.0, 0.96)
			accent = Color(0.36, 0.92, 1.0, 0.98)
		"unpowered":
			tint = Color(0.35, 0.38, 0.43, 0.9)
			accent = Color(0.52, 0.58, 0.65, 0.92)
		"broken":
			tint = Color(0.7, 0.38, 0.34, 0.95)
			accent = Color(0.95, 0.28, 0.22, 0.98)
	var preset_override: Dictionary = Dictionary(map_constructor_door_visual_preset_overrides.get(normalized_id, {}))
	var room_visual_preset_id: String = str(preset_override.get("preset_id", "")).strip_edges()
	var room_visual_hint: String = str(preset_override.get("visual_hint", "")).strip_edges()
	var normalized_room_visual_hint: String = room_visual_hint.to_lower()
	var created_by_room_visual_preset: bool = bool(preset_override.get("created_by_room_visual_preset", false))
	if not normalized_room_visual_hint.is_empty():
		var is_hazard_hint: bool = normalized_room_visual_hint.contains("hazard") or normalized_room_visual_hint.contains("power") or normalized_room_visual_hint.contains("alert") or normalized_room_visual_hint.contains("damaged")
		var is_diag_hint: bool = normalized_room_visual_hint.contains("diag") or normalized_room_visual_hint.contains("blue") or normalized_room_visual_hint.contains("clean") or normalized_room_visual_hint.contains("cool")
		var is_security_hint: bool = normalized_room_visual_hint.contains("security") or normalized_room_visual_hint.contains("reinforced")
		var is_maintenance_hint: bool = normalized_room_visual_hint.contains("maintenance") or normalized_room_visual_hint.contains("dark") or normalized_room_visual_hint.contains("service")
		if is_hazard_hint:
			tint = _blend_color(tint, Color(0.95, 0.84, 0.38, 0.95), 0.18)
			accent = _blend_color(accent, Color(0.44, 0.9, 1.0, 0.98), 0.16)
		elif is_diag_hint:
			tint = _blend_color(tint, Color(0.7, 0.88, 1.0, 0.94), 0.18)
			accent = _blend_color(accent, Color(0.55, 0.96, 1.0, 0.98), 0.16)
		elif is_security_hint:
			tint = _blend_color(tint, Color(0.72, 0.78, 0.86, 0.95), 0.18)
			accent = _blend_color(accent, Color(0.56, 0.66, 0.78, 0.98), 0.16)
		elif is_maintenance_hint:
			tint = _blend_color(tint, Color(0.28, 0.31, 0.36, 0.95), 0.18)
			accent = _blend_color(accent, Color(0.38, 0.45, 0.54, 0.98), 0.16)
		room_visual_hint = normalized_room_visual_hint
	return {"ok": true, "object_id": normalized_id, "state": state, "badges": badges, "tint": tint, "accent": accent, "texture_asset_id": "door_state_generic", "room_visual_preset_id": room_visual_preset_id, "room_visual_hint": room_visual_hint, "created_by_room_visual_preset": created_by_room_visual_preset, "message": message}

func _blend_color(base_color: Color, overlay_color: Color, weight: float) -> Color:
	var safe_weight: float = clampf(weight, 0.0, 1.0)
	return base_color.lerp(overlay_color, safe_weight)

func get_map_constructor_terminal_visual_state(object_id: String) -> Dictionary:
	var normalized_id: String = object_id.strip_edges()
	var fallback: Dictionary = {"ok": false, "object_id": normalized_id, "terminal_type": "unknown", "state": "unknown", "badges": [], "tint": Color(1.0, 1.0, 1.0, 1.0), "accent": Color(0.78, 0.87, 0.96, 0.98), "message": "Object not found."}
	if normalized_id.is_empty():
		fallback["message"] = "Object id is empty."
		return fallback
	var object_data: Dictionary = get_world_object_by_id(normalized_id)
	if object_data.is_empty():
		return fallback
	var object_type: String = str(object_data.get("object_type", "")).to_lower()
	var object_group: String = str(object_data.get("object_group", "")).to_lower()
	if not object_type.contains("terminal") and not object_type.contains("device") and object_group != "terminal":
		fallback["message"] = "Object is not terminal/device."
		return fallback
	var terminal_type: String = "unknown"
	var normalized_terminal_type: String = str(object_data.get("terminal_type", "")).to_lower()
	var controlled_target_type: String = str(object_data.get("controlled_target_type", "none")).to_lower()
	if normalized_terminal_type == "information":
		terminal_type = "information_terminal"
	elif normalized_terminal_type == "control":
		terminal_type = "%s_terminal" % controlled_target_type if controlled_target_type != "none" else "control_terminal"
	var raw_state: String = str(object_data.get("status", object_data.get("state", "idle"))).to_lower()
	var state: String = "idle"
	var badges: Array[String] = []
	var is_broken: bool = bool(object_data.get("broken", false)) or bool(object_data.get("is_broken", false)) or bool(object_data.get("damaged", false))
	var has_error: bool = bool(object_data.get("error", false)) or bool(object_data.get("has_error", false)) or raw_state == "error"
	var scanning: bool = bool(object_data.get("scanning", false)) or bool(object_data.get("diagnostic_in_progress", false)) or raw_state == "scanning"
	var is_offline: bool = bool(object_data.get("offline", false)) or raw_state == "offline"
	var enabled: bool = bool(object_data.get("enabled", object_data.get("is_enabled", true)))
	var powered: bool = bool(object_data.get("is_powered", object_data.get("powered", true)))
	if is_broken or raw_state == "broken":
		state = "broken"
	elif has_error:
		state = "error"
	elif scanning:
		state = "scanning"
	elif is_offline:
		state = "offline"
	elif not enabled or raw_state == "disabled":
		state = "disabled"
	elif raw_state in ["active", "enabled", "hacked"] or powered:
		state = "active"
	if not powered and state == "active":
		state = "disabled"
	if terminal_type != "unknown":
		badges.append(terminal_type)
	if not str(object_data.get("target_door_id", "")).strip_edges().is_empty():
		badges.append("target_door:%s" % str(object_data.get("target_door_id", "")))
	if not str(object_data.get("target_platform_id", "")).strip_edges().is_empty():
		badges.append("target_platform:%s" % str(object_data.get("target_platform_id", "")))
	var tint: Color = Color(1.0, 1.0, 1.0, 1.0)
	var accent: Color = Color(0.78, 0.87, 0.96, 0.98)
	match terminal_type:
		"door_terminal": accent = Color(1.0, 0.8, 0.26, 0.99)
		"power_terminal": accent = Color(0.45, 0.98, 0.78, 0.99)
		"diagnostic_terminal": accent = Color(0.46, 0.92, 1.0, 0.99)
		"control_terminal": accent = Color(0.78, 0.62, 1.0, 0.99)
		"terminal": accent = Color(0.67, 0.86, 1.0, 0.99)
	match state:
		"disabled", "offline":
			tint = Color(0.42, 0.45, 0.5, 0.9)
		"error", "broken":
			tint = Color(0.72, 0.36, 0.34, 0.95)
			accent = Color(1.0, 0.29, 0.22, 0.99)
		"scanning":
			tint = Color(0.7, 0.92, 1.0, 0.96)
			accent = Color(0.39, 0.95, 1.0, 0.99)
	var terminal_preset_override: Dictionary = Dictionary(map_constructor_terminal_visual_preset_overrides.get(normalized_id, {}))
	var terminal_room_preset_id: String = str(terminal_preset_override.get("preset_id", "")).strip_edges()
	var terminal_room_visual_hint: String = str(terminal_preset_override.get("visual_hint", "")).strip_edges()
	var normalized_terminal_room_visual_hint: String = terminal_room_visual_hint.to_lower()
	var terminal_created_by_room_preset: bool = bool(terminal_preset_override.get("created_by_room_visual_preset", false))
	if not normalized_terminal_room_visual_hint.is_empty():
		var terminal_is_hazard_hint: bool = normalized_terminal_room_visual_hint.contains("hazard") or normalized_terminal_room_visual_hint.contains("power") or normalized_terminal_room_visual_hint.contains("alert") or normalized_terminal_room_visual_hint.contains("damaged")
		var terminal_is_diag_hint: bool = normalized_terminal_room_visual_hint.contains("diag") or normalized_terminal_room_visual_hint.contains("blue") or normalized_terminal_room_visual_hint.contains("clean") or normalized_terminal_room_visual_hint.contains("cool")
		var terminal_is_security_hint: bool = normalized_terminal_room_visual_hint.contains("security") or normalized_terminal_room_visual_hint.contains("reinforced")
		var terminal_is_maintenance_hint: bool = normalized_terminal_room_visual_hint.contains("maintenance") or normalized_terminal_room_visual_hint.contains("dark") or normalized_terminal_room_visual_hint.contains("service")
		if terminal_is_hazard_hint:
			tint = _blend_color(tint, Color(0.98, 0.83, 0.34, 0.94), 0.16)
			accent = _blend_color(accent, Color(0.44, 0.92, 1.0, 0.98), 0.14)
		elif terminal_is_diag_hint:
			tint = _blend_color(tint, Color(0.72, 0.9, 1.0, 0.94), 0.16)
			accent = _blend_color(accent, Color(0.56, 0.98, 1.0, 0.98), 0.14)
		elif terminal_is_security_hint:
			tint = _blend_color(tint, Color(0.7, 0.76, 0.86, 0.95), 0.16)
			accent = _blend_color(accent, Color(0.54, 0.64, 0.78, 0.98), 0.14)
		elif terminal_is_maintenance_hint:
			tint = _blend_color(tint, Color(0.3, 0.33, 0.38, 0.95), 0.16)
			accent = _blend_color(accent, Color(0.38, 0.46, 0.55, 0.98), 0.14)
		terminal_room_visual_hint = normalized_terminal_room_visual_hint
	return {"ok": true, "object_id": normalized_id, "terminal_type": terminal_type, "state": state, "badges": badges, "tint": tint, "accent": accent, "texture_asset_id": "terminal_state_generic", "room_visual_preset_id": terminal_room_preset_id, "room_visual_hint": terminal_room_visual_hint, "created_by_room_visual_preset": terminal_created_by_room_preset, "message": "Terminal visual state resolved."}

func get_map_constructor_property_presets(entity_kind: String, entity_id: String) -> Array[Dictionary]:
	var entity_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	var data: Dictionary = _safe_dictionary(entity_info.get("data", {}))
	if not str(data.get("archetype_id", "")).strip_edges().is_empty():
		return []
	var group: String = get_map_constructor_entity_type_group(entity_kind, entity_id)
	match group:
		"door": return [{"id":"open","label":"Open","group":"Door","description":"Door is open and unlocked."},{"id":"closed","label":"Closed","group":"Door","description":"Door is closed and unlocked."},{"id":"locked","label":"Locked","group":"Door","description":"Door is closed and locked."},{"id":"jammed","label":"Jammed","group":"Door","description":"Door is jammed/damaged."}]
		"terminal": return [{"id":"linked","label":"Linked","group":"Terminal","description":"Terminal set active."},{"id":"unlinked","label":"Unlinked","group":"Terminal","description":"Clears linked targets."},{"id":"damaged","label":"Damaged","group":"Terminal","description":"Marks terminal damaged."},{"id":"encrypted","label":"Encrypted","group":"Terminal","description":"Marks terminal encrypted."}]
		"power": return [{"id":"powered","label":"Powered","group":"Power","description":"Active powered state."},{"id":"unpowered","label":"Unpowered","group":"Power","description":"Unpowered state."},{"id":"broken","label":"Broken","group":"Power","description":"Broken/damaged state."}]
	return []

func apply_map_constructor_property_preset(entity_kind: String, entity_id: String, preset_id: String) -> Dictionary:
	var updates: Dictionary = {}
	var group: String = get_map_constructor_entity_type_group(entity_kind, entity_id)
	var warning: String = ""
	match group:
		"door":
			if preset_id == "open": updates={"state":"open"}
			elif preset_id == "closed": updates={"state":"closed"}
			elif preset_id == "locked": updates={"state":"locked"}
			elif preset_id == "jammed": updates={"state":"jammed"}
		"terminal":
			if preset_id == "linked": updates={"state":"active","is_powered":true,"damaged":false,"encrypted":false}
			elif preset_id == "unlinked": updates={"state":"active","target_door_id":"","target_platform_id":"","linked_terminal_id":"","controls":[]}
			elif preset_id == "damaged": updates={"state":"damaged","damaged":true}
			elif preset_id == "encrypted": updates={"state":"encrypted","encrypted":true}
		"power":
			if preset_id == "powered": updates={"state":"active","is_powered":true,"damaged":false,"broken":false}
			elif preset_id == "unpowered": updates={"state":"unpowered","is_powered":false}
			elif preset_id == "broken": updates={"state":"broken","damaged":true,"broken":true}
	if updates.is_empty():
		return {"ok": false, "message": "Unsupported preset.", "entity_kind": entity_kind, "entity_id": entity_id}
	var apply: Dictionary = update_map_constructor_entity_properties(entity_kind, entity_id, updates)
	if group == "terminal" and preset_id == "linked":
		var e: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		var d: Dictionary = _safe_dictionary(e.get("data", {}))
		if str(d.get("target_door_id", "")).is_empty() and str(d.get("target_platform_id", "")).is_empty() and str(d.get("linked_terminal_id", "")).is_empty():
			warning = "Terminal is active but no linked target selected."
	return {"ok": bool(apply.get("ok", false)), "message": warning if not warning.is_empty() else str(apply.get("message", "Preset applied.")), "entity_kind": entity_kind, "entity_id": entity_id}

func update_map_constructor_entity_properties(entity_kind: String, entity_id: String, updates: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	for k in updates.keys():
		if str(k) == "id" or str(k) == "position" or str(k) == "wall_side":
			warnings.append("Field %s is restricted." % str(k))
	var safe: Dictionary = updates.duplicate(true)
	safe.erase("id"); safe.erase("position"); safe.erase("wall_side")
	for k in safe.keys():
		var r: Dictionary = apply_map_constructor_property_update(entity_kind, entity_id, str(k), safe[k])
		if not bool(r.get("ok", false)):
			return {"ok": false, "message": str(r.get("message", "Update failed.")), "warnings": warnings}
	return {"ok": true, "message": "Updated properties.", "warnings": warnings}

func get_map_constructor_link_candidates(entity_kind: String, entity_id: String, link_type: String) -> Array[Dictionary]:
	var field_map := {"linked_terminal":"linked_terminal_id","linked_door":"target_door_id","power_network":"power_network_id","control_source":"control_source_id","terminal_target":"target_door_id","platform_target":"target_platform_id","power_source":"power_source_id","control_terminal":"control_terminal_id","access_terminal":"access_terminal_id"}
	if not field_map.has(link_type): return []
	var entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
	var current_value: String = ""
	if bool(entity.get("ok", false)):
		current_value = str(_safe_dictionary(entity.get("data", {})).get(str(field_map[link_type]), "")).strip_edges()
	var raw: Dictionary = get_map_constructor_link_targets_for_field(entity_kind, entity_id, str(field_map[link_type]))
	var out: Array[Dictionary] = []
	for t in Array(raw.get("targets", [])):
		var td: Dictionary = Dictionary(t)
		if str(td.get("id", "")) == "__none__": continue
		var id: String = str(td.get("id",""))
		out.append({"id":id,"label":str(td.get("label","")),"cell":Vector2i(td.get("cell",Vector2i(-1,-1))),"entity_kind":"world_object","object_type":str(td.get("kind","")),"current":id == current_value})
	if link_type == "power_network":
		var known: Dictionary = {}
		for entry in out:
			known[str(Dictionary(entry).get("id", ""))] = true
		if not current_value.is_empty() and not known.has(current_value):
			out.append({"id":current_value,"label":"Network: %s" % current_value,"cell":Vector2i(-1,-1),"entity_kind":"world_object","object_type":"power_network","current":true})
	return out

func _set_map_constructor_key_door_link(entity_kind: String, key_id: String, door_id: String) -> Dictionary:
	var key_entity: Dictionary = get_map_constructor_entity_by_id(entity_kind, key_id)
	if not bool(key_entity.get("ok", false)):
		key_entity = find_map_constructor_key_item_by_id(key_id)
	if not bool(key_entity.get("ok", false)):
		return {"ok": false, "message": "Key item not found.", "target_id": door_id}
	var old_door_id: String = str(_safe_dictionary(key_entity.get("data", {})).get("linked_door_id", "")).strip_edges()
	if not old_door_id.is_empty() and old_door_id != door_id:
		var old_door: Dictionary = get_map_constructor_entity_by_id("world_object", old_door_id)
		if bool(old_door.get("ok", false)) and str(_safe_dictionary(old_door.get("data", {})).get("required_key_id", "")).strip_edges() == key_id:
			apply_map_constructor_property_update("world_object", old_door_id, "required_key_id", "")
	var normalized_door_id: String = door_id.strip_edges()
	if not normalized_door_id.is_empty():
		var door_entity: Dictionary = get_map_constructor_entity_by_id("world_object", normalized_door_id)
		if not bool(door_entity.get("ok", false)):
			return {"ok": false, "message": "Linked door not found.", "target_id": normalized_door_id}
		var existing_key: String = _map_constructor_get_linked_key_for_door(normalized_door_id)
		if not existing_key.is_empty() and existing_key != key_id:
			return {"ok": false, "message": "Door already has a linked key.", "target_id": normalized_door_id}
	var key_location: String = str(key_entity.get("location", "map"))
	if key_location == "inventory":
		var runtime_map: Dictionary = _get_world_item_runtime_map()
		var key_runtime: Dictionary = Dictionary(runtime_map.get(key_id, {}))
		key_runtime["linked_door_id"] = normalized_door_id
		var key_runtime_data: Dictionary = Dictionary(key_runtime.get("item_data", {}))
		if not key_runtime_data.is_empty():
			key_runtime_data["linked_door_id"] = normalized_door_id
			key_runtime["item_data"] = key_runtime_data
		runtime_map[key_id] = key_runtime
		runtime_inventory_state["world_item_runtime"] = runtime_map
	else:
		var key_apply: Dictionary = apply_map_constructor_property_update(str(key_entity.get("entity_kind", entity_kind)), key_id, "linked_door_id", normalized_door_id)
		if not bool(key_apply.get("ok", false)):
			return key_apply
	if not normalized_door_id.is_empty():
		apply_map_constructor_property_update("world_object", normalized_door_id, "required_key_id", key_id)
	var target_cell: Vector2i = Vector2i(-1, -1)
	var target_entity: Dictionary = get_map_constructor_entity_by_id("world_object", normalized_door_id)
	if bool(target_entity.get("ok", false)):
		target_cell = Vector2i(target_entity.get("cell", Vector2i(-1, -1)))
	return {"ok": true, "message": "Door link updated.", "target_cell": target_cell, "target_id": normalized_door_id}

func set_map_constructor_entity_link(entity_kind: String, entity_id: String, link_type: String, target_id: String) -> Dictionary:
	var field_map := {"linked_terminal":"linked_terminal_id","linked_door":"target_door_id","power_network":"power_network_id","control_source":"control_source_id","terminal_target":"target_door_id","platform_target":"target_platform_id","power_source":"power_source_id","control_terminal":"control_terminal_id","access_terminal":"access_terminal_id","key_door":"linked_door_id"}
	if not field_map.has(link_type): return {"ok":false,"message":"Unsupported link type.","target_id":target_id}
	if link_type == "key_door":
		return _set_map_constructor_key_door_link(entity_kind, entity_id, target_id)
	var apply: Dictionary = apply_map_constructor_link_target(entity_kind, entity_id, str(field_map[link_type]), target_id)
	var target_cell: Vector2i = Vector2i(-1, -1)
	var target_entity: Dictionary = get_map_constructor_entity_by_id("world_object", target_id)
	if bool(target_entity.get("ok", false)): target_cell = Vector2i(target_entity.get("cell", Vector2i(-1, -1)))
	return {"ok":bool(apply.get("ok",false)),"message":str(apply.get("message","Link updated.")),"target_cell":target_cell,"target_id":target_id}


func _map_constructor_link_target_exists_for_field(field_name: String, target_id: String) -> bool:
	var normalized_target_id: String = target_id.strip_edges()
	if normalized_target_id.is_empty():
		return false
	if field_name == "required_key_id":
		return bool(find_map_constructor_key_item_by_id(normalized_target_id).get("ok", false))
	if field_name in ["power_source_id", "power_network_id"]:
		if bool(get_map_constructor_entity_by_id("world_object", normalized_target_id).get("ok", false)):
			return true
		for object_data in mission_world_objects:
			if str(Dictionary(object_data).get("power_network_id", "")).strip_edges() == normalized_target_id:
				return true
		return false
	return bool(get_map_constructor_entity_by_id("world_object", normalized_target_id).get("ok", false))


func _normalize_map_constructor_access_type(raw_value: Variant, fallback_value: String = "") -> String:
	var normalized_access_type: String = WorldObjectCatalogRef.normalize_access_type(raw_value)
	if str(raw_value).strip_edges().is_empty() and not fallback_value.is_empty():
		return WorldObjectCatalogRef.normalize_access_type(fallback_value)
	return normalized_access_type

func _default_map_constructor_access_type_for_object(object_data: Dictionary) -> String:
	var classifier: String = "%s %s %s" % [str(object_data.get("object_type", "")).to_lower(), str(object_data.get("map_constructor_prefab_id", "")).to_lower(), str(object_data.get("display_name", "")).to_lower()]
	if classifier.contains("powered_gate") or classifier.contains("gate"):
		return WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY
	var access_type: String = WorldObjectCatalogRef.normalize_access_type(object_data.get("access_type", object_data.get("lock_type", "")))
	if classifier.contains("digital") or access_type in [WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY, WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE, WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL]:
		return WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY
	return WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD

func _normalize_map_constructor_active_object_fields(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(object_data)
	var classifier: String = "%s %s %s %s" % [str(data.get("object_group", "")).to_lower(), str(data.get("object_type", "")).to_lower(), str(data.get("map_constructor_prefab_id", "")).to_lower(), str(data.get("id", "")).to_lower()]
	var type_group: String = "generic"
	if _map_constructor_is_door_data(data):
		type_group = "door"
	elif classifier.contains("terminal"):
		type_group = "terminal"
	elif classifier.contains("power") or classifier.contains("switch") or classifier.contains("control"):
		type_group = "power"
	if not (type_group in ["door", "terminal", "power", "control"]):
		return data
	var prefab_id: String = str(data.get("map_constructor_prefab_id", data.get("object_type", ""))).to_lower()
	var default_power_mode: String = "external" if prefab_id == "powered_gate" or bool(data.get("requires_external_power", false)) else "internal"
	var power_mode: String = str(data.get("power_mode", default_power_mode)).strip_edges().to_lower()
	if power_mode in ["external_power", "external power"]:
		power_mode = "external"
	if power_mode in ["none", "non", "no", ""]:
		power_mode = "none"
	if not (power_mode in ["internal", "external", "none"]):
		power_mode = default_power_mode
	data["power_mode"] = power_mode
	data["requires_external_power"] = power_mode == "external"
	if not data.has("power_network_id"):
		data["power_network_id"] = str(data.get("network_id", data.get("connected_power_source_id", ""))).strip_edges()
	if not data.has("power_source_id"):
		data["power_source_id"] = str(data.get("connected_power_source_id", data.get("power_network_id", ""))).strip_edges()
	var object_type_normalized: String = str(data.get("object_type", prefab_id)).strip_edges().to_lower()
	if object_type_normalized in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]:
		ensure_power_source_network_id(data)
		var source_state: String = str(data.get("state", "on")).strip_edges().to_lower()
		if source_state.is_empty():
			source_state = "on"
		if source_state == "active":
			source_state = "on"
		if not (source_state in ["on", "off", "damaged", "broken"]):
			source_state = "on"
		var source_class: int = int(data.get("power_source_class", data.get("source_class", 1)))
		if object_type_normalized.ends_with("class_2"):
			source_class = 2
		elif object_type_normalized.ends_with("class_3"):
			source_class = 3
		source_class = clampi(source_class, 1, 3)
		data["state"] = source_state
		data["power_mode"] = "internal"
		data["control_mode"] = "internal"
		data["requires_external_power"] = false
		data["requires_external_control"] = false
		data["is_powered"] = source_state == "on"
		data["damaged"] = source_state == "damaged"
		data["broken"] = source_state == "broken"
		data["power_source_class"] = source_class
		data["source_class"] = source_class
		data["outlet_capacity"] = source_class + 3
	if type_group == "terminal" and not data.has("is_powered"):
		data["is_powered"] = true
	if object_type_normalized in ["power_cable", "power_socket", "circuit_breaker", "circuit_switch", "fuse_box", "fuse_box_installed", "fuse_box_empty", "light", "light_switch", "power_switcher"]:
		if not data.has("is_powered"):
			data["is_powered"] = false
		if not data.has("physical_connection_source_id"):
			# Physical provenance is traversal-owned. A logical source/network link
			# must not masquerade as a placed cable route.
			data["physical_connection_source_id"] = ""
		if not data.has("damaged"):
			data["damaged"] = false
		if not data.has("broken"):
			data["broken"] = false
	if object_type_normalized == "power_cable":
		data["state"] = str(data.get("state", "ok")).strip_edges().to_lower()
		if data["state"] == "active":
			data["state"] = "ok"
		if not (str(data["state"]) in ["ok", "cut", "damaged", "broken"]):
			data["state"] = "ok"
		if not data.has("connected"):
			data["connected"] = true
		if not data.has("disconnected"):
			data["disconnected"] = not bool(data.get("connected", true))
		if not data.has("connected_side"):
			data["connected_side"] = bool(data.get("connected", true))
		if not data.has("cut"):
			data["cut"] = false
		data = WorldObjectCatalogRef.normalize_cable_contract(data)
		if not data.has("cable_path_cells"):
			data["cable_path_cells"] = []
		if not data.has("cable_length"):
			data["cable_length"] = 0
	if object_type_normalized in ["circuit_breaker", "circuit_switch", "light_switch", "power_switcher"]:
		var switch_default_state: String = "switch_on" if object_type_normalized == "circuit_breaker" else "switch_off"
		if str(data.get("state", "active")).strip_edges().to_lower() == "active":
			data["state"] = switch_default_state
		if not data.has("is_on"):
			data["is_on"] = str(data.get("state", switch_default_state)).strip_edges().to_lower() == "switch_on"
		data["switch_state"] = "on" if bool(data.get("is_on", false)) else "off"
	if object_type_normalized in ["fuse_box", "fuse_box_installed", "fuse_box_empty"]:
		var fuse_installed_default: bool = object_type_normalized != "fuse_box_empty"
		if str(data.get("state", "active")).strip_edges().to_lower() == "active":
			data["state"] = "installed" if fuse_installed_default else "empty"
		if not data.has("requires_fuse"):
			data["requires_fuse"] = true
		if not data.has("fuse_installed"):
			data["fuse_installed"] = fuse_installed_default
		data["fuse_present"] = bool(data.get("fuse_present", data.get("fuse_installed", fuse_installed_default)))
		data["fuse_installed"] = bool(data.get("fuse_present", false))
	if object_type_normalized == "power_socket":
		if str(data.get("state", "active")).strip_edges().to_lower() == "active":
			data["state"] = "disconnected"
		if not data.has("connected"):
			data["connected"] = false
		if not data.has("disconnected"):
			data["disconnected"] = not bool(data.get("connected", false))
		if not data.has("connected_side"):
			data["connected_side"] = bool(data.get("connected", false))
	if object_type_normalized == "power_cable_reel":
		if str(data.get("state", "active")).strip_edges().to_lower() == "active":
			data["state"] = "disconnected"
		var legacy_reel_target_id: String = str(data.get("cable_endpoint_b_id", "")).strip_edges()
		var has_explicit_reel_ends: bool = data.has("end_1_state") or data.has("end_1_target_id") or data.has("end_2_state") or data.has("end_2_target_id")
		if not has_explicit_reel_ends and bool(data.get("connected", false)) and not legacy_reel_target_id.is_empty():
			data["end_1_state"] = "connected"
			data["end_1_target_id"] = legacy_reel_target_id
			var legacy_reel_path: Variant = data.get("cable_path_cells", [])
			data["end_1_path_cells"] = legacy_reel_path.duplicate(true) if legacy_reel_path is Array else []
			data["end_1_cable_length"] = maxi(0, int(data.get("cable_length", 0)))
		if not data.has("cut"):
			data["cut"] = false
		if not data.has("damaged"):
			data["damaged"] = false
		if not data.has("broken"):
			data["broken"] = false
		for end_index in range(1, 3):
			var end_state_key: String = "end_%d_state" % end_index
			var end_target_key: String = "end_%d_target_id" % end_index
			var end_path_key: String = "end_%d_path_cells" % end_index
			var end_length_key: String = "end_%d_cable_length" % end_index
			var end_state: String = str(data.get(end_state_key, "on_reel")).strip_edges().to_lower()
			if not (end_state in ["on_reel", "held", "connected", "disconnected"]):
				end_state = "on_reel"
			data[end_state_key] = end_state
			data[end_target_key] = str(data.get(end_target_key, "")).strip_edges()
			if not data.has(end_path_key):
				data[end_path_key] = []
			if not data.has(end_length_key):
				data[end_length_key] = 0
			if not data.has("connected_side_%d" % end_index):
				data["connected_side_%d" % end_index] = end_state == "connected" and not str(data.get(end_target_key, "")).is_empty()
		if not data.has("connected"):
			data["connected"] = bool(data.get("connected_side_1", false)) or bool(data.get("connected_side_2", false))
		if not data.has("disconnected"):
			data["disconnected"] = not bool(data.get("connected", false))
		if not data.has("connected_side"):
			data["connected_side"] = bool(data.get("connected", false))
		if not data.has("cable_endpoint_a_id"):
			data["cable_endpoint_a_id"] = ""
		if not data.has("cable_endpoint_b_id"):
			data["cable_endpoint_b_id"] = ""
		if not data.has("cable_path_cells"):
			data["cable_path_cells"] = []
		if not data.has("cable_length"):
			data["cable_length"] = 0
	var control_mode: String = str(data.get("control_type", data.get("control_mode", "external" if bool(data.get("requires_external_control", false)) else "internal"))).strip_edges().to_lower()
	if control_mode in ["external_control", "external control", "terminal"]:
		control_mode = "external"
	if control_mode in ["none", "non", "no", ""]:
		control_mode = "none"
	if not (control_mode in ["internal", "external", "none"]):
		control_mode = "internal"
	data["control_mode"] = control_mode
	data["requires_external_control"] = control_mode == "external"
	var terminal_id: String = str(data.get("control_terminal_id", data.get("linked_terminal_id", data.get("control_source_id", "")))).strip_edges()
	data["control_terminal_id"] = terminal_id
	if not data.has("linked_terminal_id"):
		data["linked_terminal_id"] = terminal_id
	if control_mode == "external":
		data["linked_terminal_id"] = terminal_id
		data["control_source_id"] = terminal_id
	if type_group == "door":
		data["control_type"] = control_mode if control_mode in ["internal", "external"] else "internal"
		var door_state: String = str(data.get("state", "closed")).strip_edges().to_lower()
		if not (door_state in ["open", "closed", "locked", "jammed", "damaged"]):
			door_state = "closed"
		data["state"] = door_state
		data["damaged"] = bool(data.get("damaged", false)) or door_state == "damaged"
		var default_access: String = _default_map_constructor_access_type_for_object(data)
		var access_type: String = _normalize_map_constructor_access_type(data.get("access_type", data.get("lock_type", "")), default_access)
		data["access_type"] = access_type
		if access_type == WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY:
			data["required_key_id"] = ""
			data["lock_type"] = "none"
			if str(data.get("state", "closed")) == "locked":
				data["state"] = "closed"
		elif access_type == WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL:
			data["required_key_id"] = ""
			data["lock_type"] = "terminal_lock"
			if str(data.get("access_terminal_id", "")).strip_edges().is_empty():
				data["access_terminal_id"] = terminal_id
			if control_mode == "external" and not terminal_id.is_empty():
				data["access_terminal_id"] = terminal_id
		else:
			data["lock_type"] = "mechanical_key" if access_type == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD else access_type
			if access_type == WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE and str(data.get("access_code_value", "")).strip_edges().is_empty():
				var seed_value: int = abs(hash(str(data.get("id", "access_code")))) % 10000
				data["access_code_value"] = "%04d" % seed_value
	return WorldObjectCatalogRef.normalize_door_state_fields(data)

func _map_constructor_make_validation_link(label: String, target_id: String, target_kind: String, field_name: String) -> Dictionary:
	return _ensure_map_constructor_validation_service()._map_constructor_make_validation_link(label, target_id, target_kind, field_name)

func _map_constructor_terminal_stores_key(terminal_id: String, key_id: String) -> bool:
	return _ensure_map_constructor_validation_service()._map_constructor_terminal_stores_key(terminal_id, key_id)

func _count_lights_linked_to_source(source_id: String) -> int:
	return _ensure_map_constructor_validation_service()._count_lights_linked_to_source(source_id)

func _count_adjacent_power_wires(cell: Vector2i, target_id: String = "") -> int:
	return _ensure_map_constructor_validation_service()._count_adjacent_power_wires(cell, target_id)

func _append_light_switch_target_id(target_ids: Array[String], raw_target_id: Variant) -> void:
	var target_id: String = str(raw_target_id).strip_edges()
	if not target_id.is_empty() and not target_ids.has(target_id):
		target_ids.append(target_id)

func toggle_light_switch_links(light_switch_id: String, switch_is_on: bool) -> Dictionary:
	var normalized_switch_id: String = light_switch_id.strip_edges()
	var switch_object: Dictionary = get_world_object_by_id(normalized_switch_id)
	if switch_object.is_empty():
		return {"success": false, "updated": 0, "reason": "switch_missing", "message": "Light switch is missing."}
	switch_object["state"] = "switch_on" if switch_is_on else "switch_off"
	switch_object["is_on"] = switch_is_on
	var source_id: String = str(switch_object.get("power_source_id", switch_object.get("power_network_id", ""))).strip_edges()
	var explicit_target_ids: Array[String] = []
	for field_name in ["target_light_id", "linked_light_id", "target_object_id", "linked_object_id"]:
		_append_light_switch_target_id(explicit_target_ids, switch_object.get(field_name, ""))
	for field_name in ["target_light_ids", "linked_light_ids", "controlled_object_ids", "controls"]:
		var raw_target_ids: Variant = switch_object.get(field_name, [])
		if raw_target_ids is Array:
			for raw_target_id in raw_target_ids:
				_append_light_switch_target_id(explicit_target_ids, raw_target_id)
	var linked_lights: Array[Dictionary] = []
	var linked_light_ids: Array[String] = []
	var warnings: Array[String] = []
	for target_id in explicit_target_ids:
		var linked_object: Dictionary = get_world_object_by_id(target_id)
		if linked_object.is_empty():
			warnings.append("Linked light not found: %s." % target_id)
			continue
		linked_light_ids.append(target_id)
		if str(linked_object.get("object_type", "")).strip_edges().to_lower() != "light":
			warnings.append("Linked light target is invalid: %s." % target_id)
			continue
		var linked_state: String = str(linked_object.get("state", "")).strip_edges().to_lower()
		if linked_state in ["damaged", "broken", "destroyed"] or bool(linked_object.get("damaged", false)) or bool(linked_object.get("broken", false)) or bool(linked_object.get("destroyed", false)):
			warnings.append("Linked light is damaged: %s." % target_id)
			continue
		linked_lights.append(linked_object)
	if not source_id.is_empty():
		for object_data in mission_world_objects:
			if str(object_data.get("object_type", "")).strip_edges().to_lower() != "light":
				continue
			var linked_source: String = str(object_data.get("power_source_id", object_data.get("power_network_id", ""))).strip_edges()
			var object_id: String = str(object_data.get("id", "")).strip_edges()
			if linked_source != source_id or linked_light_ids.has(object_id):
				continue
			linked_light_ids.append(object_id)
			var linked_state: String = str(object_data.get("state", "")).strip_edges().to_lower()
			if linked_state in ["damaged", "broken", "destroyed"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
				warnings.append("Linked light is damaged: %s." % object_id)
				continue
			linked_lights.append(object_data)
	for linked_light in linked_lights:
		linked_light["light_switch_off"] = not switch_is_on
		if not switch_is_on:
			linked_light["is_powered"] = false
	if not source_id.is_empty():
		PowerSystemRef.recalculate_network(mission_world_objects, source_id)
	if switch_is_on:
		for linked_light in linked_lights:
			if not bool(linked_light.get("is_powered", false)):
				warnings.append("Linked light is unpowered: %s." % str(linked_light.get("id", "")))
	if linked_lights.is_empty():
		var reason: String = "source_missing" if source_id.is_empty() else "linked_light_missing"
		var local_message: String = "Light switch source is missing." if source_id.is_empty() else "Light switch has no linked lights."
		if not warnings.is_empty():
			local_message = " ".join(warnings)
		return {"success": false, "updated": 0, "reason": reason, "source_id": source_id, "warnings": warnings, "message": local_message}
	var message: String = "Linked lights toggled."
	if not warnings.is_empty():
		message += " " + " ".join(warnings)
	return {"success": true, "updated": linked_lights.size(), "reason": "ok", "source_id": source_id, "warnings": warnings, "message": message}

func validate_map_constructor_entity_links(entity_kind: String, entity_id: String) -> Dictionary:
	return _ensure_map_constructor_validation_service().validate_map_constructor_entity_links(entity_kind, entity_id)

func _is_map_constructor_cleanup_protected_object(object_data: Dictionary) -> bool:
	var object_id: String = str(object_data.get("id", "")).to_lower()
	if object_id == "bipob" or object_id.find("bipob") >= 0:
		return true
	if object_id.find("start") >= 0 and object_id.find("marker") >= 0:
		return true
	if object_id.find("exit") >= 0 and object_id.find("marker") >= 0:
		return true
	return false

func _build_map_constructor_cleanup_row(entity_kind: String, data: Dictionary, cell: Vector2i) -> Dictionary:
	var object_id: String = str(data.get("id", ""))
	return {"entity_kind": entity_kind, "id": object_id, "object_type": str(data.get("object_type", data.get("item_type", ""))), "object_group": str(data.get("object_group", "")), "category": str(data.get("category", "")), "type_group": get_map_constructor_entity_type_group(entity_kind, object_id), "cell": cell, "created_by_map_constructor": bool(data.get("created_by_map_constructor", false))}

func get_map_constructor_cleanup_preview(cleanup_type: String, options: Dictionary = {}) -> Dictionary:
	var lower_type: String = cleanup_type.strip_edges().to_lower()
	if not _is_task_test_constructor_context():
		return {"ok": false, "cleanup_type": lower_type, "message": "Cleanup tools work only in TASK TEST runtime.", "affected_count": 0, "affected_objects": [], "warnings": []}
	var include_base: bool = bool(options.get("include_base_task_test_objects", false))
	var include_constructor_created: bool = bool(options.get("include_constructor_created", true))
	var rows: Array[Dictionary] = []
	var warnings: Array[String] = []
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = _safe_dictionary(object_data)
		var created: bool = bool(data.get("created_by_map_constructor", false))
		if include_constructor_created and not created and not include_base:
			continue
		if not include_constructor_created and created:
			continue
		if _is_map_constructor_cleanup_protected_object(data):
			continue
		var row: Dictionary = _build_map_constructor_cleanup_row("world_object", data, Vector2i(data.get("position", Vector2i(-1, -1))))
		var add_row: bool = false
		match lower_type:
			"items":
				add_row = row["type_group"] == "item" or _map_constructor_is_item_like_world_object(data)
			"wall_mounted":
				add_row = str(data.get("placement_mode", "")) == "wall_mounted"
			"category":
				add_row = str(row.get("category", "")).to_lower() == str(options.get("category", "")).to_lower()
			"type_group":
				add_row = str(row.get("type_group", "")) == str(options.get("type_group", "")).to_lower()
			"all_constructor_objects", "reset_runtime_map":
				add_row = created or include_base
				if lower_type == "reset_runtime_map":
					warnings.append("Full baseline reset is not available yet; constructor-created runtime edits will be cleared.")
			"invalid_references":
				var fields: Array[String] = ["target_door_id","target_platform_id","linked_terminal_id","control_source_id","required_key_id"]
				for f in fields:
					var tid: String = str(data.get(f, "")).strip_edges()
					if tid.is_empty():
						continue
					if not _map_constructor_link_target_exists_for_field(f, tid):
						rows.append({"entity_kind":"world_object","id":str(data.get("id","")),"field_name":f,"invalid_value":tid,"cell":Vector2i(data.get("position", Vector2i(-1,-1))),"created_by_map_constructor":created})
				for connected_id in Array(data.get("connected_device_ids", [])):
					var cid: String = str(connected_id).strip_edges()
					if cid.is_empty():
						continue
					if not _map_constructor_link_target_exists_for_field("connected_device_ids", cid):
						rows.append({"entity_kind":"world_object","id":str(data.get("id","")),"field_name":"connected_device_ids","invalid_value":cid,"cell":Vector2i(data.get("position", Vector2i(-1,-1))),"created_by_map_constructor":created})
			_:
				return {"ok": false, "cleanup_type": lower_type, "message": "Unsupported cleanup type.", "affected_count": 0, "affected_objects": [], "warnings": []}
		if add_row:
			rows.append(row)
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item_variant in Array(cell_items.get(cell_variant, [])):
			var item_data: Dictionary = _safe_dictionary(item_variant)
			var created_item: bool = bool(item_data.get("created_by_map_constructor", false))
			if include_constructor_created and not created_item and not include_base:
				continue
			if not include_constructor_created and created_item:
				continue
			if lower_type in ["items", "all_constructor_objects", "reset_runtime_map"]:
				rows.append(_build_map_constructor_cleanup_row("item", item_data, cell))
	return {"ok": true, "cleanup_type": lower_type, "message": "Preview ready.", "affected_count": rows.size(), "affected_objects": rows, "warnings": warnings}

func apply_map_constructor_cleanup(cleanup_type: String, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Operation is available only in TASK TEST constructor mode."}
	var preview: Dictionary = get_map_constructor_cleanup_preview(cleanup_type, options)
	if not bool(preview.get("ok", false)):
		return {"ok": false, "message": str(preview.get("message", "Cleanup failed.")), "deleted_count": 0, "cleanup_id": "", "warnings": Array(preview.get("warnings", []))}
	var affected: Array = Array(preview.get("affected_objects", []))
	if affected.is_empty():
		return {"ok": true, "message": "Nothing to clean up.", "deleted_count": 0, "cleanup_id": "", "warnings": Array(preview.get("warnings", []))}
	_map_constructor_last_cleanup_snapshot = {"cleanup_id": "cleanup_%d" % Time.get_unix_time_from_system(), "mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	var deleted_count: int = 0
	if str(cleanup_type).to_lower() == "invalid_references":
		var cleared: int = 0
		for row_variant in affected:
			var row: Dictionary = Dictionary(row_variant)
			var entity: Dictionary = get_map_constructor_entity_by_id(str(row.get("entity_kind", "world_object")), str(row.get("id", "")))
			if not bool(entity.get("ok", false)):
				continue
			var data: Dictionary = _safe_dictionary(entity.get("data", {}))
			var field_name: String = str(row.get("field_name", ""))
			if field_name == "connected_device_ids":
				var filtered: Array[String] = []
				for cid in Array(data.get("connected_device_ids", [])):
					if _map_constructor_link_target_exists_for_field("connected_device_ids", str(cid)):
						filtered.append(str(cid))
				data["connected_device_ids"] = filtered
				cleared += 1
			else:
				data[field_name] = ""
				cleared += 1
			update_world_object_by_id(str(row.get("id", "")), data)
		PowerSystemRef.recalculate_network(mission_world_objects, "")
		refresh_world_cooling_received()
		_record_map_constructor_change("cleanup", {"entity_kind":"", "entity_id":"", "summary":"Applied cleanup: %d objects affected" % cleared, "details":{"cleanup_type":str(cleanup_type).to_lower(), "affected_count":cleared}, "undo_hint":"Use Undo Last Cleanup."})
		return {"ok": true, "message": "Invalid references cleaned.", "deleted_count": cleared, "cleanup_id": str(_map_constructor_last_cleanup_snapshot.get("cleanup_id", "")), "warnings": []}
	for row_variant in affected:
		var row: Dictionary = Dictionary(row_variant)
		var remove_result: Dictionary = _remove_map_constructor_entity_by_id(str(row.get("entity_kind", "")), str(row.get("id", "")))
		if bool(remove_result.get("ok", false)):
			deleted_count += 1
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	var message: String = "Cleanup applied."
	if str(cleanup_type).to_lower() == "reset_runtime_map":
		message = "Runtime map reset cleared constructor-created edits. Full baseline reset is not available yet."
	_record_map_constructor_change("reset" if str(cleanup_type).to_lower() == "reset_runtime_map" else "cleanup", {"entity_kind":"", "entity_id":"", "summary":"Applied cleanup: %d objects affected" % deleted_count if str(cleanup_type).to_lower() != "reset_runtime_map" else "Reset runtime map.", "details":{"cleanup_type":str(cleanup_type).to_lower(), "affected_count":deleted_count}, "undo_hint":"Use Undo Last Cleanup."})
	return {"ok": true, "message": message, "deleted_count": deleted_count, "cleanup_id": str(_map_constructor_last_cleanup_snapshot.get("cleanup_id", "")), "warnings": Array(preview.get("warnings", []))}

func undo_last_map_constructor_cleanup() -> Dictionary:
	if _map_constructor_last_cleanup_snapshot.is_empty():
		return {"ok": false, "message": "No cleanup to undo."}
	mission_world_objects = Array(_map_constructor_last_cleanup_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_cleanup_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_cleanup_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_cleanup_snapshot.clear()
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("cleanup_undo", {"summary":"Undid last cleanup.", "undo_hint":"Redo cleanup manually if needed."})
	return {"ok": true, "message": "Last cleanup undone."}
func is_task_test_expected_invalid_object_id(object_id: String) -> bool:
	match object_id:
		"task_test_control_missing_source", "task_test_control_invalid_source", "task_test_powered_gate_unpowered", "task_test_platform_lift":
			return true
		_:
			return false

func get_map_constructor_object_dependency_status(object_data: Dictionary) -> Dictionary:
	return _ensure_map_constructor_validation_service().get_map_constructor_object_dependency_status(object_data)

func _map_constructor_merge_overlay_issue(overlay_objects: Dictionary, overlay_cells: Dictionary, object_id: String, severity: String, message: String) -> void:
	_ensure_map_constructor_validation_service()._map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, severity, message)

func get_map_constructor_validation_overlay() -> Dictionary:
	return _ensure_map_constructor_validation_service().get_map_constructor_validation_overlay()

func _make_map_constructor_issue(issue_id: String, severity: String, message: String, cell: Vector2i, source: String, entity_kind: String = "", entity_id: String = "", fix_hint: String = "") -> Dictionary:
	return _ensure_map_constructor_validation_service()._make_map_constructor_issue(issue_id, severity, message, cell, source, entity_kind, entity_id, fix_hint)

func _is_map_constructor_door_like_tile_type(tile_type: int) -> bool:
	return _ensure_map_constructor_validation_service()._is_map_constructor_door_like_tile_type(tile_type)

func _get_map_constructor_door_object_for_cell(cell: Vector2i) -> Dictionary:
	return _ensure_map_constructor_validation_service()._get_map_constructor_door_object_for_cell(cell)

func _get_map_constructor_door_opening_probe(cell: Vector2i) -> Dictionary:
	return _ensure_map_constructor_validation_service()._get_map_constructor_door_opening_probe(cell)

func get_map_constructor_door_opening_summary() -> Dictionary:
	return _ensure_map_constructor_validation_service().get_map_constructor_door_opening_summary()

func get_map_constructor_validation_issues() -> Array[Dictionary]:
	return _ensure_map_constructor_validation_service().get_map_constructor_validation_issues()

func _map_constructor_collect_world_ids() -> Dictionary:
	var ids: Dictionary = {}
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var object_id: String = str(Dictionary(object_data).get("id", "")).strip_edges()
		if not object_id.is_empty():
			ids[object_id] = true
	return ids

func _map_constructor_collect_item_ids() -> Dictionary:
	var ids: Dictionary = {}
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_id: String = str(_safe_dictionary(item_variant).get("id", "")).strip_edges()
			if not item_id.is_empty():
				ids[item_id] = true
	return ids

func get_map_constructor_autofix_preview(fix_type: String, options: Dictionary = {}) -> Dictionary:
	var lower_type: String = str(fix_type).strip_edges().to_lower()
	var preview: Dictionary = {"ok": false, "fix_type": lower_type, "message": "Unsupported auto-fix type.", "affected_count": 0, "affected_fixes": [], "warnings": []}
	if not _is_task_test_constructor_context():
		preview["message"] = "Auto-fix works only in TASK TEST runtime constructor mode."
		return preview
	var world_ids: Dictionary = _map_constructor_collect_world_ids()
	var item_ids: Dictionary = _map_constructor_collect_item_ids()
	var fixes: Array[Dictionary] = []
	var warnings: Array[String] = []
	if lower_type in ["clear_broken_reference", "remove_invalid_reference", "clear_all_broken_references"]:
		var target_fields: Array[String] = ["target_door_id","target_platform_id","linked_terminal_id","control_source_id","required_key_id","connected_device_ids"]
		for object_data in mission_world_objects:
			var data: Dictionary = _safe_dictionary(object_data)
			var object_id: String = str(data.get("id", ""))
			if lower_type != "clear_all_broken_references":
				if object_id != str(options.get("entity_id", "")) or str(options.get("entity_kind", "world_object")) != "world_object":
					continue
			for field_name in target_fields:
				if lower_type != "clear_all_broken_references" and not str(options.get("field_name", "")) == field_name:
					continue
				if field_name == "connected_device_ids":
					var current_ids: Array[String] = []
					var valid_ids: Array[String] = []
					for cid_variant in Array(data.get("connected_device_ids", [])):
						var cid: String = str(cid_variant).strip_edges()
						if cid.is_empty():
							continue
						current_ids.append(cid)
						if world_ids.has(cid) or item_ids.has(cid):
							valid_ids.append(cid)
					if valid_ids.size() != current_ids.size():
						fixes.append({"entity_kind":"world_object","entity_id":object_id,"field_name":field_name,"old_value":current_ids,"new_value":valid_ids,"cell":Vector2i(data.get("position", Vector2i(-1,-1))),"description":"Remove invalid connected_device_ids on %s" % object_id})
				else:
					var ref_id: String = str(data.get(field_name, "")).strip_edges()
					if ref_id.is_empty():
						continue
					var is_valid: bool = world_ids.has(ref_id) or (field_name == "required_key_id" and item_ids.has(ref_id))
					if not is_valid:
						fixes.append({"entity_kind":"world_object","entity_id":object_id,"field_name":field_name,"old_value":ref_id,"new_value":"","cell":Vector2i(data.get("position", Vector2i(-1,-1))),"description":"Clear broken %s on %s" % [field_name, object_id]})
	elif lower_type in ["repair_wall_mounted_attachment", "repair_all_wall_mounted_attachments"]:
		for object_data in mission_world_objects:
			var data: Dictionary = _safe_dictionary(object_data)
			if str(data.get("placement_mode", "")) != "wall_mounted":
				continue
			if lower_type == "repair_wall_mounted_attachment" and str(data.get("id", "")) != str(options.get("entity_id", "")):
				continue
			var anchor: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", data.get("position", Vector2i(-1, -1))))
			var preferred: String = str(data.get("wall_side", ""))
			var resolved: Dictionary = _resolve_wall_mounted_attachment(anchor, preferred)
			if bool(resolved.get("ok", false)):
				var new_side: String = str(resolved.get("wall_side", ""))
				var new_wall: Vector2i = Vector2i(resolved.get("attached_wall_cell", Vector2i(-1, -1)))
				if new_side != str(data.get("wall_side", "")) or new_wall != _deserialize_cell_variant(data.get("attached_wall_cell", Vector2i(-1,-1))):
					fixes.append({"entity_kind":"world_object","entity_id":str(data.get("id","")),"field_name":"wall_attachment","old_value":{"wall_side":str(data.get("wall_side","")),"attached_wall_cell":_deserialize_cell_variant(data.get("attached_wall_cell", Vector2i(-1,-1)))},"new_value":{"wall_side":new_side,"attached_wall_cell":new_wall},"cell":anchor,"description":"Repair wall-mounted attachment on %s" % str(data.get("id",""))})
			else:
				warnings.append("Cannot repair wall-mounted attachment: no adjacent wall near anchor.")
	elif lower_type == "assign_power_network":
		var entity: Dictionary = get_map_constructor_entity_by_id(str(options.get("entity_kind", "world_object")), str(options.get("entity_id", "")))
		if bool(entity.get("ok", false)):
			var data: Dictionary = _safe_dictionary(entity.get("data", {}))
			var new_net: String = str(options.get("new_power_network_id", "")).strip_edges()
			if new_net.is_empty():
				warnings.append("New power network id is required.")
			elif str(data.get("power_network_id", "")) != new_net:
				fixes.append({"entity_kind":str(entity.get("entity_kind", "world_object")),"entity_id":str(entity.get("id", "")),"field_name":"power_network_id","old_value":str(data.get("power_network_id","")),"new_value":new_net,"cell":Vector2i(entity.get("cell", Vector2i(-1,-1))),"description":"Assign power network on %s" % str(entity.get("id", ""))})
	elif lower_type == "create_power_network":
		var selected_ids: Array = Array(options.get("apply_to_selected_ids", []))
		if selected_ids.is_empty():
			warnings.append("Choose target objects before creating/assigning a power network.")
		else:
			var new_network_id: String = str(options.get("new_power_network_id", "")).strip_edges()
			for id_variant in selected_ids:
				var object_id: String = str(id_variant)
				var entity_info: Dictionary = get_map_constructor_entity_by_id("world_object", object_id)
				if not bool(entity_info.get("ok", false)):
					continue
				var current_data: Dictionary = Dictionary(entity_info.get("data", {}))
				if new_network_id.is_empty() or str(current_data.get("power_network_id", "")) == new_network_id:
					continue
				fixes.append({"entity_kind":"world_object","entity_id":object_id,"field_name":"power_network_id","old_value":str(current_data.get("power_network_id", "")),"new_value":new_network_id,"cell":Vector2i(entity_info.get("cell", Vector2i(-1,-1))),"description":"Assign new network %s to %s" % [new_network_id, object_id]})
	elif lower_type == "fix_missing_required_id":
		var entity_kind: String = str(options.get("entity_kind", "world_object"))
		var entity_id: String = str(options.get("entity_id", ""))
		var field_name: String = str(options.get("field_name", "id"))
		var entity_info: Dictionary = get_map_constructor_entity_by_id(entity_kind, entity_id)
		if bool(entity_info.get("ok", false)):
			var data: Dictionary = _safe_dictionary(entity_info.get("data", {}))
			if field_name == "required_key_id" and str(data.get("required_key_id", "")).is_empty():
				var keys: Array[String] = []
				for cell_variant in cell_items.keys():
					for item_variant in Array(cell_items.get(cell_variant, [])):
						var item: Dictionary = _safe_dictionary(item_variant)
						var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item)
						if storage_class in [WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD, WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL]:
							keys.append(str(item.get("id", "")))
				if keys.size() == 1:
					fixes.append({"entity_kind":entity_kind,"entity_id":entity_id,"field_name":"required_key_id","old_value":"","new_value":keys[0],"cell":Vector2i(entity_info.get("cell", Vector2i(-1,-1))),"description":"Set required_key_id on %s" % entity_id})
				else:
					warnings.append("Cannot safely set required_key_id: need exactly one matching key item.")
	elif lower_type == "apply_issue_fix":
		var issue_id: String = str(options.get("issue_id", "")).strip_edges()
		if issue_id.is_empty():
			warnings.append("Issue id is required.")
		else:
			var validation_issues: Array[Dictionary] = []
			validation_issues = _safe_dictionary_array(get_map_constructor_validation_issues())
			var issue_match: Dictionary = {}
			for issue_variant in validation_issues:
				var issue_data: Dictionary = Dictionary(issue_variant)
				if str(issue_data.get("id", "")).strip_edges() == issue_id:
					issue_match = issue_data
					break
			if issue_match.is_empty():
				warnings.append("Issue not found.")
			else:
				var issue_fix_options: Array[Dictionary] = []
				issue_fix_options.append_array(get_map_constructor_issue_autofix_options(issue_match))
				var safe_options: Array[Dictionary] = []
				for option_variant in issue_fix_options:
					var option_data: Dictionary = Dictionary(option_variant)
					if str(option_data.get("danger_level", "")).to_lower() == "safe":
						safe_options.append(option_data)
				if safe_options.size() == 1:
					var selected_fix: Dictionary = Dictionary(safe_options[0])
					var nested_fix_type: String = str(selected_fix.get("fix_type", "")).strip_edges()
					var nested_options: Dictionary = Dictionary(selected_fix.get("options", {}))
					if nested_fix_type.is_empty():
						warnings.append("No safe auto-fix available for this issue.")
					else:
						var nested_preview: Dictionary = get_map_constructor_autofix_preview(nested_fix_type, nested_options)
						if bool(nested_preview.get("ok", false)):
							fixes = Array(nested_preview.get("affected_fixes", []))
							for nested_warning_variant in Array(nested_preview.get("warnings", [])):
								warnings.append(str(nested_warning_variant))
						else:
							warnings.append(str(nested_preview.get("message", "No safe auto-fix available for this issue.")))
				elif safe_options.size() > 1:
					warnings.append("Multiple fixes available; choose a specific fix.")
				else:
					warnings.append("No safe auto-fix available for this issue.")
	preview["ok"] = lower_type in ["clear_broken_reference","remove_invalid_reference","clear_all_broken_references","repair_wall_mounted_attachment","repair_all_wall_mounted_attachments","assign_power_network","create_power_network","fix_missing_required_id","apply_issue_fix"]
	preview["affected_fixes"] = fixes
	preview["affected_count"] = fixes.size()
	preview["warnings"] = warnings
	preview["message"] = "Preview ready." if preview["ok"] else "Unsupported auto-fix type."
	return preview

func apply_map_constructor_autofix(fix_type: String, options: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = get_map_constructor_autofix_preview(fix_type, options)
	if not bool(preview.get("ok", false)):
		return {"ok": false, "message": str(preview.get("message", "Auto-fix failed.")), "fixed_count": 0, "fix_id": "", "warnings": Array(preview.get("warnings", []))}
	var fixes: Array = Array(preview.get("affected_fixes", []))
	if fixes.is_empty():
		return {"ok": true, "message": "Nothing to fix.", "fixed_count": 0, "fix_id": "", "warnings": Array(preview.get("warnings", []))}
	_map_constructor_last_autofix_snapshot = {"fix_id":"autofix_%d" % Time.get_unix_time_from_system(), "mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	for row_variant in fixes:
		var row: Dictionary = Dictionary(row_variant)
		var apply_res: Dictionary = apply_map_constructor_property_update(str(row.get("entity_kind", "world_object")), str(row.get("entity_id", "")), str(row.get("field_name", "")), row.get("new_value"))
		if not bool(apply_res.get("ok", false)) and str(row.get("field_name", "")) == "wall_attachment":
			var entity: Dictionary = get_map_constructor_entity_by_id("world_object", str(row.get("entity_id", "")))
			if bool(entity.get("ok", false)):
				var d: Dictionary = _safe_dictionary(entity.get("data", {}))
				var wall_data: Dictionary = Dictionary(row.get("new_value", {}))
				d["wall_side"] = str(wall_data.get("wall_side", d.get("wall_side", "")))
				d["attached_wall_cell"] = Vector2i(wall_data.get("attached_wall_cell", d.get("attached_wall_cell", Vector2i(-1,-1))))
				update_world_object_by_id(str(row.get("entity_id", "")), d)
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("autofix", {"summary":"Applied auto-fix: %d fields fixed" % fixes.size(), "details":{"fix_type":fix_type, "fixed_count":fixes.size()}, "undo_hint":"Use Undo Last Auto-fix."})
	return {"ok": true, "message": "Auto-fix applied.", "fixed_count": fixes.size(), "fix_id": str(_map_constructor_last_autofix_snapshot.get("fix_id", "")), "warnings": Array(preview.get("warnings", []))}

func undo_last_map_constructor_autofix() -> Dictionary:
	if _map_constructor_last_autofix_snapshot.is_empty():
		return {"ok": false, "message": "No auto-fix to undo."}
	mission_world_objects = Array(_map_constructor_last_autofix_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_autofix_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_autofix_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_autofix_snapshot.clear()
	PowerSystemRef.recalculate_network(mission_world_objects, "")
	refresh_world_cooling_received()
	_record_map_constructor_change("autofix_undo", {"summary":"Undid last auto-fix.", "undo_hint":"Re-apply auto-fix manually if needed."})
	return {"ok": true, "message": "Last auto-fix undone."}

func get_map_constructor_issue_autofix_options(issue: Dictionary) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var message: String = str(issue.get("message", "")).to_lower()
	var entity_id: String = str(issue.get("entity_id", ""))
	var entity_kind: String = str(issue.get("entity_kind", "world_object"))
	var issue_id: String = str(issue.get("id", ""))
	if message.find("missing") >= 0 and (message.find("target_door_id") >= 0 or message.find("target_platform_id") >= 0 or message.find("linked_terminal_id") >= 0 or message.find("control_source_id") >= 0 or message.find("required_key_id") >= 0):
		var field_name: String = ""
		for candidate in ["target_door_id","target_platform_id","linked_terminal_id","control_source_id","required_key_id"]:
			if message.find(candidate) >= 0:
				field_name = candidate
				break
		if not field_name.is_empty():
			options.append({"label":"Clear broken %s" % field_name, "fix_type":"clear_broken_reference", "options":{"entity_kind":entity_kind,"entity_id":entity_id,"field_name":field_name,"issue_id":issue_id}, "danger_level":"safe"})
	if str(issue_id).begins_with("wm_"):
		options.append({"label":"Repair wall mount", "fix_type":"repair_wall_mounted_attachment", "options":{"entity_kind":entity_kind,"entity_id":entity_id,"issue_id":issue_id}, "danger_level":"safe"})
	return options


func _map_constructor_issue_is_expected_invalid(issue: Dictionary) -> bool:
	return _ensure_map_constructor_validation_service()._map_constructor_issue_is_expected_invalid(issue)

func _map_constructor_build_readiness_check(issue: Dictionary, status: String) -> Dictionary:
	return _ensure_map_constructor_validation_service()._map_constructor_build_readiness_check(issue, status)

func get_map_constructor_mission_readiness_report() -> Dictionary:
	return _ensure_map_constructor_validation_service().get_map_constructor_mission_readiness_report()

func get_map_constructor_audit_summary() -> Dictionary:
	return _ensure_map_constructor_validation_service().get_map_constructor_audit_summary()

func get_map_constructor_audit_summary_text() -> String:
	return _ensure_map_constructor_validation_service().get_map_constructor_audit_summary_text()

func get_world_object_by_id(id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if str(object_data.get("id", "")) == id:
			return object_data
	return {}

func get_cell_item_by_id(id: String) -> Dictionary:
	var normalized_id: String = id.strip_edges()
	if normalized_id.is_empty():
		return {}
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if item_variant is Dictionary and str(Dictionary(item_variant).get("id", "")) == normalized_id:
				return Dictionary(item_variant)
	return {}

func update_world_object_by_id(id: String, data: Dictionary) -> void:
	if id.is_empty() or data.is_empty():
		return
	data = WorldObjectCatalogRef.normalize_door_state_fields(WorldObjectCatalogRef.normalize_world_object_contract(data))
	for index in range(mission_world_objects.size()):
		var object_data: Dictionary = mission_world_objects[index]
		if str(object_data.get("id", "")) != id:
			continue
		var old_position := Vector2i(object_data.get("position", Vector2i(-1, -1)))
		for key in data.keys():
			object_data[key] = data[key]
		mission_world_objects[index] = object_data
		var new_position := Vector2i(object_data.get("position", old_position))
		if old_position != new_position:
			world_objects_by_cell.erase(old_position)
		world_objects_by_cell[new_position] = object_data
		refresh_generic_cable_runtime_state(str(object_data.get("power_network_id", "")))
		refresh_world_cooling_received()
		return


func move_world_object_by_heavy_claw(object_id: String, target_cell: Vector2i) -> Dictionary:
	var result := {"success": false, "message": "Cannot move object there.", "object_id": object_id, "from": Vector2i(-1, -1), "to": target_cell}
	if object_id.strip_edges().is_empty():
		result["message"] = "Object not found."
		return result
	var object_data := get_world_object_by_id(object_id)
	if object_data.is_empty():
		result["message"] = "Object not found."
		return result
	var from_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	result["from"] = from_cell
	if not WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data):
		result["message"] = "Object cannot be moved by Heavy Claw."
		return result
	if from_cell == target_cell:
		result["message"] = "Object already there."
		return result
	var target_cell_state: Dictionary = get_runtime_cell_state(target_cell)
	if not bool(target_cell_state.get("in_bounds", false)) or not bool(target_cell_state.get("is_passable", false)):
		result["message"] = "Target cell is blocked."
		return result
	if from_cell.x < 0 or from_cell.y < 0:
		result["message"] = "Object not found."
		return result
	var target_object := get_world_object_at_cell(target_cell)
	if not target_object.is_empty():
		result["message"] = "Target cell is occupied."
		return result
	world_objects_by_cell.erase(from_cell)
	object_data["position"] = target_cell
	world_objects_by_cell[target_cell] = object_data
	for object_index in range(mission_world_objects.size()):
		if str(mission_world_objects[object_index].get("id", "")) == object_id:
			mission_world_objects[object_index] = object_data
			break
	refresh_world_cooling_received()
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()
	result["success"] = true
	result["message"] = "Moved %s." % str(object_data.get("display_name", "Object"))
	return result

func refresh_world_cooling_received() -> void:
	for object_data in mission_world_objects:
		if bool(object_data.get("generic_airflow_runtime", false)) and bool(object_data.get("cooling_required", false)):
			continue
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		var target_position: Vector2i = WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var cooling_received: int = WorldObjectCatalogRef.calculate_world_cooling_received_for_target(object_data, target_position, mission_world_objects)
		object_data["cooling_received"] = cooling_received
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)
	refresh_generic_airflow_runtime_state()

func preview_cooling_application(filter: String = "") -> Dictionary:
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var report := {"filter": filter.strip_edges(), "resolved_filter": resolved_filter, "cooling_sources": [], "targets": [], "changes": [], "warnings": []}
	for object_data in mission_world_objects:
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		var object_network := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and object_network != resolved_filter:
			continue
		var object_id := str(object_data.get("id", ""))
		var previous_cooling := maxi(0, int(object_data.get("cooling_received", 0)))
		var previous_heat := maxi(0, int(object_data.get("current_heat", 0)))
		var previous_state := str(object_data.get("state", ""))
		var target_position := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var next_cooling := WorldObjectCatalogRef.calculate_world_cooling_received_for_target(object_data, target_position, mission_world_objects)
		var projected_heat := maxi(0, int(object_data.get("working_heat", previous_heat)) + int(object_data.get("heat_from_connections", 0)) - next_cooling)
		var threshold := maxi(0, int(object_data.get("overheat_threshold", 0)))
		var next_state := previous_state
		if threshold > 0 and projected_heat >= threshold:
			next_state = "overheated"
		elif previous_state == "overheated":
			next_state = str(object_data.get("overheated_state_before", object_data.get("powered_state_before_unpowered", "active")))
		var reason := "stable"
		if next_cooling > 0:
			reason = "cooled"
		report["targets"].append({"object_id": object_id, "cooling_received": next_cooling, "previous_heat": previous_heat, "new_heat": projected_heat, "previous_state": previous_state, "new_state": next_state, "reason": reason})
		if previous_cooling != next_cooling or previous_heat != projected_heat or previous_state != next_state:
			report["changes"].append({"object_id": object_id, "cooling_received": next_cooling, "previous_heat": previous_heat, "new_heat": projected_heat, "previous_state": previous_state, "new_state": next_state, "reason": reason})
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) != "cooling":
			continue
		var object_network := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and object_network != resolved_filter:
			continue
		report["cooling_sources"].append({"object_id": str(object_data.get("id", "")), "cooling_output": maxi(0, int(object_data.get("cooling_output", 0))), "cooling_device_type": str(object_data.get("cooling_device_type", "")), "facing_dir": str(object_data.get("facing_dir", "")), "state": str(object_data.get("state", ""))})
	return report

func apply_cooling_application(filter: String = "") -> Dictionary:
	var preview := preview_cooling_application(filter)
	for target_variant in preview.get("targets", []):
		if typeof(target_variant) != TYPE_DICTIONARY:
			continue
		var target: Dictionary = target_variant
		var object_id := str(target.get("object_id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty():
			continue
		if not WorldObjectCatalogRef.can_world_object_receive_cooling(object_data):
			continue
		object_data["cooling_received"] = maxi(0, int(target.get("cooling_received", 0)))
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)
	return preview

func update_cooling_for_network_or_area(filter: String = "") -> Dictionary:
	return apply_cooling_application(filter)

func get_cooling_debug_report_text(filter: String = "") -> String:
	var preview := preview_cooling_application(filter)
	var lines: Array[String] = []
	lines.append("Cooling sources:")
	for source_variant in preview.get("cooling_sources", []):
		var source: Dictionary = source_variant
		lines.append("- %s type=%s output=%d facing=%s state=%s" % [str(source.get("object_id", "")), str(source.get("cooling_device_type", "")), int(source.get("cooling_output", 0)), str(source.get("facing_dir", "-")), str(source.get("state", ""))])
	lines.append("Cooling targets:")
	for target_variant in preview.get("targets", []):
		var target: Dictionary = target_variant
		lines.append("- %s heat %d->%d cooling=%d state %s->%s reason=%s" % [str(target.get("object_id", "")), int(target.get("previous_heat", 0)), int(target.get("new_heat", 0)), int(target.get("cooling_received", 0)), str(target.get("previous_state", "")), str(target.get("new_state", "")), str(target.get("reason", ""))])
	lines.append("Preview changes:")
	lines.append("- %d" % Array(preview.get("changes", [])).size())
	lines.append("Warnings:")
	for warning in preview.get("warnings", []):
		lines.append("- %s" % str(warning))
	return "\n".join(lines)

func get_hidden_objects_at_cell(cell: Vector2i) -> Array[Dictionary]:
	var object_data := get_world_object_at_cell(cell)
	if object_data.is_empty():
		return []
	var hidden: Array[Dictionary] = []
	for hidden_id in object_data.get("hidden_content", []):
		hidden.append({"id": hidden_id, "display_name": str(hidden_id).capitalize()})
	return hidden

func get_threats() -> Array[Dictionary]:
	var threats: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) == "threat":
			threats.append(object_data)
	return threats

func is_threat_active(threat: Dictionary) -> bool:
	if threat.is_empty():
		return false
	if str(threat.get("object_group", "")) != "threat":
		return false
	var state := str(threat.get("state", "active"))
	if state in ["destroyed", "disabled", "hacked", "stunned", "unpowered"]:
		return false
	if str(threat.get("behavior_state", "")) == "disabled":
		return false
	if str(threat.get("power_mode", "")) == "external_power" and not bool(threat.get("is_powered", true)):
		return false
	return true

func can_threat_detect_bipop(threat: Dictionary, bipob_cell: Vector2i, grid_manager_ref: Node) -> bool:
	return bool(get_threat_detection_result(threat, bipob_cell, grid_manager_ref).get("detected", false))

func get_threat_detection_result(threat: Dictionary, bipob_cell: Vector2i, grid_manager_ref: Node) -> Dictionary:
	var result := {"detected":false, "threat_id":str(threat.get("id", "")), "threat_name":str(threat.get("display_name", "Threat")), "detection_mode":"", "distance":999, "message":"Threat cannot detect Bipop."}
	if threat.is_empty() or not is_threat_active(threat):
		result["message"] = "Threat inactive."
		return result
	var threat_position := Vector2i(threat.get("position", Vector2i(-1, -1)))
	var distance: int = abs(threat_position.x - bipob_cell.x) + abs(threat_position.y - bipob_cell.y)
	result["distance"] = distance
	var max_range := int(threat.get("detection_range", 0))
	if distance > max_range:
		result["message"] = "%s is out of detection range." % result["threat_name"]
		return result
	for mode_variant in Array(threat.get("detection_modes", [])):
		var mode := str(mode_variant)
		var mode_range := int(threat.get("%s_range" % mode, max_range))
		if mode_range <= 0 or distance > mode_range:
			continue
		if _can_detect_by_mode(mode, threat_position, bipob_cell, grid_manager_ref):
			result["detected"] = true
			result["detection_mode"] = mode
			result["message"] = "%s detected Bipop by %s." % [result["threat_name"], mode]
			return result
	result["message"] = "%s has no clear detection path." % result["threat_name"]
	return result

func _can_detect_by_mode(mode: String, from_cell: Vector2i, to_cell: Vector2i, grid_manager_ref: Node) -> bool:
	if grid_manager_ref == null:
		return false
	return _has_cardinal_clear_path(from_cell, to_cell, grid_manager_ref, mode, mode != "vision")

func _has_cardinal_clear_path(from_cell: Vector2i, to_cell: Vector2i, grid_manager_ref: Node, scan_type: String, allow_wall_pass: bool) -> bool:
	var threat := get_world_object_at_cell(from_cell)
	var detection_shape := str(threat.get("detection_shape", "cardinal"))
	if detection_shape == "cardinal" and from_cell.x != to_cell.x and from_cell.y != to_cell.y:
		return false
	if detection_shape == "radius":
		if from_cell.x != to_cell.x and from_cell.y != to_cell.y:
			return true
	var step := Vector2i(signi(to_cell.x - from_cell.x), signi(to_cell.y - from_cell.y))
	var current := from_cell + step
	while current != to_cell:
		if not grid_manager_ref.is_in_bounds(current):
			return false
		var tile := int(grid_manager_ref.get_tile(current))
		if tile == grid_manager_ref.TILE_WALL:
			return false
		var blocker := get_world_object_at_cell(current)
		if blocker.is_empty():
			current += step
			continue
		if bool(blocker.get("blocks_vision", false)):
			if not allow_wall_pass:
				return false
			if not ScanSystemRef.can_scan_through_wall(blocker, scan_type):
				return false
		current += step
	return true


func reset_world_object_turn_flags() -> void:
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) != "threat":
			continue
		object_data["drained_this_turn"] = false
		var stunned_turns := int(object_data.get("stunned_turns", 0))
		if stunned_turns > 0:
			stunned_turns -= 1
			object_data["stunned_turns"] = stunned_turns
			if stunned_turns <= 0 and str(object_data.get("state", "")) == "stunned":
				var previous_state := str(object_data.get("state_before_stun", ""))
				var previous_behavior := str(object_data.get("behavior_before_stun", ""))
				if previous_state.is_empty() or previous_state in ["destroyed", "hacked", "disabled", "unpowered", "stunned"]:
					object_data["state"] = "active"
				else:
					object_data["state"] = previous_state
				if previous_behavior.is_empty():
					object_data["behavior_state"] = "idle"
				else:
					object_data["behavior_state"] = previous_behavior
				object_data.erase("state_before_stun")
				object_data.erase("behavior_before_stun")

func get_world_object_debug_summary() -> String:
	var world_count := mission_world_objects.size()
	var items_count := 0
	var threats_count := 0
	var powered_count := 0
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) == "item":
			items_count += 1
		if str(object_data.get("object_group", "")) == "threat":
			threats_count += 1
		if bool(object_data.get("is_powered", false)):
			powered_count += 1
	var warning_count := last_threat_warning_ids.size()
	return "WorldObjects: %d | Items: %d | Threats: %d | Powered: %d | Warnings: %d" % [world_count, items_count, threats_count, powered_count, warning_count]

func _is_power_network_object(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var object_group := str(object_data.get("object_group", "")).strip_edges().to_lower()
	if object_group == "power":
		return true
	var object_type := str(object_data.get("object_type", "")).strip_edges().to_lower()
	if object_type in [
		"power_source",
		"power_cable",
		"power_socket",
		"cable_reel",
		"circuit_breaker",
		"circuit_switch",
		"fuse_box",
		"light",
		"light_switch"
	]:
		return true
	return object_data.has("power_network_id") or object_data.has("network_id") or object_data.has("connected_power_source_id")

func _get_power_network_id(object_data: Dictionary) -> String:
	for key in ["power_network_id", "network_id", "connected_power_source_id"]:
		var value := str(object_data.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""

func _get_power_event_filter_for_object(object_data: Dictionary) -> String:
	var network_id := _get_power_network_id(object_data)
	if not network_id.is_empty():
		return network_id
	var object_id := str(object_data.get("id", "")).strip_edges()
	if not object_id.is_empty():
		return object_id
	return ""

func _is_power_source_object(object_data: Dictionary) -> bool:
	var object_type := str(object_data.get("object_type", "")).strip_edges().to_lower()
	var power_role := str(object_data.get("power_role", "")).strip_edges().to_lower()
	return object_type == "power_source" or power_role == "source" or object_type in ["power_source_class_1", "power_source_class_2", "power_source_class_3"]

func _collect_power_network_objects() -> Dictionary:
	var power_objects: Array[Dictionary] = []
	var networks := {}
	var sources_by_id := {}
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		power_objects.append(object_data)
		var network_id := _get_power_network_id(object_data)
		if not networks.has(network_id):
			networks[network_id] = []
		networks[network_id].append(object_data)
		if _is_power_source_object(object_data):
			var source_id := str(object_data.get("id", "")).strip_edges()
			if not source_id.is_empty():
				sources_by_id[source_id] = object_data
	return {"objects": power_objects, "networks": networks, "sources_by_id": sources_by_id}

func _is_power_source_available(source: Dictionary) -> bool:
	if not _is_power_source_object(source):
		return false
	var state := str(source.get("state", "")).strip_edges().to_lower()
	var is_powered := bool(source.get("is_powered", false))
	var damaged_or_broken := bool(source.get("damaged", false)) or bool(source.get("broken", false))
	if state in ["overheated", "damaged", "broken", "destroyed"]:
		return false
	if damaged_or_broken:
		return false
	if is_powered:
		return true
	return state in ["active", "switch_on", "connected"]

func _normalize_power_gate_text(raw_value: Variant) -> String:
	return str(raw_value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")

func _normalize_power_consumer_text(raw_value: Variant) -> String:
	return _normalize_power_gate_text(raw_value)

func _is_terminal_object(object_data: Dictionary) -> bool:
	var object_group := _normalize_power_consumer_text(object_data.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(object_data.get("object_type", ""))
	if object_group == "terminal":
		return true
	return object_type in ["terminal", "door_terminal", "info_terminal", "cooling_terminal", "platform_terminal", "elevator_terminal", "turret_terminal", "security_terminal"]

func _is_terminal_powered_for_interaction(object_data: Dictionary) -> bool:
	var state := _normalize_power_consumer_text(object_data.get("state", ""))
	if bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
		return false
	if state in ["damaged", "broken", "destroyed", "overheated", "unpowered"]:
		return false
	if object_data.has("is_powered"):
		return bool(object_data.get("is_powered", true))
	return true

func _is_power_reactive_door_object(object_data: Dictionary) -> bool:
	var normalized_door: Dictionary = _normalize_runtime_door_data(object_data)
	var object_group := _normalize_power_consumer_text(normalized_door.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(normalized_door.get("object_type", ""))
	var material := _normalize_power_consumer_text(normalized_door.get("material", ""))
	if object_group == "door" and _door_is_powered_mechanism(normalized_door):
		return true
	if object_type in ["grid_door", "power_door", "electromagnetic_door"]:
		return true
	if object_group == "door" and (material in ["electromagnetic", "energy", "grid"] or object_type.find("electromagnetic") != -1 or object_type.find("grid") != -1):
		return true
	return false

func _is_platform_power_consumer(object_data: Dictionary) -> bool:
	var object_group := _normalize_power_consumer_text(object_data.get("object_group", ""))
	var object_type := _normalize_power_consumer_text(object_data.get("object_type", ""))
	return object_group == "platform" or object_type in ["platform", "lifting_platform", "rotating_platform"]

func update_terminal_power_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var state := _normalize_power_consumer_text(object_data.get("state", ""))
	var previous_state := str(object_data.get("state", ""))
	var report := {"changed": false, "object_id": str(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_terminal"}
	if not _is_terminal_object(object_data):
		return report
	if state in ["damaged", "broken", "destroyed", "overheated"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
		report["reason"] = "terminal_blocked_state"
		return report
	if not bool(object_data.get("is_powered", false)):
		if not state in ["unpowered", "damaged", "broken", "destroyed", "overheated"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			report["changed"] = true
			report["new_state"] = "unpowered"
		report["reason"] = "terminal_unpowered"
		return report
	if state == "unpowered":
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "damaged", "broken", "destroyed", "overheated"]:
			restore_state = "active"
		object_data["state"] = restore_state
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "terminal_power_restored"
		return report
	report["reason"] = "terminal_already_powered"
	return report

func update_power_door_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var previous_state := str(object_data.get("state", ""))
	var state := _normalize_power_consumer_text(previous_state)
	var report := {"changed": false, "object_id": str(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_power_reactive_door"}
	if not _is_power_reactive_door_object(object_data):
		return report
	if state in ["damaged", "broken", "destroyed", "sealed"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
		report["reason"] = "door_blocked_state"
		return report
	var normalized_door: Dictionary = _normalize_runtime_door_data(object_data)
	var opens_when_unpowered: bool = str(normalized_door.get("power_behavior", "")) == WorldObjectCatalogRef.POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED
	var requires_power_to_open: bool = str(normalized_door.get("power_behavior", "")) == WorldObjectCatalogRef.POWER_BEHAVIOR_REQUIRES_POWER_TO_OPEN
	if not bool(object_data.get("is_powered", false)):
		if opens_when_unpowered:
			object_data["state"] = "open"
			WorldObjectCatalogRef.normalize_door_state_fields(object_data)
			report["changed"] = previous_state != "open"
			report["new_state"] = "open"
			report["reason"] = "door_opened_without_power"
			return report
		if requires_power_to_open and state == "jammed":
			report["reason"] = "door_blocked_state"
			return report
		if not state in ["unpowered", "disabled", "damaged", "broken", "destroyed", "sealed"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			WorldObjectCatalogRef.normalize_door_state_fields(object_data)
			report["changed"] = true
			report["new_state"] = "unpowered"
			report["reason"] = "door_unpowered"
		return report
	if opens_when_unpowered and state == "open":
		object_data["state"] = "closed"
		WorldObjectCatalogRef.normalize_door_state_fields(object_data)
		report["changed"] = true
		report["new_state"] = "closed"
		report["reason"] = "door_closed_with_power"
		return report
	if state in ["unpowered", "disabled"]:
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "disabled", "damaged", "broken", "destroyed", "sealed"]:
			restore_state = "closed"
		object_data["state"] = restore_state
		WorldObjectCatalogRef.normalize_door_state_fields(object_data)
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "door_power_restored"
		return report
	report["reason"] = "door_already_powered"
	return report

func update_platform_power_state_from_is_powered(object_data: Dictionary) -> Dictionary:
	var previous_state := str(object_data.get("state", ""))
	var state := _normalize_power_consumer_text(previous_state)
	var report := {"changed": false, "object_id": str(object_data.get("id", "")), "previous_state": previous_state, "new_state": previous_state, "reason": "not_platform_consumer"}
	if not _is_platform_power_consumer(object_data):
		return report
	if state in ["damaged", "broken", "destroyed"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
		report["reason"] = "platform_blocked_state"
		return report
	if not bool(object_data.get("is_powered", false)):
		if not state in ["unpowered", "disabled", "damaged", "broken", "destroyed"]:
			object_data["powered_state_before_unpowered"] = previous_state
		if state != "unpowered":
			object_data["state"] = "unpowered"
			report["changed"] = true
			report["new_state"] = "unpowered"
		report["reason"] = "platform_unpowered"
		return report
	if state in ["unpowered", "disabled"]:
		var restore_state := _normalize_power_consumer_text(object_data.get("powered_state_before_unpowered", ""))
		if restore_state in ["", "unpowered", "disabled", "damaged", "broken", "destroyed"]:
			restore_state = "active"
		object_data["state"] = restore_state
		report["changed"] = true
		report["new_state"] = restore_state
		report["reason"] = "platform_power_restored"
		return report
	report["reason"] = "platform_already_powered"
	return report

func _get_power_gate_state(object_data: Dictionary) -> Dictionary:
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	var state := _normalize_power_gate_text(object_data.get("state", ""))
	var damaged_or_broken := bool(object_data.get("cut", false)) or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
	if state in ["cut", "damaged", "broken"] or damaged_or_broken:
		if object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker", "fuse_box", "power_cable", "cable", "cable_reel"]:
			return {"is_gate": true, "gate_type": object_type, "is_closed": false, "reason": state if not state.is_empty() else "damaged"}
	var closed_states := {}
	var open_states := {}
	var is_gate := false
	if object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker"]:
		is_gate = true
		closed_states = {"switch_on": true, "on": true, "active": true, "closed": true}
		open_states = {"switch_off": true, "off": true, "inactive": true, "open": true}
	elif object_type == "fuse_box":
		is_gate = true
		closed_states = {"installed": true, "fuse_installed": true, "active": true}
		open_states = {"empty": true, "missing_fuse": true, "open": true}
	elif object_type in ["power_cable", "cable", "cable_reel"]:
		is_gate = true
		closed_states = {"connected": true, "installed": true, "active": true}
		open_states = {"disconnected": true, "cut": true, "damaged": true, "broken": true}
	if not is_gate:
		return {"is_gate": false, "gate_type": "", "is_closed": true, "reason": "not_gate"}
	if open_states.has(state):
		return {"is_gate": true, "gate_type": object_type, "is_closed": false, "reason": state}
	if closed_states.has(state):
		return {"is_gate": true, "gate_type": object_type, "is_closed": true, "reason": state}
	return {"is_gate": true, "gate_type": object_type, "is_closed": true, "reason": "default_closed"}

func _is_power_gate_closed(object_data: Dictionary) -> bool:
	var gate_state := _get_power_gate_state(object_data)
	return bool(gate_state.get("is_closed", true))

func _resolve_power_graph_filter_to_network_id(filter: String) -> String:
	var filter_text := filter.strip_edges()
	if filter_text.is_empty():
		return ""
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	if networks.has(filter_text):
		return filter_text
	for network_id_variant in networks.keys():
		var network_id := str(network_id_variant)
		var network_objects: Array = networks.get(network_id, [])
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if str(object_data.get("id", "")).strip_edges() == filter_text:
				return network_id
	return filter_text

func _is_power_load_gate_object(object_data: Dictionary) -> bool:
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	return object_type in ["switch", "light_switch", "circuit_switch", "circuit_breaker", "power_switcher", "fuse_box", "power_cable", "cable", "cable_reel"]

func _is_power_load_consumer_object(object_data: Dictionary) -> bool:
	if _is_power_source_object(object_data):
		return false
	if _is_power_load_gate_object(object_data):
		return false
	var state := _normalize_power_gate_text(object_data.get("state", ""))
	var damaged_or_broken := bool(object_data.get("cut", false)) or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
	if damaged_or_broken or state in ["cut", "damaged", "broken", "destroyed"]:
		return false
	var object_type := _normalize_power_gate_text(object_data.get("object_type", ""))
	var object_group := _normalize_power_gate_text(object_data.get("object_group", ""))
	if bool(object_data.get("consumes_power", false)):
		return true
	if object_group == "terminal" or object_type in ["terminal", "door_terminal"]:
		return true
	if object_group == "door" and str(object_data.get("material", "")).strip_edges().to_lower() == WorldObjectCatalogRef.DOOR_MATERIAL_ENERGY:
		return true
	if object_type in ["energy_wall", "electromagnetic_door", "electromagnetic_wall", "grid_door", "grid_wall"]:
		return true
	if object_type in ["platform", "lifting_platform", "rotating_platform", "lift"]:
		return true
	if object_type in ["light", "camera", "alarm", "turret"]:
		return true
	if object_type.find("cooling") != -1:
		return true
	return false

func _get_power_source_capacity_for_load(source: Dictionary) -> int:
	var source_class: int = int(source.get("power_source_class", source.get("source_class", 1)))
	var object_type: String = str(source.get("object_type", "")).strip_edges().to_lower()
	if object_type == "power_source_class_2" or object_type.find("class_2") != -1:
		source_class = 2
	elif object_type == "power_source_class_3" or object_type.find("class_3") != -1:
		source_class = 3
	source_class = clampi(source_class, 1, 3)
	var canonical_capacity: int = source_class + 3
	if source.has("outlet_capacity"):
		return maxi(1, int(source.get("outlet_capacity", canonical_capacity)))
	return canonical_capacity

func preview_power_source_load_heat_for_network(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var source_reports: Array[Dictionary] = []
	var warnings: Array[String] = []
	var report := {
		"updated": 0,
		"sources": source_reports,
		"warnings": warnings
	}
	for network_id_variant in networks.keys():
		var network_id := str(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var consumer_count := 0
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_load_consumer_object(object_data):
				consumer_count += 1
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = object_variant
			if not _is_power_source_object(source):
				continue
			var source_capacity := _get_power_source_capacity_for_load(source)
			var overheat_threshold := int(source.get("overheat_threshold", 0))
			var current_heat := int(source.get("current_heat", 0))
			var source_overloaded := consumer_count > source_capacity
			var heat_from_connections := maxi(0, consumer_count - source_capacity)
			var projected_heat := maxi(0, current_heat - int(source.get("cooling_received", 0))) + int(source.get("working_heat", 0)) + heat_from_connections
			var projected_state := str(source.get("state", "")).strip_edges().to_lower()
			if overheat_threshold > 0 and projected_heat >= overheat_threshold:
				projected_state = "overheated"
			source_reports.append({
				"object_id": str(source.get("id", "")),
				"network_id": network_id,
				"source_load": consumer_count,
				"source_capacity": source_capacity,
				"source_overloaded": source_overloaded,
				"current_heat": projected_heat,
				"overheat_threshold": overheat_threshold,
				"state": projected_state
			})
			report["updated"] = int(report.get("updated", 0)) + 1
	return report

func update_power_source_load_heat_for_network(filter: String = "") -> Dictionary:
	PowerSystemRef.recalculate_network(mission_world_objects, filter)
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var source_reports: Array[Dictionary] = []
	var warnings: Array[String] = []
	var report := {
		"updated": 0,
		"sources": source_reports,
		"warnings": warnings
	}
	for network_id_variant in networks.keys():
		var network_id := str(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var consumer_count := 0
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_load_consumer_object(object_data):
				consumer_count += 1
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = object_variant
			if not _is_power_source_object(source):
				continue
			var source_capacity := _get_power_source_capacity_for_load(source)
			source["source_load"] = consumer_count
			source["source_capacity"] = source_capacity
			source["source_overloaded"] = consumer_count > source_capacity
			source["heat_from_connections"] = maxi(0, consumer_count - source_capacity)
			WorldObjectCatalogRef.update_world_object_heat_state(source)
			source_reports.append({
				"object_id": str(source.get("id", "")),
				"network_id": network_id,
				"source_load": int(source.get("source_load", 0)),
				"source_capacity": int(source.get("source_capacity", source_capacity)),
				"source_overloaded": bool(source.get("source_overloaded", false)),
				"current_heat": int(source.get("current_heat", 0)),
				"overheat_threshold": int(source.get("overheat_threshold", 0)),
				"state": str(source.get("state", ""))
			})
			report["updated"] = int(report.get("updated", 0)) + 1
	return report

func preview_power_graph_state_application(filter: String = "") -> Dictionary:
	PowerSystemRef.recalculate_network(mission_world_objects, filter)
	var collected := _collect_power_network_objects()
	var networks: Dictionary = collected.get("networks", {})
	var filter_text := filter.strip_edges()
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter_text)
	var source_load_report := preview_power_source_load_heat_for_network(filter_text)
	var warnings: Array[String] = []
	var changes: Array[Dictionary] = []
	var blocked_entries: Array[Dictionary] = []
	var sources: Array[Dictionary] = []
	var nodes: Array[String] = []
	var reachable: Array[String] = []
	var result: Dictionary = {
		"filter": filter_text,
		"resolved_filter": resolved_filter,
		"sources": sources,
		"nodes": nodes,
		"reachable_object_ids": reachable,
		"blocked": blocked_entries,
		"changes": changes,
		"warnings": warnings,
		"source_load_report": source_load_report
	}
	warnings.append("Power graph combines physical 4-neighbor recalculation with legacy network-level gate blocking.")
	for network_id_variant in networks.keys():
		var network_id := str(network_id_variant)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var network_objects: Array = networks.get(network_id, [])
		var has_available_source := false
		var network_open_gate := false
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := str(object_data.get("id", "")).strip_edges()
			if not object_id.is_empty():
				nodes.append(object_id)
			if _is_power_source_object(object_data) and _is_power_source_available(object_data):
				has_available_source = true
				sources.append({"object_id": object_id, "network_id": network_id})
			var gate_state := _get_power_gate_state(object_data)
			if bool(gate_state.get("is_gate", false)) and not bool(gate_state.get("is_closed", true)):
				network_open_gate = true
				blocked_entries.append({
					"object_id": object_id,
					"network_id": network_id,
					"gate_type": str(gate_state.get("gate_type", "")),
					"reason": str(gate_state.get("reason", "blocked_by_gate"))
				})
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_source_object(object_data):
				continue
			var object_id := str(object_data.get("id", "")).strip_edges()
			var current_is_powered := bool(object_data.get("is_powered", false))
			var state := _normalize_power_gate_text(object_data.get("state", ""))
			var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
			var preview_is_powered := current_is_powered
			var reason := "no_powered_source"
			if state == "cut":
				preview_is_powered = false
				reason = "cut"
			elif state == "broken" or damaged_or_broken:
				preview_is_powered = false
				reason = "broken" if state == "broken" else "damaged"
			elif state == "damaged":
				preview_is_powered = false
				reason = "damaged"
			elif not has_available_source:
				preview_is_powered = false
				reason = "no_powered_source"
			elif bool(object_data.get("is_powered", false)):
				preview_is_powered = true
				reason = "physical_power_reachable"
			elif network_open_gate:
				preview_is_powered = false
				reason = "blocked_by_gate"
			else:
				preview_is_powered = false
				reason = "no_physical_power_path"
			if preview_is_powered:
				reachable.append(object_id)
			if preview_is_powered == current_is_powered:
				continue
			changes.append({
				"object_id": object_id,
				"network_id": network_id,
				"current_is_powered": current_is_powered,
				"preview_is_powered": preview_is_powered,
				"reason": reason
			})
	return result

func get_power_graph_preview_text(filter: String = "") -> String:
	var preview := preview_power_graph_state_application(filter)
	var lines: Array[String] = []
	lines.append("PowerGraphPreview: filter=%s sources=%d reachable=%d blocked=%d changes=%d warnings=%d" % [
		str(preview.get("filter", "")),
		(preview.get("sources", []) as Array).size(),
		(preview.get("reachable_object_ids", []) as Array).size(),
		(preview.get("blocked", []) as Array).size(),
		(preview.get("changes", []) as Array).size(),
		(preview.get("warnings", []) as Array).size()
	])
	for source_variant in preview.get("sources", []):
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = source_variant
		lines.append("SOURCE: object=%s network=%s" % [str(source.get("object_id", "")), str(source.get("network_id", ""))])
	for blocked_variant in preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		lines.append("BLOCKED: object=%s network=%s gate=%s reason=%s" % [str(blocked.get("object_id", "")), str(blocked.get("network_id", "")), str(blocked.get("gate_type", "")), str(blocked.get("reason", ""))])
	for change_variant in preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [str(change.get("object_id", "")), str(change.get("network_id", "")), str(bool(change.get("current_is_powered", false))).to_lower(), str(bool(change.get("preview_is_powered", false))).to_lower(), str(change.get("reason", ""))])
	for warning_variant in preview.get("warnings", []):
		lines.append("WARNING: %s" % str(warning_variant))
	return "\n".join(lines)

func apply_power_graph_state_from_preview(filter: String = "") -> Dictionary:
	var source_load_report := update_power_source_load_heat_for_network(filter)
	var preview := preview_power_graph_state_application(filter)
	var applied_changes: Array[Dictionary] = []
	for change_variant in preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var object_id := str(change.get("object_id", "")).strip_edges()
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty() or _is_power_source_object(object_data):
			continue
		var previous_is_powered := bool(object_data.get("is_powered", false))
		var next_is_powered := bool(change.get("preview_is_powered", false))
		var state := _normalize_power_gate_text(object_data.get("state", ""))
		var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		if next_is_powered and (state in ["damaged", "broken", "cut"] or damaged_or_broken):
			next_is_powered = false
		if previous_is_powered == next_is_powered:
			continue
		object_data["is_powered"] = next_is_powered
		if next_is_powered:
			object_data.erase("power_unavailable_reason")
		else:
			object_data["power_unavailable_reason"] = str(change.get("reason", ""))
		var applied_change := {"object_id": object_id, "network_id": str(change.get("network_id", "")), "previous_is_powered": previous_is_powered, "new_is_powered": next_is_powered, "reason": str(change.get("reason", ""))}
		var consumer_state_report := {}
		if _is_terminal_object(object_data):
			consumer_state_report = update_terminal_power_state_from_is_powered(object_data)
		elif _is_power_reactive_door_object(object_data):
			consumer_state_report = update_power_door_state_from_is_powered(object_data)
		elif _is_platform_power_consumer(object_data):
			consumer_state_report = update_platform_power_state_from_is_powered(object_data)
		if not consumer_state_report.is_empty():
			applied_change["consumer_state_report"] = consumer_state_report
		applied_changes.append(applied_change)
	return {"applied": applied_changes.size(), "changes": applied_changes, "warnings": preview.get("warnings", []), "source_load_report": source_load_report}

func execute_power_graph_apply_and_get_report_text(filter: String = "") -> String:
	var report := apply_power_graph_state_from_preview(filter)
	var lines: Array[String] = []
	lines.append("PowerGraphApply: filter=%s applied=%d warnings=%d" % [filter, int(report.get("applied", 0)), (report.get("warnings", []) as Array).size()])
	for change_variant in report.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var line := "APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [str(change.get("object_id", "")), str(change.get("network_id", "")), str(bool(change.get("previous_is_powered", false))).to_lower(), str(bool(change.get("new_is_powered", false))).to_lower(), str(change.get("reason", ""))]
		var consumer_state_report_variant: Variant = change.get("consumer_state_report", {})
		if consumer_state_report_variant is Dictionary:
			var consumer_state_report: Dictionary = consumer_state_report_variant
			if bool(consumer_state_report.get("changed", false)):
				line += " state %s -> %s" % [str(consumer_state_report.get("previous_state", "")), str(consumer_state_report.get("new_state", ""))]
		lines.append(line)
	for warning_variant in report.get("warnings", []):
		lines.append("WARNING: %s" % str(warning_variant))
	return "\n".join(lines)

func preview_power_network_state_application(filter: String = "") -> Dictionary:
	var collected := _collect_power_network_objects()
	var power_objects: Array[Dictionary] = _safe_dictionary_array(collected.get("objects", []))
	var networks: Dictionary = collected.get("networks", {})
	var sources_by_id: Dictionary = collected.get("sources_by_id", {})
	var changes: Array[Dictionary] = []
	var warnings: Array[String] = []
	var filter_text := filter.strip_edges().to_lower()
	var all_network_ids: Array[String] = []
	for network_id_variant in networks.keys():
		all_network_ids.append(str(network_id_variant))
	all_network_ids.sort()
	for network_id in all_network_ids:
		var network_objects: Array = networks.get(network_id, [])
		var network_has_available_source := false
		var has_powered_consumer := false
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var source_candidate: Dictionary = object_variant
			if not _is_power_source_object(source_candidate):
				continue
			if _is_power_source_available(source_candidate):
				network_has_available_source = true
			else:
				var source_state := str(source_candidate.get("state", "")).strip_edges().to_lower()
				var source_damaged := bool(source_candidate.get("damaged", false)) or bool(source_candidate.get("broken", false))
				if source_state in ["overheated", "damaged"] or source_damaged:
					var source_id := str(source_candidate.get("id", "")).strip_edges()
					warnings.append("Source %s in network %s is unavailable: overheated/damaged." % [source_id, network_id if not network_id.is_empty() else "-"])
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _is_power_source_object(object_data):
				continue
			if bool(object_data.get("is_powered", false)):
				has_powered_consumer = true
				break
		if has_powered_consumer and not network_has_available_source:
			warnings.append("Network %s has powered consumers but no available source." % (network_id if not network_id.is_empty() else "-"))
		for object_variant in network_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := str(object_data.get("id", "")).strip_edges()
			var object_state := str(object_data.get("state", "")).strip_edges().to_lower()
			var object_damaged := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
			var current_is_powered := bool(object_data.get("is_powered", false))
			var preview_is_powered := current_is_powered
			var reason := "source"
			if _is_power_source_object(object_data):
				preview_is_powered = current_is_powered
				reason = "source"
			elif object_state == "damaged" or object_damaged:
				preview_is_powered = false
				reason = "damaged"
			elif object_state == "overheated":
				preview_is_powered = false
				reason = "overheated"
			else:
				preview_is_powered = network_has_available_source
				reason = "powered_source_available" if network_has_available_source else "no_powered_source"
			var connected_source_id := str(object_data.get("connected_power_source_id", "")).strip_edges()
			if not connected_source_id.is_empty() and not sources_by_id.has(connected_source_id):
				warnings.append("Power object %s connected_power_source_id points to missing source %s." % [object_id, connected_source_id])
			if network_id.is_empty():
				warnings.append("Power object %s has no network id." % object_id)
			if preview_is_powered == current_is_powered:
				continue
			var change_line := "object=%s network=%s reason=%s" % [object_id, network_id, reason]
			if not filter_text.is_empty() and change_line.to_lower().find(filter_text) == -1:
				continue
			changes.append({
				"object_id": object_id,
				"network_id": network_id,
				"current_is_powered": current_is_powered,
				"preview_is_powered": preview_is_powered,
				"reason": reason
			})
	var filtered_warnings: Array[String] = []
	for warning in warnings:
		if filter_text.is_empty() or warning.to_lower().find(filter_text) != -1:
			filtered_warnings.append(warning)
	return {"networks": networks.size(), "objects": power_objects.size(), "changes": changes, "warnings": filtered_warnings}

func get_power_network_state_preview_text(filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkStatePreview: networks=%d objects=%d changes=%d warnings=%d" % [
		int(preview.get("networks", 0)),
		int(preview.get("objects", 0)),
		changes.size(),
		warnings.size()
	])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("CHANGE: object=%s network=%s is_powered %s -> %s reason=%s" % [
			str(change.get("object_id", "")),
			str(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			str(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)

func apply_power_network_state_from_preview(filter: String = "") -> Dictionary:
	var preview := preview_power_network_state_application(filter)
	var preview_changes: Array = preview.get("changes", [])
	var applied_changes: Array[Dictionary] = []
	var warnings: Array[String] = []
	for change_variant in preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var object_id := str(change.get("object_id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_data := get_world_object_by_id(object_id)
		if object_data.is_empty():
			warnings.append("Power apply skipped missing object %s." % object_id)
			continue
		if not _is_power_network_object(object_data):
			warnings.append("Power apply skipped non-power object %s." % object_id)
			continue
		if _is_power_source_object(object_data):
			continue
		var previous_is_powered := bool(object_data.get("is_powered", false))
		var preview_is_powered := bool(change.get("preview_is_powered", false))
		var object_state := str(object_data.get("state", "")).strip_edges().to_lower()
		var object_damaged := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		var blocked_from_power_up := object_state in ["damaged", "overheated"] or object_damaged
		var new_is_powered := preview_is_powered
		if blocked_from_power_up and preview_is_powered:
			new_is_powered = false
		if previous_is_powered == new_is_powered:
			continue
		object_data["is_powered"] = new_is_powered
		applied_changes.append({
			"object_id": object_id,
			"network_id": str(change.get("network_id", "")),
			"previous_is_powered": previous_is_powered,
			"new_is_powered": new_is_powered,
			"reason": str(change.get("reason", ""))
		})
	for preview_warning in preview.get("warnings", []):
		var warning_text := str(preview_warning).strip_edges()
		if warning_text.is_empty():
			continue
		warnings.append(warning_text)
	return {"applied": applied_changes.size(), "changes": applied_changes, "warnings": warnings}



func _apply_graph_power_after_world_object_power_change(object_data: Dictionary, reason: String) -> Dictionary:
	var filter := _get_power_event_filter_for_object(object_data)
	return apply_power_network_after_explicit_power_event(reason, filter)

func preview_cable_path(cable_reel_id: String, target_id: String) -> Dictionary:
	var reel := get_world_object_by_id(cable_reel_id.strip_edges())
	var target := get_world_object_by_id(target_id.strip_edges())
	if reel.is_empty() or target.is_empty():
		return {"valid": false, "reason": "target_not_connectable", "length": 0, "max_length": 0, "path_cells": []}
	var reel_cell := WorldObjectCatalogRef.to_world_cell(reel.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var target_cell := WorldObjectCatalogRef.to_world_cell(target.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var path_cells: Array = []
	var x_step := signi(target_cell.x - reel_cell.x)
	var y_step := signi(target_cell.y - reel_cell.y)
	var current := reel_cell
	while current.x != target_cell.x:
		current = Vector2i(current.x + x_step, current.y)
		path_cells.append(current)
	while current.y != target_cell.y:
		current = Vector2i(current.x, current.y + y_step)
		path_cells.append(current)
	return validate_cable_path(reel, target, path_cells)

func validate_cable_path(cable_reel: Dictionary, target: Dictionary, path_cells: Array = []) -> Dictionary:
	if cable_reel.is_empty() or target.is_empty():
		return {"valid": false, "reason": "target_not_connectable", "length": 0, "max_length": 0, "path_cells": []}
	if bool(cable_reel.get("cut", false)):
		return {"valid": false, "reason": "cable_cut", "length": 0, "max_length": 0, "path_cells": path_cells}
	if bool(cable_reel.get("damaged", false)):
		return {"valid": false, "reason": "cable_damaged", "length": 0, "max_length": 0, "path_cells": path_cells}
	var target_type: String = str(target.get("object_type", "")).strip_edges().to_lower()
	if not bool(target.get("can_connect_cable", false)) and not (target_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]):
		return {"valid": false, "reason": "no_socket", "length": 0, "max_length": 0, "path_cells": path_cells}
	var max_length := maxi(1, int(cable_reel.get("max_cable_length", 5)))
	var length := path_cells.size()
	if length > max_length:
		return {"valid": false, "reason": "too_far", "length": length, "max_length": max_length, "path_cells": path_cells}
	for path_cell_variant in path_cells:
		if typeof(path_cell_variant) != TYPE_VECTOR2I:
			continue
		var path_cell: Vector2i = path_cell_variant
		var blocker := get_world_object_at_cell(path_cell)
		if blocker.is_empty():
			continue
		if bool(blocker.get("blocks_movement", false)) or str(blocker.get("state", "")) == "closed":
			return {"valid": false, "reason": "path_blocked", "length": length, "max_length": max_length, "path_cells": path_cells}
	var cable_preview: Dictionary = cable_reel.duplicate(true)
	cable_preview["cable_path_cells"] = path_cells.duplicate(true)
	var topology_validation: Dictionary = CableTopologyServiceRef.validate_cable_object(mission_world_objects, cable_preview)
	if not bool(topology_validation.get("ok", false)):
		return {"valid": false, "reason": "invalid_cable_junction", "message": str(topology_validation.get("message", CableTopologyServiceRef.ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH)), "length": length, "max_length": max_length, "path_cells": path_cells, "cable_topology": topology_validation}
	return {"valid": true, "reason": "ok", "length": length, "max_length": max_length, "path_cells": path_cells}

func can_connect_cable_reel_to_target(cable_reel: Dictionary, target: Dictionary) -> Dictionary:
	var path_report := preview_cable_path(str(cable_reel.get("id", "")), str(target.get("id", "")))
	if not bool(path_report.get("valid", false)):
		return path_report
	return {"valid": true, "reason": "ok", "length": int(path_report.get("length", 0)), "max_length": int(path_report.get("max_length", 0)), "path_cells": path_report.get("path_cells", [])}

func _is_power_cable_unavailable(cable: Dictionary) -> bool:
	var cable_state: String = str(cable.get("state", "")).strip_edges().to_lower()
	return cable_state in ["cut", "damaged", "broken", "destroyed"] or bool(cable.get("cut", false)) or bool(cable.get("damaged", false)) or bool(cable.get("broken", false))

func _normalize_power_cable_reel_state(cable: Dictionary) -> void:
	if cable.is_empty():
		return
	var legacy_target_id: String = str(cable.get("cable_endpoint_b_id", "")).strip_edges()
	var has_explicit_end_fields: bool = cable.has("end_1_state") or cable.has("end_1_target_id") or cable.has("end_2_state") or cable.has("end_2_target_id")
	if not has_explicit_end_fields and bool(cable.get("connected", false)) and not legacy_target_id.is_empty():
		cable["end_1_state"] = "connected"
		cable["end_1_target_id"] = legacy_target_id
		var legacy_path_variant: Variant = cable.get("cable_path_cells", [])
		cable["end_1_path_cells"] = legacy_path_variant.duplicate(true) if legacy_path_variant is Array else []
		cable["end_1_cable_length"] = maxi(0, int(cable.get("cable_length", 0)))
	var cable_unavailable: bool = _is_power_cable_unavailable(cable)
	var first_connected_target_id: String = ""
	var first_connected_path_cells: Array = []
	var first_connected_length: int = 0
	for end_index in range(1, 3):
		var state_key: String = "end_%d_state" % end_index
		var target_key: String = "end_%d_target_id" % end_index
		var path_key: String = "end_%d_path_cells" % end_index
		var length_key: String = "end_%d_cable_length" % end_index
		var has_end_state: bool = cable.has(state_key)
		var end_state: String = str(cable.get(state_key, "on_reel")).strip_edges().to_lower()
		if not has_end_state and not str(cable.get(target_key, "")).strip_edges().is_empty():
			end_state = "connected"
		if not (end_state in ["on_reel", "held", "connected", "disconnected"]):
			end_state = "on_reel"
		var end_target_id: String = str(cable.get(target_key, "")).strip_edges()
		var end_has_target: bool = end_state == "connected" and not end_target_id.is_empty()
		cable[state_key] = end_state
		cable[target_key] = end_target_id if end_has_target else ""
		cable["connected_side_%d" % end_index] = end_has_target and not cable_unavailable
		if end_has_target:
			if first_connected_target_id.is_empty():
				first_connected_target_id = end_target_id
				var path_variant: Variant = cable.get(path_key, [])
				first_connected_path_cells = path_variant.duplicate(true) if path_variant is Array else []
				first_connected_length = maxi(0, int(cable.get(length_key, first_connected_path_cells.size())))
			continue
		cable[path_key] = []
		cable[length_key] = 0
	var has_operational_connection: bool = not cable_unavailable and not first_connected_target_id.is_empty()
	cable["connected"] = has_operational_connection
	cable["connected_side"] = has_operational_connection
	cable["disconnected"] = not has_operational_connection
	cable["cable_endpoint_b_id"] = first_connected_target_id
	cable["cable_path_cells"] = first_connected_path_cells
	cable["cable_length"] = first_connected_length

func connect_cable_reel_to_target(cable_reel_id: String, target_id: String, end_index: int = 1) -> Dictionary:
	var normalized_reel_id: String = cable_reel_id.strip_edges()
	var normalized_target_id: String = target_id.strip_edges()
	if end_index < 1 or end_index > 2:
		return {"success": false, "reason": "invalid_end", "message": "Cable end index must be 1 or 2."}
	if normalized_target_id.is_empty():
		return {"success": false, "reason": "target_missing", "message": "Cable target is missing."}
	var cable_reel := get_world_object_by_id(normalized_reel_id)
	if cable_reel.is_empty():
		return {"success": false, "reason": "target_not_found", "message": "Cable reel not found."}
	var target := get_world_object_by_id(normalized_target_id)
	if target.is_empty():
		return {"success": false, "reason": "target_not_found", "message": "Cable target not found."}
	_normalize_power_cable_reel_state(cable_reel)
	if _is_power_cable_unavailable(cable_reel):
		return {"success": false, "reason": "cable_damaged", "message": "Cable reel must be repaired first."}
	var can_connect := can_connect_cable_reel_to_target(cable_reel, target)
	if not bool(can_connect.get("valid", false)):
		return {"success": false, "reason": str(can_connect.get("reason", "target_not_connectable")), "message": str(can_connect.get("message", "Cable target is not connectable.")), "path": can_connect}
	cable_reel["state"] = "connected"
	cable_reel["end_%d_state" % end_index] = "connected"
	cable_reel["end_%d_target_id" % end_index] = normalized_target_id
	cable_reel["end_%d_path_cells" % end_index] = can_connect.get("path_cells", [])
	cable_reel["end_%d_cable_length" % end_index] = int(can_connect.get("length", 0))
	cable_reel["cable_endpoint_a_id"] = str(cable_reel.get("id", "")).strip_edges()
	cable_reel["cable_max_length"] = int(can_connect.get("max_length", 0))
	_normalize_power_cable_reel_state(cable_reel)
	var report := _apply_graph_power_after_world_object_power_change(cable_reel, "cable_connected")
	return {"success": true, "reason": "ok", "message": "Cable end connected.", "apply": report, "path": can_connect, "reel_id": normalized_reel_id, "end_index": end_index, "target_id": normalized_target_id}

func disconnect_cable_from_target(cable_id_or_reel_id: String, target_id: String = "", end_index: int = 0) -> Dictionary:
	var normalized_cable_id: String = cable_id_or_reel_id.strip_edges()
	if end_index < 0 or end_index > 2:
		return {"success": false, "reason": "invalid_end", "message": "Cable end index must be 1 or 2."}
	var cable := get_world_object_by_id(normalized_cable_id)
	if cable.is_empty():
		return {"success": false, "reason": "target_not_found", "message": "Cable reel not found."}
	_normalize_power_cable_reel_state(cable)
	var normalized_target_id: String = target_id.strip_edges()
	var disconnected_any: bool = false
	for candidate_end in range(1, 3):
		if end_index > 0 and candidate_end != end_index:
			continue
		var target_key: String = "end_%d_target_id" % candidate_end
		if not normalized_target_id.is_empty() and str(cable.get(target_key, "")).strip_edges() != normalized_target_id:
			continue
		if str(cable.get(target_key, "")).strip_edges().is_empty() and str(cable.get("end_%d_state" % candidate_end, "on_reel")) != "connected":
			continue
		cable["end_%d_state" % candidate_end] = "disconnected"
		cable[target_key] = ""
		disconnected_any = true
	if not disconnected_any:
		return {"success": false, "reason": "target_missing", "message": "Cable end is not connected."}
	_normalize_power_cable_reel_state(cable)
	cable["state"] = "connected" if bool(cable.get("connected", false)) else "disconnected"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_disconnected")
	return {"success": true, "reason": "ok", "message": "Cable end disconnected.", "apply": report}

func cut_power_cable(cable_id: String) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	cable["state"] = "cut"
	cable["cut"] = true
	cable["connected"] = false
	cable["disconnected"] = true
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_cut")
	return {"success": true, "reason": "cable_cut", "apply": report}

func repair_power_cable(cable_id: String, normalize_repaired: bool = false) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	if not normalize_repaired and not bool(cable.get("cut", false)) and not bool(cable.get("damaged", false)) and not bool(cable.get("broken", false)) and not (str(cable.get("state", "")).strip_edges().to_lower() in ["damaged", "broken"]):
		return {"success": false, "reason": "ok"}
	cable["cut"] = false
	cable["damaged"] = false
	cable["broken"] = false
	var is_cable_reel: bool = str(cable.get("object_type", "")).strip_edges().to_lower() == "power_cable_reel" or cable.has("end_1_state") or cable.has("end_1_target_id") or cable.has("end_2_state") or cable.has("end_2_target_id")
	if is_cable_reel:
		for repaired_end in range(1, 3):
			if str(cable.get("end_%d_target_id" % repaired_end, "")).strip_edges().is_empty():
				cable["end_%d_state" % repaired_end] = "on_reel"
		_normalize_power_cable_reel_state(cable)
	cable["state"] = "connected" if bool(cable.get("connected", false)) else "ok"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_repaired")
	return {"success": true, "reason": "cable_repaired", "apply": report}

func reconnect_power_cable(cable_id: String) -> Dictionary:
	var cable := get_world_object_by_id(cable_id.strip_edges())
	if cable.is_empty():
		return {"success": false, "reason": "target_not_connectable"}
	if bool(cable.get("cut", false)) or bool(cable.get("damaged", false)):
		return {"success": false, "reason": "cable_damaged"}
	var topology_validation: Dictionary = CableTopologyServiceRef.validate_cable_object(mission_world_objects, cable)
	if not bool(topology_validation.get("ok", false)):
		return {"success": false, "reason": "invalid_cable_junction", "message": str(topology_validation.get("message", CableTopologyServiceRef.ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH)), "cable_topology": topology_validation}
	cable["connected"] = true
	cable["disconnected"] = false
	cable["state"] = "connected"
	var report := _apply_graph_power_after_world_object_power_change(cable, "cable_reconnected")
	return {"success": true, "reason": "cable_reconnected", "apply": report}

func update_power_source_overheat_recovery_for_network(filter: String = "") -> Dictionary:
	var resolved_filter := _resolve_power_graph_filter_to_network_id(filter.strip_edges())
	var recovered: Array[Dictionary] = []
	var warnings: Array[String] = []
	for object_data in mission_world_objects:
		if not _is_power_source_object(object_data):
			continue
		var network_id := _get_power_network_id(object_data)
		if not resolved_filter.is_empty() and network_id != resolved_filter:
			continue
		var prev_state := str(object_data.get("state", "")).strip_edges().to_lower()
		var prev_is_powered := bool(object_data.get("is_powered", false))
		var prev_overheated_state_before := str(object_data.get("overheated_state_before", object_data.get("powered_state_before_unpowered", "active"))).strip_edges().to_lower()
		var prev_damaged_flag := bool(object_data.get("damaged", false))
		var prev_broken_flag := bool(object_data.get("broken", false))
		var prev_destroyed_flag := bool(object_data.get("destroyed", false))
		var prev_current_heat := int(object_data.get("current_heat", 0))
		var prev_threshold := int(object_data.get("overheat_threshold", 0))
		var has_prev_damage_flags := prev_damaged_flag or prev_broken_flag or prev_destroyed_flag
		var prev_state_is_damage := prev_state in ["damaged", "broken", "destroyed"]
		var prev_overheated_state_is_damage := prev_overheated_state_before in ["damaged", "broken", "destroyed"]
		WorldObjectCatalogRef.update_world_object_heat_state(object_data)
		var next_state := str(object_data.get("state", "")).strip_edges().to_lower()
		var threshold := int(object_data.get("overheat_threshold", 0))
		var heat := int(object_data.get("current_heat", 0))
		if prev_state != "overheated":
			continue
		if has_prev_damage_flags or prev_state_is_damage or prev_overheated_state_is_damage or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)) or next_state in ["damaged", "broken", "destroyed"]:
			if prev_overheated_state_is_damage:
				object_data["state"] = prev_overheated_state_before
			elif prev_state_is_damage:
				object_data["state"] = prev_state
			elif has_prev_damage_flags and next_state == "active":
				object_data["state"] = "unpowered"
			object_data["is_powered"] = false
			object_data["power_unavailable_reason"] = "source_damage_state"
			warnings.append("Source %s remains unavailable due to source_damage_state." % str(object_data.get("id", "")))
			continue
		if threshold > 0 and heat >= threshold:
			continue
		var restore_state := prev_overheated_state_before
		if restore_state in ["", "unpowered", "overheated", "damaged", "broken", "destroyed"]:
			restore_state = "active"
		object_data["state"] = restore_state
		object_data["power_unavailable_reason"] = ""
		recovered.append({
			"object_id": str(object_data.get("id", "")),
			"network_id": network_id,
			"previous_state": prev_state,
			"new_state": restore_state,
			"current_heat": heat,
			"overheat_threshold": threshold,
			"previous_is_powered": prev_is_powered,
			"previous_overheated_state_before": prev_overheated_state_before,
			"previous_damage_flags": {"damaged": prev_damaged_flag, "broken": prev_broken_flag, "destroyed": prev_destroyed_flag},
			"previous_current_heat": prev_current_heat,
			"previous_overheat_threshold": prev_threshold
		})
	return {"filter": filter.strip_edges(), "resolved_filter": resolved_filter, "recovered": recovered, "warnings": warnings}

func execute_power_source_recovery_apply(filter: String = "") -> Dictionary:
	var recovery := update_power_source_overheat_recovery_for_network(filter)
	var apply := apply_power_network_after_explicit_power_event("source_cooling_recovered", str(recovery.get("resolved_filter", filter)))
	return {"recovery": recovery, "apply": apply}

func apply_power_network_after_explicit_power_event(reason: String = "", filter: String = "") -> Dictionary:
	PowerSystemRef.recalculate_network(mission_world_objects, filter)
	refresh_generic_cable_runtime_state(filter)
	var report := apply_power_graph_state_from_preview(filter)
	return {
		"event_reason": reason,
		"applied": int(report.get("applied", 0)),
		"changes": report.get("changes", []),
		"warnings": report.get("warnings", [])
	}

func execute_power_event_apply_and_get_report_text(reason: String = "", filter: String = "") -> String:
	var report := apply_power_network_after_explicit_power_event(reason, filter)
	var changes: Array = report.get("changes", [])
	var warnings: Array = report.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerEventApply: reason=%s applied=%d warnings=%d" % [reason, int(report.get("applied", 0)), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [
			str(change.get("object_id", "")),
			str(change.get("network_id", "")),
			str(bool(change.get("previous_is_powered", false))).to_lower(),
			str(bool(change.get("new_is_powered", false))).to_lower(),
			str(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % str(warning))
	return "\n".join(lines)

func get_power_event_apply_preview_text(reason: String = "", filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerEventApplyPreview: reason=%s changes=%d warnings=%d" % [reason, changes.size(), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [
			str(change.get("object_id", "")),
			str(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			str(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % str(warning))
	return "\n".join(lines)

func execute_power_network_apply_and_get_report_text(filter: String = "") -> String:
	var report := apply_power_network_state_from_preview(filter)
	var changes: Array = report.get("changes", [])
	var warnings: Array = report.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkApply: applied=%d warnings=%d" % [int(report.get("applied", 0)), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("APPLIED: object=%s network=%s is_powered %s -> %s reason=%s" % [
			str(change.get("object_id", "")),
			str(change.get("network_id", "")),
			str(bool(change.get("previous_is_powered", false))).to_lower(),
			str(bool(change.get("new_is_powered", false))).to_lower(),
			str(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % str(warning))
	return "\n".join(lines)

func execute_power_network_apply_debug_command(filter: String = "") -> String:
	return execute_power_network_apply_and_get_report_text(filter)

func get_power_network_apply_debug_preview_text(filter: String = "") -> String:
	return get_power_network_apply_preview_report_text(filter)

func get_power_network_apply_preview_report_text(filter: String = "") -> String:
	var preview := preview_power_network_state_application(filter)
	var changes: Array = preview.get("changes", [])
	var warnings: Array = preview.get("warnings", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkApplyPreview: changes=%d warnings=%d" % [changes.size(), warnings.size()])
	for change_variant in changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		lines.append("WOULD_APPLY: object=%s network=%s is_powered %s -> %s reason=%s" % [
			str(change.get("object_id", "")),
			str(change.get("network_id", "")),
			str(bool(change.get("current_is_powered", false))).to_lower(),
			str(bool(change.get("preview_is_powered", false))).to_lower(),
			str(change.get("reason", ""))
		])
	for warning in warnings:
		lines.append("WARNING: %s" % str(warning))
	return "\n".join(lines)

func _get_power_network_summary_lines(filter: String = "") -> Array[String]:
	var grouped := {}
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		var network_id := _get_power_network_id(object_data)
		if not grouped.has(network_id):
			grouped[network_id] = []
		grouped[network_id].append(object_data)
	var ids: Array[String] = []
	for key in grouped.keys():
		ids.append(str(key))
	ids.sort()
	var filter_text := filter.strip_edges().to_lower()
	var lines: Array[String] = []
	for network_id in ids:
		var objects: Array = grouped.get(network_id, [])
		var object_count := 0
		var source_count := 0
		var cable_count := 0
		var socket_count := 0
		var network_powered := false
		var overheated_sources := 0
		var damaged_count := 0
		var connection_count := 0
		for object_variant in objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			object_count += 1
			var object_type := str(object_data.get("object_type", "")).strip_edges().to_lower()
			var state := str(object_data.get("state", "")).strip_edges().to_lower()
			var is_source := _is_power_source_object(object_data)
			if is_source:
				source_count += 1
			if object_type.find("cable") != -1 or object_type == "power_cable":
				cable_count += 1
			if object_type.find("socket") != -1 or object_type == "power_socket":
				socket_count += 1
			if bool(object_data.get("is_powered", false)) or state in ["active", "switch_on", "connected"]:
				network_powered = true
			var threshold := int(object_data.get("overheat_threshold", 0))
			var current_heat := int(object_data.get("current_heat", 0))
			if is_source and (state == "overheated" or (threshold > 0 and current_heat >= threshold)):
				overheated_sources += 1
			if state == "damaged" or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)):
				damaged_count += 1
			if state == "connected" or bool(object_data.get("connected", false)):
				connection_count += 1
		var network_text := network_id if not network_id.is_empty() else "-"
		var line := "network=%s | objects=%d | sources=%d | cables=%d | sockets=%d | powered=%s | overheated_sources=%d | damaged=%d | connections=%d" % [
			network_text, object_count, source_count, cable_count, socket_count, str(network_powered).to_lower(), overheated_sources, damaged_count, connection_count
		]
		if not filter_text.is_empty() and line.to_lower().find(filter_text) == -1:
			continue
		lines.append(line)
	return lines

func get_power_network_debug_summary_text(filter: String = "") -> String:
	var lines := _get_power_network_summary_lines(filter)
	if lines.is_empty():
		return "PowerNetworkSummary:\nnone" if filter.strip_edges().is_empty() else "PowerNetworkSummary:\nnone (filter=%s)" % filter.strip_edges().to_lower()
	return "PowerNetworkSummary:\n%s" % "\n".join(lines)

func _build_power_network_debug_object(object_id: String, object_type: String, network_id: String, overrides: Dictionary = {}) -> Dictionary:
	var object_data := {
		"id": object_id,
		"object_group": "power",
		"object_type": object_type,
		"power_network_id": network_id,
		"state": "active",
		"is_powered": false,
		"current_heat": 0,
		"overheat_threshold": 0,
		"connected": false
	}
	for key in overrides.keys():
		object_data[key] = overrides[key]
	return object_data

func validate_power_network_runtime_state() -> Dictionary:
	var warnings: Array[String] = []
	var errors: Array[String] = []
	var collected := _collect_power_network_objects()
	var power_objects: Array[Dictionary] = _safe_dictionary_array(collected.get("objects", []))
	var networks: Dictionary = collected.get("networks", {})
	var sources_by_id: Dictionary = collected.get("sources_by_id", {})
	var source_ids := {}
	for source_id in sources_by_id.keys():
		source_ids[str(source_id)] = true
	var network_has_powered_source := {}
	for object_data in power_objects:
		var object_id := str(object_data.get("id", "")).strip_edges()
		var network_id := _get_power_network_id(object_data)
		if network_id.is_empty():
			warnings.append("Power object %s has no network id." % object_id)
		if _is_power_source_object(object_data):
			var state := str(object_data.get("state", "")).strip_edges().to_lower()
			var powered_source := bool(object_data.get("is_powered", false)) and state != "overheated"
			if powered_source:
				network_has_powered_source[network_id] = true
	for object_data in power_objects:
		var object_id := str(object_data.get("id", "")).strip_edges()
		var current_heat := int(object_data.get("current_heat", 0))
		var threshold := int(object_data.get("overheat_threshold", 0))
		if current_heat < 0:
			errors.append("Power object %s has negative current_heat (%d)." % [object_id, current_heat])
		if threshold < 0:
			errors.append("Power object %s has negative overheat_threshold (%d)." % [object_id, threshold])
		var state_text := str(object_data.get("state", "")).strip_edges().to_lower()
		var damaged_or_broken := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false))
		if _is_power_source_object(object_data):
			if not bool(object_data.get("blocks_movement", false)):
				warnings.append("Power source %s must block movement." % object_id)
			if threshold > 0 and current_heat >= threshold and state_text != "overheated":
				warnings.append("Power source %s current_heat >= overheat_threshold but state is not overheated." % object_id)
			if threshold > 0 and state_text == "overheated" and current_heat < threshold and not damaged_or_broken:
				warnings.append("Power source %s state is overheated but current_heat < overheat_threshold and object is not damaged/broken." % object_id)
		var linked_source_id := str(object_data.get("connected_power_source_id", "")).strip_edges()
		if not linked_source_id.is_empty() and not source_ids.has(linked_source_id):
			warnings.append("Power object %s connected_power_source_id points to missing source %s." % [object_id, linked_source_id])
		var logical_source_id: String = str(object_data.get("power_source_id", object_data.get("power_network_id", ""))).strip_edges()
		var validation_type: String = str(object_data.get("object_type", "")).strip_edges().to_lower()
		if not logical_source_id.is_empty() and source_ids.has(logical_source_id) and validation_type != "light" and not _is_power_source_object(object_data):
			var physical_source_id: String = str(object_data.get("physical_connection_source_id", "")).strip_edges()
			if physical_source_id != logical_source_id:
				warnings.append("Power object %s is linked to source %s but has no physical wire path." % [object_id, logical_source_id])
		if validation_type.begins_with("fuse_box") or validation_type == "fuse_block":
			var fuse_cell: Vector2i = _deserialize_cell_variant(object_data.get("position", Vector2i(-1, -1)))
			var connected_wire_count: int = _count_adjacent_power_wires(fuse_cell, object_id)
			if connected_wire_count > 2:
				warnings.append("Fuse block %s has more than 2 adjacent/connected wires (%d)." % [object_id, connected_wire_count])
	for network_id in networks.keys():
		var objects: Array = networks[network_id]
		var has_source := false
		var has_cable_or_socket := false
		var has_powered_source := bool(network_has_powered_source.get(network_id, false))
		for object_variant in objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			var object_id := str(object_data.get("id", "")).strip_edges()
			var object_type := str(object_data.get("object_type", "")).strip_edges().to_lower()
			var state := str(object_data.get("state", "")).strip_edges().to_lower()
			var connected := state == "connected" or bool(object_data.get("connected", false))
			var is_source := _is_power_source_object(object_data)
			if is_source:
				has_source = true
				if object_data.has("allowed_connections"):
					var allowed := int(object_data.get("allowed_connections", -1))
					if allowed >= 0:
						var source_connections := 0
						for object_variant_2 in objects:
							if typeof(object_variant_2) != TYPE_DICTIONARY:
								continue
							var connected_object: Dictionary = object_variant_2
							var connected_source_id := str(connected_object.get("connected_power_source_id", "")).strip_edges()
							if connected_source_id == object_id:
								source_connections += 1
						if source_connections > allowed:
							warnings.append("Power source %s connections (%d) exceed allowed_connections (%d)." % [object_id, source_connections, allowed])
			if object_type.find("cable") != -1 or object_type.find("socket") != -1:
				has_cable_or_socket = true
			if connected and not has_powered_source:
				warnings.append("Connected power object %s is in network %s but no source is powered." % [object_id, str(network_id if not str(network_id).is_empty() else "-")])
			if bool(object_data.get("is_powered", false)) and not has_powered_source:
				warnings.append("Power object %s is_powered=true but network %s has no powered source." % [object_id, str(network_id if not str(network_id).is_empty() else "-")])
		if has_cable_or_socket and not has_source:
			warnings.append("Network %s has cables/sockets but no source." % str(network_id if not str(network_id).is_empty() else "-"))
	return {"valid": errors.is_empty(), "networks": networks.size(), "objects": power_objects.size(), "warnings": warnings, "errors": errors}

func get_power_network_validation_text() -> String:
	var validation := validate_power_network_runtime_state()
	var warnings: Array[String] = validation.get("warnings", [])
	var errors: Array[String] = validation.get("errors", [])
	var lines: Array[String] = []
	lines.append("PowerNetworkValidation: valid=%s networks=%d objects=%d warnings=%d errors=%d" % [
		str(bool(validation.get("valid", false))).to_lower(),
		int(validation.get("networks", 0)),
		int(validation.get("objects", 0)),
		warnings.size(),
		errors.size()
	])
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	for err in errors:
		lines.append("ERROR: %s" % err)
	return "\n".join(lines)

func validate_power_network_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var temp_objects: Array[Dictionary] = []
	var temp_ids := {}
	var base_size := mission_world_objects.size()
	var unchanged_snapshot: Array = []
	for object_data in mission_world_objects:
		unchanged_snapshot.append(object_data)
	temp_objects.append(_build_power_network_debug_object("power_debug_source_no_threshold", "power_source", "power_debug_no_threshold", {
		"is_powered": true,
		"current_heat": 0
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheated", "power_source", "power_debug_overheated", {
		"state": "overheated",
		"is_powered": false,
		"current_heat": 0,
		"overheat_threshold": 3
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_before_source", "power_cable", "power_debug_order", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_order"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_order", "power_source", "power_debug_order", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_missing_source", "power_cable", "power_debug_missing_source", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_missing"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_limit", "power_source", "power_debug_limit", {
		"allowed_connections": 1,
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_limit_a", "power_cable", "power_debug_limit", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_limit"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_limit_b", "power_cable", "power_debug_limit", {
		"state": "connected",
		"connected": true,
		"connected_power_source_id": "power_debug_source_limit"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_generic_connected", "power_source", "power_debug_generic_connected", {
		"allowed_connections": 0
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_generic_connected", "power_cable", "power_debug_generic_connected", {
		"state": "connected",
		"connected": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_negative_heat", "power_cable", "power_debug_negative_heat", {
		"current_heat": -1
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source", "power_source", "power_debug_preview_active", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_cable", "power_cable", "power_debug_preview_active", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source_overheated", "power_source", "power_debug_preview_overheated", {
		"state": "overheated",
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_cable_overheated", "power_cable", "power_debug_preview_overheated", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_source_damaged_consumer", "power_source", "power_debug_preview_damaged_consumer", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_consumer_damaged", "power_cable", "power_debug_preview_damaged_consumer", {
		"is_powered": false,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_preview_consumer_damaged_powered", "power_cable", "power_debug_preview_damaged_consumer", {
		"is_powered": true,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_a_source", "power_source", "power_debug_apply_case_a", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_a_consumer", "power_cable", "power_debug_apply_case_a", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_b_source", "power_source", "power_debug_apply_case_b", {
		"is_powered": true,
		"state": "overheated"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_b_consumer", "power_cable", "power_debug_apply_case_b", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_c_source", "power_source", "power_debug_apply_case_c", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_c_consumer", "power_cable", "power_debug_apply_case_c", {
		"is_powered": true,
		"state": "damaged"
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_source_on", "power_source", "power_debug_apply_case_d", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_source_off", "power_source", "power_debug_apply_case_d", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_apply_case_d_consumer", "power_cable", "power_debug_apply_case_d", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_event_apply_source", "power_source", "power_debug_event_apply", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_event_apply_consumer", "power_cable", "power_debug_event_apply", {
		"is_powered": false
	}))
	var debug_switch_object := _build_power_network_debug_object("power_debug_switch_toggle_object", "circuit_switch", "power_debug_switch_toggle", {
		"state": "switch_off",
		"is_powered": false
	})
	temp_objects.append(debug_switch_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_switch_toggle_source", "power_source", "power_debug_switch_toggle", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_switch_toggle_consumer", "power_cable", "power_debug_switch_toggle", {
		"is_powered": false
	}))
	var debug_fuse_object := _build_power_network_debug_object("power_debug_fuse_box", "fuse_box", "power_debug_fuse_event", {
		"state": "empty",
		"is_powered": false
	})
	temp_objects.append(debug_fuse_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_fuse_source", "power_source", "power_debug_fuse_event", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_fuse_consumer", "power_cable", "power_debug_fuse_event", {
		"is_powered": false
	}))
	var debug_cable_object := _build_power_network_debug_object("power_debug_cable_object", "power_cable", "power_debug_cable_event", {
		"state": "disconnected",
		"is_powered": false
	})
	temp_objects.append(debug_cable_object)
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_source", "power_source", "power_debug_cable_event", {
		"is_powered": true
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_cable_consumer", "power_socket", "power_debug_cable_event", {
		"is_powered": false
	}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_source", "power_source", "power_debug_graph_closed_gate", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_switch", "circuit_switch", "power_debug_graph_closed_gate", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_closed_gate_consumer", "power_socket", "power_debug_graph_closed_gate", {"is_powered": false}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_source", "power_source", "power_debug_graph_open_switch", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_gate", "circuit_switch", "power_debug_graph_open_switch", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_open_switch_consumer", "power_socket", "power_debug_graph_open_switch", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_source", "power_source", "power_debug_graph_empty_fuse", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_gate", "fuse_box", "power_debug_graph_empty_fuse", {"state": "empty"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_empty_fuse_consumer", "power_socket", "power_debug_graph_empty_fuse", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_source", "power_source", "power_debug_graph_cut_cable", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_gate", "power_cable", "power_debug_graph_cut_cable", {"state": "cut"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_cut_cable_consumer", "power_socket", "power_debug_graph_cut_cable", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_no_source_source", "power_source", "power_debug_graph_no_source", {"is_powered": false, "state": "off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_no_source_consumer", "power_socket", "power_debug_graph_no_source", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_damaged_consumer_source", "power_source", "power_debug_graph_damaged_consumer", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_graph_damaged_consumer", "power_socket", "power_debug_graph_damaged_consumer", {"is_powered": false, "state": "damaged"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_source", "power_source", "power_debug_terminal_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_switch", "circuit_switch", "power_debug_terminal_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_powered_terminal", "terminal", "power_debug_terminal_powered", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_source", "power_source", "power_debug_terminal_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_switch", "circuit_switch", "power_debug_terminal_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_blocked_terminal", "terminal", "power_debug_terminal_blocked", {"is_powered": true, "state": "active"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_damaged_source", "power_source", "power_debug_terminal_damaged", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_terminal_damaged_terminal", "terminal", "power_debug_terminal_damaged", {"is_powered": false, "state": "damaged"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_source", "power_source", "power_debug_energy_door_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_switch", "circuit_switch", "power_debug_energy_door_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_blocked_door", "door", "power_debug_energy_door_blocked", {"object_group":"door", "archetype_id":"door", "material":"energy", "door_type":"powered", "access_type":"no_key", "power_behavior":"opens_when_unpowered", "is_powered": true, "state": "closed"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_source", "power_source", "power_debug_energy_door_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_switch", "circuit_switch", "power_debug_energy_door_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_energy_door_powered_door", "door", "power_debug_energy_door_powered", {"object_group":"door", "archetype_id":"door", "material":"energy", "door_type":"powered", "access_type":"no_key", "power_behavior":"opens_when_unpowered", "is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_source", "power_source", "power_debug_platform_blocked", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_switch", "circuit_switch", "power_debug_platform_blocked", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_blocked_platform", "lifting_platform", "power_debug_platform_blocked", {"is_powered": true, "state": "active", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_source", "power_source", "power_debug_platform_powered", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_switch", "circuit_switch", "power_debug_platform_powered", {"state": "switch_on"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_powered_platform", "lifting_platform", "power_debug_platform_powered", {"is_powered": false, "state": "unpowered", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_source", "power_source", "power_debug_platform_damaged", {"is_powered": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_switch", "circuit_switch", "power_debug_platform_damaged", {"state": "switch_off"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_platform_damaged_platform", "lifting_platform", "power_debug_platform_damaged", {"is_powered": true, "state": "damaged", "height_level": 2, "damaged": true}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok", "power_source_class_2", "power_debug_source_load_ok", {"is_powered": true, "state": "active", "outlet_capacity": 2, "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok_terminal", "terminal", "power_debug_source_load_ok", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_load_ok_door", "door", "power_debug_source_load_ok", {"object_group":"door", "archetype_id":"door", "material":"energy", "door_type":"powered", "access_type":"no_key", "power_behavior":"opens_when_unpowered", "is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_source", "power_source_class_2", "power_debug_source_fallback_class2", {"is_powered": true, "state": "active", "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_terminal_a", "terminal", "power_debug_source_fallback_class2", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class2_terminal_b", "terminal", "power_debug_source_fallback_class2", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_source", "power_source_class_3", "power_debug_source_fallback_class3", {"is_powered": true, "state": "active", "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_a", "terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_b", "terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_fallback_class3_terminal_c", "terminal", "power_debug_source_fallback_class3", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_source", "power_source_class_1", "power_debug_source_overloaded", {"is_powered": true, "state": "active", "outlet_capacity": 1, "current_heat": 0, "overheat_threshold": 10}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_terminal", "terminal", "power_debug_source_overloaded", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overloaded_platform", "lifting_platform", "power_debug_source_overloaded", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_source", "power_source_class_1", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active", "outlet_capacity": 1, "current_heat": 0, "overheat_threshold": 2, "working_heat": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_terminal", "terminal", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_overheat_shutdown_platform", "lifting_platform", "power_debug_source_overheat_shutdown", {"is_powered": true, "state": "active"}))
	for object_data in temp_objects:
		mission_world_objects.append(object_data)
		var object_id := str(object_data.get("id", "")).strip_edges()
		if not object_id.is_empty():
			temp_ids[object_id] = true
	var validation := validate_power_network_runtime_state()
	var runtime_warnings: Array = validation.get("warnings", [])
	var runtime_errors: Array = validation.get("errors", [])
	var summary_text := get_power_network_debug_summary_text()
	if summary_text.find("network=power_debug_no_threshold") == -1:
		warnings.append("Expected debug network summary for power_debug_no_threshold.")
	if summary_text.find("network=power_debug_no_threshold") != -1 and summary_text.find("network=power_debug_no_threshold |") != -1:
		var no_threshold_summary := get_power_network_debug_summary_text("network=power_debug_no_threshold")
		if no_threshold_summary.find("overheated_sources=1") != -1:
			warnings.append("No-threshold source regression: power_debug_no_threshold incorrectly counted overheated source.")
	var no_threshold_warning := "Power source power_debug_source_no_threshold current_heat >= overheat_threshold but state is not overheated."
	if runtime_warnings.has(no_threshold_warning):
		warnings.append("No-threshold source regression: unexpected overheat threshold warning for power_debug_source_no_threshold.")
	var overheated_summary := get_power_network_debug_summary_text("network=power_debug_overheated")
	if overheated_summary.find("overheated_sources=1") == -1:
		warnings.append("Expected overheated source count for power_debug_overheated.")
	var order_missing_source_warning := "Power object power_debug_cable_before_source connected_power_source_id points to missing source power_debug_source_order."
	if runtime_warnings.has(order_missing_source_warning):
		warnings.append("Connected object before source produced false missing-source warning.")
	var true_missing_source_warning := "Power object power_debug_cable_missing_source connected_power_source_id points to missing source power_debug_source_missing."
	if not runtime_warnings.has(true_missing_source_warning):
		warnings.append("Missing-source warning not reported for power_debug_cable_missing_source.")
	var source_limit_warning := "Power source power_debug_source_limit connections (2) exceed allowed_connections (1)."
	if not runtime_warnings.has(source_limit_warning):
		warnings.append("Expected allowed_connections warning for power_debug_source_limit.")
	var generic_limit_warning := "Power source power_debug_source_generic_connected connections (1) exceed allowed_connections (0)."
	if runtime_warnings.has(generic_limit_warning):
		warnings.append("Generic connected object without connected_power_source_id incorrectly counted toward source limit.")
	var negative_heat_error := "Power object power_debug_negative_heat has negative current_heat (-1)."
	if not runtime_errors.has(negative_heat_error):
		warnings.append("Expected negative current_heat error for power_debug_negative_heat.")
	var preview_result := preview_power_network_state_application()
	var preview_changes: Array = preview_result.get("changes", [])
	var saw_power_up_change := false
	var saw_overheated_power_up_change := false
	var saw_damaged_consumer_change := false
	var saw_damaged_powered_change := false
	var damaged_powered_reason_ok := false
	for change_variant in preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		var changed_id := str(change.get("object_id", ""))
		var preview_powered := bool(change.get("preview_is_powered", false))
		if changed_id == "power_debug_preview_cable" and preview_powered:
			saw_power_up_change = true
		if changed_id == "power_debug_preview_cable_overheated" and preview_powered:
			saw_overheated_power_up_change = true
		if changed_id == "power_debug_preview_consumer_damaged":
			saw_damaged_consumer_change = true
		if changed_id == "power_debug_preview_consumer_damaged_powered":
			saw_damaged_powered_change = true
			if not preview_powered and str(change.get("reason", "")) == "damaged":
				damaged_powered_reason_ok = true
	if not saw_power_up_change:
		warnings.append("Preview regression: powered source did not predict power-up for connected consumer.")
	if saw_overheated_power_up_change:
		warnings.append("Preview regression: overheated source incorrectly predicted consumer power-up.")
	if saw_damaged_consumer_change:
		warnings.append("Preview regression: damaged consumer should remain unpowered with no change entry.")
	if not saw_damaged_powered_change:
		warnings.append("Preview regression: powered damaged consumer did not emit power-down change.")
	elif not damaged_powered_reason_ok:
		warnings.append("Preview regression: powered damaged consumer change missing reason=damaged.")
	var preview_cable_object := get_world_object_by_id("power_debug_preview_cable")
	var preview_cable_before := bool(preview_cable_object.get("is_powered", false))
	preview_power_network_state_application()
	var preview_cable_after := bool(preview_cable_object.get("is_powered", false))
	if preview_cable_before != preview_cable_after:
		warnings.append("Preview mutated temporary object state for power_debug_preview_cable.")
	var apply_case_a_consumer := get_world_object_by_id("power_debug_apply_case_a_consumer")
	var apply_case_a_before_preview_report := bool(apply_case_a_consumer.get("is_powered", false))
	var apply_preview_report_text := get_power_network_apply_debug_preview_text("power_debug_apply_case_a")
	if apply_preview_report_text.find("WOULD_APPLY") == -1:
		warnings.append("Apply preview report regression: missing WOULD_APPLY entry for case A.")
	if apply_preview_report_text.find("APPLIED") != -1:
		warnings.append("Apply preview report regression: preview text must not include APPLIED entries.")
	var apply_case_a_after_preview_report := bool(apply_case_a_consumer.get("is_powered", false))
	if apply_case_a_before_preview_report != apply_case_a_after_preview_report:
		warnings.append("Apply preview report regression: report mutated apply_case_a_consumer before apply.")
	var apply_execute_report_text := execute_power_network_apply_debug_command("power_debug_apply_case_a")
	if apply_execute_report_text.find("PowerNetworkApply") == -1:
		warnings.append("Apply debug execute regression: missing PowerNetworkApply header for case A.")
	if apply_execute_report_text.find("APPLIED") == -1:
		warnings.append("Apply debug execute regression: missing APPLIED entry for case A.")
	if not bool(apply_case_a_consumer.get("is_powered", false)):
		warnings.append("Apply regression A: powered source did not power unpowered consumer.")
	if apply_execute_report_text.find("object=power_debug_apply_case_a_consumer") == -1:
		warnings.append("Apply debug execute regression: report missing applied consumer power-up.")
	var apply_case_b_consumer := get_world_object_by_id("power_debug_apply_case_b_consumer")
	var apply_case_b_before := bool(apply_case_b_consumer.get("is_powered", false))
	var apply_result_b := apply_power_network_state_from_preview("power_debug_apply_case_b")
	var apply_case_b_after := bool(apply_case_b_consumer.get("is_powered", false))
	if apply_case_b_before != apply_case_b_after or apply_case_b_after:
		warnings.append("Apply regression B: consumer power changed with overheated source.")
	for change_variant in apply_result_b.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_apply_case_b_consumer" and bool(change.get("new_is_powered", false)):
			warnings.append("Apply regression B: report included invalid consumer power-up.")
			break
	var apply_case_c_consumer := get_world_object_by_id("power_debug_apply_case_c_consumer")
	var apply_result_c := apply_power_network_state_from_preview("power_debug_apply_case_c")
	if bool(apply_case_c_consumer.get("is_powered", false)):
		warnings.append("Apply regression C: damaged consumer remained powered.")
	var apply_case_c_reason_ok := false
	for change_variant in apply_result_c.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) != "power_debug_apply_case_c_consumer":
			continue
		if not bool(change.get("new_is_powered", false)) and str(change.get("reason", "")) == "damaged":
			apply_case_c_reason_ok = true
			break
	if not apply_case_c_reason_ok:
		warnings.append("Apply regression C: damaged consumer power-down missing reason=damaged.")
	var apply_case_d_source_on := get_world_object_by_id("power_debug_apply_case_d_source_on")
	var apply_case_d_source_off := get_world_object_by_id("power_debug_apply_case_d_source_off")
	var source_on_before := bool(apply_case_d_source_on.get("is_powered", false))
	var source_off_before := bool(apply_case_d_source_off.get("is_powered", false))
	apply_power_network_state_from_preview("power_debug_apply_case_d")
	var source_on_after := bool(apply_case_d_source_on.get("is_powered", false))
	var source_off_after := bool(apply_case_d_source_off.get("is_powered", false))
	if source_on_before != source_on_after or source_off_before != source_off_after:
		warnings.append("Apply regression D: source object is_powered mutated by apply.")
	var event_apply_consumer := get_world_object_by_id("power_debug_event_apply_consumer")
	var event_preview_before := bool(event_apply_consumer.get("is_powered", false))
	var event_preview_text := get_power_event_apply_preview_text("debug_event", "power_debug_event_apply")
	if event_preview_text.find("PowerEventApplyPreview") == -1:
		warnings.append("Event apply preview regression: missing PowerEventApplyPreview header.")
	if event_preview_text.find("WOULD_APPLY") == -1:
		warnings.append("Event apply preview regression: missing WOULD_APPLY entry.")
	if event_preview_text.find("APPLIED") != -1:
		warnings.append("Event apply preview regression: preview text must not include APPLIED entries.")
	var event_preview_after := bool(event_apply_consumer.get("is_powered", false))
	if event_preview_before != event_preview_after:
		warnings.append("Event apply preview regression: preview mutated consumer state.")
	var event_execute_text := execute_power_event_apply_and_get_report_text("debug_event", "power_debug_event_apply")
	if event_execute_text.find("PowerEventApply") == -1:
		warnings.append("Event apply execute regression: missing PowerEventApply header.")
	if event_execute_text.find("reason=debug_event") == -1:
		warnings.append("Event apply execute regression: missing reason=debug_event in header.")
	if event_execute_text.find("APPLIED") == -1:
		warnings.append("Event apply execute regression: missing APPLIED entry.")
	if not bool(event_apply_consumer.get("is_powered", false)):
		warnings.append("Event apply execute regression: consumer did not become powered.")
	var event_dict_report := apply_power_network_after_explicit_power_event("debug_event_dict", "power_debug_event_apply")
	if int(event_dict_report.get("applied", -1)) != 0:
		warnings.append("Event apply dictionary regression: expected applied=0 after execute.")
	if str(event_dict_report.get("event_reason", "")) != "debug_event_dict":
		warnings.append("Event apply dictionary regression: event_reason mismatch.")
	var switch_toggle_consumer := get_world_object_by_id("power_debug_switch_toggle_consumer")
	var switch_toggle_before := bool(switch_toggle_consumer.get("is_powered", false))
	debug_switch_object["state"] = "switch_on"
	var switch_filter := _get_power_event_filter_for_object(debug_switch_object)
	if switch_filter != "power_debug_switch_toggle":
		warnings.append("Power event filter helper regression: expected power_debug_switch_toggle for switch object.")
	var switch_toggle_report := apply_power_network_after_explicit_power_event("switch_toggled", switch_filter)
	if str(switch_toggle_report.get("event_reason", "")) != "switch_toggled":
		warnings.append("Switch toggle event apply regression: event_reason mismatch.")
	if not bool(switch_toggle_consumer.get("is_powered", false)):
		warnings.append("Switch toggle event apply regression: consumer did not become powered.")
	if switch_toggle_before == bool(switch_toggle_consumer.get("is_powered", false)):
		warnings.append("Switch toggle event apply regression: consumer power state did not change.")
	var fuse_consumer := get_world_object_by_id("power_debug_fuse_consumer")
	var fuse_filter := _get_power_event_filter_for_object(debug_fuse_object)
	if fuse_filter != "power_debug_fuse_event":
		warnings.append("Power event filter helper regression: expected power_debug_fuse_event for fuse object.")
	debug_fuse_object["state"] = "installed"
	var fuse_insert_report := apply_power_network_after_explicit_power_event("fuse_inserted", fuse_filter)
	if str(fuse_insert_report.get("event_reason", "")) != "fuse_inserted":
		warnings.append("Fuse insert event apply regression: event_reason mismatch.")
	if not bool(fuse_consumer.get("is_powered", false)):
		warnings.append("Fuse insert event apply regression: consumer did not become powered.")
	fuse_consumer["is_powered"] = true
	debug_fuse_object["state"] = "empty"
	var fuse_remove_report := apply_power_network_after_explicit_power_event("fuse_removed", fuse_filter)
	if str(fuse_remove_report.get("event_reason", "")) != "fuse_removed":
		warnings.append("Fuse remove event apply regression: event_reason mismatch.")
	var debug_cable_consumer := get_world_object_by_id("power_debug_cable_consumer")
	debug_cable_object["state"] = "connected"
	debug_cable_object["connected"] = true
	var cable_filter := _get_power_event_filter_for_object(debug_cable_object)
	if cable_filter != "power_debug_cable_event":
		warnings.append("Power event filter helper regression: expected power_debug_cable_event for cable object.")
	var cable_connect_report := apply_power_network_after_explicit_power_event("cable_connected", cable_filter)
	if str(cable_connect_report.get("event_reason", "")) != "cable_connected":
		warnings.append("Cable connect event apply regression: event_reason mismatch.")
	if not bool(debug_cable_consumer.get("is_powered", false)):
		warnings.append("Cable connect event apply regression: consumer did not become powered.")
	debug_cable_consumer["is_powered"] = true
	debug_cable_object["state"] = "disconnected"
	debug_cable_object["connected"] = false
	var cable_disconnect_report := apply_power_network_after_explicit_power_event("cable_disconnected", cable_filter)
	if str(cable_disconnect_report.get("event_reason", "")) != "cable_disconnected":
		warnings.append("Cable disconnect event apply regression: event_reason mismatch.")
	var graph_closed_source := get_world_object_by_id("power_debug_graph_closed_gate_source")
	var graph_closed_gate := get_world_object_by_id("power_debug_graph_closed_gate_switch")
	var graph_closed_consumer := get_world_object_by_id("power_debug_graph_closed_gate_consumer")
	var graph_closed_source_before_preview := bool(graph_closed_source.get("is_powered", false))
	var graph_closed_gate_state_before_preview := str(graph_closed_gate.get("state", ""))
	var graph_closed_gate_power_before_preview := bool(graph_closed_gate.get("is_powered", false))
	var graph_closed_consumer_before_preview := bool(graph_closed_consumer.get("is_powered", false))
	var graph_closed_preview := preview_power_graph_state_application("power_debug_graph_closed_gate")
	var graph_closed_preview_changes: Array = graph_closed_preview.get("changes", [])
	var graph_closed_preview_reason_ok := false
	for change_variant in graph_closed_preview_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_graph_closed_gate_consumer" and str(change.get("reason", "")) == "graph_powered_source_reachable":
			graph_closed_preview_reason_ok = true
			break
	if not graph_closed_preview_reason_ok:
		warnings.append("Graph closed gate scenario regression: expected reason=graph_powered_source_reachable.")
	if graph_closed_source_before_preview != bool(graph_closed_source.get("is_powered", false)) or graph_closed_consumer_before_preview != bool(graph_closed_consumer.get("is_powered", false)) or graph_closed_gate_state_before_preview != str(graph_closed_gate.get("state", "")) or graph_closed_gate_power_before_preview != bool(graph_closed_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: preview mutated closed-gate objects.")
	var graph_closed_apply := apply_power_graph_state_from_preview("power_debug_graph_closed_gate")
	if int(graph_closed_apply.get("applied", 0)) <= 0:
		warnings.append("Graph closed gate scenario regression: expected apply changes.")
	if not bool(graph_closed_consumer.get("is_powered", false)):
		warnings.append("Graph closed gate scenario regression: consumer did not become powered.")
	if not bool(graph_closed_source.get("is_powered", false)):
		warnings.append("Graph closed gate scenario regression: source mutated from powered state.")
	for change_variant in graph_closed_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_graph_closed_gate_source":
			warnings.append("Graph apply regression: source object appeared in applied changes.")
			break
	var graph_open_source := get_world_object_by_id("power_debug_graph_open_switch_source")
	var graph_open_gate := get_world_object_by_id("power_debug_graph_open_switch_gate")
	var graph_open_consumer := get_world_object_by_id("power_debug_graph_open_switch_consumer")
	var graph_open_source_before_preview := bool(graph_open_source.get("is_powered", false))
	var graph_open_gate_state_before_preview := str(graph_open_gate.get("state", ""))
	var graph_open_gate_power_before_preview := bool(graph_open_gate.get("is_powered", false))
	var graph_open_consumer_before_preview := bool(graph_open_consumer.get("is_powered", false))
	var graph_open_preview := preview_power_graph_state_application("power_debug_graph_open_switch")
	if str(get_power_graph_preview_text("power_debug_graph_open_switch")).find("blocked=1") == -1:
		warnings.append("Graph open switch scenario regression: blocked gate not reported.")
	if str(graph_open_preview).find("blocked_by_gate") == -1:
		warnings.append("Graph open switch scenario regression: reason blocked_by_gate missing.")
	if graph_open_source_before_preview != bool(graph_open_source.get("is_powered", false)) or graph_open_consumer_before_preview != bool(graph_open_consumer.get("is_powered", false)) or graph_open_gate_state_before_preview != str(graph_open_gate.get("state", "")) or graph_open_gate_power_before_preview != bool(graph_open_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: preview mutated open-gate objects.")
	var graph_open_blocked_ok := false
	for blocked_variant in graph_open_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if str(blocked.get("object_id", "")) == "power_debug_graph_open_switch_gate":
			graph_open_blocked_ok = true
			break
	if not graph_open_blocked_ok:
		warnings.append("Graph open switch scenario regression: blocked entry missing switch gate.")
	var graph_open_apply := apply_power_graph_state_from_preview("power_debug_graph_open_switch")
	if bool(graph_open_consumer.get("is_powered", false)):
		warnings.append("Graph open switch scenario regression: consumer should be unpowered.")
	if not bool(graph_open_source.get("is_powered", false)):
		warnings.append("Graph open switch scenario regression: source mutated from powered state.")
	var graph_open_reason_ok := false
	for change_variant in graph_open_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_graph_open_switch_consumer":
			if str(change.get("reason", "")) == "blocked_by_gate":
				graph_open_reason_ok = true
		elif str(change.get("object_id", "")) == "power_debug_graph_open_switch_source":
			warnings.append("Graph apply regression: source object appeared in open-switch changes.")
	if not graph_open_reason_ok:
		warnings.append("Graph open switch scenario regression: missing reason=blocked_by_gate.")
	var graph_empty_fuse_source := get_world_object_by_id("power_debug_graph_empty_fuse_source")
	var graph_empty_fuse_consumer := get_world_object_by_id("power_debug_graph_empty_fuse_consumer")
	var graph_empty_fuse_preview := preview_power_graph_state_application("power_debug_graph_empty_fuse")
	var graph_empty_fuse_blocked_ok := false
	for blocked_variant in graph_empty_fuse_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if str(blocked.get("object_id", "")) == "power_debug_graph_empty_fuse_gate":
			graph_empty_fuse_blocked_ok = true
			break
	if not graph_empty_fuse_blocked_ok:
		warnings.append("Graph empty fuse scenario regression: blocked entry missing fuse gate.")
	var graph_empty_fuse_apply := apply_power_graph_state_from_preview("power_debug_graph_empty_fuse")
	if bool(graph_empty_fuse_consumer.get("is_powered", false)):
		warnings.append("Graph empty fuse scenario regression: consumer should be unpowered.")
	if not bool(graph_empty_fuse_source.get("is_powered", false)):
		warnings.append("Graph empty fuse scenario regression: source mutated from powered state.")
	var graph_empty_fuse_reason_ok := false
	for change_variant in graph_empty_fuse_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_graph_empty_fuse_consumer" and str(change.get("reason", "")) == "blocked_by_gate":
			graph_empty_fuse_reason_ok = true
		elif str(change.get("object_id", "")) == "power_debug_graph_empty_fuse_source":
			warnings.append("Graph apply regression: source object appeared in empty-fuse changes.")
	if not graph_empty_fuse_reason_ok:
		warnings.append("Graph empty fuse scenario regression: missing reason=blocked_by_gate.")
	var graph_cut_cable_source := get_world_object_by_id("power_debug_graph_cut_cable_source")
	var graph_cut_cable_consumer := get_world_object_by_id("power_debug_graph_cut_cable_consumer")
	var graph_cut_cable_preview := preview_power_graph_state_application("power_debug_graph_cut_cable")
	var graph_cut_cable_blocked_ok := false
	for blocked_variant in graph_cut_cable_preview.get("blocked", []):
		if typeof(blocked_variant) != TYPE_DICTIONARY:
			continue
		var blocked: Dictionary = blocked_variant
		if str(blocked.get("object_id", "")) == "power_debug_graph_cut_cable_gate":
			graph_cut_cable_blocked_ok = true
			break
	if not graph_cut_cable_blocked_ok:
		warnings.append("Graph cut cable scenario regression: blocked entry missing cable gate.")
	var graph_cut_cable_apply := apply_power_graph_state_from_preview("power_debug_graph_cut_cable")
	if bool(graph_cut_cable_consumer.get("is_powered", false)):
		warnings.append("Graph cut cable scenario regression: consumer should be unpowered.")
	if not bool(graph_cut_cable_source.get("is_powered", false)):
		warnings.append("Graph cut cable scenario regression: source mutated from powered state.")
	var graph_cut_cable_reason_ok := false
	for change_variant in graph_cut_cable_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_graph_cut_cable_consumer":
			var change_reason := str(change.get("reason", ""))
			if change_reason == "blocked_by_gate" or change_reason == "cut":
				graph_cut_cable_reason_ok = true
		elif str(change.get("object_id", "")) == "power_debug_graph_cut_cable_source":
			warnings.append("Graph apply regression: source object appeared in cut-cable changes.")
	if not graph_cut_cable_reason_ok:
		warnings.append("Graph cut cable scenario regression: missing reason=blocked_by_gate/cut.")
	var graph_no_source_consumer := get_world_object_by_id("power_debug_graph_no_source_consumer")
	var graph_no_source_apply := apply_power_graph_state_from_preview("power_debug_graph_no_source")
	if bool(graph_no_source_consumer.get("is_powered", false)):
		warnings.append("Graph no source scenario regression: consumer should be unpowered.")
	var graph_no_source_reason_ok := false
	for change_variant in graph_no_source_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_graph_no_source_consumer" and str(change.get("reason", "")) == "no_powered_source":
			graph_no_source_reason_ok = true
			break
	if not graph_no_source_reason_ok:
		warnings.append("Graph no source scenario regression: missing reason=no_powered_source.")
	var graph_damaged_consumer := get_world_object_by_id("power_debug_graph_damaged_consumer")
	var graph_damaged_preview := preview_power_graph_state_application("power_debug_graph_damaged_consumer")
	var graph_damaged_apply := apply_power_graph_state_from_preview("power_debug_graph_damaged_consumer")
	if bool(graph_damaged_consumer.get("is_powered", false)):
		warnings.append("Graph damaged consumer scenario regression: damaged consumer became powered.")
	for change_variant in graph_damaged_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_graph_damaged_consumer_source":
			warnings.append("Graph apply regression: source object appeared in damaged-consumer changes.")
	for change_variant in graph_damaged_preview.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_graph_damaged_consumer" and str(change.get("reason", "")) != "damaged":
			warnings.append("Graph damaged consumer scenario regression: expected reason=damaged for preview change.")
	var terminal_powered := get_world_object_by_id("power_debug_terminal_powered_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_powered")
	if not bool(terminal_powered.get("is_powered", false)) or str(terminal_powered.get("state", "")) != "active":
		warnings.append("Terminal powered restore regression: terminal did not restore active powered state.")
	var terminal_blocked := get_world_object_by_id("power_debug_terminal_blocked_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_blocked")
	if bool(terminal_blocked.get("is_powered", true)) or str(terminal_blocked.get("state", "")) != "unpowered":
		warnings.append("Terminal blocked regression: terminal should become unpowered.")
	var terminal_damaged := get_world_object_by_id("power_debug_terminal_damaged_terminal")
	apply_power_graph_state_from_preview("power_debug_terminal_damaged")
	if str(terminal_damaged.get("state", "")) != "damaged" or _is_terminal_powered_for_interaction(terminal_damaged):
		warnings.append("Terminal damaged regression: damaged terminal must remain non-interactable.")
	var terminal_legacy := {"object_type": "terminal", "state": "active"}
	if not _is_terminal_powered_for_interaction(terminal_legacy):
		warnings.append("Terminal legacy default regression: missing is_powered must remain interactable.")
	var terminal_explicit_unpowered := {"object_type": "terminal", "state": "active", "is_powered": false}
	if _is_terminal_powered_for_interaction(terminal_explicit_unpowered):
		warnings.append("Terminal explicit unpowered regression: is_powered=false must block interaction.")
	var energy_door_blocked := get_world_object_by_id("power_debug_energy_door_blocked_door")
	apply_power_graph_state_from_preview("power_debug_energy_door_blocked")
	if bool(energy_door_blocked.get("is_powered", true)) or not str(energy_door_blocked.get("state", "")) in ["unpowered", "disabled"]:
		warnings.append("Energy door blocked regression: powered barrier did not disable when unpowered.")
	var energy_door_powered := get_world_object_by_id("power_debug_energy_door_powered_door")
	apply_power_graph_state_from_preview("power_debug_energy_door_powered")
	if not bool(energy_door_powered.get("is_powered", false)) or not str(energy_door_powered.get("state", "")) in ["closed", "active", "powered"]:
		warnings.append("Energy door powered regression: barrier did not restore.")
	var platform_blocked := get_world_object_by_id("power_debug_platform_blocked_platform")
	var platform_blocked_height_before := int(platform_blocked.get("height_level", 0))
	apply_power_graph_state_from_preview("power_debug_platform_blocked")
	if bool(platform_blocked.get("is_powered", true)) or not str(platform_blocked.get("state", "")) in ["unpowered", "disabled"] or int(platform_blocked.get("height_level", 0)) != platform_blocked_height_before:
		warnings.append("Platform blocked regression: platform power-off should disable without movement.")
	var platform_powered := get_world_object_by_id("power_debug_platform_powered_platform")
	var platform_powered_height_before := int(platform_powered.get("height_level", 0))
	apply_power_graph_state_from_preview("power_debug_platform_powered")
	if not bool(platform_powered.get("is_powered", false)) or not str(platform_powered.get("state", "")) in ["active", "idle"] or int(platform_powered.get("height_level", 0)) != platform_powered_height_before:
		warnings.append("Platform powered regression: platform should restore and not move.")
	var platform_damaged := get_world_object_by_id("power_debug_platform_damaged_platform")
	var platform_damaged_state_before := str(platform_damaged.get("state", ""))
	apply_power_graph_state_from_preview("power_debug_platform_damaged")
	if str(platform_damaged.get("state", "")) != platform_damaged_state_before or str(platform_damaged.get("state", "")) == "unpowered" or str(platform_damaged.get("state", "")) == "active":
		warnings.append("Platform damaged regression: damaged platform state must be preserved when unpowered.")
	var platform_damaged_switch := get_world_object_by_id("power_debug_platform_damaged_switch")
	platform_damaged_switch["state"] = "switch_on"
	apply_power_graph_state_from_preview("power_debug_platform_damaged")
	if str(platform_damaged.get("state", "")) != platform_damaged_state_before:
		warnings.append("Platform damaged restore regression: power restore must not heal damaged platform.")
	var graph_filter_source := get_world_object_by_id("power_debug_graph_open_switch_source")
	var graph_filter_gate := get_world_object_by_id("power_debug_graph_open_switch_gate")
	var graph_filter_consumer := get_world_object_by_id("power_debug_graph_open_switch_consumer")
	var graph_filter_source_before_preview := bool(graph_filter_source.get("is_powered", false))
	var graph_filter_gate_state_before_preview := str(graph_filter_gate.get("state", ""))
	var graph_filter_gate_power_before_preview := bool(graph_filter_gate.get("is_powered", false))
	var graph_filter_consumer_before_preview := bool(graph_filter_consumer.get("is_powered", false))
	var graph_filter_object_preview := preview_power_graph_state_application("power_debug_graph_open_switch_gate")
	if int((graph_filter_object_preview.get("sources", []) as Array).size()) != 1:
		warnings.append("Graph filter fallback regression: object-id filter did not resolve to network.")
	if graph_filter_source_before_preview != bool(graph_filter_source.get("is_powered", false)) or graph_filter_consumer_before_preview != bool(graph_filter_consumer.get("is_powered", false)) or graph_filter_gate_state_before_preview != str(graph_filter_gate.get("state", "")) or graph_filter_gate_power_before_preview != bool(graph_filter_gate.get("is_powered", false)):
		warnings.append("Graph preview regression: object-id filter preview mutated open-switch objects.")
	var load_ok_source := get_world_object_by_id("power_debug_source_load_ok")
	var _load_ok_preview := preview_power_graph_state_application("power_debug_source_load_ok")
	if int(load_ok_source.get("source_load", -1)) != -1:
		warnings.append("Source load preview regression: preview mutated source load fields.")
	var load_ok_apply := apply_power_graph_state_from_preview("power_debug_source_load_ok")
	if int(load_ok_source.get("source_load", -1)) != 2 or int(load_ok_source.get("source_capacity", -1)) != 2 or bool(load_ok_source.get("source_overloaded", true)):
		warnings.append("Source load scenario A regression: expected load=2 capacity=2 overloaded=false.")
	if str(load_ok_source.get("state", "")).to_lower() == "overheated":
		warnings.append("Source load scenario A regression: source should not overheat.")
	if int(load_ok_apply.get("applied", 0)) < 2:
		warnings.append("Source load scenario A regression: expected consumers to be powered.")
	var fallback_class2_source := get_world_object_by_id("power_debug_source_fallback_class2_source")
	var fallback_class2_preview := preview_power_graph_state_application("power_debug_source_fallback_class2")
	if int(fallback_class2_source.get("source_capacity", -1)) != -1:
		warnings.append("Source fallback class2 preview regression: preview mutated source capacity fields.")
	var fallback_class2_preview_sources: Array = fallback_class2_preview.get("source_load_report", {}).get("sources", [])
	var fallback_class2_preview_capacity_ok := false
	for source_variant in fallback_class2_preview_sources:
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source_entry: Dictionary = source_variant
		if str(source_entry.get("object_id", "")) == "power_debug_source_fallback_class2_source" and int(source_entry.get("source_capacity", -1)) == 5:
			fallback_class2_preview_capacity_ok = true
			break
	if not fallback_class2_preview_capacity_ok:
		warnings.append("Source fallback class2 preview regression: expected source_capacity=5 from object_type fallback.")
	apply_power_graph_state_from_preview("power_debug_source_fallback_class2")
	if int(fallback_class2_source.get("source_capacity", -1)) != 5:
		warnings.append("Source fallback class2 apply regression: expected source_capacity=5.")
	var fallback_class3_source := get_world_object_by_id("power_debug_source_fallback_class3_source")
	var fallback_class3_preview := preview_power_graph_state_application("power_debug_source_fallback_class3")
	if int(fallback_class3_source.get("source_capacity", -1)) != -1:
		warnings.append("Source fallback class3 preview regression: preview mutated source capacity fields.")
	var fallback_class3_preview_sources: Array = fallback_class3_preview.get("source_load_report", {}).get("sources", [])
	var fallback_class3_preview_capacity_ok := false
	for source_variant in fallback_class3_preview_sources:
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source_entry: Dictionary = source_variant
		if str(source_entry.get("object_id", "")) == "power_debug_source_fallback_class3_source" and int(source_entry.get("source_capacity", -1)) == 6:
			fallback_class3_preview_capacity_ok = true
			break
	if not fallback_class3_preview_capacity_ok:
		warnings.append("Source fallback class3 preview regression: expected source_capacity=6 from object_type fallback.")
	apply_power_graph_state_from_preview("power_debug_source_fallback_class3")
	if int(fallback_class3_source.get("source_capacity", -1)) != 6:
		warnings.append("Source fallback class3 apply regression: expected source_capacity=6.")
	var overloaded_source := get_world_object_by_id("power_debug_source_overloaded_source")
	apply_power_graph_state_from_preview("power_debug_source_overloaded")
	if int(overloaded_source.get("source_load", 0)) <= int(overloaded_source.get("source_capacity", 0)) or not bool(overloaded_source.get("source_overloaded", false)) or int(overloaded_source.get("heat_from_connections", 0)) <= 0:
		warnings.append("Source load scenario B regression: expected overloaded source with heat_from_connections.")
	var overheat_source := get_world_object_by_id("power_debug_source_overheat_shutdown_source")
	var overheat_terminal := get_world_object_by_id("power_debug_source_overheat_shutdown_terminal")
	var overheat_platform := get_world_object_by_id("power_debug_source_overheat_shutdown_platform")
	var overheat_preview_before := preview_power_graph_state_application("power_debug_source_overheat_shutdown")
	if str(overheat_preview_before).find("source_load_report") == -1 and int((overheat_preview_before.get("source_load_report", {}).get("updated", 0))) <= 0:
		warnings.append("Source load preview regression: missing source_load_report in graph preview.")
	if int(overheat_source.get("source_load", -1)) != -1:
		warnings.append("Source load preview regression: source overheat preview mutated source fields.")
	var overheat_apply := apply_power_graph_state_from_preview("power_debug_source_overheat_shutdown")
	if str(overheat_source.get("state", "")).to_lower() != "overheated":
		warnings.append("Source load scenario C regression: source did not overheat.")
	if bool(overheat_terminal.get("is_powered", true)) or bool(overheat_platform.get("is_powered", true)):
		warnings.append("Source load scenario C regression: dependent consumers should be unpowered.")
	for change_variant in overheat_apply.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		if str(change.get("object_id", "")) == "power_debug_source_overheat_shutdown_source":
			warnings.append("Source load scenario C regression: source appeared in applied changes.")
			break
	var allowed_fuse_remove_fields := {
		"is_powered": true,
		"current_heat": true,
		"working_heat": true,
		"cooling_received": true,
		"heat_from_connections": true,
		"state": true
	}
	for change_variant in fuse_remove_report.get("changes", []):
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		var change: Dictionary = change_variant
		for key_variant in change.keys():
			var key := str(key_variant)
			if not allowed_fuse_remove_fields.has(key):
				warnings.append("Fuse remove event apply regression: unexpected change field %s." % key)
				break
	var index := mission_world_objects.size() - 1
	while index >= 0:
		var object_data: Dictionary = mission_world_objects[index]
		var object_id := str(object_data.get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			mission_world_objects.remove_at(index)
		index -= 1
	for object_data in mission_world_objects:
		var object_id := str(object_data.get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			warnings.append("Temporary debug power object remained after cleanup: %s." % object_id)
	if mission_world_objects.size() != base_size:
		warnings.append("Mission world object count changed after debug scenario cleanup (expected %d, got %d)." % [base_size, mission_world_objects.size()])
	if mission_world_objects.size() == unchanged_snapshot.size():
		for i in range(mission_world_objects.size()):
			if mission_world_objects[i] != unchanged_snapshot[i]:
				warnings.append("Mission world object at index %d changed during debug scenario." % i)
				break
	return warnings

func get_power_network_debug_validation_text() -> String:
	var warnings := validate_power_network_debug_scenario()
	var lines: Array[String] = []
	lines.append("PowerNetworkDebugScenario: warnings=%d" % warnings.size())
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)



func get_power_network_full_debug_report_text(filter: String = "") -> String:
	var preview := preview_power_graph_state_application(filter)
	var lines: Array[String] = []
	lines.append("PowerNetworkFullDebug: filter=%s resolved_filter=%s" % [filter.strip_edges(), str(preview.get("resolved_filter", ""))])
	lines.append("Sources:")
	for source_variant in preview.get("source_load_report", {}).get("sources", []):
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = source_variant
		var obj := get_world_object_by_id(str(source.get("object_id", "")))
		lines.append("- %s state=%s available=%s load=%d/%d heat=%d/%d overloaded=%s" % [str(source.get("object_id", "")), str(source.get("state", obj.get("state", ""))), str(_is_power_source_available(obj)).to_lower(), int(source.get("source_load", 0)), int(source.get("source_capacity", 0)), int(source.get("current_heat", 0)), int(source.get("overheat_threshold", 0)), str(bool(source.get("source_overloaded", false))).to_lower()])
	lines.append("Gates:")
	for object_data in mission_world_objects:
		if not _is_power_network_object(object_data):
			continue
		if not _resolve_power_graph_filter_to_network_id(filter).is_empty() and _get_power_network_id(object_data) != _resolve_power_graph_filter_to_network_id(filter):
			continue
		var gate := _get_power_gate_state(object_data)
		if not bool(gate.get("is_gate", false)):
			continue
		lines.append("- %s type=%s state=%s closed=%s reason=%s" % [str(object_data.get("id", "")), str(gate.get("gate_type", "")), str(object_data.get("state", "")), str(bool(gate.get("is_closed", true))).to_lower(), str(gate.get("reason", ""))])
	lines.append("Consumers:")
	for object_data in mission_world_objects:
		if _is_power_source_object(object_data) or not _is_power_network_object(object_data):
			continue
		if not _resolve_power_graph_filter_to_network_id(filter).is_empty() and _get_power_network_id(object_data) != _resolve_power_graph_filter_to_network_id(filter):
			continue
		lines.append("- %s type=%s powered=%s state=%s reason=%s" % [str(object_data.get("id", "")), str(object_data.get("object_type", "")), str(bool(object_data.get("is_powered", false))).to_lower(), str(object_data.get("state", "")), str(object_data.get("power_unavailable_reason", ""))])
	lines.append("Blocked:")
	for b in preview.get("blocked", []):
		lines.append("- %s" % str(b))
	lines.append("Preview changes:")
	for c in preview.get("changes", []):
		lines.append("- %s" % str(c))
	lines.append("Source load preview:")
	lines.append(str(preview.get("source_load_report", {})))
	lines.append("Warnings:")
	for w in preview.get("warnings", []):
		lines.append("- %s" % str(w))
	return "\n".join(lines)

func validate_full_power_system_runtime() -> Array[String]:
	var warnings := validate_power_network_debug_scenario()
	var runtime_validation := validate_power_network_runtime_state()
	for warning in runtime_validation.get("warnings", []):
		warnings.append("runtime: %s" % str(warning))
	for err in runtime_validation.get("errors", []):
		warnings.append("runtime_error: %s" % str(err))
	var temp_objects: Array[Dictionary] = []
	var cleanup_ids: Array[String] = []
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_source", "power_source_class_1", "power_debug_source_recovery", {"state": "overheated", "is_powered": false, "overheated_state_before": "active", "current_heat": 4, "working_heat": 1, "heat_from_connections": 2, "cooling_received": 5, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_terminal", "terminal", "power_debug_source_recovery", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_door", "door", "power_debug_source_recovery", {"object_group":"door", "archetype_id":"door", "material":"energy", "door_type":"powered", "access_type":"no_key", "power_behavior":"opens_when_unpowered", "is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_platform", "lifting_platform", "power_debug_source_recovery", {"is_powered": false, "state": "unpowered", "height_level": 1}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_damaged_source", "power_source_class_1", "power_debug_source_recovery_damaged", {"state": "overheated", "is_powered": false, "overheated_state_before": "damaged", "current_heat": 4, "working_heat": 1, "cooling_received": 6, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_damaged_terminal", "terminal", "power_debug_source_recovery_damaged", {"is_powered": false, "state": "unpowered"}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_broken_source", "power_source_class_1", "power_debug_source_recovery_broken", {"state": "overheated", "is_powered": false, "broken": true, "overheated_state_before": "active", "current_heat": 4, "working_heat": 1, "cooling_received": 6, "overheat_threshold": 4}))
	temp_objects.append(_build_power_network_debug_object("power_debug_source_recovery_broken_terminal", "terminal", "power_debug_source_recovery_broken", {"is_powered": false, "state": "unpowered"}))
	for object_data in temp_objects:
		mission_world_objects.append(object_data)
		cleanup_ids.append(str(object_data.get("id", "")))
	var recovery_a := execute_power_source_recovery_apply("power_debug_source_recovery")
	var source_a := get_world_object_by_id("power_debug_source_recovery_source")
	if str(source_a.get("state", "")).to_lower() != "active":
		warnings.append("power_debug_source_recovery: expected source state active after valid cooling recovery.")
	if not _is_power_source_available(source_a):
		warnings.append("power_debug_source_recovery: expected source available after valid cooling recovery.")
	var recovery_a_changes: Array = recovery_a.get("apply", {}).get("changes", [])
	for change_variant in recovery_a_changes:
		if typeof(change_variant) != TYPE_DICTIONARY:
			continue
		if str(Dictionary(change_variant).get("object_id", "")) == "power_debug_source_recovery_source":
			warnings.append("power_debug_source_recovery: source should not be included in consumer apply changes.")
			break
	for object_id in ["power_debug_source_recovery_terminal", "power_debug_source_recovery_door", "power_debug_source_recovery_platform"]:
		var consumer := get_world_object_by_id(object_id)
		if not bool(consumer.get("is_powered", false)):
			warnings.append("power_debug_source_recovery: expected %s to become powered after valid recovery." % object_id)
	var recovery_b := execute_power_source_recovery_apply("power_debug_source_recovery_damaged")
	var source_b := get_world_object_by_id("power_debug_source_recovery_damaged_source")
	if str(source_b.get("state", "")).to_lower() == "active":
		warnings.append("power_debug_source_recovery_damaged: source unexpectedly recovered to active from damaged pre-overheat state.")
	if _is_power_source_available(source_b):
		warnings.append("power_debug_source_recovery_damaged: expected source to remain unavailable.")
	if str(source_b.get("power_unavailable_reason", "")) != "source_damage_state":
		warnings.append("power_debug_source_recovery_damaged: expected power_unavailable_reason=source_damage_state.")
	if bool(get_world_object_by_id("power_debug_source_recovery_damaged_terminal").get("is_powered", false)):
		warnings.append("power_debug_source_recovery_damaged: consumer should remain unpowered.")
	if Array(recovery_b.get("recovery", {}).get("warnings", [])).is_empty():
		warnings.append("power_debug_source_recovery_damaged: expected recovery warning for blocked damaged restore.")
	var _recovery_c := execute_power_source_recovery_apply("power_debug_source_recovery_broken")
	var source_c := get_world_object_by_id("power_debug_source_recovery_broken_source")
	if str(source_c.get("state", "")).to_lower() == "active":
		warnings.append("power_debug_source_recovery_broken: source unexpectedly recovered while broken=true.")
	if bool(get_world_object_by_id("power_debug_source_recovery_broken_terminal").get("is_powered", false)):
		warnings.append("power_debug_source_recovery_broken: consumer should remain unpowered.")
	var report_snapshot := {}
	for object_id in ["power_debug_source_recovery_source", "power_debug_source_recovery_terminal", "power_debug_source_recovery_door", "power_debug_source_recovery_platform"]:
		var obj := get_world_object_by_id(object_id)
		report_snapshot[object_id] = {"state": str(obj.get("state", "")), "is_powered": bool(obj.get("is_powered", false)), "power_unavailable_reason": str(obj.get("power_unavailable_reason", "")), "connected": bool(obj.get("connected", false))}
	get_power_network_full_debug_report_text("power_debug_source_recovery")
	for object_id in report_snapshot.keys():
		var obj := get_world_object_by_id(str(object_id))
		var snap: Dictionary = report_snapshot[object_id]
		if str(obj.get("state", "")) != str(snap.get("state", "")) or bool(obj.get("is_powered", false)) != bool(snap.get("is_powered", false)) or str(obj.get("power_unavailable_reason", "")) != str(snap.get("power_unavailable_reason", "")) or bool(obj.get("connected", false)) != bool(snap.get("connected", false)):
			warnings.append("power_debug_source_recovery: full debug report mutated runtime state for %s." % str(object_id))
	var runtime_object := _build_power_network_debug_object("power_debug_runtime_save_fields", "terminal", "power_debug_runtime_save")
	runtime_object["state"] = "unpowered"
	runtime_object["is_powered"] = false
	runtime_object["current_heat"] = 3
	runtime_object["working_heat"] = 2
	runtime_object["cooling_received"] = 1
	runtime_object["heat_from_connections"] = 4
	runtime_object["overheat_threshold"] = 5
	runtime_object["source_load"] = 1
	runtime_object["source_capacity"] = 2
	runtime_object["source_overloaded"] = false
	runtime_object["power_unavailable_reason"] = "network_blocked"
	runtime_object["connected"] = true
	runtime_object["disconnected"] = false
	runtime_object["cut"] = false
	runtime_object["damaged"] = true
	runtime_object["broken"] = false
	runtime_object["destroyed"] = false
	runtime_object["state_before_unpowered"] = "active"
	runtime_object["powered_state_before_unpowered"] = "active"
	mission_world_objects.append(runtime_object)
	cleanup_ids.append("power_debug_runtime_save_fields")
	var runtime_snapshot := get_world_object_runtime_state()
	var saved_entry: Dictionary = runtime_snapshot.get("power_debug_runtime_save_fields", {})
	for field_name in ["state", "is_powered", "current_heat", "working_heat", "cooling_received", "heat_from_connections", "overheat_threshold", "source_load", "source_capacity", "source_overloaded", "power_unavailable_reason", "connected", "disconnected", "cut", "damaged", "broken", "destroyed", "state_before_unpowered", "powered_state_before_unpowered"]:
		if not saved_entry.has(field_name):
			warnings.append("power_debug_runtime_save_fields: runtime snapshot missing field %s." % field_name)
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var object_id := str(mission_world_objects[i].get("id", "")).strip_edges()
		if cleanup_ids.has(object_id):
			mission_world_objects.remove_at(i)
	for warning in validate_cooling_runtime():
		warnings.append(str(warning))
	for warning in validate_cooling_and_cable_runtime():
		warnings.append(str(warning))
	if has_method("validate_platform_scan_visibility_runtime"):
		for warning in validate_platform_scan_visibility_runtime():
			warnings.append(str(warning))
	return warnings

func validate_cooling_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var preview := preview_cooling_application("")
	if typeof(preview.get("targets", [])) != TYPE_ARRAY:
		warnings.append("Cooling preview regression: targets missing.")
	var apply_snapshot := preview_cooling_application("")
	if str(preview) != str(apply_snapshot):
		warnings.append("Cooling preview regression: read-only preview produced unstable results.")
	return warnings

func validate_power_cable_reel_normalization() -> Array[String]:
	var warnings: Array[String] = []
	var no_connected_ends: Dictionary = {"state":"broken", "cut":true, "damaged":true, "broken":true}
	no_connected_ends["cut"] = false
	no_connected_ends["damaged"] = false
	no_connected_ends["broken"] = false
	_normalize_power_cable_reel_state(no_connected_ends)
	if bool(no_connected_ends.get("connected", true)) or not bool(no_connected_ends.get("disconnected", false)) or str(no_connected_ends.get("end_1_state", "")) != "on_reel" or str(no_connected_ends.get("end_2_state", "")) != "on_reel":
		warnings.append("Cable reel normalization regression: repaired reel without connected ends is inconsistent.")
	var one_connected_end: Dictionary = {"state":"broken", "end_1_state":"connected", "end_1_target_id":"socket_a", "end_1_path_cells":[Vector2i(1, 0)], "end_1_cable_length":1, "end_2_state":"on_reel", "end_2_target_id":""}
	_normalize_power_cable_reel_state(one_connected_end)
	if bool(one_connected_end.get("connected", true)) or bool(one_connected_end.get("connected_side_1", true)):
		warnings.append("Cable reel normalization regression: broken reel still appears connected.")
	one_connected_end["state"] = "ok"
	one_connected_end["broken"] = false
	_normalize_power_cable_reel_state(one_connected_end)
	if not bool(one_connected_end.get("connected", false)) or bool(one_connected_end.get("disconnected", true)) or str(one_connected_end.get("cable_endpoint_b_id", "")) != "socket_a" or int(one_connected_end.get("end_1_cable_length", 0)) != 1:
		warnings.append("Cable reel normalization regression: repaired reel lost its connected end.")
	var disconnect_one_end: Dictionary = {"end_1_state":"disconnected", "end_1_target_id":"", "end_1_path_cells":[Vector2i(1, 0)], "end_1_cable_length":1, "end_2_state":"connected", "end_2_target_id":"socket_b", "end_2_path_cells":[Vector2i(0, 1)], "end_2_cable_length":1}
	_normalize_power_cable_reel_state(disconnect_one_end)
	if not bool(disconnect_one_end.get("connected", false)) or str(disconnect_one_end.get("cable_endpoint_b_id", "")) != "socket_b" or not Array(disconnect_one_end.get("end_1_path_cells", [])).is_empty() or int(disconnect_one_end.get("end_1_cable_length", -1)) != 0:
		warnings.append("Cable reel normalization regression: disconnecting one end did not preserve the other end.")
	disconnect_one_end["end_2_state"] = "disconnected"
	disconnect_one_end["end_2_target_id"] = ""
	_normalize_power_cable_reel_state(disconnect_one_end)
	if bool(disconnect_one_end.get("connected", true)) or not bool(disconnect_one_end.get("disconnected", false)) or not str(disconnect_one_end.get("cable_endpoint_b_id", "missing")).is_empty():
		warnings.append("Cable reel normalization regression: disconnecting both ends left aggregate connection state.")
	var old_cable: Dictionary = {"id":"old_cable", "connected":true, "disconnected":false, "cable_endpoint_b_id":"legacy_socket"}
	_normalize_power_cable_reel_state(old_cable)
	if not bool(old_cable.get("connected", false)) or bool(old_cable.get("disconnected", true)) or str(old_cable.get("end_1_state", "")) != "connected" or str(old_cable.get("end_1_target_id", "")) != "legacy_socket" or str(old_cable.get("end_2_state", "")) != "on_reel":
		warnings.append("Cable reel normalization regression: old cable map compatibility failed.")
	return warnings

func validate_cooling_and_cable_runtime() -> Array[String]:
	var warnings: Array[String] = validate_power_cable_reel_normalization()
	var snapshot := get_world_object_runtime_state()
	var source := {"id":"temp_cooling_source", "object_group":"power", "object_type":"power_source", "position":Vector2i(130, 100), "is_powered":true, "state":"active"}
	var radiator := {"id":"temp_cooling_radiator", "object_group":"cooling", "object_type":"cooling_radiator", "position":Vector2i(131, 100), "cooling_device_type":"radiator", "cooling_output":2, "state":"active", "is_powered":true}
	var cable := {"id":"temp_validation_cable", "object_group":"cable", "object_type":"power_cable", "position":Vector2i(132, 100), "connected":true, "disconnected":false, "cut":false, "state":"active"}
	for obj in [source, radiator, cable]:
		mission_world_objects.append(obj)
		world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj
	var cool_preview_before := str(get_world_object_runtime_state())
	preview_cooling_application("")
	if str(get_world_object_runtime_state()) != cool_preview_before:
		warnings.append("cooling_preview_mutated_state")
	cable["cut"] = true
	cable["connected"] = false
	cable["disconnected"] = true
	if bool(cable.get("connected", true)):
		warnings.append("cut_cable_should_disconnect")
	var repair_item := {"id":"temp_repair_kit_cable", "object_group":"item", "object_type":"item", "position":Vector2i(133, 100), "item_type":"repair_kit"}
	mission_world_objects.append(repair_item)
	world_objects_by_cell[Vector2i(133, 100)] = repair_item
	cable["damaged"] = true
	use_inventory_item_on_world_object("temp_repair_kit_cable", "temp_validation_cable")
	if not bool(cable.get("disconnected", false)):
		warnings.append("cable_repair_should_not_reconnect")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var oid := str(mission_world_objects[i].get("id", ""))
		if oid.begins_with("temp_"):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(snapshot)
	for object_id_variant in snapshot.keys():
		var object_id := str(object_id_variant)
		var entry: Dictionary = snapshot.get(object_id_variant, {})
		if entry.has("cable_path_cells") and not entry.has("cable_length"):
			warnings.append("Runtime cable serialization regression: cable_length missing for %s." % object_id)
	return warnings

func get_cooling_and_cable_validation_text() -> String:
	var warnings := validate_cooling_and_cable_runtime()
	if warnings.is_empty():
		return "CoolingCableValidation: ok"
	return "CoolingCableValidation:\n- " + "\n- ".join(warnings)

func get_full_power_system_validation_text() -> String:
	var warnings := validate_full_power_system_runtime()
	var lines: Array[String] = ["FullPowerValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)


func _has_xray_capability() -> Dictionary:
	if active_bipob_ref != null and active_bipob_ref.has_method("has_module_id") and bool(active_bipob_ref.call("has_module_id", "xray_v1")):
		return {"ok": true, "reason": "ok"}
	return {"ok": false, "reason": "xray_capability_unavailable", "debug_reason": "debug_xray_allowed"}

func is_world_object_visible_to_player(object_data: Dictionary, scan_mode: String = "basic") -> bool:
	var cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var cell_visible := true
	if grid_manager != null and grid_manager.has_method("is_cell_visible"):
		cell_visible = bool(grid_manager.call("is_cell_visible", cell))
	var hidden := bool(object_data.get("hidden", false))
	if scan_mode == "xray":
		return cell_visible or bool(object_data.get("revealed", false)) or bool(object_data.get("discovered", false)) or bool(object_data.get("revealed_by_scan", false)) or bool(object_data.get("visible_with_xray", false))
	if hidden:
		return cell_visible and (bool(object_data.get("discovered", false)) or bool(object_data.get("revealed", false)) or bool(object_data.get("revealed_by_scan", false)))
	return cell_visible or bool(object_data.get("revealed", false)) or bool(object_data.get("discovered", false))

func get_visible_world_objects_for_scan(scan_mode: String = "basic") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if is_world_object_visible_to_player(object_data, scan_mode): out.append(object_data)
	return out

func get_xray_visible_objects(filter: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if not bool(object_data.get("hidden", false)): continue
		if not bool(object_data.get("visible_with_xray", false)) and not bool(object_data.get("hidden_cable", false)): continue
		if not filter.strip_edges().is_empty() and str(object_data.get("power_network_id", "")) != filter.strip_edges(): continue
		out.append(object_data)
	return out

func reveal_xray_objects(filter: String = "") -> Dictionary:
	var cap := _has_xray_capability()
	var targets := get_xray_visible_objects(filter)
	for target in targets:
		target["revealed"] = true
		target["discovered"] = true
		target["revealed_by_scan"] = true
	return {"success": true, "reason": str(cap.get("reason", "ok")), "debug_reason": str(cap.get("debug_reason", "")), "revealed": targets.size()}

func get_world_object_debug_info(object_id: String) -> Dictionary:
	var normalized_id := object_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	var object_data := get_world_object_by_id(normalized_id)
	if object_data.is_empty():
		return {}
	var info := {}
	for key in ["id", "object_type", "display_name", "object_group", "state"]:
		if object_data.has(key):
			info[key] = object_data[key]
	info["position"] = _debug_cell_to_array(WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
	for key in [
		"is_powered",
		"current_heat",
		"working_heat",
		"cooling_received",
		"heat_from_connections",
		"overheat_threshold",
		"connected_device_ids",
		"power_network_id",
		"facing_dir",
		"movable",
		"heavy_claw_movable",
		"cooling_device_type",
		"cooling_output",
		"cooling_amplifier",
		"material",
		"storage_type",
		"storage_capacity",
		"storage_locked",
		"lock_type",
		"lock_difficulty",
		"access_level",
		"required_access_level"
	]:
		if object_data.has(key):
			info[key] = object_data[key]
	for key in ["platform_height_level", "carried_by_platform_id"]:
		if object_data.has(key):
			info[key] = object_data[key]
	if _is_power_network_object(object_data):
		info["power_network_id"] = _get_power_network_id(object_data)
		info["current_heat"] = int(object_data.get("current_heat", 0))
		info["overheat_threshold"] = int(object_data.get("overheat_threshold", 0))
		info["is_powered"] = bool(object_data.get("is_powered", false))
		info["connected_power_source_id"] = str(object_data.get("connected_power_source_id", "")).strip_edges()
		var network_summary_lines := _get_power_network_summary_lines(_get_power_network_id(object_data))
		if not network_summary_lines.is_empty():
			info["power_network_summary_line"] = network_summary_lines[0]
	if str(object_data.get("object_group", "")) == "platform":
		info["platform_state_summary"] = get_platform_state_summary(object_data)
		info["platform_occupant_summary"] = get_platform_occupant_summary(object_data)
	return info

func _get_debug_tile_info(cell: Vector2i) -> Variant:
	if grid_manager == null:
		return null
	if not grid_manager.has_method("get_tile"):
		return null
	var tile_variant: Variant = grid_manager.get_tile(cell)
	match typeof(tile_variant):
		TYPE_NIL:
			return null
		TYPE_INT:
			return int(tile_variant)
		TYPE_FLOAT:
			return float(tile_variant)
		TYPE_STRING:
			return str(tile_variant)
		TYPE_DICTIONARY:
			return Dictionary(tile_variant).duplicate(true)
		TYPE_ARRAY:
			var tile_array := Array(tile_variant)
			if tile_array.size() <= 16:
				return tile_array.duplicate(true)
			return str(tile_array)
		_:
			return str(tile_variant)

func _get_wall_tile_id() -> Variant:
	if grid_manager == null:
		return null
	if not grid_manager.has_method("get_property_list"):
		return null
	for property_data in grid_manager.get_property_list():
		if typeof(property_data) != TYPE_DICTIONARY:
			continue
		if str(property_data.get("name", "")) == "TILE_WALL":
			return grid_manager.get("TILE_WALL")
	return null

func get_world_cell_debug_info(cell: Vector2i) -> Dictionary:
	var info := {"cell": _debug_cell_to_array(cell)}
	info["height_level"] = get_cell_height_level(cell)
	if grid_manager != null:
		if grid_manager.has_method("is_in_bounds"):
			info["in_bounds"] = bool(grid_manager.is_in_bounds(cell))
		if grid_manager.has_method("is_walkable"):
			info["walkable"] = bool(grid_manager.is_walkable(cell))
		var tile_info: Variant = _get_debug_tile_info(cell)
		if tile_info != null:
			info["tile"] = tile_info
			if typeof(tile_info) == TYPE_DICTIONARY:
				var tile_data: Dictionary = Dictionary(tile_info)
				if str(tile_data.get("type", "")) == "wall":
					info["is_wall"] = true
			elif typeof(tile_info) == TYPE_INT:
				var wall_tile_id: Variant = _get_wall_tile_id()
				if wall_tile_id != null and typeof(wall_tile_id) == TYPE_INT:
					info["is_wall"] = int(tile_info) == int(wall_tile_id)
	var object_data := get_world_object_at_cell(cell)
	if not object_data.is_empty():
		info["world_object_id"] = str(object_data.get("id", ""))
		info["world_object_type"] = str(object_data.get("object_type", ""))
		if _is_power_network_object(object_data):
			var power_network_id := _get_power_network_id(object_data)
			info["power_network_id"] = power_network_id
			var network_summary_lines := _get_power_network_summary_lines(power_network_id)
			if not network_summary_lines.is_empty():
				info["power_network_debug_summary_line"] = network_summary_lines[0]
		if str(object_data.get("object_group", "")) == "platform":
			info["platform_id"] = str(object_data.get("platform_id", ""))
			info["platform_state_summary"] = get_platform_state_summary(object_data)
			info["platform_occupant_summary"] = get_platform_occupant_summary(object_data)
	var items: Array = cell_items.get(cell, [])
	info["item_count"] = items.size()
	if not items.is_empty():
		var item_ids: Array[String] = []
		var item_types: Array[String] = []
		for item_variant in items:
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_data := _safe_dictionary(item_variant)
			item_ids.append(str(item_data.get("id", "")))
			item_types.append(str(item_data.get("object_type", "")))
		info["item_ids"] = item_ids
		info["item_types"] = item_types
	return info

func get_world_objects_debug_table_text(filter: String = "") -> String:
	if mission_world_objects.is_empty():
		return "world_objects: none"
	var filter_text := filter.strip_edges().to_lower()
	var object_rows: Array[String] = []
	for object_data in mission_world_objects:
		var object_id := str(object_data.get("id", ""))
		var object_type := str(object_data.get("object_type", ""))
		var object_group := str(object_data.get("object_group", ""))
		var state := str(object_data.get("state", ""))
		if not filter_text.is_empty():
			var match_blob := ("%s|%s|%s|%s" % [object_id, object_type, object_group, state]).to_lower()
			if match_blob.find(filter_text) == -1:
				continue
		object_rows.append(_format_world_object_debug_row(object_data))
	if object_rows.is_empty():
		return "world_objects: none (filter=%s)" % filter_text
	object_rows.sort()
	var lines: Array[String] = []
	lines.append("id | type | pos | state | heat | cooling | powered | facing | movable")
	lines.append_array(object_rows)
	if has_method("get_world_runtime_restore_warnings"):
		var warnings: Array = get_world_runtime_restore_warnings()
		lines.append("restore_warnings=%d" % warnings.size())
	return "\n".join(lines)

func _format_world_object_debug_row(object_data: Dictionary) -> String:
	var object_id := str(object_data.get("id", ""))
	var object_type := str(object_data.get("object_type", ""))
	var state := str(object_data.get("state", ""))
	var cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var position_text := "[%d,%d]" % [cell.x, cell.y]
	var heat_text := "-"
	if object_data.has("current_heat") or object_data.has("overheat_threshold"):
		heat_text = "%d/%d" % [int(object_data.get("current_heat", 0)), int(object_data.get("overheat_threshold", 0))]
	var cooling_text := "-"
	if object_data.has("cooling_received"):
		cooling_text = str(int(object_data.get("cooling_received", 0)))
	var powered_text := "-"
	if object_data.has("is_powered"):
		powered_text = str(bool(object_data.get("is_powered", false)))
	var facing_text := "-"
	if object_data.has("facing_dir"):
		facing_text = str(object_data.get("facing_dir", "")).strip_edges()
		if facing_text.is_empty():
			facing_text = "-"
	var movable_text := str(WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data))
	if object_data.has("heavy_claw_movable"):
		movable_text = str(bool(object_data.get("heavy_claw_movable", false)))
	elif object_data.has("movable"):
		movable_text = str(bool(object_data.get("movable", false)))
	return "%s | %s | %s | %s | heat=%s | cool=%s | powered=%s | facing=%s | movable=%s" % [
		object_id,
		object_type,
		position_text,
		state,
		heat_text,
		cooling_text,
		powered_text,
		facing_text,
		movable_text
	]

func _debug_cell_to_array(cell: Vector2i) -> Array[int]:
	return [cell.x, cell.y]

func get_world_heat_debug_summary_text() -> String:
	var terminals_count := 0
	var overheated_terminals := 0
	var power_sources_count := 0
	var overheated_power_sources := 0
	var invalid_heat_metadata := 0
	var missing_threshold := 0
	var cooling_devices_count := 0
	var cooled_heat_targets := 0
	var max_cooling_received := 0
	var invalid_cooling_metadata := 0
	var has_cooling_debug_scenario := not get_world_object_by_id("terminal_c2_radiator").is_empty()
	for object_data in mission_world_objects:
		var group := str(object_data.get("object_group", ""))
		var object_type := str(object_data.get("object_type", ""))
		var is_power_source := object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]
		if group == "cooling":
			cooling_devices_count += 1
		var heat_enabled := object_data.has("working_heat") or object_data.has("overheat_threshold")
		if group == "terminal":
			terminals_count += 1
			if str(object_data.get("state", "")) == "overheated":
				overheated_terminals += 1
		elif is_power_source:
			power_sources_count += 1
			if str(object_data.get("state", "")) == "overheated":
				overheated_power_sources += 1
		if heat_enabled:
			var cooling_value := maxi(0, int(object_data.get("cooling_received", 0)))
			if cooling_value > 0:
				cooled_heat_targets += 1
			max_cooling_received = maxi(max_cooling_received, cooling_value)
			if not object_data.has("overheat_threshold"):
				missing_threshold += 1
			var threshold := int(object_data.get("overheat_threshold", 0))
			if threshold < 0 or int(object_data.get("working_heat", 0)) < 0:
				invalid_heat_metadata += 1
		var object_cooling_type := str(object_data.get("cooling_device_type", ""))
		if group == "cooling":
			if object_cooling_type.is_empty():
				invalid_cooling_metadata += 1
			elif not object_cooling_type in ["radiator", "air_cooler", "water_pipe", "air_duct"]:
				invalid_cooling_metadata += 1
		if object_cooling_type == "air_cooler" and not object_data.has("facing_dir"):
			invalid_cooling_metadata += 1
	var summary := "WorldHeat: terminals=%d overheated=%d | power_sources=%d overheated=%d | invalid_heat=%d | missing_threshold=%d | cooling_devices=%d | cooled_targets=%d | max_cooling=%d | invalid_cooling=%d" % [
		terminals_count,
		overheated_terminals,
		power_sources_count,
		overheated_power_sources,
		invalid_heat_metadata,
		missing_threshold,
		cooling_devices_count,
		cooled_heat_targets,
		max_cooling_received,
		invalid_cooling_metadata
	]
	if has_cooling_debug_scenario:
		var validation_warnings := validate_world_cooling_debug_scenario()
		if debug_world_logs and not validation_warnings.is_empty():
			for warning in validation_warnings:
				push_warning("[WorldCoolingValidation] %s" % warning)
		summary += " | cooling_validation_issues=%d" % validation_warnings.size()
	return summary

func get_world_object_runtime_state() -> Dictionary:
	# Runtime-only snapshot helper for future save manager integration.
	var runtime_state := {}
	var runtime_fields := [
		"state",
		"is_powered",
		"current_heat",
		"working_heat",
		"cooling_received",
		"heat_from_connections",
		"connected_device_ids",
		"overheated_state_before",
		"overheated_powered_before",
		"facing_dir",
		"power_network_id",
		"drain_pool",
		"platform_id",
		"platform_type",
		"platform_cells",
		"local_switch_cell",
		"local_switch_facing_dir",
		"linked_terminal_id",
		"requires_terminal_enabled",
		"control_type",
		"power_type",
		"height_level",
		"min_height_level",
		"max_height_level",
		"activation_mode",
		"timer_turns",
		"timer_remaining_turns",
		"period_turns",
		"periodic_active",
		"permanent_state",
		"pending_activation",
		"rotation_direction",
		"platform_height_level",
		"carried_by_platform_id",
		"target_platform_id",
		"platform_control_enabled",
		"platform_remote_control",
		"state_before_unpowered",
		"powered_state_before_unpowered",
		"source_load",
		"source_capacity",
		"source_overloaded",
		"overheat_threshold",
		"power_unavailable_reason",
		"connected",
		"disconnected",
		"cut",
		"cable_endpoint_a_id",
		"cable_endpoint_b_id",
		"cable_path_cells",
		"cable_length",
		"cable_max_length",
		"cooling_source_ids",
		"cooling_reason",
		"damaged",
		"broken",
		"destroyed",
		"revealed",
		"discovered",
		"revealed_by_scan",
		"visible_with_xray",
		"hidden_cable",
		"requires_xray",
		"platform_rotation",
		"local_switch_enabled",
		"terminal_control_enabled"
	]
	for object_data in mission_world_objects:
		var object_id := str(object_data.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var serialized := {}
		if object_data.has("object_type"):
			serialized["object_type"] = str(object_data.get("object_type", ""))
		if object_data.has("position"):
			var world_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			serialized["position"] = [world_cell.x, world_cell.y]
		for field_name in runtime_fields:
			if object_data.has(field_name):
				serialized[field_name] = object_data[field_name]
		if not serialized.is_empty():
			runtime_state[object_id] = serialized
	return runtime_state

func _get_runtime_inventory_item_id(item_variant: Variant) -> String:
	if item_variant is String or item_variant is StringName:
		return str(item_variant).strip_edges()
	if item_variant is Dictionary:
		var item_data: Dictionary = Dictionary(item_variant)
		return str(item_data.get("id", item_data.get("item_id", ""))).strip_edges()
	return ""

func get_manipulator_item_id() -> String:
	return _get_runtime_inventory_item_id(runtime_inventory_state.get("manipulator_hold", ""))

func get_manipulator_held_item_id() -> String:
	return get_manipulator_item_id()

func get_manipulator_item_data() -> Dictionary:
	var held_variant: Variant = runtime_inventory_state.get("manipulator_hold", "")
	var held_id: String = _get_runtime_inventory_item_id(held_variant)
	if held_id.is_empty():
		return {}
	var item_data: Dictionary = {}
	if held_variant is Dictionary:
		item_data = Dictionary(held_variant).duplicate(true)
	else:
		item_data = _get_runtime_item_data_snapshot(held_id)
	if item_data.is_empty():
		item_data = {"id": held_id}
	elif _get_runtime_inventory_item_id(item_data).is_empty():
		item_data["id"] = held_id
	return item_data

func get_manipulator_held_item_data() -> Dictionary:
	return get_manipulator_item_data()

func clear_manipulator() -> void:
	runtime_inventory_state["manipulator_hold"] = ""

func clear_manipulator_held_item() -> void:
	clear_manipulator()

func set_manipulator_item(item_variant: Variant) -> bool:
	var held_id: String = _get_runtime_inventory_item_id(item_variant)
	if held_id.is_empty():
		clear_manipulator()
		return true
	var item_data: Dictionary = Dictionary(item_variant).duplicate(true) if item_variant is Dictionary else _get_known_inventory_item_data(held_id)
	var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item_data)
	if storage_class in [WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD, WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL]:
		return false
	runtime_inventory_state["manipulator_hold"] = held_id
	if item_data.is_empty():
		return true
	var runtime_map: Dictionary = _get_world_item_runtime_map()
	var item_runtime: Dictionary = Dictionary(runtime_map.get(held_id, {})).duplicate(true)
	item_runtime["item_data"] = item_data
	runtime_map[held_id] = item_runtime
	runtime_inventory_state["world_item_runtime"] = runtime_map
	return true

func set_manipulator_held_item(item_variant: Variant) -> void:
	set_manipulator_item(item_variant)

func get_pocket_items() -> Array:
	return Array(runtime_inventory_state.get("pocket_items", [])).duplicate(true)

func set_pocket_item(index: int, item_variant: Variant) -> bool:
	if index < 0:
		return false
	var item_id: String = _get_runtime_inventory_item_id(item_variant)
	var item_data: Dictionary = Dictionary(item_variant).duplicate(true) if item_variant is Dictionary else _get_known_inventory_item_data(item_id)
	var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item_data)
	if not item_id.is_empty() and storage_class in [WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD, WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL]:
		return false
	var pocket: Array = get_pocket_items()
	if index >= pocket.size():
		pocket.resize(index + 1)
	pocket[index] = item_id
	runtime_inventory_state["pocket_items"] = pocket
	return true

func get_keychain_ids() -> Array:
	return Array(runtime_inventory_state.get("collected_key_ids", [])).duplicate()

func add_keycard_to_keychain(item_id: String) -> void:
	var normalized_id: String = item_id.strip_edges()
	if normalized_id.is_empty():
		return
	var collected: Array = get_keychain_ids()
	if not collected.has(normalized_id):
		collected.append(normalized_id)
	runtime_inventory_state["collected_key_ids"] = collected

func remove_keycard_if_no_door_references(item_id: String) -> bool:
	var normalized_id: String = item_id.strip_edges()
	if normalized_id.is_empty():
		return false
	for object_variant in mission_world_objects:
		var object_data: Dictionary = Dictionary(object_variant)
		if str(object_data.get("object_group", "")) != "door":
			continue
		# Door.required_key_id is the canonical key-card link. Keep the legacy
		# required_key compatibility field reference-sensitive as well.
		var required_key_id: String = str(object_data.get("required_key_id", "")).strip_edges()
		var legacy_required_key: String = str(object_data.get("required_key", "")).strip_edges()
		if required_key_id == normalized_id or legacy_required_key == normalized_id:
			return false
	var collected: Array = get_keychain_ids()
	if not collected.has(normalized_id):
		return false
	collected.erase(normalized_id)
	runtime_inventory_state["collected_key_ids"] = collected
	return true

func has_keycard_access(item_id_or_required_key_id: String) -> bool:
	var normalized_id: String = item_id_or_required_key_id.strip_edges()
	if not normalized_id.is_empty() and get_keychain_ids().has(normalized_id):
		return true
	if WorldObjectCatalogRef.normalize_item_type(normalized_id) != WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD:
		return false
	for key_variant in get_keychain_ids():
		var key_id: String = _get_runtime_inventory_item_id(key_variant)
		var key_data: Dictionary = _get_runtime_item_data_snapshot(key_id)
		if WorldObjectCatalogRef.is_key_card_item(key_data) or WorldObjectCatalogRef.normalize_item_type(key_id) == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD:
			return true
	return false

func get_digital_buffer_items() -> Array:
	return Array(runtime_inventory_state.get("digital_buffer", [])).duplicate(true)

func get_digital_storage_items() -> Array:
	return Array(runtime_inventory_state.get("digital_storage", [])).duplicate(true)

func move_runtime_digital_buffer_to_storage(item_id: String) -> void:
	var normalized_id: String = item_id.strip_edges()
	if normalized_id.is_empty():
		return
	var buffer_items: Array = get_digital_buffer_items()
	buffer_items.erase(normalized_id)
	runtime_inventory_state["digital_buffer"] = buffer_items
	var storage_items: Array = get_digital_storage_items()
	if not storage_items.has(normalized_id):
		storage_items.append(normalized_id)
	runtime_inventory_state["digital_storage"] = storage_items

func move_runtime_digital_storage_to_buffer(item_id: String) -> void:
	var normalized_id: String = item_id.strip_edges()
	if normalized_id.is_empty():
		return
	var storage_items: Array = get_digital_storage_items()
	storage_items.erase(normalized_id)
	runtime_inventory_state["digital_storage"] = storage_items
	var buffer_items: Array = get_digital_buffer_items()
	if not buffer_items.has(normalized_id):
		buffer_items.append(normalized_id)
	runtime_inventory_state["digital_buffer"] = buffer_items

func swap_runtime_digital_buffer_and_storage(buffer_item_id: String, storage_item_id: String) -> void:
	move_runtime_digital_buffer_to_storage(buffer_item_id)
	move_runtime_digital_storage_to_buffer(storage_item_id)

func validate_runtime_inventory_storage_contract() -> Array[String]:
	var warnings: Array[String] = []
	var stored_ids: Dictionary = {}
	var held_id: String = get_manipulator_item_id()
	if not held_id.is_empty():
		_validate_runtime_inventory_storage_item(held_id, "manipulator", WorldObjectCatalogRef.ITEM_STORAGE_CLASS_PHYSICAL, stored_ids, warnings)
	for pocket_variant in get_pocket_items():
		var pocket_id: String = _get_runtime_inventory_item_id(pocket_variant)
		if not pocket_id.is_empty():
			_validate_runtime_inventory_storage_item(pocket_id, "pocket", WorldObjectCatalogRef.ITEM_STORAGE_CLASS_PHYSICAL, stored_ids, warnings)
	for key_variant in get_keychain_ids():
		var key_id: String = _get_runtime_inventory_item_id(key_variant)
		if not key_id.is_empty():
			_validate_runtime_inventory_storage_item(key_id, "keychain", WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD, stored_ids, warnings)
	for buffer_variant in get_digital_buffer_items():
		var buffer_id: String = _get_runtime_inventory_item_id(buffer_variant)
		if not buffer_id.is_empty():
			_validate_runtime_inventory_storage_item(buffer_id, "digital_buffer", WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL, stored_ids, warnings)
	for storage_variant in get_digital_storage_items():
		var storage_id: String = _get_runtime_inventory_item_id(storage_variant)
		if not storage_id.is_empty():
			_validate_runtime_inventory_storage_item(storage_id, "digital_storage", WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL, stored_ids, warnings)
	for cell_variant in cell_items.keys():
		for world_item_variant in Array(cell_items.get(cell_variant, [])):
			var world_item_id: String = _get_runtime_inventory_item_id(world_item_variant)
			if not world_item_id.is_empty() and stored_ids.has(world_item_id):
				warnings.append("world_item_also_stored_%s" % world_item_id)
	return warnings

func _validate_runtime_inventory_storage_item(item_id: String, storage_name: String, expected_class: String, stored_ids: Dictionary, warnings: Array[String]) -> void:
	if stored_ids.has(item_id):
		warnings.append("inventory_item_duplicated_%s_%s_%s" % [item_id, str(stored_ids[item_id]), storage_name])
	else:
		stored_ids[item_id] = storage_name
	var item_data: Dictionary = _get_known_inventory_item_data(item_id)
	var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item_data)
	if storage_class != expected_class:
		warnings.append("inventory_storage_class_mismatch_%s_%s_%s" % [storage_name, item_id, storage_class])

func get_inventory_state() -> Dictionary:
	var snapshot: Dictionary = runtime_inventory_state.duplicate(true)
	snapshot["manipulator_hold"] = get_manipulator_item_id()
	snapshot["pocket_items"] = get_pocket_items()
	snapshot["collected_key_ids"] = get_keychain_ids()
	snapshot["digital_buffer"] = get_digital_buffer_items()
	snapshot["digital_storage"] = get_digital_storage_items()
	return snapshot

func mark_key_collected(key_id: String) -> void:
	add_keycard_to_keychain(key_id)

func has_collected_key(key_id: String) -> bool:
	return has_keycard_access(key_id)

func get_actor_capability_levels() -> Dictionary:
	var defaults := {
		"manipulator_level": 0,
		"connector_level": 0,
		"processor_level": 0,
		"connector_types": [],
		"power_class": "none",
		"modules": [],
		"tools": [],
		"port_state": {}
	}
	if active_bipob_ref == null:
		return defaults
	defaults["manipulator_level"] = int(active_bipob_ref.call("get_installed_manipulator_arm_level")) if active_bipob_ref.has_method("get_installed_manipulator_arm_level") else 0
	defaults["power_class"] = str(active_bipob_ref.call("get_bipob_power_class")) if active_bipob_ref.has_method("get_bipob_power_class") else "none"
	var port_state: Dictionary = active_bipob_ref.call("preview_module_port_activity") if active_bipob_ref.has_method("preview_module_port_activity") else {}
	defaults["port_state"] = port_state
	var modules_state: Dictionary = Dictionary(port_state.get("modules", {}))
	var installed_modules: Array = Array(active_bipob_ref.installed_modules) if _active_bipob_has_property("installed_modules") else []
	var modules: Array[String] = []
	var tools: Array[String] = []
	var tool_seen := {}
	var connector_types: Array[String] = []
	var connector_kind_seen := {}
	var connector_level := 0
	var processor_level := 0
	var level_regex := RegEx.new()
	level_regex.compile("_v(\\d+)$")
	for module_id_variant in modules_state.keys():
		var module_id := str(module_id_variant)
		var module_state: Dictionary = Dictionary(modules_state.get(module_id_variant, {}))
		if not bool(module_state.get("active", false)):
			continue
		modules.append(module_id)
		if module_id.contains("_connector_v"):
			var found := level_regex.search(module_id)
			if found != null:
				connector_level = maxi(connector_level, int(found.get_string(1)))
			var connector_type := ""
			if module_id.begins_with("external_interface_connector_"):
				connector_type = "physical"
			elif module_id.begins_with("optical_connector_"):
				connector_type = "optical"
			elif module_id.begins_with("wireless_connector_"):
				connector_type = "wireless"
			elif module_id.begins_with("high_bandwidth_connector_"):
				connector_type = "high_bandwidth"
			if not connector_type.is_empty() and not connector_kind_seen.has(connector_type):
				connector_kind_seen[connector_type] = true
				connector_types.append(connector_type)
		elif module_id.begins_with("processor_"):
			var pfound := level_regex.search(module_id)
			if pfound != null:
				processor_level = maxi(processor_level, int(pfound.get_string(1)))
	for module_variant in installed_modules:
		if module_variant == null:
			continue
		var module_id := str(module_variant.id).strip_edges()
		if module_id.is_empty():
			continue
		if str(module_variant.category) != "Tools":
			continue
		var module_state: Dictionary = Dictionary(modules_state.get(module_id, {}))
		if not bool(module_state.get("active", false)):
			continue
		var tool_action := str(module_variant.tool_action).strip_edges()
		var tool_id := tool_action if not tool_action.is_empty() else module_id
		if tool_seen.has(tool_id):
			continue
		tool_seen[tool_id] = true
		tools.append(tool_id)
	defaults["modules"] = modules
	defaults["tools"] = tools
	defaults["connector_types"] = connector_types
	defaults["connector_level"] = connector_level
	defaults["processor_level"] = processor_level
	return defaults

func _diagnostic_has_inventory_item(item_id: String, inventory_ids: Array) -> bool:
	var normalized_id: String = item_id.strip_edges()
	if normalized_id.is_empty():
		return not inventory_ids.is_empty()
	return inventory_ids.has(normalized_id)

func _build_device_diagnostic_capabilities(actor: Dictionary = {}) -> Dictionary:
	var capabilities: Dictionary = get_actor_capability_levels().duplicate(true)
	var key_card_ids: Array = get_keychain_ids()
	var digital_ids: Array = get_digital_buffer_items() + get_digital_storage_items()
	capabilities["has_free_manipulator"] = get_manipulator_item_id().is_empty()
	capabilities["has_power"] = str(capabilities.get("power_class", "none")) != "none"
	capabilities["has_power_state_knowledge"] = true
	capabilities["key_card_ids"] = key_card_ids.duplicate()
	capabilities["digital_item_ids"] = digital_ids.duplicate()
	capabilities["has_key_card"] = not key_card_ids.is_empty()
	capabilities["has_digital_key"] = false
	capabilities["has_access_code"] = false
	for item_variant in digital_ids:
		var item_id: String = _get_runtime_inventory_item_id(item_variant)
		var item_data: Dictionary = _get_runtime_item_data_snapshot(item_id)
		var item_type: String = str(item_data.get("item_type", item_data.get("object_type", item_id))).strip_edges().to_lower()
		if item_type.contains("digital_key") or item_id.to_lower().contains("digital_key"):
			capabilities["has_digital_key"] = true
		if item_type.contains("access_code") or item_id.to_lower().contains("access_code"):
			capabilities["has_access_code"] = true
	for actor_key_variant in actor.keys():
		capabilities[str(actor_key_variant)] = actor[actor_key_variant]
	return capabilities

func _append_device_diagnostic_missing(missing: Array[Dictionary], id: String, label: String, required: Variant = true, current: Variant = false) -> void:
	missing.append({"id": id, "label": label, "required": required, "current": current})

func _get_device_diagnostic_requirements(target: Dictionary) -> Dictionary:
	var access_type: String = WorldObjectCatalogRef.normalize_access_type(target.get("access_type", target.get("lock_type", "")))
	var power_behavior: String = str(target.get("power_behavior", "")).strip_edges().to_lower()
	var required_key_id: String = str(target.get("required_key_id", target.get("required_key", ""))).strip_edges()
	var requires_fuse: bool = bool(target.get("fuse_required", target.get("requires_fuse", false))) or not str(target.get("required_fuse_id", "")).strip_edges().is_empty()
	var requires_cable: bool = bool(target.get("cable_connection_required", target.get("requires_cable_connection", false)))
	var requires_repair: bool = bool(target.get("repair_required", target.get("requires_repair", false)))
	return {
		"scan_level": maxi(0, int(target.get("required_scan_level", 0))),
		"manipulator_level": maxi(0, int(target.get("required_manipulator_level", 0))),
		"connector_level": maxi(0, int(target.get("required_connector_level", target.get("required_interface_level", 0)))),
		"processor_level": maxi(0, int(target.get("required_processor_level", target.get("required_cpu_level", 0)))),
		"free_manipulator_required": bool(target.get("free_manipulator_required", false)) or access_type == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD,
		"required_key_id": required_key_id,
		"key_card_required": access_type == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD,
		"digital_key_required": access_type == WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY,
		"access_code_required": access_type == WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE or access_type == "password",
		"terminal_required": access_type == WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL or access_type == "terminal_lock",
		"power_required": bool(target.get("power_required", false)) or (not str(target.get("power_network_id", "")).strip_edges().is_empty() and power_behavior != WorldObjectCatalogRef.POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED),
		"power_must_be_cut": power_behavior == WorldObjectCatalogRef.POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED,
		"fuse_required": requires_fuse,
		"cable_connection_required": requires_cable,
		"repair_required": requires_repair
	}

func _get_device_diagnostic_missing(requirements: Dictionary, capabilities: Dictionary, target: Dictionary, scan_level: int) -> Array[Dictionary]:
	var missing: Array[Dictionary] = []
	var required_scan_level: int = int(requirements.get("scan_level", 0))
	if scan_level < required_scan_level:
		_append_device_diagnostic_missing(missing, "scan_level_required", "Scan level %d required" % required_scan_level, required_scan_level, scan_level)
	for capability_name in ["connector", "processor", "manipulator"]:
		var required_level: int = int(requirements.get("%s_level" % capability_name, 0))
		var current_level: int = int(capabilities.get("%s_level" % capability_name, 0))
		if current_level < required_level:
			_append_device_diagnostic_missing(missing, "%s_level_required" % capability_name, "%s Version %d required" % [capability_name.capitalize(), required_level], required_level, current_level)
	if bool(requirements.get("free_manipulator_required", false)) and not bool(capabilities.get("has_free_manipulator", false)):
		_append_device_diagnostic_missing(missing, "free_manipulator_required", "Free manipulator required")
	var required_key_id: String = str(requirements.get("required_key_id", "")).strip_edges()
	var digital_ids: Array = Array(capabilities.get("digital_item_ids", []))
	var has_required_key_card: bool = _diagnostic_has_inventory_item(required_key_id, Array(capabilities.get("key_card_ids", []))) if not required_key_id.is_empty() else bool(capabilities.get("has_key_card", false))
	if bool(requirements.get("key_card_required", false)) and not has_required_key_card:
		_append_device_diagnostic_missing(missing, "key_card_required", "Key-card required", required_key_id, capabilities.get("key_card_ids", []))
	var has_required_digital_key: bool = _diagnostic_has_inventory_item(required_key_id, digital_ids) if not required_key_id.is_empty() else bool(capabilities.get("has_digital_key", false))
	if bool(requirements.get("digital_key_required", false)) and not has_required_digital_key:
		_append_device_diagnostic_missing(missing, "digital_key_required", "Digital key required", required_key_id, digital_ids)
	var has_required_access_code: bool = _diagnostic_has_inventory_item(required_key_id, digital_ids) if not required_key_id.is_empty() else bool(capabilities.get("has_access_code", false))
	if bool(requirements.get("access_code_required", false)) and not has_required_access_code:
		_append_device_diagnostic_missing(missing, "access_code_required", "Access code required", required_key_id, digital_ids)
	if bool(requirements.get("terminal_required", false)) and str(target.get("control_terminal_id", target.get("linked_terminal_id", ""))).strip_edges().is_empty():
		_append_device_diagnostic_missing(missing, "terminal_required", "Linked terminal required")
	var is_powered: bool = bool(target.get("is_powered", true))
	if bool(requirements.get("power_required", false)) and not is_powered:
		_append_device_diagnostic_missing(missing, "power_required", "Power required")
	if bool(requirements.get("power_must_be_cut", false)) and is_powered:
		_append_device_diagnostic_missing(missing, "power_must_be_cut", "Power must be cut")
	if bool(requirements.get("fuse_required", false)) and not bool(target.get("has_fuse", target.get("fuse_inserted", false))):
		_append_device_diagnostic_missing(missing, "fuse_required", "Fuse required")
	if bool(requirements.get("cable_connection_required", false)) and not bool(target.get("connected", target.get("is_connected", false))):
		_append_device_diagnostic_missing(missing, "cable_connection_required", "Cable connection required")
	if bool(requirements.get("repair_required", false)):
		_append_device_diagnostic_missing(missing, "repair_required", "Repair required")
	return missing

func build_device_diagnostic_result(target_object: Dictionary, target_cell: Vector2i, actor: Dictionary = {}) -> Dictionary:
	var normalized_target: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(target_object)
	if str(normalized_target.get("object_group", "")) == "door":
		normalized_target = WorldObjectCatalogRef.normalize_door_contract(normalized_target)
		normalized_target = WorldObjectCatalogRef.normalize_door_state_fields(normalized_target)
	var scan_level: int = maxi(0, int(normalized_target.get("scan_level", 0)))
	var requirements: Dictionary = _get_device_diagnostic_requirements(normalized_target)
	var capabilities: Dictionary = _build_device_diagnostic_capabilities(actor)
	var missing: Array[Dictionary] = _get_device_diagnostic_missing(requirements, capabilities, normalized_target, scan_level)
	var available_actions: Array[Dictionary] = []
	var blocked_actions: Array[Dictionary] = []
	if active_bipob_ref != null and is_instance_valid(active_bipob_ref) and active_bipob_ref.has_method("build_runtime_action_view_model"):
		var view_model_variant: Variant = active_bipob_ref.call("build_runtime_action_view_model", normalized_target, target_cell)
		if typeof(view_model_variant) == TYPE_DICTIONARY:
			for descriptor_variant in Array(Dictionary(view_model_variant).get("actions", [])):
				if typeof(descriptor_variant) != TYPE_DICTIONARY:
					continue
				var descriptor: Dictionary = Dictionary(descriptor_variant).duplicate(true)
				if bool(descriptor.get("enabled", false)):
					available_actions.append(descriptor)
				else:
					blocked_actions.append(descriptor)
	var summary: String = "Device ready."
	if normalized_target.is_empty():
		summary = "No device detected."
	elif not missing.is_empty():
		var missing_labels: Array[String] = []
		for missing_item in missing:
			missing_labels.append(str(missing_item.get("label", "Requirement missing")))
		summary = "Device blocked: %s." % ", ".join(missing_labels)
	elif available_actions.is_empty() and not blocked_actions.is_empty():
		summary = "Device scanned; runtime actions are blocked."
	return {
		"ok": not normalized_target.is_empty(),
		"target_id": str(normalized_target.get("id", "")),
		"target_name": str(normalized_target.get("display_name", normalized_target.get("name", normalized_target.get("object_type", "Unknown device")))),
		"target_group": str(normalized_target.get("object_group", "")),
		"target_type": str(normalized_target.get("object_type", "")),
		"target_cell": target_cell,
		"scan_level": scan_level,
		"required_scan_level": int(requirements.get("scan_level", 0)),
		"is_scanned": scan_level > 0,
		"is_known": bool(normalized_target.get("discovered", normalized_target.get("revealed", scan_level > 0))),
		"state": str(normalized_target.get("state", "unknown")),
		"power_state": "powered" if bool(normalized_target.get("is_powered", true)) else "unpowered",
		"door_type": str(normalized_target.get("door_type", "")),
		"material": str(normalized_target.get("material", "")),
		"access_type": str(normalized_target.get("access_type", "")),
		"requirements": requirements,
		"capabilities": capabilities,
		"missing": missing,
		"available_actions": available_actions,
		"blocked_actions": blocked_actions,
		"summary": summary,
		"warnings": []
	}

func _get_device_interaction_blocking_ids(action_id: String) -> Array[String]:
	match action_id:
		"scan":
			return []
		"open", "unlock":
			return ["key_card_required", "digital_key_required", "access_code_required", "terminal_required", "free_manipulator_required", "power_must_be_cut", "connector_level_required", "manipulator_level_required"]
		"connect", "hack", "download", "control", "activate_platform":
			return ["connector_level_required", "processor_level_required", "power_required", "digital_access_required", "hack_required"]
		"repair", "insert_fuse", "plug_in", "plug_out", "take_end_1", "take_end_2", "connect_wire_end", "connect_wire_1", "connect_wire_2", "disconnect_power_wire", "disconnect_wire_1", "disconnect_wire_2":
			return ["free_manipulator_required", "manipulator_level_required", "fuse_required", "cable_connection_required", "repair_required"]
	return []

func _get_device_interaction_blocked_message(reason: String, missing_item: Dictionary = {}) -> String:
	var required_level: int = int(missing_item.get("required", 0))
	match reason:
		"key_card_required": return "Key-card required."
		"free_manipulator_required": return "Free manipulator required."
		"connector_level_required": return "Connector Version %d required." % required_level
		"processor_level_required": return "Processor Version %d required." % required_level
		"manipulator_level_required": return "Manipulator Version %d required." % required_level
		"power_required", "unpowered": return "Power required."
		"power_must_be_cut": return "Cut power to open this device."
		"terminal_required", "terminal_control_required": return "Use linked terminal."
		"digital_key_required": return "Digital key required."
		"digital_access_required": return "Digital access required."
		"access_code_required": return "Access code required."
		"fuse_required": return "Fuse required."
		"cable_connection_required": return "Cable connection required."
		"repair_required": return "Repair required."
		"hack_required": return "Hack device first."
		"storage_buffer_required": return "Storage buffer required."
		"target_missing": return "No device detected."
	return "Action unavailable."

func build_device_interaction_preflight(target_object: Dictionary, target_cell: Vector2i, action_id: String, actor: Dictionary = {}) -> Dictionary:
	var target_snapshot: Dictionary = target_object.duplicate(true)
	var diagnostic: Dictionary = build_device_diagnostic_result(target_snapshot, target_cell, actor)
	var target_id: String = str(diagnostic.get("target_id", target_snapshot.get("id", "")))
	var target_name: String = str(diagnostic.get("target_name", target_snapshot.get("display_name", target_snapshot.get("name", "Unknown device"))))
	var result: Dictionary = {
		"success": true,
		"action_id": action_id,
		"target_id": target_id,
		"target_name": target_name,
		"diagnostic": diagnostic.duplicate(true),
		"preflight_ok": true,
		"blocked_reason": "",
		"message": "Device ready.",
		"state_changed": false
	}
	if target_snapshot.is_empty():
		result["success"] = false
		result["preflight_ok"] = false
		result["blocked_reason"] = "target_missing"
		result["message"] = _get_device_interaction_blocked_message("target_missing")
		return result
	var blocking_ids: Array[String] = _get_device_interaction_blocking_ids(action_id)
	for missing_variant in Array(diagnostic.get("missing", [])):
		if typeof(missing_variant) != TYPE_DICTIONARY:
			continue
		var missing_item: Dictionary = missing_variant
		var missing_id: String = str(missing_item.get("id", ""))
		if blocking_ids.has(missing_id):
			result["success"] = false
			result["preflight_ok"] = false
			result["blocked_reason"] = missing_id
			result["message"] = _get_device_interaction_blocked_message(missing_id, missing_item)
			return result
	for descriptor_variant in Array(diagnostic.get("blocked_actions", [])):
		if typeof(descriptor_variant) != TYPE_DICTIONARY:
			continue
		var descriptor: Dictionary = descriptor_variant
		if str(descriptor.get("id", "")) != action_id:
			continue
		var descriptor_reason: String = str(descriptor.get("reason", "action_unavailable"))
		result["success"] = false
		result["preflight_ok"] = false
		result["blocked_reason"] = descriptor_reason
		result["message"] = _get_device_interaction_blocked_message(descriptor_reason)
		return result
	return result

func _get_device_interaction_state_next_step(missing_id: String) -> Dictionary:
	match missing_id:
		"key_card_required": return {"id":"collect_key_card", "label":"Collect Key-card"}
		"free_manipulator_required": return {"id":"free_manipulator", "label":"Free Manipulator"}
		"connector_level_required": return {"id":"upgrade_connector", "label":"Upgrade Connector"}
		"processor_level_required": return {"id":"upgrade_processor", "label":"Upgrade Processor"}
		"power_required", "unpowered": return {"id":"restore_power", "label":"Restore Power"}
		"power_must_be_cut": return {"id":"cut_power", "label":"Cut Power"}
		"terminal_required", "terminal_control_required": return {"id":"use_terminal", "label":"Use Terminal"}
		"digital_key_required": return {"id":"find_digital_key", "label":"Find Digital Key"}
		"access_code_required": return {"id":"find_access_code", "label":"Find Access Code"}
		"fuse_required": return {"id":"insert_fuse", "label":"Insert Fuse"}
		"cable_connection_required": return {"id":"connect_cable", "label":"Connect Cable"}
		"repair_required": return {"id":"repair", "label":"Repair"}
		"scan_level_required": return {"id":"scan", "label":"Scan"}
		"manipulator_level_required": return {"id":"upgrade_manipulator", "label":"Upgrade Manipulator"}
		"digital_access_required": return {"id":"find_digital_key", "label":"Find Digital Key"}
		"hack_required": return {"id":"hack", "label":"Hack"}
		"storage_buffer_required": return {"id":"clear_storage_buffer", "label":"Clear Storage Buffer"}
	return {}

func _get_device_interaction_action_label(diagnostic: Dictionary, action_id: String) -> String:
	for descriptor_variant in Array(diagnostic.get("available_actions", [])) + Array(diagnostic.get("blocked_actions", [])):
		if typeof(descriptor_variant) != TYPE_DICTIONARY:
			continue
		var descriptor: Dictionary = descriptor_variant
		if str(descriptor.get("id", "")) == action_id:
			return str(descriptor.get("label", action_id.capitalize()))
	return action_id.capitalize()

func _device_diagnostic_has_available_action(diagnostic: Dictionary, action_id: String) -> bool:
	for descriptor_variant in Array(diagnostic.get("available_actions", [])):
		if typeof(descriptor_variant) == TYPE_DICTIONARY and str(Dictionary(descriptor_variant).get("id", "")) == action_id:
			return true
	return false

func _is_device_interaction_state_flow_target(target: Dictionary, diagnostic: Dictionary) -> bool:
	var target_group: String = str(target.get("object_group", "")).strip_edges().to_lower()
	if target_group in ["door", "terminal", "device", "power", "platform"] or bool(target.get("is_digital_device", false)):
		return true
	var requirements_variant: Variant = diagnostic.get("requirements", {})
	if typeof(requirements_variant) != TYPE_DICTIONARY:
		return false
	var requirements: Dictionary = requirements_variant
	for requirement_id in ["scan_level", "manipulator_level", "connector_level", "processor_level"]:
		if int(requirements.get(requirement_id, 0)) > 0:
			return true
	for requirement_id in ["free_manipulator_required", "key_card_required", "digital_key_required", "access_code_required", "terminal_required", "power_required", "power_must_be_cut", "fuse_required", "cable_connection_required", "repair_required"]:
		if bool(requirements.get(requirement_id, false)):
			return true
	return false

func build_device_interaction_state_flow(target_object: Dictionary, target_cell: Vector2i, action_id: String = "", actor: Dictionary = {}) -> Dictionary:
	var target_snapshot: Dictionary = target_object.duplicate(true)
	var diagnostic: Dictionary = build_device_diagnostic_result(target_snapshot, target_cell, actor)
	var preflight: Dictionary = build_device_interaction_preflight(target_snapshot, target_cell, action_id, actor)
	var result: Dictionary = {
		"target_id": str(diagnostic.get("target_id", target_snapshot.get("id", ""))),
		"target_name": str(diagnostic.get("target_name", target_snapshot.get("display_name", target_snapshot.get("name", "Unknown device")))),
		"target_cell": target_cell,
		"state": "no_target",
		"next_step_id": "",
		"next_step_label": "",
		"message": "No device detected.",
		"diagnostic": diagnostic.duplicate(true),
		"preflight": preflight.duplicate(true),
		"can_execute": false,
		"warnings": Array(diagnostic.get("warnings", [])).duplicate(true),
		"is_applicable": false
	}
	if target_snapshot.is_empty():
		return result
	result["is_applicable"] = _is_device_interaction_state_flow_target(target_snapshot, diagnostic)
	if not bool(diagnostic.get("is_scanned", false)):
		result["state"] = "unknown"
		result["next_step_id"] = "scan"
		result["next_step_label"] = "Scan"
		result["message"] = "Scan device first."
		return result
	if not bool(diagnostic.get("ok", false)):
		result["state"] = "scanned"
		result["next_step_id"] = "diagnose"
		result["next_step_label"] = "Diagnose"
		result["message"] = "Diagnose device readiness."
		return result
	for missing_variant in Array(diagnostic.get("missing", [])):
		if typeof(missing_variant) != TYPE_DICTIONARY:
			continue
		var missing_item: Dictionary = missing_variant
		var missing_id: String = str(missing_item.get("id", ""))
		var next_step: Dictionary = _get_device_interaction_state_next_step(missing_id)
		if next_step.is_empty():
			continue
		result["state"] = "blocked"
		result["next_step_id"] = str(next_step.get("id", ""))
		result["next_step_label"] = str(next_step.get("label", ""))
		result["message"] = _get_device_interaction_blocked_message(missing_id, missing_item)
		return result
	if bool(preflight.get("preflight_ok", false)) and not action_id.is_empty() and _device_diagnostic_has_available_action(diagnostic, action_id):
		result["state"] = "ready"
		result["next_step_id"] = action_id
		result["next_step_label"] = _get_device_interaction_action_label(diagnostic, action_id)
		result["message"] = "Ready."
		result["can_execute"] = true
		return result
	var blocked_reason: String = str(preflight.get("blocked_reason", ""))
	var blocked_step: Dictionary = _get_device_interaction_state_next_step(blocked_reason)
	if not blocked_step.is_empty():
		result["state"] = "blocked"
		result["next_step_id"] = str(blocked_step.get("id", ""))
		result["next_step_label"] = str(blocked_step.get("label", ""))
		result["message"] = str(preflight.get("message", _get_device_interaction_blocked_message(blocked_reason)))
		return result
	result["state"] = "executed_unavailable"
	result["message"] = "Action unavailable."
	if not blocked_reason.is_empty():
		result["message"] = str(preflight.get("message", _get_device_interaction_blocked_message(blocked_reason)))
	return result

func get_runtime_device_diagnostic(target_id: String) -> Dictionary:
	var target: Dictionary = get_world_object_by_id(target_id)
	if target.is_empty():
		return build_device_diagnostic_result({}, Vector2i(-1, -1))
	return build_device_diagnostic_result(target, _get_world_object_cell_from_data(target))

func check_world_object_requirements(object_id: String, action: String = "") -> Dictionary:
	var object_data := get_world_object_by_id(object_id)
	var capabilities := get_actor_capability_levels()
	var requirements: Dictionary = {}
	var reasons: Array[String] = []
	if object_data.is_empty():
		return {"allowed": false, "object_id": object_id, "action": action, "requirements": requirements, "capabilities": capabilities, "reasons": ["object_missing"]}
	for key in ["required_manipulator_level", "required_connector_level", "required_processor_level", "required_bipob_power_class", "fits_targets", "required_tool", "required_item_id", "lock_type", "terminal_class", "door_class", "item_form", "storage_type"]:
		if object_data.has(key):
			requirements[key] = object_data[key]
	if int(requirements.get("required_manipulator_level", 0)) > int(capabilities.get("manipulator_level", 0)): reasons.append("manipulator_level_too_low")
	if int(requirements.get("required_connector_level", 0)) > int(capabilities.get("connector_level", 0)): reasons.append("connector_level_too_low")
	if int(requirements.get("required_processor_level", 0)) > int(capabilities.get("processor_level", 0)): reasons.append("processor_level_too_low")
	var required_power_class := str(requirements.get("required_bipob_power_class", "")).strip_edges()
	if not required_power_class.is_empty() and required_power_class != str(capabilities.get("power_class", "none")):
		reasons.append("power_class_too_low")
	if not str(requirements.get("required_tool", "")).strip_edges().is_empty() and not Array(capabilities.get("tools", [])).has(str(requirements.get("required_tool", ""))):
		reasons.append("required_tool_missing")
	if not str(requirements.get("required_item_id", "")).strip_edges().is_empty():
		var inv := get_inventory_state()
		var all_items: Array = Array(inv.get("pocket_items", [])) + [get_manipulator_held_item_id()] + Array(inv.get("digital_buffer", []))
		if not all_items.has(str(requirements.get("required_item_id", ""))):
			reasons.append("required_item_missing")
	if reasons.is_empty():
		reasons.append("ok")
	return {"allowed": reasons.size() == 1 and reasons[0] == "ok", "object_id": object_id, "action": action, "requirements": requirements, "capabilities": capabilities, "reasons": reasons}

func _is_keycard_item(item_data: Dictionary) -> bool:
	return WorldObjectCatalogRef.is_key_card_item(item_data)

func can_pickup_world_item(item_id: String) -> Dictionary:
	var normalized_id: String = item_id.strip_edges()
	var item := get_world_object_by_id(normalized_id)
	if item.is_empty():
		item = get_cell_item_by_id(normalized_id)
	if item.is_empty():
		return {"success": false, "reasons": ["item_missing"], "item_id": normalized_id}
	if not bool(item.get("can_pickup", true)):
		return {"success": false, "reasons": ["item_does_not_fit"], "item_id": normalized_id}
	var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item)
	if storage_class == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL:
		if not bool(item.get("can_place_in_digital_buffer", true)) and str(item.get("storage_type", "")) != "digital_storage":
			return {"success": false, "reasons": ["digital_storage_full"], "message": "No free digital storage slot.", "item_id": normalized_id}
		if not get_digital_buffer_items().is_empty():
			return {"success": false, "reasons": ["digital_buffer_full"], "message": "No free digital buffer slot.", "item_id": normalized_id}
	elif storage_class != WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD:
		var hold_gate := can_hold_item_in_manipulator(normalized_id)
		if not bool(hold_gate.get("success", false)):
			return {"success": false, "reasons": ["manipulator_occupied"], "message": "Free manipulator required.", "item_id": normalized_id}
	return {"success": true, "reasons": ["ok"], "item_id": normalized_id}

func _get_world_item_runtime_map() -> Dictionary:
	var runtime_map: Dictionary = Dictionary(runtime_inventory_state.get("world_item_runtime", {}))
	runtime_inventory_state["world_item_runtime"] = runtime_map
	return runtime_map

func _find_linked_door_id_for_key(item_id: String) -> String:
	var normalized_id: String = item_id.strip_edges()
	if normalized_id.is_empty():
		return ""
	for object_data in mission_world_objects:
		if str(object_data.get("required_key_id", "")).strip_edges() == normalized_id:
			return str(object_data.get("id", "")).strip_edges()
	return ""

func _build_picked_up_world_item_runtime(item_data: Dictionary) -> Dictionary:
	var item_id: String = str(item_data.get("id", "")).strip_edges()
	var snapshot := {
		"picked_up": true,
		"in_inventory": true,
		"carried_by": "bipob",
		"item_data": item_data.duplicate(true),
		"key_kind": str(item_data.get("key_kind", "")).strip_edges(),
		"key_type": str(item_data.get("key_type", item_data.get("item_type", ""))).strip_edges(),
		"linked_door_id": str(item_data.get("linked_door_id", item_data.get("door_id", ""))).strip_edges()
	}
	if str(snapshot.get("linked_door_id", "")).is_empty():
		snapshot["linked_door_id"] = _find_linked_door_id_for_key(item_id)
	return snapshot

func _get_runtime_item_data_snapshot(item_id: String) -> Dictionary:
	var runtime_map := _get_world_item_runtime_map()
	var item_runtime: Dictionary = Dictionary(runtime_map.get(item_id.strip_edges(), {}))
	var item_data: Dictionary = Dictionary(item_runtime.get("item_data", {}))
	if item_data.is_empty() and not item_runtime.is_empty():
		item_data = item_runtime.duplicate(true)
	return item_data

func _get_known_inventory_item_data(item_id: String) -> Dictionary:
	var normalized_id: String = item_id.strip_edges()
	var item_data: Dictionary = _get_runtime_item_data_snapshot(normalized_id)
	if not item_data.is_empty():
		return item_data
	item_data = get_world_object_by_id(normalized_id)
	if item_data.is_empty():
		item_data = get_cell_item_by_id(normalized_id)
	return item_data

func pickup_world_item(item_id: String) -> Dictionary:
	var normalized_id: String = item_id.strip_edges()
	var gate := can_pickup_world_item(normalized_id)
	if not bool(gate.get("success", false)):
		return gate
	var item := get_world_object_by_id(normalized_id)
	if item.is_empty():
		item = get_cell_item_by_id(normalized_id)
	if item.is_empty():
		return {"success": false, "reasons": ["item_missing"], "item_id": normalized_id}
	var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item)
	if storage_class == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL:
		var digital_buffer: Array = get_digital_buffer_items()
		if not digital_buffer.has(normalized_id):
			digital_buffer.append(normalized_id)
		runtime_inventory_state["digital_buffer"] = digital_buffer
	elif storage_class == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD:
		add_keycard_to_keychain(normalized_id)
	else:
		set_manipulator_item(item)
	var runtime_map := _get_world_item_runtime_map()
	runtime_map[normalized_id] = _build_picked_up_world_item_runtime(item)
	runtime_inventory_state["world_item_runtime"] = runtime_map
	_remove_world_item_from_lookup_tables(normalized_id, item)
	refresh_world_cooling_received()
	var message: String = "Key-card collected." if storage_class == WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD else "Item collected."
	return {"success": true, "reasons": ["ok"], "message": message, "item_id": normalized_id}


func move_runtime_manipulator_to_pocket(pocket_index: int, pocket_capacity: int) -> Dictionary:
	var held_id: String = get_manipulator_held_item_id()
	if held_id.is_empty():
		return {"ok": false, "message": "Manipulator is empty."}
	if pocket_index < 0 or pocket_index >= pocket_capacity:
		return {"ok": false, "message": "Pocket slot is unavailable."}
	var pocket: Array = Array(runtime_inventory_state.get("pocket_items", []))
	pocket.resize(pocket_capacity)
	if not _get_runtime_inventory_item_id(pocket[pocket_index]).is_empty():
		return {"ok": false, "message": "Pocket slot is occupied."}
	if not set_pocket_item(pocket_index, get_manipulator_item_data()):
		return {"ok": false, "message": "Only physical items can be stored in pockets."}
	clear_manipulator()
	return {"ok": true, "message": "Stored manipulator item in pocket."}

func move_or_swap_runtime_pocket_slot_with_manipulator(pocket_index: int, pocket_capacity: int) -> Dictionary:
	if pocket_index < 0 or pocket_index >= pocket_capacity:
		return {"ok": false, "message": "Pocket slot is unavailable."}
	var pocket: Array = Array(runtime_inventory_state.get("pocket_items", []))
	pocket.resize(pocket_capacity)
	var pocket_id: String = _get_runtime_inventory_item_id(pocket[pocket_index])
	var pocket_data: Dictionary = _get_runtime_item_data_snapshot(pocket_id)
	var held_id: String = get_manipulator_item_id()
	var held_data: Dictionary = get_manipulator_item_data()
	if pocket_id.is_empty() and held_id.is_empty():
		return {"ok": false, "message": "Pocket slot is empty."}
	if not pocket_id.is_empty() and not WorldObjectCatalogRef.is_physical_inventory_item(pocket_data):
		return {"ok": false, "message": "Only physical items can move to the manipulator."}
	if not set_pocket_item(pocket_index, held_data):
		return {"ok": false, "message": "Only physical items can be stored in pockets."}
	if not set_manipulator_item(pocket_data if not pocket_id.is_empty() else ""):
		set_pocket_item(pocket_index, pocket_data)
		set_manipulator_item(held_data)
		return {"ok": false, "message": "Only physical items can move to the manipulator."}
	return {"ok": true, "message": "Moved or swapped pocket and manipulator items."}

func can_drop_inventory_item(item_id: String) -> Dictionary:
	var inv := get_inventory_state()
	var has_item := Array(inv.get("pocket_items", [])).has(item_id) or get_manipulator_held_item_id() == item_id
	return {"success": has_item, "item_id": item_id, "reasons": ["ok"] if has_item else ["item_missing"]}

func drop_inventory_item(item_id: String, target_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var gate := can_drop_inventory_item(item_id)
	if not bool(gate.get("success", false)):
		return gate
	if target_cell == Vector2i(-1, -1):
		return {"success": false, "item_id": item_id, "target_cell": target_cell, "reasons": ["invalid_target_cell"]}
	var pocket: Array = runtime_inventory_state.get("pocket_items", [])
	pocket.erase(item_id)
	runtime_inventory_state["pocket_items"] = pocket
	if get_manipulator_held_item_id() == item_id:
		clear_manipulator_held_item()
	var runtime_map := _get_world_item_runtime_map()
	var dropped_runtime: Dictionary = {}
	var dropped_runtime_variant: Variant = runtime_map.get(item_id, {})
	if dropped_runtime_variant is Dictionary:
		dropped_runtime = dropped_runtime_variant.duplicate(true)
	if dropped_runtime.is_empty():
		dropped_runtime["item_data"] = _get_runtime_item_data_snapshot(item_id)
	dropped_runtime["picked_up"] = false
	dropped_runtime["in_inventory"] = false
	dropped_runtime["carried_by"] = ""
	dropped_runtime["position"] = [target_cell.x, target_cell.y]
	var dropped_item_data: Dictionary = Dictionary(dropped_runtime.get("item_data", {})).duplicate(true)
	if dropped_item_data.is_empty():
		dropped_item_data = {"id": item_id}
	dropped_item_data["id"] = item_id
	add_item_at_cell(target_cell, dropped_item_data)
	dropped_runtime["item_data"] = get_cell_item_by_id(item_id).duplicate(true)
	runtime_map[item_id] = dropped_runtime
	runtime_inventory_state["world_item_runtime"] = runtime_map
	return {"success": true, "item_id": item_id, "target_cell": target_cell, "reasons": ["ok"]}

func get_manipulator_items() -> Array:
	var held_item_id: String = get_manipulator_held_item_id()
	if held_item_id.is_empty():
		return []
	return [get_manipulator_held_item_data()]

func can_hold_item_in_manipulator(item_id: String) -> Dictionary:
	var item_data: Dictionary = _get_runtime_item_data_snapshot(item_id)
	var storage_class: String = WorldObjectCatalogRef.get_item_storage_class(item_data)
	if storage_class in [WorldObjectCatalogRef.ITEM_STORAGE_CLASS_KEY_CARD, WorldObjectCatalogRef.ITEM_STORAGE_CLASS_DIGITAL]:
		return {"success": false, "item_id": item_id, "reasons": ["item_does_not_fit"]}
	if not get_manipulator_items().is_empty():
		return {"success": false, "item_id": item_id, "reasons": ["item_does_not_fit"]}
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func hold_item_in_manipulator(item_id: String) -> Dictionary:
	var gate := can_hold_item_in_manipulator(item_id)
	if not bool(gate.get("success", false)):
		return gate
	set_manipulator_held_item(item_id)
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func can_place_item_in_digital_buffer(item_id: String) -> Dictionary:
	var item: Dictionary = get_world_object_by_id(item_id)
	if item.is_empty():
		item = _get_runtime_item_data_snapshot(item_id)
	if item.is_empty():
		return {"success": false, "item_id": item_id, "reasons": ["item_missing"]}
	if not WorldObjectCatalogRef.is_digital_inventory_item(item) or not bool(item.get("can_place_in_digital_buffer", false)):
		return {"success": false, "item_id": item_id, "reasons": ["item_does_not_fit"]}
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func place_item_in_digital_buffer(item_id: String) -> Dictionary:
	var gate := can_place_item_in_digital_buffer(item_id)
	if not bool(gate.get("success", false)):
		return gate
	var buffer: Array = runtime_inventory_state.get("digital_buffer", [])
	if not buffer.has(item_id):
		buffer.append(item_id)
	runtime_inventory_state["digital_buffer"] = buffer
	return {"success": true, "item_id": item_id, "reasons": ["ok"]}

func _add_world_runtime_restore_warning(message: String) -> void:
	if message.strip_edges().is_empty():
		return
	last_world_runtime_restore_warnings.append(message)

func _extract_saved_world_runtime_position(saved_data: Dictionary, object_id: String, fallback_position: Vector2i) -> Dictionary:
	if not saved_data.has("position"):
		return {"ok": true, "position": fallback_position}
	var position_variant: Variant = saved_data.get("position")
	var parsed_position := WorldObjectCatalogRef.to_world_cell(position_variant, Vector2i(-1, -1))
	if parsed_position.x < 0 and parsed_position.y < 0:
		_add_world_runtime_restore_warning("Restore skipped for %s: invalid position data." % object_id)
		return {"ok": false}
	if parsed_position.x < 0 or parsed_position.y < 0:
		_add_world_runtime_restore_warning("Restore skipped for %s: position has negative coordinate %s." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("is_in_bounds") and not bool(grid_manager.call("is_in_bounds", parsed_position)):
		_add_world_runtime_restore_warning("Restore skipped for %s: position %s is out of bounds." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("is_walkable") and not bool(grid_manager.call("is_walkable", parsed_position)):
		_add_world_runtime_restore_warning("Restore skipped for %s: position %s is not walkable." % [object_id, str(parsed_position)])
		return {"ok": false}
	if grid_manager != null and grid_manager.has_method("get_tile"):
		var tile_variant: Variant = grid_manager.call("get_tile", parsed_position)
		if typeof(tile_variant) == TYPE_DICTIONARY:
			var tile_data: Dictionary = tile_variant
			if str(tile_data.get("type", "")) == "wall":
				_add_world_runtime_restore_warning("Restore skipped for %s: position %s is a wall tile." % [object_id, str(parsed_position)])
				return {"ok": false}
	return {"ok": true, "position": parsed_position}

func apply_world_object_runtime_state(saved_state: Dictionary) -> void:
	last_world_runtime_restore_warnings.clear()
	if saved_state.is_empty():
		return
	for object_id_variant in saved_state.keys():
		var object_id := str(object_id_variant).strip_edges()
		if object_id.is_empty():
			continue
		var saved_data_variant: Variant = saved_state.get(object_id_variant, {})
		if typeof(saved_data_variant) != TYPE_DICTIONARY:
			_add_world_runtime_restore_warning("Restore skipped for %s: runtime entry is not a dictionary." % object_id)
			continue
		var saved_data: Dictionary = saved_data_variant
		var existing_object := get_world_object_by_id(object_id)
		var is_new_object := existing_object.is_empty()
		var candidate_object := existing_object
		if is_new_object:
			var object_type := str(saved_data.get("object_type", "")).strip_edges()
			if object_type.is_empty():
				_add_world_runtime_restore_warning("Restore skipped for %s: missing object_type for unknown object id." % object_id)
				continue
			var created := WorldObjectCatalogRef.create_world_object(object_type, object_id)
			if created.is_empty():
				_add_world_runtime_restore_warning("Restore skipped for %s: failed to create object_type %s." % [object_id, object_type])
				continue
			created["id"] = object_id
			candidate_object = created
		var old_position := WorldObjectCatalogRef.to_world_cell(candidate_object.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var parsed_position_info := _extract_saved_world_runtime_position(saved_data, object_id, old_position)
		if not bool(parsed_position_info.get("ok", false)):
			continue
		var new_position := Vector2i(parsed_position_info.get("position", old_position))
		var replaced := get_world_object_at_cell(new_position)
		if not replaced.is_empty() and str(replaced.get("id", "")) != object_id:
			_add_world_runtime_restore_warning("Restore skipped for %s: target cell occupied by %s." % [object_id, str(replaced.get("id", ""))])
			continue
		var runtime_updates: Dictionary = {}
		for key_variant in saved_data.keys():
			var key := str(key_variant)
			if str(key) == "position":
				continue
			runtime_updates[key] = saved_data[key_variant]
		for key in runtime_updates.keys():
			candidate_object[key] = runtime_updates[key]
		candidate_object["id"] = object_id
		candidate_object["position"] = new_position
		if not is_new_object and old_position != new_position:
			world_objects_by_cell.erase(old_position)
		world_objects_by_cell[new_position] = candidate_object
		if is_new_object and not mission_world_objects.has(candidate_object):
			mission_world_objects.append(candidate_object)
	refresh_world_cooling_received()
	PowerSystemRef.recalculate_network(mission_world_objects, "power_net_A")
	refresh_world_cooling_received()

func get_world_runtime_persistence_debug_summary_text() -> String:
	var serialized := get_world_object_runtime_state()
	var moved_objects := 0
	var heat_enabled_objects := 0
	var powered_objects := 0
	var connection_state_objects := 0
	for object_data in mission_world_objects:
		var current_position := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		if object_data.has("original_position"):
			var original_position := WorldObjectCatalogRef.to_world_cell(object_data.get("original_position", current_position), current_position)
			if original_position != current_position:
				moved_objects += 1
		if object_data.has("working_heat") or object_data.has("overheat_threshold") or object_data.has("current_heat"):
			heat_enabled_objects += 1
		if bool(object_data.get("is_powered", false)):
			powered_objects += 1
		if object_data.has("connected_device_ids") or object_data.has("heat_from_connections"):
			connection_state_objects += 1
	return "WorldRuntimePersistence: serialized=%d | moved=%d | heat_enabled=%d | powered=%d | connection_state=%d | restore_warnings=%d" % [
		serialized.size(),
		moved_objects,
		heat_enabled_objects,
		powered_objects,
		connection_state_objects,
		last_world_runtime_restore_warnings.size()
	]

func get_world_runtime_restore_warnings_text() -> String:
	if last_world_runtime_restore_warnings.is_empty():
		return "No world runtime restore warnings."
	return "\n".join(last_world_runtime_restore_warnings)

func get_world_runtime_restore_warnings() -> Array[String]:
	return last_world_runtime_restore_warnings.duplicate()


func set_active_bipob_ref(bipob: Node) -> void:
	active_bipob_ref = bipob

func get_platform_by_id(platform_id: String) -> Dictionary:
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) != "platform":
			continue
		if str(object_data.get("platform_id", "")) == platform_id:
			return object_data
	return {}

func get_platform_for_cell(cell: Vector2i) -> Dictionary:
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) != "platform":
			continue
		for platform_cell_variant in Array(object_data.get("platform_cells", [])):
			var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
			if platform_cell == cell:
				return object_data
	return {}

func get_cell_height_level(cell: Vector2i) -> int:
	var platform := get_platform_for_cell(cell)
	if platform.is_empty() or str(platform.get("platform_type", "")) != "lifting":
		return 0
	return int(platform.get("height_level", 0))

func refresh_world_object_platform_height_state(object_data: Dictionary) -> void:
	if object_data.is_empty():
		return
	var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	if object_cell.x < 0 or object_cell.y < 0:
		return
	var platform := get_platform_for_cell(object_cell)
	if not platform.is_empty() and str(platform.get("platform_type", "")) == "lifting":
		object_data["platform_height_level"] = int(platform.get("height_level", 0))
		object_data["carried_by_platform_id"] = str(platform.get("platform_id", ""))
		return
	object_data["platform_height_level"] = get_cell_height_level(object_cell)
	object_data.erase("carried_by_platform_id")

func get_world_object_height_level(object_data: Dictionary) -> int:
	if object_data.is_empty():
		return 0
	if object_data.has("platform_height_level"):
		return int(object_data.get("platform_height_level", 0))
	var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	return get_cell_height_level(object_cell)

func get_actor_height_level(actor_cell: Vector2i, actor: Node = null) -> int:
	var cell_height := get_cell_height_level(actor_cell)
	if actor == null:
		return cell_height
	if actor.has_method("get_carried_by_platform_id"):
		var carried_platform_id := str(actor.call("get_carried_by_platform_id")).strip_edges()
		if carried_platform_id.is_empty():
			return cell_height
		var current_platform := get_platform_for_cell(actor_cell)
		if current_platform.is_empty():
			return cell_height
		var current_platform_id := str(current_platform.get("platform_id", "")).strip_edges()
		if current_platform_id != carried_platform_id:
			return cell_height
		if actor.has_method("get_platform_height_level"):
			return int(actor.call("get_platform_height_level"))
		return cell_height
	if actor.has_method("get_platform_height_level"):
		return int(actor.call("get_platform_height_level"))
	return get_cell_height_level(actor_cell)

func can_move_between_height_levels(from_cell: Vector2i, to_cell: Vector2i, actor: Node = null) -> bool:
	var from_height := get_actor_height_level(from_cell, actor)
	var to_height := get_cell_height_level(to_cell)
	if from_height == to_height:
		return true
	if actor != null and actor.has_method("get_carried_by_platform_id"):
		var carried_platform_id := str(actor.call("get_carried_by_platform_id")).strip_edges()
		if not carried_platform_id.is_empty():
			var target_platform := get_platform_for_cell(to_cell)
			if not target_platform.is_empty() and str(target_platform.get("platform_id", "")).strip_edges() == carried_platform_id:
				return true
	return false

func get_platform_occupants(platform_id: String) -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		return {"world_objects": [], "items": [], "bipobs": []}
	var cells: Array = []
	for c in Array(platform.get("platform_cells", [])):
		cells.append(WorldObjectCatalogRef.to_world_cell(c, Vector2i(-1, -1)))
	var occupants := {"world_objects": [], "items": [], "bipobs": []}
	for object_data in mission_world_objects:
		if str(object_data.get("id", "")) == str(platform.get("id", "")):
			continue
		var pos := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		if cells.has(pos):
			occupants["world_objects"].append(object_data)
	for cell in cells:
		for item in get_items_at_cell(cell):
			occupants["items"].append(item)
	if active_bipob_ref != null and active_bipob_ref.has_method("get_grid_position"):
		var bipob_cell: Vector2i = active_bipob_ref.get_grid_position()
		if cells.has(bipob_cell):
			var bipob_direction := "up"
			if active_bipob_ref.has_method("get_direction"):
				bipob_direction = str(active_bipob_ref.get_direction())
			occupants["bipobs"].append({"id":"active_bipob","position":bipob_cell,"direction":bipob_direction})
	return occupants

func can_bipob_access_platform_switch(platform: Dictionary, actor_cell: Vector2i, facing_dir: String) -> bool:
	if platform.is_empty():
		return false
	if str(platform.get("object_group", "")) != "platform":
		return false
	if str(platform.get("control_type", "internal")) != "internal":
		return false
	if not platform.has("local_switch_cell"):
		return false
	var local_switch_cell := WorldObjectCatalogRef.to_world_cell(platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if local_switch_cell.x < 0 or local_switch_cell.y < 0:
		return false
	var facing_vector := _facing_to_vector(facing_dir)
	return actor_cell + facing_vector == local_switch_cell

func activate_platform_by_id(platform_id: String, source: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		return {"success":false, "message":"Platform not found."}
	if str(platform.get("state", "active")) in ["unpowered", "disabled"] or not bool(platform.get("is_powered", true)):
		return {"success":false, "message":"Platform is unpowered."}
	if bool(platform.get("requires_terminal_enabled", false)):
		var terminal := get_world_object_by_id(str(platform.get("linked_terminal_id", "")))
		if terminal.is_empty() or str(terminal.get("state", "active")) in ["unpowered", "disabled", "damaged"] or not bool(terminal.get("platform_control_enabled", true)) or not bool(terminal.get("is_powered", true)):
			return {"success":false, "message":"Platform terminal is unavailable."}
	var mode := str(platform.get("activation_mode", "instant"))
	if mode == "timer":
		platform["pending_activation"] = true
		platform["timer_remaining_turns"] = maxi(1, int(platform.get("timer_turns", 1)))
		return {"success":true, "message":"Platform timer armed."}
	if mode == "periodic":
		platform["periodic_active"] = not bool(platform.get("periodic_active", false))
		platform["timer_remaining_turns"] = maxi(1, int(platform.get("period_turns", 1)))
		return {"success":true, "message":"Platform periodic toggled."}
	if mode == "permanent":
		platform["permanent_state"] = not bool(platform.get("permanent_state", false))
	return _execute_platform_action(platform, source)


func get_platform_action_availability(platform_id: String, action: String = "") -> Dictionary:
	var normalized_action := action.strip_edges().to_lower()
	var result := {"available": false, "platform_id": platform_id, "action": normalized_action, "reasons": [], "state": "", "is_powered": false, "control_type": "", "power_type": ""}
	var valid_actions := ["", "activate", "raise", "lower", "toggle", "rotate_clockwise", "rotate_counterclockwise"]
	if not valid_actions.has(normalized_action):
		result["reasons"] = ["invalid_action"]
		return result
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty():
		result["reasons"] = ["platform_missing"]
		return result
	if str(platform.get("object_group", "")) != "platform":
		result["reasons"] = ["not_platform"]
		return result
	result["state"] = str(platform.get("state", ""))
	result["is_powered"] = bool(platform.get("is_powered", false))
	result["control_type"] = str(platform.get("control_type", "internal"))
	result["power_type"] = str(platform.get("power_type", "external"))
	var reasons: Array[String] = []
	if bool(platform.get("damaged", false)) or str(platform.get("state", "")) == "damaged": reasons.append("platform_damaged")
	if bool(platform.get("broken", false)) or str(platform.get("state", "")) == "broken": reasons.append("platform_broken")
	if bool(platform.get("destroyed", false)) or str(platform.get("state", "")) == "destroyed": reasons.append("platform_destroyed")
	if not bool(platform.get("is_powered", true)) or str(platform.get("state", "")) in ["unpowered", "disabled"] or str(platform.get("power_type", "external")) == "external" and not bool(platform.get("is_powered", false)):
		reasons.append("platform_unpowered")
	if not bool(platform.get("local_switch_enabled", true)): reasons.append("local_switch_disabled")
	if not bool(platform.get("terminal_control_enabled", true)): reasons.append("terminal_control_disabled")
	if bool(platform.get("requires_terminal_enabled", false)):
		var terminal := get_world_object_by_id(str(platform.get("linked_terminal_id", "")))
		if terminal.is_empty() or not bool(terminal.get("platform_control_enabled", true)) or str(terminal.get("state", "")) in ["unpowered", "disabled", "damaged"]:
			reasons.append("linked_terminal_unavailable")
	if reasons.is_empty(): reasons.append("ok")
	result["reasons"] = reasons
	result["available"] = reasons.size() == 1 and reasons[0] == "ok"
	return result

func get_lifting_platform_carry_targets(platform_id: String) -> Array[Dictionary]:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty() or str(platform.get("platform_type", "")) != "lifting":
		return []
	var targets: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if str(object_data.get("id", "")) == str(platform.get("id", "")):
			continue
		if str(object_data.get("object_group", "")) in ["wall", "door", "terminal"] and not bool(object_data.get("rotate_with_platform", false)):
			continue
		if bool(object_data.get("destroyed", false)):
			continue
		var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var on_platform := false
		for platform_cell_variant in Array(platform.get("platform_cells", [])):
			if WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1)) == object_cell:
				on_platform = true
				break
		if on_platform or str(object_data.get("carried_by_platform_id", "")) == platform_id:
			targets.append(object_data)
	return targets

func apply_lifting_platform_height_change(platform_id: String, delta: int, controller_id: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty(): return {"success": false, "reason": "platform_missing"}
	var current := int(platform.get("height_level", 0))
	var min_h := int(platform.get("min_height_level", 0))
	var max_h := int(platform.get("max_height_level", 1))
	var target := clampi(current + delta, min_h, max_h)
	if target == current:
		return {"success": false, "reason": "already_at_max_height" if delta > 0 else "already_at_min_height", "height_level": current}
	platform["height_level"] = target
	for obj in get_lifting_platform_carry_targets(platform_id):
		obj["platform_height_level"] = target
		obj["height_level"] = target
		obj["carried_by_platform_id"] = platform_id
	if active_bipob_ref != null and active_bipob_ref.has_method("set_platform_height_level") and _is_active_bipob_on_platform(platform):
		active_bipob_ref.call("set_platform_height_level", target, platform_id)
	return {"success": true, "reason": "ok", "height_level": target, "controller_id": controller_id}

func apply_rotating_platform_rotation(platform_id: String, clockwise: bool = true, controller_id: String = "") -> Dictionary:
	var platform := get_platform_by_id(platform_id)
	if platform.is_empty(): return {"success": false, "reason": "platform_missing"}
	var occupants := get_platform_occupants(platform_id)
	platform["rotation_direction"] = "clockwise" if clockwise else "counterclockwise"
	if platform.has("facing_dir"):
		platform["facing_dir"] = _rotate_facing(str(platform.get("facing_dir", "up")), clockwise)
	for obj in Array(occupants.get("world_objects", [])):
		if str(obj.get("object_type", "")) in ["external_air_cooler", "external_air_duct"] or bool(obj.get("rotate_with_platform", false)):
			if obj.has("facing_dir"):
				obj["facing_dir"] = _rotate_facing(str(obj.get("facing_dir", "up")), clockwise)
	var filter := str(platform.get("power_network_id", ""))
	apply_cooling_application(filter)
	execute_power_source_recovery_apply(filter)
	return {"success": true, "reason": "ok", "rotation_direction": platform["rotation_direction"], "controller_id": controller_id}

func execute_platform_action(platform_id: String, action: String = "", controller_id: String = "") -> Dictionary:
	var availability := get_platform_action_availability(platform_id, action)
	if not bool(availability.get("available", false)):
		return {"success": false, "platform_id": platform_id, "action": action, "reason": str((availability.get("reasons", ["blocked"]) as Array)[0]), "availability": availability}
	var normalized := action.strip_edges().to_lower()
	if normalized in ["", "activate", "toggle"]:
		var r := activate_platform_by_id(platform_id, controller_id)
		r["reason"] = "ok" if bool(r.get("success", false)) else "invalid_action"
		return r
	if normalized == "raise": return apply_lifting_platform_height_change(platform_id, 1, controller_id)
	if normalized == "lower": return apply_lifting_platform_height_change(platform_id, -1, controller_id)
	if normalized == "rotate_clockwise": return apply_rotating_platform_rotation(platform_id, true, controller_id)
	if normalized == "rotate_counterclockwise": return apply_rotating_platform_rotation(platform_id, false, controller_id)
	return {"success": false, "platform_id": platform_id, "action": action, "reason": "invalid_action"}

func _is_active_bipob_on_platform(platform: Dictionary) -> bool:
	if active_bipob_ref == null:
		return false
	if not active_bipob_ref.has_method("get_grid_position"):
		return false
	var actor_cell: Variant = active_bipob_ref.call("get_grid_position")
	if typeof(actor_cell) != TYPE_VECTOR2I:
		return false
	for platform_cell_variant in Array(platform.get("platform_cells", [])):
		var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
		if platform_cell == actor_cell:
			return true
	return false

func _execute_platform_action(platform: Dictionary, source: String = "") -> Dictionary:
	var platform_id := str(platform.get("platform_id", platform.get("id", "")))
	var platform_type := str(platform.get("platform_type", ""))
	var activation_mode := str(platform.get("activation_mode", "instant"))
	var normalized_source := source
	var result := {
		"success": false,
		"message": "",
		"platform_id": platform_id,
		"platform_type": platform_type,
		"activation_mode": activation_mode,
		"source": normalized_source,
		"height_level": -1,
		"rotation_direction": ""
	}
	if platform_type == "rotating":
		var rotation_direction := str(platform.get("rotation_direction", "clockwise"))
		result["rotation_direction"] = rotation_direction
		var occupants := get_platform_occupants(str(platform.get("platform_id", "")))
		for obj in Array(occupants.get("world_objects", [])):
			if obj.has("facing_dir"):
				obj["facing_dir"] = _rotate_facing(str(obj.get("facing_dir", "up")), rotation_direction != "counterclockwise")
		if _is_active_bipob_on_platform(platform) and active_bipob_ref.has_method("set_direction"):
			var current_direction := "up"
			if active_bipob_ref.has_method("get_direction"):
				current_direction = str(active_bipob_ref.get_direction())
			active_bipob_ref.set_direction(_rotate_facing(current_direction, rotation_direction != "counterclockwise"))
		refresh_world_cooling_received()
		result["success"] = true
		var affected_count := Array(occupants.get("world_objects", [])).size() + Array(occupants.get("items", [])).size() + Array(occupants.get("bipobs", [])).size()
		if affected_count > 0:
			result["message"] = "Platform %s rotated %s; occupants affected: %d." % [platform_id, rotation_direction, affected_count]
		else:
			result["message"] = "Platform %s rotated %s." % [platform_id, rotation_direction]
		platform["last_activation_source"] = normalized_source
		platform["last_activation_message"] = str(result.get("message", ""))
		return result
	if platform_type == "lifting":
		var min_h := int(platform.get("min_height_level", 0))
		var max_h := int(platform.get("max_height_level", 1))
		var previous_height := int(platform.get("height_level", min_h))
		platform["height_level"] = max_h if previous_height <= min_h else min_h
		var current_height := int(platform.get("height_level", min_h))
		result["height_level"] = current_height
		var occupants := get_platform_occupants(str(platform.get("platform_id", "")))
		for obj in Array(occupants.get("world_objects", [])):
			refresh_world_object_platform_height_state(obj)
		if active_bipob_ref != null and active_bipob_ref.has_method("set_platform_height_level") and active_bipob_ref.has_method("get_grid_position"):
			var actor_cell: Vector2i = active_bipob_ref.call("get_grid_position")
			for platform_cell_variant in Array(platform.get("platform_cells", [])):
				var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1))
				if platform_cell == actor_cell:
					active_bipob_ref.call("set_platform_height_level", int(platform.get("height_level", 0)), str(platform.get("platform_id", "")))
					break
		result["success"] = true
		if current_height > previous_height:
			result["message"] = "Platform %s lifted to height %d." % [platform_id, current_height]
		elif current_height < previous_height:
			result["message"] = "Platform %s lowered to height %d." % [platform_id, current_height]
		else:
			result["message"] = "Platform %s stayed at height %d." % [platform_id, current_height]
		platform["last_activation_source"] = normalized_source
		platform["last_activation_message"] = str(result.get("message", ""))
		return result
	result["message"] = "Unknown platform type."
	return result

func _rotate_facing(facing: String, clockwise: bool) -> String:
	var dirs := ["up", "right", "down", "left"]
	var idx := dirs.find(facing)
	if idx == -1:
		idx = 0
	idx = posmod(idx + (1 if clockwise else -1), 4)
	return dirs[idx]

func _facing_to_vector(facing_dir: String) -> Vector2i:
	match facing_dir:
		"up":
			return Vector2i(0, -1)
		"down":
			return Vector2i(0, 1)
		"left":
			return Vector2i(-1, 0)
		"right":
			return Vector2i(1, 0)
	return Vector2i.ZERO

func process_platform_turn_tick() -> Array[String]:
	var events: Array[String] = []
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	if platforms.is_empty():
		return events
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s|%s" % [str(a.get("platform_id", "")), str(a.get("id", ""))]
		var b_key := "%s|%s" % [str(b.get("platform_id", "")), str(b.get("id", ""))]
		return a_key < b_key
	)
	for platform in platforms:
		var mode := str(platform.get("activation_mode", "instant"))
		if mode == "timer":
			if not bool(platform.get("pending_activation", false)):
				continue
			var timer_turns := int(platform.get("timer_turns", 0))
			var timer_remaining := int(platform.get("timer_remaining_turns", 0))
			if timer_turns <= 0 and timer_remaining <= 0:
				platform["pending_activation"] = false
				continue
			var next_timer := maxi(0, int(platform.get("timer_remaining_turns", 0)) - 1)
			platform["timer_remaining_turns"] = next_timer
			if next_timer == 0:
				platform["pending_activation"] = false
				var result := _execute_platform_action(platform, "timer")
				if bool(result.get("success", false)):
					var result_message := str(result.get("message", "")).strip_edges()
					if not result_message.is_empty():
						events.append(result_message)
					else:
						events.append("%s activated (timer)." % str(platform.get("display_name", platform.get("platform_id", platform.get("id", "Platform")))))
		elif mode == "periodic":
			if not bool(platform.get("periodic_active", false)):
				continue
			var period_turns := int(platform.get("period_turns", 0))
			if period_turns <= 0:
				continue
			var next_periodic_timer := maxi(0, int(platform.get("timer_remaining_turns", 0)) - 1)
			platform["timer_remaining_turns"] = next_periodic_timer
			if next_periodic_timer == 0:
				var periodic_result := _execute_platform_action(platform, "periodic")
				platform["timer_remaining_turns"] = maxi(1, period_turns)
				if bool(periodic_result.get("success", false)):
					var periodic_message := str(periodic_result.get("message", "")).strip_edges()
					if not periodic_message.is_empty():
						events.append(periodic_message)
					else:
						events.append("%s activated (periodic)." % str(platform.get("display_name", platform.get("platform_id", platform.get("id", "Platform")))))
	return events

func process_platform_turn_tick_once(action_index: int) -> Array[String]:
	if action_index == platform_last_tick_action_index:
		return []
	platform_last_tick_action_index = action_index
	return process_platform_turn_tick()

func get_platform_last_tick_action_index() -> int:
	return platform_last_tick_action_index

func get_platform_timer_debug_summary_text() -> String:
	var lines: Array[String] = []
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) != "platform":
			continue
		lines.append("%s mode=%s pending=%s periodic=%s remaining=%d" % [str(object_data.get("platform_id", object_data.get("id", ""))), str(object_data.get("activation_mode", "instant")), str(bool(object_data.get("pending_activation", false))), str(bool(object_data.get("periodic_active", false))), int(object_data.get("timer_remaining_turns", 0))])
	return "\n".join(lines) if not lines.is_empty() else "No platforms."

func get_platform_state_summary(platform: Dictionary) -> String:
	var platform_id := str(platform.get("platform_id", platform.get("id", ""))).strip_edges()
	if platform_id.is_empty():
		platform_id = "-"
	var platform_type := str(platform.get("platform_type", "")).strip_edges()
	if platform_type.is_empty():
		platform_type = "-"
	var activation_mode := str(platform.get("activation_mode", "instant")).strip_edges()
	if activation_mode.is_empty():
		activation_mode = "instant"
	var state := str(platform.get("state", "active")).strip_edges()
	if state.is_empty():
		state = "active"
	var powered_text := str(bool(platform.get("is_powered", true))).to_lower()
	var details: Array[String] = []
	if platform_type == "lifting":
		details.append("height=%d" % int(platform.get("height_level", 0)))
	elif platform_type == "rotating":
		var rotation_direction := str(platform.get("rotation_direction", "")).strip_edges()
		if rotation_direction.is_empty():
			rotation_direction = "-"
		details.append("rotation=%s" % rotation_direction)
	if activation_mode == "timer":
		details.append("timer=%d/%d" % [int(platform.get("timer_remaining_turns", 0)), int(platform.get("timer_turns", 0))])
	elif activation_mode == "periodic":
		details.append("timer=%d/%d" % [int(platform.get("timer_remaining_turns", 0)), int(platform.get("period_turns", 0))])
	details.append("pending=%s" % str(bool(platform.get("pending_activation", false))).to_lower())
	details.append("periodic=%s" % str(bool(platform.get("periodic_active", false))).to_lower())
	var control_type := str(platform.get("control_type", "internal")).strip_edges()
	if control_type.is_empty():
		control_type = "internal"
	details.append("control=%s" % control_type)
	var terminal_id := str(platform.get("linked_terminal_id", "")).strip_edges()
	if terminal_id.is_empty():
		terminal_id = "-"
	details.append("terminal=%s" % terminal_id)
	var last_source := str(platform.get("last_activation_source", "")).strip_edges()
	var last_message := str(platform.get("last_activation_message", "")).strip_edges()
	var last_text := "-"
	if not last_source.is_empty() and not last_message.is_empty():
		last_text = "%s:%s" % [last_source, last_message]
	elif not last_message.is_empty():
		last_text = last_message
	elif not last_source.is_empty():
		last_text = last_source
	details.append("last=%s" % last_text)
	return "Platform %s | %s | mode=%s | state=%s | powered=%s | %s" % [
		platform_id,
		platform_type,
		activation_mode,
		state,
		powered_text,
		" | ".join(details)
	]

func get_platform_state_summary_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id := str(a.get("platform_id", a.get("id", ""))).strip_edges()
		var b_id := str(b.get("platform_id", b.get("id", ""))).strip_edges()
		if a_id == b_id:
			return str(a.get("id", "")) < str(b.get("id", ""))
		return a_id < b_id
	)
	var lines: Array[String] = ["PlatformStateSummary:"]
	for platform in platforms:
		var summary := get_platform_state_summary(platform)
		if not filter_text.is_empty() and summary.to_lower().find(filter_text) == -1:
			continue
		lines.append(summary)
	if lines.size() == 1:
		if filter_text.is_empty():
			lines.append("none")
		else:
			lines.append("none (filter=%s)" % filter_text)
	return "\n".join(lines)

func get_platform_occupant_summary(platform: Dictionary) -> String:
	var platform_id := str(platform.get("platform_id", platform.get("id", ""))).strip_edges()
	if platform_id.is_empty():
		platform_id = "-"
	var cells_count := Array(platform.get("platform_cells", [])).size()
	var occupants: Dictionary
	if platform_id != "-":
		occupants = get_platform_occupants(platform_id)
	else:
		occupants = {"world_objects": [], "items": [], "bipobs": []}
	var world_objects: Array = Array(occupants.get("world_objects", []))
	var items_count := Array(occupants.get("items", [])).size()
	var bipobs_count := Array(occupants.get("bipobs", [])).size()
	var is_lifting_platform := str(platform.get("platform_type", "")) == "lifting"
	var carried_world_objects := 0
	var stale_world_objects := 0
	for object_data_variant in world_objects:
		if typeof(object_data_variant) != TYPE_DICTIONARY:
			continue
		var object_data: Dictionary = object_data_variant
		var carried_id := str(object_data.get("carried_by_platform_id", "")).strip_edges()
		if carried_id == platform_id:
			carried_world_objects += 1
		elif is_lifting_platform:
			stale_world_objects += 1
	if not is_lifting_platform:
		stale_world_objects = 0
	var carry_required := str(is_lifting_platform).to_lower()
	var active_bipob_on_platform := str(_is_active_bipob_on_platform(platform)).to_lower()
	return "Occupants %s | cells=%d | world_objects=%d | items=%d | bipobs=%d | carry_required=%s | carried_world_objects=%d | stale_world_objects=%d | active_bipop_on_platform=%s" % [
		platform_id,
		cells_count,
		world_objects.size(),
		items_count,
		bipobs_count,
		carry_required,
		carried_world_objects,
		stale_world_objects,
		active_bipob_on_platform
	]

func get_platform_occupant_summary_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id := str(a.get("platform_id", a.get("id", ""))).strip_edges()
		var b_id := str(b.get("platform_id", b.get("id", ""))).strip_edges()
		if a_id == b_id:
			return str(a.get("id", "")) < str(b.get("id", ""))
		return a_id < b_id
	)
	var lines: Array[String] = ["PlatformOccupantSummary:"]
	for platform in platforms:
		var summary := get_platform_occupant_summary(platform)
		if not filter_text.is_empty() and summary.to_lower().find(filter_text) == -1:
			continue
		lines.append(summary)
	if lines.size() == 1:
		lines.append("none" if filter_text.is_empty() else "none (filter=%s)" % filter_text)
	return "\n".join(lines)

func validate_platform_runtime_state() -> Dictionary:
	var warnings: Array[String] = []
	var errors: Array[String] = []
	var platforms: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	var platform_cell_owner := {}
	var platform_ids := {}
	var terminal_targets_count := {}
	for object_data in mission_world_objects:
		var group := str(object_data.get("object_group", ""))
		if group == "platform":
			platforms.append(object_data)
			continue
		if str(object_data.get("object_group", "")) == "terminal" and str(object_data.get("controlled_target_type", "")) == "platform":
			terminals.append(object_data)
	for platform in platforms:
		var object_id := str(platform.get("id", ""))
		var platform_id := str(platform.get("platform_id", "")).strip_edges()
		if platform_id.is_empty():
			errors.append("Platform %s has empty platform_id." % object_id)
		else:
			platform_ids[platform_id] = true
		var platform_type := str(platform.get("platform_type", ""))
		if not platform_type in ["rotating", "lifting"]:
			errors.append("Platform %s has invalid platform_type %s." % [platform_id if not platform_id.is_empty() else object_id, platform_type])
		var raw_cells: Array = platform.get("platform_cells", [])
		if raw_cells.is_empty():
			errors.append("Platform %s has empty platform_cells." % (platform_id if not platform_id.is_empty() else object_id))
		var local_cells := {}
		for cell_variant in raw_cells:
			var world_cell := WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
			if world_cell.x < 0 or world_cell.y < 0:
				errors.append("Platform %s has invalid cell %s." % [platform_id if not platform_id.is_empty() else object_id, str(world_cell)])
				continue
			if local_cells.has(world_cell):
				errors.append("Platform %s has duplicate cell %s." % [platform_id if not platform_id.is_empty() else object_id, str(world_cell)])
				continue
			local_cells[world_cell] = true
			if platform_cell_owner.has(world_cell):
				errors.append("Cell %s is claimed by multiple platforms (%s and %s)." % [str(world_cell), str(platform_cell_owner[world_cell]), platform_id])
			else:
				platform_cell_owner[world_cell] = platform_id
		var control_type := str(platform.get("control_type", ""))
		if not control_type in ["internal", "external"]:
			errors.append("Platform %s has invalid control_type %s." % [platform_id, control_type])
		var power_type := str(platform.get("power_type", ""))
		if not power_type in ["internal", "external"]:
			errors.append("Platform %s has invalid power_type %s." % [platform_id, power_type])
		if control_type == "internal":
			var local_switch := WorldObjectCatalogRef.to_world_cell(platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
			if local_switch.x < 0 or local_switch.y < 0:
				errors.append("Platform %s has invalid local_switch_cell %s." % [platform_id, str(local_switch)])
		if platform_type == "rotating":
			var rotation_direction := str(platform.get("rotation_direction", ""))
			if not rotation_direction in ["clockwise", "counterclockwise"]:
				errors.append("Platform %s has invalid rotation_direction %s." % [platform_id, rotation_direction])
			if not platform.has("rotation_direction"):
				warnings.append("Platform %s (rotating) is missing rotation_direction." % platform_id)
		if platform_type == "lifting":
			var min_h := int(platform.get("min_height_level", 0))
			var max_h := int(platform.get("max_height_level", 0))
			if typeof(platform.get("height_level", 0)) != TYPE_INT:
				errors.append("Platform %s has non-int height_level." % platform_id)
			var height := int(platform.get("height_level", 0))
			if min_h > height or height > max_h:
				errors.append("Platform %s has invalid height range min=%d height=%d max=%d." % [platform_id, min_h, height, max_h])
			if not platform.has("height_level"):
				warnings.append("Platform %s (lifting) is missing height_level." % platform_id)
		for timer_key in ["timer_turns", "timer_remaining_turns", "period_turns"]:
			if int(platform.get(timer_key, 0)) < 0:
				errors.append("Platform %s has negative %s." % [platform_id, timer_key])
		var activation_mode := str(platform.get("activation_mode", "instant"))
		if activation_mode == "timer":
			if int(platform.get("timer_turns", 0)) <= 0:
				warnings.append("Platform %s uses timer mode with timer_turns <= 0." % platform_id)
			if bool(platform.get("pending_activation", false)) and int(platform.get("timer_remaining_turns", 0)) <= 0:
				warnings.append("Platform %s has pending timer activation with timer_remaining_turns <= 0." % platform_id)
		if activation_mode == "periodic":
			if int(platform.get("period_turns", 0)) <= 0:
				warnings.append("Platform %s uses periodic mode with period_turns <= 0." % platform_id)
			if bool(platform.get("periodic_active", false)) and int(platform.get("timer_remaining_turns", 0)) <= 0 and int(platform.get("period_turns", 0)) > 0:
				warnings.append("Platform %s has periodic_active with timer_remaining_turns <= 0." % platform_id)
		var last_source := str(platform.get("last_activation_source", ""))
		if not last_source in ["", "timer", "periodic", "terminal", "local_switch", "debug", "direct"]:
			warnings.append("Platform %s has unexpected last_activation_source %s." % [platform_id, last_source])
		if platform.has("last_activation_message") and typeof(platform.get("last_activation_message", "")) != TYPE_STRING:
			warnings.append("Platform %s has non-string last_activation_message." % platform_id)
		var has_pending_activation := bool(platform.get("pending_activation", false))
		if has_pending_activation and not activation_mode in ["timer", "permanent"]:
			warnings.append("Platform %s has pending_activation outside timer/permanent mode." % platform_id)
		var has_periodic_active := bool(platform.get("periodic_active", false))
		if has_periodic_active and activation_mode != "periodic":
			warnings.append("Platform %s has periodic_active outside periodic mode." % platform_id)
		if bool(platform.get("requires_terminal_enabled", false)):
			var linked_terminal_id := str(platform.get("linked_terminal_id", "")).strip_edges()
			if linked_terminal_id.is_empty():
				errors.append("Platform %s requires terminal but linked_terminal_id is empty." % platform_id)
			else:
				var linked_terminal := get_world_object_by_id(linked_terminal_id)
				if linked_terminal.is_empty():
					errors.append("Platform %s linked terminal %s is missing." % [platform_id, linked_terminal_id])
				else:
					if str(linked_terminal.get("controlled_target_type", "")) != "platform":
						errors.append("Platform %s linked terminal %s has invalid terminal_type." % [platform_id, linked_terminal_id])
					if str(linked_terminal.get("target_platform_id", "")) != platform_id:
						errors.append("Platform %s linked terminal %s targets %s." % [platform_id, linked_terminal_id, str(linked_terminal.get("target_platform_id", ""))])
	for terminal in terminals:
		var terminal_id := str(terminal.get("id", ""))
		var target_platform_id := str(terminal.get("target_platform_id", "")).strip_edges()
		if target_platform_id.is_empty():
			errors.append("Platform terminal %s has empty target_platform_id." % terminal_id)
			continue
		terminal_targets_count[target_platform_id] = int(terminal_targets_count.get(target_platform_id, 0)) + 1
		if get_platform_by_id(target_platform_id).is_empty():
			errors.append("Platform terminal %s targets missing platform %s." % [terminal_id, target_platform_id])
	for target_id in terminal_targets_count.keys():
		var count := int(terminal_targets_count[target_id])
		if count > 1:
			warnings.append("Multiple terminals (%d) target platform %s." % [count, str(target_id)])
	for object_data in mission_world_objects:
		var object_id := str(object_data.get("id", ""))
		var carried_platform_id := str(object_data.get("carried_by_platform_id", "")).strip_edges()
		if carried_platform_id.is_empty():
			var object_cell := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			var object_platform := get_platform_for_cell(object_cell)
			if not object_platform.is_empty() and str(object_platform.get("platform_type", "")) == "lifting":
				var expected_platform_id := str(object_platform.get("platform_id", "")).strip_edges()
				warnings.append("Object %s stands on lifting platform %s but carried_by_platform_id is missing." % [object_id, expected_platform_id])
			continue
		if not platform_ids.has(carried_platform_id):
			warnings.append("Object %s references missing carried_by_platform_id %s." % [object_id, carried_platform_id])
			continue
		var object_cell_with_carried := WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
		var current_platform := get_platform_for_cell(object_cell_with_carried)
		if current_platform.is_empty():
			warnings.append("Object %s references carried_by_platform_id %s but is not on a platform cell." % [object_id, carried_platform_id])
			continue
		var current_platform_id := str(current_platform.get("platform_id", "")).strip_edges()
		var current_platform_type := str(current_platform.get("platform_type", ""))
		if current_platform_type != "lifting":
			warnings.append("Object %s references carried_by_platform_id %s but stands on non-lifting platform %s." % [object_id, carried_platform_id, current_platform_id])
			continue
		if current_platform_id != carried_platform_id:
			warnings.append("Object %s references carried_by_platform_id %s but stands on lifting platform %s." % [object_id, carried_platform_id, current_platform_id])
		if object_data.has("platform_height_level"):
			var carried_platform := get_platform_by_id(carried_platform_id)
			if not carried_platform.is_empty():
				var platform_height := int(carried_platform.get("height_level", 0))
				var object_height := int(object_data.get("platform_height_level", 0))
				if object_height != platform_height:
					warnings.append("Object %s platform_height_level %d differs from platform %s height %d." % [object_id, object_height, carried_platform_id, platform_height])
	for platform in platforms:
		var platform_id := str(platform.get("platform_id", "")).strip_edges()
		if platform_id.is_empty():
			continue
		var occupants := get_platform_occupants(platform_id)
		var platform_cells: Array = []
		for cell_variant in Array(platform.get("platform_cells", [])):
			var platform_cell := WorldObjectCatalogRef.to_world_cell(cell_variant, Vector2i(-1, -1))
			if platform_cell.x >= 0 and platform_cell.y >= 0:
				platform_cells.append(platform_cell)
		var is_lifting_platform := str(platform.get("platform_type", "")) == "lifting"
		var platform_height := int(platform.get("height_level", 0))
		for world_object_variant in Array(occupants.get("world_objects", [])):
			if typeof(world_object_variant) != TYPE_DICTIONARY:
				continue
			var world_object: Dictionary = world_object_variant
			var world_object_id := str(world_object.get("id", ""))
			var world_object_carried_id := str(world_object.get("carried_by_platform_id", "")).strip_edges()
			if is_lifting_platform and world_object_carried_id != platform_id:
				warnings.append("World object %s is on lifting platform %s but carried_by_platform_id is stale." % [world_object_id, platform_id])
			if is_lifting_platform and int(world_object.get("platform_height_level", 0)) != platform_height:
				warnings.append("World object %s has platform_height_level mismatch on lifting platform %s." % [world_object_id, platform_id])
		for world_object in mission_world_objects:
			if str(world_object.get("carried_by_platform_id", "")).strip_edges() != platform_id:
				continue
			var object_cell := WorldObjectCatalogRef.to_world_cell(world_object.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
			if not platform_cells.has(object_cell):
				warnings.append("World object %s is carried by platform %s but is not on its cells." % [str(world_object.get("id", "")), platform_id])
		if active_bipob_ref != null and active_bipob_ref.has_method("get_grid_position"):
			var active_cell_variant: Variant = active_bipob_ref.call("get_grid_position")
			if typeof(active_cell_variant) == TYPE_VECTOR2I:
				var active_cell: Vector2i = active_cell_variant
				var active_on_platform := platform_cells.has(active_cell)
				var has_bipob_carried_getter := active_bipob_ref.has_method("get_carried_by_platform_id")
				var has_bipob_height_getter := active_bipob_ref.has_method("get_platform_height_level")
				var bipob_carried_id := ""
				if has_bipob_carried_getter:
					bipob_carried_id = str(active_bipob_ref.call("get_carried_by_platform_id")).strip_edges()
				if is_lifting_platform and active_on_platform and has_bipob_carried_getter and bipob_carried_id != platform_id:
					warnings.append("Active Bipop is on lifting platform %s but carried_by_platform_id is stale." % platform_id)
				if has_bipob_carried_getter and bipob_carried_id == platform_id and not active_on_platform:
					warnings.append("Active Bipop is carried by platform %s but is not on its cells." % platform_id)
				if is_lifting_platform and active_on_platform and has_bipob_height_getter:
					var bipob_height := int(active_bipob_ref.call("get_platform_height_level"))
					if bipob_height != platform_height:
						warnings.append("Active Bipop platform_height_level mismatch on lifting platform %s." % platform_id)
	return {
		"valid": errors.is_empty(),
		"platforms": platforms.size(),
		"terminals": terminals.size(),
		"warnings": warnings,
		"errors": errors
	}

func get_platform_runtime_validation_text() -> String:
	var validation := validate_platform_runtime_state()
	var warnings: Array[String] = validation.get("warnings", [])
	var errors: Array[String] = validation.get("errors", [])
	var lines: Array[String] = []
	lines.append("PlatformRuntimeValidation: valid=%s | platforms=%d | terminals=%d | errors=%d | warnings=%d" % [
		str(bool(validation.get("valid", false))).to_lower(),
		int(validation.get("platforms", 0)),
		int(validation.get("terminals", 0)),
		errors.size(),
		warnings.size()
	])
	for error in errors:
		lines.append("ERROR: %s" % error)
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)

func get_platform_runtime_table_text(filter: String = "") -> String:
	var filter_text := filter.strip_edges().to_lower()
	var platforms: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) == "platform":
			platforms.append(object_data)
		elif str(object_data.get("object_group", "")) == "terminal" and str(object_data.get("controlled_target_type", "")) == "platform":
			terminals.append(object_data)
	platforms.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s|%s" % [str(a.get("platform_id", "")), str(a.get("id", ""))]
		var b_key := "%s|%s" % [str(b.get("platform_id", "")), str(b.get("id", ""))]
		return a_key < b_key
	)
	terminals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	var lines: Array[String] = []
	lines.append("Platforms:")
	for platform in platforms:
		var platform_id := str(platform.get("platform_id", platform.get("id", "")))
		var terminal_id := str(platform.get("linked_terminal_id", "none"))
		if terminal_id.strip_edges().is_empty():
			terminal_id = "none"
		var occupants := get_platform_occupants(platform_id)
		var occ_obj := Array(occupants.get("world_objects", [])).size()
		var occ_item := Array(occupants.get("items", [])).size()
		var occ_bipob := Array(occupants.get("bipobs", [])).size()
		var mode := str(platform.get("activation_mode", "instant"))
		var timer_remaining := int(platform.get("timer_remaining_turns", 0))
		var height := "-"
		if str(platform.get("platform_type", "")) == "lifting":
			height = str(int(platform.get("height_level", 0)))
		var last_source := str(platform.get("last_activation_source", "")).strip_edges()
		var last_message := str(platform.get("last_activation_message", "")).strip_edges()
		var last_fragment := "last=-"
		if not last_source.is_empty() or not last_message.is_empty():
			last_fragment = "last=%s:%s" % [last_source if not last_source.is_empty() else "-", last_message if not last_message.is_empty() else "-"]
		var line := "%s | %s | cells=%d | %s | powered=%s | %s/%s | terminal=%s | %s | pending=%s | periodic=%s | timer_turns=%d | period_turns=%d | timer=%d | height=%s | occupants obj=%d item=%d bipob=%d" % [
			platform_id,
			str(platform.get("platform_type", "")),
			Array(platform.get("platform_cells", [])).size(),
			str(platform.get("state", "active")),
			str(bool(platform.get("is_powered", true))).to_lower(),
			str(platform.get("power_type", "internal")),
			str(platform.get("control_type", "internal")),
			terminal_id,
			mode,
			str(bool(platform.get("pending_activation", false))).to_lower(),
			str(bool(platform.get("periodic_active", false))).to_lower(),
			int(platform.get("timer_turns", 0)),
			int(platform.get("period_turns", 0)),
			timer_remaining,
			height,
			occ_obj,
			occ_item,
			occ_bipob
		]
		line = "%s | %s" % [line, last_fragment]
		var haystack := "%s %s %s %s %s" % [platform_id, str(platform.get("id", "")), str(platform.get("platform_type", "")), str(platform.get("state", "")), terminal_id]
		if filter_text.is_empty() or haystack.to_lower().find(filter_text) != -1:
			lines.append(line)
	lines.append("Terminals:")
	for terminal in terminals:
		var line := "%s | target=%s | %s | powered=%s | enabled=%s | remote=%s | interface=%s" % [
			str(terminal.get("id", "")),
			str(terminal.get("target_platform_id", "")),
			str(terminal.get("state", "active")),
			str(bool(terminal.get("is_powered", true))).to_lower(),
			str(bool(terminal.get("platform_control_enabled", true))).to_lower(),
			str(bool(terminal.get("platform_remote_control", true))).to_lower(),
			str(terminal.get("terminal_interface", "standard"))
		]
		var haystack := "%s %s %s" % [str(terminal.get("id", "")), str(terminal.get("target_platform_id", "")), str(terminal.get("state", ""))]
		if filter_text.is_empty() or haystack.to_lower().find(filter_text) != -1:
			lines.append(line)
	return "\n".join(lines)

func seed_platform_debug_scenario(origin: Vector2i = Vector2i(10, 2)) -> void:
	_place_debug_world_object("rotating_platform", "rotating_platform_debug", origin, {"platform_id":"platform_rot_a","platform_cells":[[origin.x, origin.y],[origin.x+1, origin.y]],"control_type":"external","linked_terminal_id":"platform_terminal_debug","requires_terminal_enabled":true})
	_place_debug_world_object("lifting_platform", "lifting_platform_debug", origin + Vector2i(0, 3), {"platform_id":"platform_lift_a","platform_cells":[[origin.x, origin.y+3]],"control_type":"internal","local_switch_cell":[origin.x-1, origin.y+3],"height_level":0,"min_height_level":0,"max_height_level":1})
	_place_debug_world_object("terminal", "platform_terminal_debug", origin + Vector2i(-2, 0), {"terminal_type":"control","controlled_target_type":"platform","linked_platform_ids":["platform_rot_a"],"target_platform_id":"platform_rot_a","platform_control_enabled":true})
	_place_debug_world_object("external_air_cooler", "platform_air_cooler_debug", origin, {"facing_dir":"right"})

func _snapshot_platform_debug_fields(object_data: Dictionary, fields: Array[String]) -> Dictionary:
	var snapshot := {}
	for field in fields:
		var had_field := object_data.has(field)
		var value = null
		if had_field:
			value = object_data[field]
			if value is Dictionary or value is Array:
				value = value.duplicate(true)
		snapshot[field] = {"had_field": had_field, "value": value}
	return snapshot

func _restore_platform_debug_fields(object_data: Dictionary, snapshot: Dictionary) -> void:
	for field in snapshot.keys():
		var field_state: Dictionary = snapshot[field]
		if bool(field_state.get("had_field", false)):
			var restored_value = field_state.get("value")
			if restored_value is Dictionary or restored_value is Array:
				restored_value = restored_value.duplicate(true)
			object_data[field] = restored_value
		else:
			object_data.erase(field)

func _find_debug_floor_cell_near_platform(platform_cells: Array, origin_cell: Vector2i) -> Vector2i:
	var platform_world_cells: Array[Vector2i] = []
	for cell in platform_cells:
		var world_cell := WorldObjectCatalogRef.to_world_cell(cell, Vector2i(-1, -1))
		if world_cell != Vector2i(-1, -1):
			platform_world_cells.append(world_cell)
	var candidate_offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	for offset in candidate_offsets:
		var candidate := origin_cell + offset
		if platform_world_cells.has(candidate):
			continue
		if not get_platform_for_cell(candidate).is_empty():
			continue
		if grid_manager != null and grid_manager.has_method("is_in_bounds") and not grid_manager.is_in_bounds(candidate):
			continue
		if grid_manager != null and grid_manager.has_method("is_walkable") and not grid_manager.is_walkable(candidate):
			continue
		return candidate
	return Vector2i(-1, -1)


func _build_platform_timer_tick_debug_platform(platform_id: String, mode: String, cell: Vector2i, overrides: Dictionary = {}) -> Dictionary:
	var platform: Dictionary = {
		"id": "platform_timer_tick_debug_%s" % platform_id,
		"object_group": "platform",
		"object_type": "platform_debug_helper",
		"platform_id": platform_id,
		"platform_type": "rotating",
		"platform_cells": [[cell.x, cell.y]],
		"control_type": "internal",
		"power_type": "internal",
		"state": "active",
		"is_powered": true,
		"height_level": 0,
		"min_height_level": 0,
		"max_height_level": 1,
		"rotation_direction": "clockwise",
		"permanent_state": "active",
		"activation_mode": mode,
		"timer_turns": 0,
		"period_turns": 0,
		"timer_remaining_turns": 0,
		"pending_activation": false,
		"periodic_active": false
	}
	for key in overrides.keys():
		platform[key] = overrides[key]
	return platform

func _cleanup_platform_timer_tick_debug_state(temp_platforms: Array[Dictionary], original_platform_snapshots: Dictionary, original_last_tick_action_index: int) -> void:
	for temp_platform in temp_platforms:
		mission_world_objects.erase(temp_platform)
	for object_data in original_platform_snapshots.keys():
		_restore_platform_debug_fields(object_data, original_platform_snapshots[object_data])
	platform_last_tick_action_index = original_last_tick_action_index


func validate_platform_timer_tick_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var fields_to_snapshot: Array[String] = [
		"activation_mode",
		"pending_activation",
		"periodic_active",
		"timer_turns",
		"period_turns",
		"timer_remaining_turns",
		"height_level",
		"rotation_direction",
		"permanent_state",
		"platform_last_tick_action_index"
	]
	var original_last_tick_action_index := platform_last_tick_action_index
	var original_platform_snapshots := {}
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) != "platform":
			continue
		original_platform_snapshots[object_data] = _snapshot_platform_debug_fields(object_data, fields_to_snapshot)

	var temp_platforms: Array[Dictionary] = []
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_timer", "timer", Vector2i(80, 80), {"pending_activation": true, "timer_turns": 2, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_periodic", "periodic", Vector2i(82, 80), {"periodic_active": true, "period_turns": 2, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_periodic_invalid", "periodic", Vector2i(84, 80), {"periodic_active": true, "period_turns": 0, "timer_remaining_turns": 2}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_timer_invalid", "timer", Vector2i(86, 80), {"pending_activation": true, "timer_turns": 0, "timer_remaining_turns": 0}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_instant", "instant", Vector2i(88, 80), {"height_level": 0}))
	temp_platforms.append(_build_platform_timer_tick_debug_platform("debug_timer_tick_permanent", "permanent", Vector2i(90, 80), {"pending_activation": true, "permanent_state": "active", "height_level": 0}))
	for temp_platform in temp_platforms:
		mission_world_objects.append(temp_platform)
	var temp_cells := {}
	var has_temp_overlap := false
	for temp_platform in temp_platforms:
		var platform_cells: Array = temp_platform.get("platform_cells", [])
		if platform_cells.is_empty():
			continue
		var world_cell := WorldObjectCatalogRef.to_world_cell(platform_cells[0], Vector2i(-1, -1))
		if world_cell == Vector2i(-1, -1):
			continue
		if temp_cells.has(world_cell):
			has_temp_overlap = true
			break
		temp_cells[world_cell] = true
	if has_temp_overlap:
		warnings.append("Timer tick debug platforms overlap cells.")

	var instant_platform := get_platform_by_id("debug_timer_tick_instant")
	var permanent_platform := get_platform_by_id("debug_timer_tick_permanent")
	var instant_height_before := int(instant_platform.get("height_level", 0)) if not instant_platform.is_empty() else 0
	var permanent_height_before := int(permanent_platform.get("height_level", 0)) if not permanent_platform.is_empty() else 0

	process_platform_turn_tick_once(100)
	process_platform_turn_tick_once(100)

	var timer_platform := get_platform_by_id("debug_timer_tick_timer")
	if timer_platform.is_empty():
		warnings.append("Missing timer validation platform.")
	else:
		if int(timer_platform.get("timer_remaining_turns", -1)) != 1:
			warnings.append("Timer platform ticked more than once for the same action index.")
	process_platform_turn_tick_once(101)
	if timer_platform.is_empty():
		timer_platform = get_platform_by_id("debug_timer_tick_timer")
	if timer_platform.is_empty():
		warnings.append("Timer platform missing after second tick.")
	else:
		if int(timer_platform.get("timer_remaining_turns", -1)) != 0:
			warnings.append("Timer platform did not complete after two distinct action indices.")
		if bool(timer_platform.get("pending_activation", true)):
			warnings.append("Timer platform pending_activation did not clear after activation.")

	var periodic_platform := get_platform_by_id("debug_timer_tick_periodic")
	if periodic_platform.is_empty():
		warnings.append("Missing periodic validation platform.")
	else:
		if int(periodic_platform.get("timer_remaining_turns", -1)) != 2:
			warnings.append("Periodic platform did not reactivate every two distinct action indices.")

	var periodic_invalid_platform := get_platform_by_id("debug_timer_tick_periodic_invalid")
	if periodic_invalid_platform.is_empty():
		warnings.append("Missing invalid periodic validation platform.")
	else:
		if int(periodic_invalid_platform.get("timer_remaining_turns", -1)) != 2:
			warnings.append("Periodic platform with period_turns <= 0 ticked unexpectedly.")

	var timer_invalid_platform := get_platform_by_id("debug_timer_tick_timer_invalid")
	if timer_invalid_platform.is_empty():
		warnings.append("Missing invalid timer validation platform.")
	else:
		if bool(timer_invalid_platform.get("pending_activation", true)):
			warnings.append("Timer platform with invalid turns did not clear pending_activation.")
		if int(timer_invalid_platform.get("timer_remaining_turns", -1)) != 0:
			warnings.append("Timer platform with invalid turns changed timer_remaining_turns unexpectedly.")

	if not instant_platform.is_empty() and int(instant_platform.get("height_level", 0)) != instant_height_before:
		warnings.append("Instant platform tick changed height unexpectedly.")
	if not permanent_platform.is_empty() and int(permanent_platform.get("height_level", 0)) != permanent_height_before:
		warnings.append("Permanent platform tick changed height unexpectedly.")

	_cleanup_platform_timer_tick_debug_state(temp_platforms, original_platform_snapshots, original_last_tick_action_index)
	return warnings

func get_platform_timer_tick_validation_text() -> String:
	var warnings := validate_platform_timer_tick_debug_scenario()
	var lines: Array[String] = ["PlatformTimerTickValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)
func validate_platform_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var rotating_platform := get_platform_by_id("platform_rot_a")
	if rotating_platform.is_empty(): warnings.append("Missing rotating platform.")
	var lifting_platform := get_platform_by_id("platform_lift_a")
	if lifting_platform.is_empty(): warnings.append("Missing lifting platform.")
	var terminal := get_world_object_by_id("platform_terminal_debug")
	if terminal.is_empty() or str(terminal.get("target_platform_id", "")) != "platform_rot_a": warnings.append("Platform terminal link invalid.")
	var air_cooler := get_world_object_by_id("platform_air_cooler_debug")
	if air_cooler.is_empty():
		warnings.append("Missing air cooler on rotating platform.")
	var old_requires_terminal_enabled := bool(rotating_platform.get("requires_terminal_enabled", false))
	var air_cooler_snapshot := {}
	var lifting_platform_snapshot := {}
	var terminal_snapshot := {}
	var rotating_platform_snapshot := {}
	if not air_cooler.is_empty():
		air_cooler_snapshot = _snapshot_platform_debug_fields(air_cooler, ["facing_dir"])
	if not lifting_platform.is_empty():
		lifting_platform_snapshot = _snapshot_platform_debug_fields(lifting_platform, ["height_level", "carried_by_platform_id"])
	if not terminal.is_empty():
		terminal_snapshot = _snapshot_platform_debug_fields(terminal, ["state", "is_powered", "platform_control_enabled"])
	if not rotating_platform.is_empty():
		rotating_platform_snapshot = _snapshot_platform_debug_fields(rotating_platform, ["timer_remaining_turns", "pending_activation", "periodic_active", "requires_terminal_enabled", "permanent_state", "activation_mode", "timer_turns", "period_turns", "rotation_direction"])
	if not rotating_platform.is_empty() and not air_cooler.is_empty():
		var before_facing := str(air_cooler.get("facing_dir", ""))
		var rotate_result := activate_platform_by_id("platform_rot_a", "debug_validation")
		if not bool(rotate_result.get("success", false)):
			warnings.append("Rotating platform activation failed during validation.")
		var after_facing := str(air_cooler.get("facing_dir", ""))
		if before_facing == after_facing:
			warnings.append("Rotating platform action did not rotate air cooler.")
	if not lifting_platform.is_empty():
		var before_height := int(lifting_platform.get("height_level", 0))
		var lift_result := activate_platform_by_id("platform_lift_a", "debug_validation")
		if not bool(lift_result.get("success", false)):
			warnings.append("Lifting platform activation failed during validation.")
		var after_height := int(lifting_platform.get("height_level", before_height))
		if before_height == after_height:
			warnings.append("Lifting platform action did not toggle height_level.")
		var switch_cell := WorldObjectCatalogRef.to_world_cell(lifting_platform.get("local_switch_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
		var wrong_access := can_bipob_access_platform_switch(lifting_platform, switch_cell + Vector2i(2, 0), "left")
		if wrong_access:
			warnings.append("Internal switch access returned true from wrong position.")
		var actor_cell := switch_cell - _facing_to_vector(str(lifting_platform.get("local_switch_facing_dir", "right")))
		var right_access := can_bipob_access_platform_switch(lifting_platform, actor_cell, str(lifting_platform.get("local_switch_facing_dir", "right")))
		if not right_access:
			warnings.append("Internal switch access returned false from valid position.")
	if not rotating_platform.is_empty() and not terminal.is_empty():
		rotating_platform["requires_terminal_enabled"] = true
		terminal["platform_control_enabled"] = false
		var blocked := activate_platform_by_id("platform_rot_a", "debug_validation_block")
		if bool(blocked.get("success", false)):
			warnings.append("Terminal unavailable did not block rotating platform activation.")
	if not air_cooler.is_empty():
		_restore_platform_debug_fields(air_cooler, air_cooler_snapshot)
	if not lifting_platform.is_empty():
		_restore_platform_debug_fields(lifting_platform, lifting_platform_snapshot)
	if not terminal.is_empty():
		_restore_platform_debug_fields(terminal, terminal_snapshot)
	if not rotating_platform.is_empty():
		rotating_platform["requires_terminal_enabled"] = old_requires_terminal_enabled
		_restore_platform_debug_fields(rotating_platform, rotating_platform_snapshot)
		if rotating_platform.get("requires_terminal_enabled", false) != old_requires_terminal_enabled:
			warnings.append("Validation restore mismatch: rotating platform terminal gate flag.")
	if debug_platform_scenario_enabled:
		warnings.append_array(validate_platform_height_gating_debug_scenario())
		warnings.append_array(validate_platform_timer_tick_debug_scenario())
	refresh_world_cooling_received()
	return warnings

func validate_platform_height_gating_debug_scenario() -> Array[String]:
	var warnings: Array[String] = []
	var lifting_platform := get_platform_by_id("platform_lift_a")
	if lifting_platform.is_empty():
		warnings.append("Missing lifting platform for height gating validation.")
		return warnings
	var platform_cells: Array = Array(lifting_platform.get("platform_cells", []))
	if platform_cells.is_empty():
		warnings.append("Lifting platform has no platform cells.")
		return warnings
	var platform_cell := WorldObjectCatalogRef.to_world_cell(platform_cells[0], Vector2i(-1, -1))
	if platform_cell == Vector2i(-1, -1):
		warnings.append("Lifting platform first platform cell is invalid.")
		return warnings
	var floor_cell := _find_debug_floor_cell_near_platform(platform_cells, platform_cell)
	if floor_cell == Vector2i(-1, -1):
		warnings.append("No normal floor cell found near lifting platform for height gating validation.")
		return warnings
	var same_height_platform_cell := platform_cell
	if platform_cells.size() > 1:
		same_height_platform_cell = WorldObjectCatalogRef.to_world_cell(platform_cells[1], platform_cell)
	var original_height := int(lifting_platform.get("height_level", 0))
	var platform_snapshot := _snapshot_platform_debug_fields(lifting_platform, ["height_level"])
	lifting_platform["height_level"] = original_height
	if get_cell_height_level(platform_cell) != original_height:
		warnings.append("Platform cell height does not match platform.height_level.")
	if get_cell_height_level(floor_cell) != 0:
		warnings.append("Normal floor cell did not resolve to height 0.")
	lifting_platform["height_level"] = 1
	if can_move_between_height_levels(platform_cell, floor_cell, null):
		warnings.append("Height gating failed: platform->floor movement allowed on mismatch (1->0).")
	if can_move_between_height_levels(floor_cell, platform_cell, null):
		warnings.append("Height gating failed: floor->platform movement allowed on mismatch (0->1).")
	if not can_move_between_height_levels(platform_cell, same_height_platform_cell, null):
		warnings.append("Height gating failed: movement between same-height platform cells blocked.")
	var candidate_object: Dictionary = {}
	for object_data in mission_world_objects:
		if str(object_data.get("object_group", "")) == "platform":
			continue
		if str(object_data.get("object_group", "")) == "item":
			continue
		candidate_object = object_data
		break
	if candidate_object.is_empty():
		warnings.append("No world object available for platform height validation.")
		_restore_platform_debug_fields(lifting_platform, platform_snapshot)
		return warnings
	var object_snapshot := _snapshot_platform_debug_fields(candidate_object, ["position", "platform_height_level", "carried_by_platform_id"])
	candidate_object["position"] = platform_cell
	refresh_world_object_platform_height_state(candidate_object)
	var carried_platform_id := str(candidate_object.get("carried_by_platform_id", "")).strip_edges()
	if carried_platform_id != str(lifting_platform.get("platform_id", "")).strip_edges():
		warnings.append("Object on lifting platform did not receive matching carried_by_platform_id.")
	if int(candidate_object.get("platform_height_level", -1)) != int(lifting_platform.get("height_level", -1)):
		warnings.append("Object platform height on lifting platform does not match platform height.")
	candidate_object["position"] = floor_cell
	refresh_world_object_platform_height_state(candidate_object)
	if str(candidate_object.get("carried_by_platform_id", "")).strip_edges() != "":
		warnings.append("Object moved off lifting platform kept carried_by_platform_id.")
	candidate_object["position"] = platform_cell
	refresh_world_object_platform_height_state(candidate_object)
	if str(candidate_object.get("carried_by_platform_id", "")).strip_edges() != str(lifting_platform.get("platform_id", "")).strip_edges():
		warnings.append("Object moved onto lifting platform did not get carried_by_platform_id.")
	_restore_platform_debug_fields(candidate_object, object_snapshot)
	_restore_platform_debug_fields(lifting_platform, platform_snapshot)
	return warnings

func get_platform_height_gating_validation_text() -> String:
	var warnings := validate_platform_height_gating_debug_scenario()
	var lines: Array[String] = ["PlatformHeightGatingValidation: warnings=%d" % warnings.size()]
	for warning in warnings:
		lines.append("WARNING: %s" % warning)
	return "\n".join(lines)

func get_terminal_hack_requirements(terminal_id: String) -> Dictionary:
	var terminal := get_world_object_by_id(terminal_id)
	var required_connector_level := int(terminal.get("required_connector_level", max(0, int(terminal.get("terminal_class", 1)) - 1))) if not terminal.is_empty() else 0
	var required_processor_level := int(terminal.get("required_processor_level", max(0, int(terminal.get("terminal_class", 1)) - 1))) if not terminal.is_empty() else 0
	var capabilities := get_actor_capability_levels()
	var available_connector_level := int(capabilities.get("connector_level", 0))
	var available_processor_level := int(capabilities.get("processor_level", 0))
	var reasons: Array[String] = []
	if terminal.is_empty():
		reasons.append("terminal_missing")
	else:
		if not _is_terminal_powered_for_interaction(terminal):
			reasons.append("terminal_unpowered")
		if bool(terminal.get("damaged", false)) or str(terminal.get("state", "")).to_lower() == "damaged":
			reasons.append("terminal_damaged")
	if available_connector_level < required_connector_level:
		reasons.append("connector_level_too_low")
	if available_processor_level < required_processor_level:
		reasons.append("processor_level_too_low")
	var heat_preview := {"would_overheat": false, "current_heat": 0, "hack_heat": 0, "overheat_threshold": 0, "projected_heat": 0}
	if not terminal.is_empty():
		var current_heat := int(terminal.get("current_heat", terminal.get("working_heat", 0)))
		var hack_heat := int(terminal.get("hack_heat", 0))
		var threshold := int(terminal.get("overheat_threshold", 99999))
		var projected := current_heat + hack_heat
		heat_preview = {"would_overheat": projected > threshold, "current_heat": current_heat, "hack_heat": hack_heat, "overheat_threshold": threshold, "projected_heat": projected}
	if bool(heat_preview.get("would_overheat", false)):
		reasons.append("hack_would_overheat")
	if reasons.is_empty():
		reasons.append("ok")
	return {"can_hack": reasons.size() == 1 and reasons[0] == "ok", "terminal_id": terminal_id, "required_connector_level": required_connector_level, "required_processor_level": required_processor_level, "available_connector_level": available_connector_level, "available_processor_level": available_processor_level, "reasons": reasons, "heat_preview": heat_preview}

func get_terminal_action_availability(terminal_id: String, action: String = "") -> Dictionary:
	var report := {"available": false, "terminal_id": terminal_id, "action": action, "reasons": [], "requirements": {}, "state": "", "is_powered": true}
	var terminal := get_world_object_by_id(terminal_id)
	if terminal.is_empty():
		report["reasons"] = ["terminal_missing"]
		return report
	if not _is_terminal_object(terminal):
		report["reasons"] = ["not_terminal"]
		return report
	var state := str(terminal.get("state", "active")).strip_edges().to_lower()
	report["state"] = state
	var powered := bool(terminal.get("is_powered", true)) if terminal.has("is_powered") else true
	report["is_powered"] = powered
	var reasons: Array[String] = []
	if bool(terminal.get("damaged", false)) or state == "damaged": reasons.append("terminal_damaged")
	if bool(terminal.get("broken", false)) or state == "broken": reasons.append("terminal_broken")
	if bool(terminal.get("destroyed", false)) or state == "destroyed": reasons.append("terminal_destroyed")
	if state == "overheated": reasons.append("terminal_overheated")
	if state in ["unpowered", "disabled"] or (terminal.has("is_powered") and not powered): reasons.append("terminal_unpowered")
	var req: Dictionary = get_terminal_hack_requirements(terminal_id) if action == "hack" else {}
	report["requirements"] = req
	if action == "hack":
		if req.get("reasons", []).has("connector_level_too_low"): reasons.append("connector_level_too_low")
		if req.get("reasons", []).has("processor_level_too_low"): reasons.append("processor_level_too_low")
	if reasons.is_empty():
		report["available"] = true
		report["reasons"] = ["ok"]
	else:
		report["reasons"] = reasons
	return report

func attempt_terminal_hack(terminal_id: String) -> Dictionary:
	var terminal := get_world_object_by_id(terminal_id)
	var before := str(terminal.get("state", "")) if not terminal.is_empty() else ""
	var req: Dictionary = get_terminal_hack_requirements(terminal_id)
	if not bool(req.get("can_hack", false)):
		return {"success": false, "terminal_id": terminal_id, "reasons": req.get("reasons", []), "state_before": before, "state_after": before, "heat_report": req.get("heat_preview", {})}
	if str(terminal.get("state", "")) == "hacked":
		return {"success": false, "terminal_id": terminal_id, "reasons": ["already_hacked"], "state_before": before, "state_after": before, "heat_report": req.get("heat_preview", {})}
	terminal["state"] = "hacked"
	terminal["hacked"] = true
	terminal["hack_attempts"] = int(terminal.get("hack_attempts", 0)) + 1
	return {"success": true, "terminal_id": terminal_id, "reasons": ["ok"], "state_before": before, "state_after": "hacked", "heat_report": req.get("heat_preview", {})}


func get_terminal_control_targets(terminal_id: String) -> Array[Dictionary]:
	var terminal := get_world_object_by_id(terminal_id)
	if terminal.is_empty(): return []
	var out: Array[Dictionary] = []
	for key in ["target_door_id","target_platform_id","target_object_id","linked_object_id"]:
		var tid := str(terminal.get(key, "")).strip_edges()
		if tid != "": out.append({"target_id":tid, "source":key})
	for key in ["controlled_object_ids", "controls"]:
		var target_ids_variant: Variant = terminal.get(key, [])
		if not (target_ids_variant is Array):
			continue
		for tidv in target_ids_variant:
			var tid := str(tidv).strip_edges()
			if tid != "": out.append({"target_id":tid, "source":key})
	return out

func execute_terminal_control_action(terminal_id: String, target_id: String = "", action: String = "") -> Dictionary:
	var avail := get_terminal_action_availability(terminal_id, action)
	if not bool(avail.get("available", false)): return {"success":false, "terminal_id":terminal_id, "target_id":target_id, "action":action, "reasons":avail.get("reasons", [])}
	var normalized_target_id: String = target_id.strip_edges()
	var target_actions: Array[String] = ["open_door", "close_door", "unlock_door", "lock_door", "activate_platform", "toggle_platform", "rotate_platform"]
	var global_actions: Array[String] = ["enable_cooling", "reset_source_overheat"]
	if not action in target_actions and not action in global_actions:
		return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["action_invalid"]}
	var targets := get_terminal_control_targets(terminal_id)
	var allowed: bool = normalized_target_id.is_empty() and action in global_actions
	for target_link in targets:
		if str(target_link.get("target_id", "")) == normalized_target_id: allowed = true
	if not allowed: return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["target_invalid"]}
	var target := get_world_object_by_id(normalized_target_id) if not normalized_target_id.is_empty() else {}
	if action in target_actions and target.is_empty():
		return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["target_missing"]}
	var target_state: String = str(target.get("state", "")).strip_edges().to_lower()
	if action in target_actions and (target_state in ["damaged", "broken", "destroyed"] or bool(target.get("damaged", false)) or bool(target.get("broken", false)) or bool(target.get("destroyed", false))):
		return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["target_damaged"]}
	if action in target_actions and target.has("is_powered") and not bool(target.get("is_powered", true)):
		return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["target_unpowered"]}
	if action in ["open_door", "close_door", "unlock_door", "lock_door"] and str(target.get("object_group", "")) != "door":
		return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["target_invalid"]}
	var door_control_type: String = str(target.get("control_type", target.get("control_mode", "internal"))).strip_edges().to_lower()
	var door_access_type: String = WorldObjectCatalogRef.normalize_access_type(target.get("access_type", "no_key"))
	if action in ["open_door", "close_door"] and door_control_type != "external":
		return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["door_uses_internal_control"]}
	if action == "unlock_door" and door_access_type != WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL:
		return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["door_requires_credential"]}
	if action == "open_door" and bool(target.get("is_locked", false)):
		return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["locked"]}
	if action == "open_door": target["state"] = "open"
	elif action == "close_door": target["state"] = "closed"
	elif action == "unlock_door": target["state"] = "closed"
	elif action == "lock_door": target["state"] = "locked"
	if action in ["open_door", "close_door", "unlock_door", "lock_door"]:
		WorldObjectCatalogRef.normalize_door_state_fields(target)
	elif action in ["activate_platform","toggle_platform","rotate_platform"]:
		var platform_result: Dictionary = activate_platform_by_id(str(target.get("platform_id", normalized_target_id)), "terminal")
		if not bool(platform_result.get("success", false)):
			return {"success":false, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":[str(platform_result.get("reason", "platform_unavailable"))]}
	elif action == "enable_cooling":
		apply_cooling_application()
	elif action == "reset_source_overheat":
		execute_power_source_recovery_apply()
	return {"success":true, "terminal_id":terminal_id, "target_id":normalized_target_id, "action":action, "reasons":["ok"]}

func _normalize_runtime_door_data(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(object_data)
	data = WorldObjectCatalogRef.normalize_door_contract(data)
	return WorldObjectCatalogRef.normalize_door_state_fields(data)

func _get_door_access_type(object_data: Dictionary) -> String:
	return WorldObjectCatalogRef.normalize_access_type(object_data.get("access_type", object_data.get("lock_type", "")))

func _get_door_type(object_data: Dictionary) -> String:
	return str(_normalize_runtime_door_data(object_data).get("door_type", ""))

func _door_is_powered_mechanism(object_data: Dictionary) -> bool:
	return _get_door_type(object_data) == WorldObjectCatalogRef.DOOR_TYPE_POWERED

func get_door_access_state(door_id: String) -> Dictionary:
	var door: Dictionary = get_world_object_by_id(door_id)
	if door.is_empty():
		return {"door_id":door_id, "can_open":false, "can_unlock":false, "is_locked":true, "is_open":false, "is_powered":false, "reasons":["door_missing"], "lock_type":"", "access_type":"", "door_type":"", "door_class":0}
	var normalized_door: Dictionary = _normalize_runtime_door_data(door)
	var access_type: String = _get_door_access_type(normalized_door)
	var lock_type: String = str(normalized_door.get("lock_type", "none"))
	var is_locked: bool = bool(normalized_door.get("is_locked", false))
	var is_open: bool = bool(normalized_door.get("is_open", false))
	var powered: bool = bool(normalized_door.get("is_powered", true))
	var reasons: Array[String] = []
	if str(normalized_door.get("state", "")).to_lower() == "destroyed": reasons.append("door_destroyed")
	elif is_locked: reasons.append("locked")
	else: reasons.append("ok")
	return {"door_id":door_id, "can_open":reasons.has("ok"), "can_unlock":is_locked, "is_locked":is_locked, "is_open":is_open, "is_powered":powered, "reasons":reasons, "lock_type":lock_type, "access_type":access_type, "door_type":str(normalized_door.get("door_type", "")), "door_class":int(normalized_door.get("door_class", 1))}

func can_use_access_item_on_door(item_id: String, door_id: String) -> Dictionary:
	var normalized_item_id: String = item_id.strip_edges()
	var normalized_door_id: String = door_id.strip_edges()
	var door: Dictionary = get_world_object_by_id(normalized_door_id)
	if door.is_empty():
		return {"success":false, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":["door_missing"]}
	var normalized_door: Dictionary = _normalize_runtime_door_data(door)
	var required_key_id := str(normalized_door.get("required_key_id", "")).strip_edges()
	if not required_key_id.is_empty() and normalized_item_id != required_key_id:
		return {"success":false, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":["wrong_key_id"]}
	var item := get_world_object_by_id(normalized_item_id)
	if item.is_empty():
		item = _get_runtime_item_data_snapshot(normalized_item_id)
	var has_collected_item := has_collected_key(normalized_item_id)
	if item.is_empty() and not has_collected_item:
		return {"success":false, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":["item_missing"]}
	var access_type: String = _get_door_access_type(normalized_door)
	var digital_state := str(item.get("digital_state", ""))
	if normalized_item_id.find("damaged") != -1 or digital_state == "damaged":
		return {"success":false, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":["digital_key_damaged"]}
	if normalized_item_id.find("encrypted") != -1 or digital_state == "encrypted":
		return {"success":false, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":["digital_key_encrypted"]}
	var key_kind := str(item.get("key_kind", "")).strip_edges()
	if access_type == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD and not key_kind.is_empty() and WorldObjectCatalogRef.normalize_key_item_type(item.get("item_type", key_kind)) != WorldObjectCatalogRef.KEY_ITEM_TYPE_KEY_CARD:
		return {"success":false, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":["wrong_key_type"]}
	return {"success":true, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":["ok"]}

func use_access_item_on_door(item_id: String, door_id: String) -> Dictionary:
	var normalized_item_id: String = item_id.strip_edges()
	var normalized_door_id: String = door_id.strip_edges()
	var gate := can_use_access_item_on_door(normalized_item_id, normalized_door_id)
	var door := get_world_object_by_id(normalized_door_id)
	var before := str(door.get("state", "")) if not door.is_empty() else ""
	if not bool(gate.get("success", false)): return {"success":false, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":gate.get("reasons", []), "door_state_before":before, "door_state_after":before, "consumed":false}
	door["state"] = "open"
	WorldObjectCatalogRef.normalize_door_state_fields(door)
	return {"success":true, "item_id":normalized_item_id, "door_id":normalized_door_id, "reasons":["ok"], "door_state_before":before, "door_state_after":str(door.get("state", "open")), "consumed":false}

func use_inventory_item_on_world_object(item_id: String, target_id: String, action: String = "") -> Dictionary:
	var out := {"success": false, "item_id": item_id, "target_id": target_id, "action": action, "reasons": [], "consumed": false, "target_state_before": "", "target_state_after": "", "side_effects": {}}
	var item := get_world_object_by_id(item_id)
	var target := get_world_object_by_id(target_id)
	if item.is_empty():
		out["reasons"] = ["item_missing"]
		return out
	if target.is_empty():
		out["reasons"] = ["target_missing"]
		return out
	var item_type := str(item.get("item_type", item.get("object_type", item_id)))
	var before := str(target.get("state", ""))
	out["target_state_before"] = before
	if item_type == "fuse" and str(target.get("object_type", "")) in ["fuse_box_empty", "fuse_box_installed"]:
		if str(target.get("state", "")) == "installed":
			out["reasons"] = ["fuse_already_installed"]
			return out
		target["state"] = "installed"
		out["side_effects"] = apply_power_network_after_explicit_power_event("fuse_inserted", str(target.get("power_network_id", "")))
		out["success"] = true
		out["consumed"] = bool(item.get("consumable", true))
		out["reasons"] = ["ok"]
	elif item_type == "repair_kit":
		if bool(target.get("destroyed", false)) or str(target.get("state", "")) == "destroyed":
			out["reasons"] = ["target_destroyed"]
			return out
		var target_object_type: String = str(target.get("object_type", "")).strip_edges().to_lower()
		var target_is_power_cable: bool = target_object_type in ["power_cable", "power_cable_reel"]
		if not (bool(target.get("damaged", false)) or bool(target.get("broken", false)) or bool(target.get("cut", false)) or str(target.get("state", "")) in ["damaged", "broken", "cut"]):
			out["reasons"] = ["already_repaired"]
			return out
		if target_is_power_cable:
			out["side_effects"] = repair_power_cable(str(target.get("id", "")))
		else:
			target["damaged"] = false
			target["broken"] = false
			if str(target.get("state", "")) in ["damaged", "broken"]:
				target["state"] = "active"
		out["success"] = true
		out["consumed"] = bool(item.get("consumable", true))
		out["reasons"] = ["ok"]
	elif item_type == "power_cable_reel":
		var report := connect_cable_reel_to_target(item_id, target_id)
		out["success"] = bool(report.get("success", false))
		out["reasons"] = report.get("reasons", ["cable_connect_failed"])
		out["side_effects"] = report
	elif WorldObjectCatalogRef.is_key_card_item(item) or WorldObjectCatalogRef.is_digital_inventory_item(item):
		var access_report := use_access_item_on_door(item_id, target_id)
		out["success"] = bool(access_report.get("success", false))
		out["reasons"] = access_report.get("reasons", ["access_denied"])
		out["side_effects"] = access_report
	else:
		out["reasons"] = ["wrong_item_type"]
		return out
	out["target_state_after"] = str(target.get("state", before))
	return out

func get_door_debug_report_text(door_id: String = "") -> String:
	var ids: Array[String] = []
	if door_id.strip_edges() != "": ids.append(door_id)
	else:
		for obj in mission_world_objects:
			if str(obj.get("object_group", "")) == "door": ids.append(str(obj.get("id", "")))
	var lines: Array[String] = []
	for id in ids:
		var st := get_door_access_state(id)
		lines.append("%s | lock=%s | locked=%s | powered=%s | reasons=%s" % [id, str(st.get("lock_type", "")), str(bool(st.get("is_locked", false))), str(bool(st.get("is_powered", true))), ",".join(Array(st.get("reasons", [])))])
	return "\n".join(lines)

func validate_terminal_and_door_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var base_size := mission_world_objects.size()
	var world_snapshot := get_world_object_runtime_state()
	var inventory_snapshot := runtime_inventory_state.duplicate(true)
	var temp_ids: Array[String] = []
	var terminal_id := "temp_validation_terminal"
	var linked_door_id := "temp_validation_door_linked"
	var unlinked_door_id := "temp_validation_door_unlinked"
	var mechanical_door_id := "temp_validation_door_mechanical"
	var digital_door_id := "temp_validation_door_digital"
	var terminal := {"id": terminal_id, "object_group": "terminal", "object_type": "terminal", "position": Vector2i(100, 100), "state": "active", "is_powered": true, "required_connector_level": 0, "required_processor_level": 0, "target_door_id": linked_door_id}
	var linked_door := {"id": linked_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(101, 100), "state": "closed", "is_locked": true, "lock_type": "terminal_lock", "is_powered": true}
	var unlinked_door := {"id": unlinked_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(102, 100), "state": "closed", "is_locked": true, "lock_type": "terminal_lock", "is_powered": true}
	var mechanical_door := {"id": mechanical_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(103, 100), "state": "closed", "is_locked": true, "lock_type": "mechanical_key", "required_key_id": "temp_validation_mechanical_key", "is_powered": true}
	var digital_door := {"id": digital_door_id, "object_group": "door", "object_type": "door", "position": Vector2i(104, 100), "state": "closed", "is_locked": true, "lock_type": "access_code", "is_powered": true}
	for obj in [terminal, linked_door, unlinked_door, mechanical_door, digital_door]:
		mission_world_objects.append(obj)
		world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj
		temp_ids.append(str(obj.get("id", "")))
	var av := get_terminal_action_availability(terminal_id, "hack")
	if not bool(av.get("available", false)): warnings.append("active_powered_terminal_unavailable")
	terminal["is_powered"] = false
	var unpowered := get_terminal_action_availability(terminal_id, "hack")
	if not Array(unpowered.get("reasons", [])).has("terminal_unpowered"): warnings.append("terminal_unpowered_reason_missing")
	terminal["is_powered"] = true
	terminal["damaged"] = true
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("terminal_damaged"): warnings.append("terminal_damaged_reason_missing")
	terminal["damaged"] = false
	terminal["required_connector_level"] = 1
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("connector_level_too_low"): warnings.append("connector_level_gate_missing")
	terminal["required_connector_level"] = 0
	terminal["required_processor_level"] = 1
	if not Array(get_terminal_action_availability(terminal_id, "hack").get("reasons", [])).has("processor_level_too_low"): warnings.append("processor_level_gate_missing")
	terminal["required_processor_level"] = 0
	var before_preview := str(get_world_object_runtime_state().get(terminal_id, {}))
	get_terminal_hack_requirements(terminal_id)
	if str(get_world_object_runtime_state().get(terminal_id, {})) != before_preview: warnings.append("terminal_hack_preview_mutated_state")
	terminal["required_connector_level"] = 2
	var before_fail := str(get_world_object_runtime_state().get(terminal_id, {}))
	attempt_terminal_hack(terminal_id)
	if str(get_world_object_runtime_state().get(terminal_id, {})) != before_fail: warnings.append("failed_hack_mutated_state")
	terminal["required_connector_level"] = 0
	terminal["state"] = "hacked"
	if not Array(attempt_terminal_hack(terminal_id).get("reasons", [])).has("already_hacked"): warnings.append("already_hacked_reason_missing")
	terminal["state"] = "active"
	if not bool(execute_terminal_control_action(terminal_id, linked_door_id, "unlock_door").get("success", false)): warnings.append("linked_door_control_failed")
	if bool(execute_terminal_control_action(terminal_id, unlinked_door_id, "unlock_door").get("success", false)): warnings.append("unlinked_door_control_should_fail")
	var mechanical_key := {"id":"temp_validation_mechanical_key", "object_group":"item", "object_type":"item", "position":Vector2i(105, 100), "key_kind":"mechanical", "item_type":"mechanical_keycard"}
	var wrong_key := {"id":"temp_validation_wrong_key", "object_group":"item", "object_type":"item", "position":Vector2i(106, 100), "item_type":"digital_key"}
	var damaged_key := {"id":"temp_validation_damaged_key", "object_group":"item", "object_type":"item", "position":Vector2i(107, 100), "item_type":"digital_key", "digital_state":"damaged"}
	var encrypted_key := {"id":"temp_validation_encrypted_key", "object_group":"item", "object_type":"item", "position":Vector2i(108, 100), "item_type":"digital_key", "digital_state":"encrypted"}
	var good_digital := {"id":"temp_validation_good_digital", "object_group":"item", "object_type":"item", "position":Vector2i(109, 100), "item_type":"access_code"}
	for key_obj in [mechanical_key, wrong_key, damaged_key, encrypted_key, good_digital]:
		mission_world_objects.append(key_obj); world_objects_by_cell[Vector2i(key_obj.get("position", Vector2i(-1, -1)))] = key_obj; temp_ids.append(str(key_obj.get("id", "")))
	if not bool(can_use_access_item_on_door(mechanical_key["id"], mechanical_door_id).get("success", false)): warnings.append("mechanical_key_gate_failed")
	if not bool(pickup_world_item(mechanical_key["id"]).get("success", false)): warnings.append("mechanical_key_pickup_failed")
	if not get_world_object_by_id(mechanical_key["id"]).is_empty(): warnings.append("picked_up_key_world_copy_remains")
	var key_runtime: Dictionary = Dictionary(Dictionary(runtime_inventory_state.get("world_item_runtime", {})).get(mechanical_key["id"], {}))
	if not bool(key_runtime.get("picked_up", false)) or Dictionary(key_runtime.get("item_data", {})).is_empty(): warnings.append("picked_up_key_runtime_snapshot_missing")
	if not bool(can_use_access_item_on_door(mechanical_key["id"], mechanical_door_id).get("success", false)): warnings.append("collected_key_gate_failed")
	if not bool(use_access_item_on_door(mechanical_key["id"], mechanical_door_id).get("success", false)): warnings.append("collected_key_open_failed")
	mechanical_door["state"] = "locked"; WorldObjectCatalogRef.normalize_door_state_fields(mechanical_door)
	mark_key_collected(wrong_key["id"])
	if not Array(can_use_access_item_on_door(wrong_key["id"], mechanical_door_id).get("reasons", [])).has("wrong_key_id"): warnings.append("wrong_collected_key_id_reason_missing")
	var wrong_before := str(get_world_object_runtime_state().get(mechanical_door_id, {}))
	if bool(use_access_item_on_door(wrong_key["id"], mechanical_door_id).get("success", false)): warnings.append("wrong_key_should_fail")
	if str(get_world_object_runtime_state().get(mechanical_door_id, {})) != wrong_before: warnings.append("wrong_key_mutated_door")
	if not Array(use_access_item_on_door(damaged_key["id"], digital_door_id).get("reasons", [])).has("digital_key_damaged"): warnings.append("digital_key_damaged_missing")
	if not Array(use_access_item_on_door(encrypted_key["id"], digital_door_id).get("reasons", [])).has("digital_key_encrypted"): warnings.append("digital_key_encrypted_missing")
	if not bool(use_access_item_on_door(good_digital["id"], digital_door_id).get("success", false)): warnings.append("digital_access_open_failed")
	var door_debug_before := str(get_world_object_runtime_state())
	get_door_debug_report_text()
	if str(get_world_object_runtime_state()) != door_debug_before: warnings.append("door_debug_mutated_state")
	var runtime_snap := get_world_object_runtime_state()
	if not Dictionary(runtime_snap.get(terminal_id, {})).has("state"): warnings.append("runtime_snapshot_terminal_state_missing")
	if not Dictionary(runtime_snap.get(digital_door_id, {})).has("is_locked"): warnings.append("runtime_snapshot_door_lock_missing")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var object_id := str(mission_world_objects[i].get("id", "")).strip_edges()
		if temp_ids.has(object_id):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(world_snapshot)
	runtime_inventory_state = inventory_snapshot.duplicate(true)
	if mission_world_objects.size() != base_size:
		warnings.append("terminal_door_cleanup_world_size_changed")
	return warnings

func get_terminal_and_door_validation_text() -> String:
	var warnings := validate_terminal_and_door_runtime()
	return "TerminalDoorValidation: warnings=%d" % warnings.size()

func get_scan_result_for_object(object_id: String, scan_mode: String = "basic") -> Dictionary:
	var object_data := get_world_object_by_id(object_id)
	if object_data.is_empty():
		return {"ok": false, "reason": "object_missing", "scan_mode": scan_mode}
	if not is_world_object_visible_to_player(object_data, scan_mode):
		return {"ok": false, "reason": "not_visible", "scan_mode": scan_mode}
	var result := {"ok": true, "scan_mode": scan_mode, "object_id": object_id, "object_type": str(object_data.get("object_type", "")), "state": str(object_data.get("state", ""))}
	if scan_mode in ["diagnostic", "power", "platform"]:
		result["power_reason"] = str(object_data.get("power_unavailable_reason", ""))
	if scan_mode in ["diagnostic", "cooling"]:
		result["cooling_received"] = int(object_data.get("cooling_received", 0))
		result["cooling_source_ids"] = object_data.get("cooling_source_ids", [])
	if scan_mode in ["diagnostic", "platform"] and str(object_data.get("object_group", "")) == "platform":
		result["platform"] = get_platform_action_availability(str(object_data.get("platform_id", "")), "activate")
	if scan_mode == "xray":
		result["xray_objects"] = get_xray_visible_objects(str(object_data.get("power_network_id", "")))
	return result

func get_scan_result_for_cell(cell: Vector2i, scan_mode: String = "basic") -> Dictionary:
	var object_data := get_world_object_at_cell(cell)
	if object_data.is_empty():
		return {"ok": true, "scan_mode": scan_mode, "cell": [cell.x, cell.y], "object": {}}
	return get_scan_result_for_object(str(object_data.get("id", "")), scan_mode)

func get_scan_text_for_object(object_id: String, scan_mode: String = "basic") -> String:
	return JSON.stringify(get_scan_result_for_object(object_id, scan_mode))

func validate_platform_scan_visibility_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var platform := get_platform_by_id("platform_lift_a")
	if not platform.is_empty():
		var av := get_platform_action_availability(str(platform.get("platform_id", "")), "activate")
		if not av.has("available"):
			warnings.append("platform availability helper missing fields")
	var snapshot_a := str(get_world_object_runtime_state())
	get_scan_result_for_cell(Vector2i.ZERO, "basic")
	var snapshot_b := str(get_world_object_runtime_state())
	if snapshot_a != snapshot_b:
		warnings.append("scan/report helpers are not read-only")
	var hidden_cable := {"id":"temp_hidden_cable", "object_group":"cable", "object_type":"power_cable", "position":Vector2i(140, 100), "hidden":true, "hidden_cable":true, "visible_with_xray":true}
	mission_world_objects.append(hidden_cable)
	world_objects_by_cell[Vector2i(140, 100)] = hidden_cable
	var basic_visible := is_world_object_visible_to_player(hidden_cable, "basic")
	var xray_result := get_scan_result_for_object("temp_hidden_cable", "xray")
	if basic_visible:
		warnings.append("basic_scan_should_hide_hidden_cable")
	if not bool(xray_result.get("ok", false)):
		warnings.append("xray_scan_should_report_hidden_cable")
	var reveal_before := str(get_world_object_runtime_state().get("temp_hidden_cable", {}))
	reveal_xray_objects("")
	var reveal_after: Dictionary = get_world_object_runtime_state().get("temp_hidden_cable", {})
	if not bool(reveal_after.get("revealed", false)) or not bool(reveal_after.get("discovered", false)):
		warnings.append("reveal_xray_objects_did_not_mark_revealed_discovered")
	if reveal_before == str(reveal_after):
		warnings.append("reveal_xray_objects_no_effect")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		if str(mission_world_objects[i].get("id", "")) == "temp_hidden_cable":
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	return warnings

func get_platform_scan_visibility_validation_text() -> String:
	var warnings := validate_platform_scan_visibility_runtime()
	if warnings.is_empty():
		return "PlatformScanVisibilityValidation: ok"
	return "PlatformScanVisibilityValidation:\n- " + "\n- ".join(warnings)

func validate_inventory_tools_modules_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var inventory_snapshot := runtime_inventory_state.duplicate(true)
	var world_snapshot := get_world_object_runtime_state()
	var temp_ids: Array[String] = []
	var caps := get_actor_capability_levels()
	if not caps.has("manipulator_level") or not caps.has("connector_level") or not caps.has("processor_level"):
		warnings.append("capability_defaults_missing")
	var req_obj := {"id":"temp_req_obj", "object_group":"item", "object_type":"item", "position":Vector2i(120, 100), "required_manipulator_level":1, "required_connector_level":1, "required_processor_level":1}
	mission_world_objects.append(req_obj); world_objects_by_cell[Vector2i(120, 100)] = req_obj; temp_ids.append("temp_req_obj")
	var req := check_world_object_requirements("temp_req_obj", "use")
	for r in ["manipulator_level_too_low","connector_level_too_low","processor_level_too_low"]:
		if not Array(req.get("reasons", [])).has(r): warnings.append("requirements_missing_%s" % r)
	var physical_item := {"id":"temp_item_physical", "object_group":"item", "object_type":"item", "position":Vector2i(121, 100), "item_type":"fuse", "item_form":"physical", "can_pickup":true}
	var digital_item := {"id":"temp_item_digital", "object_group":"item", "object_type":"item", "position":Vector2i(122, 100), "item_form":"digital", "can_place_in_digital_buffer":true}
	var digital_blocked := {"id":"temp_item_digital_blocked", "object_group":"item", "object_type":"item", "position":Vector2i(123, 100), "item_form":"digital", "can_place_in_digital_buffer":false}
	for obj in [physical_item, digital_item, digital_blocked]:
		mission_world_objects.append(obj); world_objects_by_cell[Vector2i(obj.get("position", Vector2i(-1, -1)))] = obj; temp_ids.append(str(obj.get("id", "")))
	if not bool(pickup_world_item("temp_item_physical").get("success", false)): warnings.append("physical_pickup_failed")
	if get_manipulator_held_item_id() != "temp_item_physical": warnings.append("physical_pickup_not_routed_to_manipulator")
	if Array(runtime_inventory_state.get("pocket_items", [])).has("temp_item_physical"): warnings.append("physical_pickup_routed_to_pocket")
	if Array(runtime_inventory_state.get("digital_buffer", [])).has("temp_item_physical"): warnings.append("physical_pickup_routed_to_digital_buffer")
	runtime_inventory_state["manipulator_hold"] = physical_item.duplicate(true)
	if get_manipulator_held_item_id() != "temp_item_physical": warnings.append("dictionary_manipulator_id_read_failed")
	runtime_inventory_state["pocket_items"] = []
	if not bool(move_runtime_manipulator_to_pocket(0, 1).get("ok", false)): warnings.append("dictionary_manipulator_to_pocket_failed")
	if not Array(runtime_inventory_state.get("pocket_items", [])).has("temp_item_physical"): warnings.append("dictionary_manipulator_to_pocket_missing_item")
	runtime_inventory_state["pocket_items"] = []
	runtime_inventory_state["manipulator_hold"] = physical_item.duplicate(true)
	var temp_drop_cell := Vector2i(125, 100)
	if not bool(drop_inventory_item("temp_item_physical", temp_drop_cell).get("success", false)): warnings.append("dictionary_manipulator_drop_failed")
	var dropped_items := get_items_at_cell(temp_drop_cell)
	if dropped_items.size() != 1 or str(Dictionary(dropped_items[0]).get("id", "")) != "temp_item_physical": warnings.append("dropped_physical_item_missing_from_cell")
	_remove_world_item_from_lookup_tables("temp_item_physical", physical_item)
	clear_manipulator_held_item()
	if not bool(pickup_world_item("temp_item_digital").get("success", false)): warnings.append("digital_pickup_allowed_failed")
	if bool(pickup_world_item("temp_item_digital_blocked").get("success", false)): warnings.append("digital_pickup_block_missing")
	var stacked_cell := Vector2i(124, 100)
	var stacked_first := {"id":"temp_item_stacked_first", "object_group":"item", "object_type":"item", "position":stacked_cell, "item_type":"scrap", "item_form":"physical", "can_pickup":true}
	var stacked_second := {"id":"temp_item_stacked_second", "object_group":"item", "object_type":"item", "position":stacked_cell, "item_type":"mechanical_key", "key_kind":"mechanical", "item_form":"physical", "can_pickup":true}
	add_item_at_cell(stacked_cell, stacked_first); add_item_at_cell(stacked_cell, stacked_second); temp_ids.append("temp_item_stacked_first"); temp_ids.append("temp_item_stacked_second")
	if not bool(pickup_world_item("temp_item_stacked_second").get("success", false)): warnings.append("stacked_second_pickup_failed")
	if get_manipulator_held_item_id() == "temp_item_stacked_second": warnings.append("mechanical_keycard_routed_to_manipulator")
	if not Array(runtime_inventory_state.get("collected_key_ids", [])).has("temp_item_stacked_second"): warnings.append("mechanical_keycard_missing_from_keychain")
	runtime_inventory_state["manipulator_hold"] = "occupied_slot"
	var blocked_physical_pickup := pickup_world_item("temp_item_stacked_first")
	if bool(blocked_physical_pickup.get("success", false)): warnings.append("occupied_manipulator_pickup_gate_missing")
	if str(blocked_physical_pickup.get("message", "")) != "Free manipulator required.": warnings.append("occupied_manipulator_pickup_message_missing")
	var stacked_remaining := get_items_at_cell(stacked_cell)
	if stacked_remaining.size() != 1 or str(Dictionary(stacked_remaining[0]).get("id", "")) != "temp_item_stacked_first": warnings.append("stacked_pickup_removed_wrong_item")
	if not get_world_object_by_id("temp_item_stacked_second").is_empty(): warnings.append("stacked_pickup_world_copy_remains")
	cell_items.erase(stacked_cell)
	if bool(hold_item_in_manipulator("temp_item_physical").get("success", false)): warnings.append("manipulator_single_item_gate_missing")
	runtime_inventory_state["manipulator_hold"] = ""
	var inv_before_fail := str(get_inventory_state())
	drop_inventory_item("missing_item")
	if str(get_inventory_state()) != inv_before_fail: warnings.append("failed_inventory_action_mutated_state")
	for i in range(mission_world_objects.size() - 1, -1, -1):
		var oid := str(mission_world_objects[i].get("id", ""))
		if temp_ids.has(oid):
			world_objects_by_cell.erase(WorldObjectCatalogRef.to_world_cell(mission_world_objects[i].get("position", Vector2i(-1, -1)), Vector2i(-1, -1)))
			mission_world_objects.remove_at(i)
	apply_world_object_runtime_state(world_snapshot)
	runtime_inventory_state = inventory_snapshot.duplicate(true)
	return warnings

func get_inventory_tools_modules_validation_text() -> String:
	var warnings := validate_inventory_tools_modules_runtime()
	return "InventoryToolsModulesValidation: ok" if warnings.is_empty() else "InventoryToolsModulesValidation:\n- " + "\n- ".join(warnings)

func validate_full_runtime_persistence() -> Array[String]:
	var warnings: Array[String] = []
	var snap := get_world_object_runtime_state()
	if snap.is_empty() and not mission_world_objects.is_empty():
		warnings.append("world_runtime_snapshot_empty")
	var inv := get_inventory_state()
	for field_name in ["pocket_items", "manipulator_hold", "digital_buffer", "item_amounts", "consumed_item_ids", "world_item_runtime"]:
		if not inv.has(field_name):
			warnings.append("inventory_field_missing_%s" % field_name)
	return warnings

func _get_mission10_layout_for_validation() -> Array:
	if grid_manager != null and grid_manager.has_method("get_mission10_layout"):
		return Array(grid_manager.call("get_mission10_layout"))
	var temporary_grid: GridManager = GridManager.new()
	var layout: Array = Array(temporary_grid.get_mission10_layout())
	temporary_grid.free()
	return layout

func _build_world_runtime_validation_fingerprint() -> Dictionary:
	var object_ids: Array[String] = []
	var object_cells: Array[String] = []
	for obj_variant in mission_world_objects:
		var obj: Dictionary = Dictionary(obj_variant)
		object_ids.append(str(obj.get("id", "")))
		object_cells.append("%s@%s" % [str(obj.get("id", "")), str(WorldObjectCatalogRef.to_world_cell(obj.get("position", Vector2i.ZERO), Vector2i.ZERO))])
	object_ids.sort()
	object_cells.sort()
	var item_ids: Array[String] = []
	var item_cells: Array[String] = []
	for cell_variant in cell_items.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		for item_variant in Array(cell_items[cell_variant]):
			var item: Dictionary = _safe_dictionary(item_variant)
			item_ids.append(str(item.get("id", "")))
			item_cells.append("%s@%s" % [str(item.get("id", "")), str(cell)])
	item_ids.sort()
	item_cells.sort()
	return {
		"mission_id": current_mission_id,
		"object_ids": object_ids,
		"item_ids": item_ids,
		"world_objects_by_cell": str(world_objects_by_cell),
		"cell_items": str(cell_items),
		"object_cells": object_cells,
		"item_cells": item_cells
	}

func _get_task_test_duplicate_cell_warnings(objects: Array[Dictionary], items_by_cell: Dictionary = {}) -> Array[String]:
	var warnings: Array[String] = []
	var occupied_cells: Dictionary = {}
	for obj in objects:
		var oid := str(obj.get("id", "")).strip_edges()
		if not oid.begins_with("task_test_"):
			continue
		var cell: Vector2i = Vector2i(obj.get("position", Vector2i.ZERO))
		if bool(obj.get("allow_cell_overlap", false)):
			continue
		if occupied_cells.has(cell):
			warnings.append("duplicate_task_test_cell_%s_between_%s_and_%s" % [str(cell), str(occupied_cells[cell]), oid])
		else:
			occupied_cells[cell] = oid
	for cell_variant in items_by_cell.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		if not occupied_cells.has(cell):
			continue
		for item_variant in Array(items_by_cell[cell_variant]):
			var item: Dictionary = _safe_dictionary(item_variant)
			var item_id: String = str(item.get("id", "")).strip_edges()
			if item_id.begins_with("task_test_"):
				warnings.append("duplicate_task_test_cell_%s_between_%s_and_%s" % [str(cell), str(occupied_cells[cell]), item_id])
	return warnings

func validate_task_test_mission_runtime() -> Array[String]:
	var warnings: Array[String] = []
	var runtime_before: Dictionary = _build_world_runtime_validation_fingerprint()
	var built: Dictionary = build_task_test_sandbox_world_objects_for_validation()
	warnings.append_array(Array(built.get("warnings", [])))
	var task_objects: Array[Dictionary] = _safe_dictionary_array(built.get("objects", []))
	var task_items_by_cell: Dictionary = built.get("items_by_cell", {})
	var task_ids := {}
	for obj in task_objects:
		var oid := str(obj.get("id", "")).strip_edges()
		if not oid.begins_with("task_test_"):
			continue
		if task_ids.has(oid):
			warnings.append("duplicate_task_test_id_%s" % oid)
		task_ids[oid] = true
		if str(obj.get("object_type", "")).strip_edges() == "":
			warnings.append("task_test_object_missing_type_%s" % oid)
		if str(obj.get("object_group", "")).strip_edges() == "":
			warnings.append("task_test_object_missing_group_%s" % oid)
	warnings.append_array(_get_task_test_duplicate_cell_warnings(task_objects, task_items_by_cell))
	for required_id in ["task_test_extraction_door","task_test_source_class_1","task_test_radiator","task_test_terminal_main","task_test_door_mechanical","task_test_platform_lift","task_test_hidden_cable","task_test_item_repair_kit","task_test_cable_reel"]:
		if not task_ids.has(required_id):
			var exists_item := false
			for cell in task_items_by_cell.keys():
				for item in Array(task_items_by_cell[cell]):
					if str(item.get("id", "")) == required_id:
						exists_item = true
						break
				if exists_item:
					break
			if not exists_item:
				warnings.append("missing_%s" % required_id)
	var extraction: Dictionary = {}
	for obj in task_objects:
		if str(obj.get("id", "")) == "task_test_extraction_door":
			extraction = obj
			break
	if extraction.is_empty() or not bool(extraction.get("mission_exit", false)):
		warnings.append("task_test_extraction_not_flagged")
	else:
		if not bool(extraction.get("extraction", false)):
			warnings.append("task_test_extraction_missing_extraction_flag")
		if str(extraction.get("state", "")) != "open":
			warnings.append("task_test_extraction_not_open")
		if bool(extraction.get("is_locked", false)):
			warnings.append("task_test_extraction_locked")
	var xray_exists := task_ids.has("task_test_xray_route_marker")
	if not xray_exists:
		warnings.append("task_test_xray_route_marker_missing")
	var xray_marker: Dictionary = {}
	for obj in task_objects:
		if str(obj.get("id", "")) == "task_test_xray_route_marker":
			xray_marker = obj
			break
	if not xray_marker.is_empty() and not extraction.is_empty():
		if Vector2i(xray_marker.get("position", Vector2i(-999, -999))) == Vector2i(extraction.get("position", Vector2i(-999, -999))):
			warnings.append("task_test_xray_route_marker_overlaps_extraction_door")
	var exit_cell := Vector2i(14, 7)
	var extraction_cell := Vector2i(extraction.get("position", Vector2i(-999, -999)))
	if extraction_cell != exit_cell and extraction_cell.distance_to(exit_cell) > 1.0:
		warnings.append("task_test_extraction_not_on_or_adjacent_to_exit")
	var mission_layout: Array = _get_mission10_layout_for_validation()
	var exit_tiles := 0
	var layout_exit_cell := Vector2i(-999, -999)
	for y in range(mission_layout.size()):
		for x in range(Array(mission_layout[y]).size()):
			if int(Array(mission_layout[y])[x]) == GridManager.TILE_EXIT:
				exit_tiles += 1
				layout_exit_cell = Vector2i(x, y)
	if exit_tiles != 1:
		warnings.append("task_test_layout_exit_tile_count_%d" % exit_tiles)
	elif extraction_cell != layout_exit_cell and extraction_cell.distance_to(layout_exit_cell) > 1.0:
		warnings.append("task_test_extraction_cell_not_matching_layout_exit")
	var runtime_after: Dictionary = _build_world_runtime_validation_fingerprint()
	if str(runtime_after.get("mission_id", "")) != str(runtime_before.get("mission_id", "")):
		warnings.append("task_test_validation_mutated_mission_id")
	if str(runtime_after.get("object_ids", "")) != str(runtime_before.get("object_ids", "")):
		warnings.append("task_test_validation_mutated_object_ids")
	if str(runtime_after.get("item_ids", "")) != str(runtime_before.get("item_ids", "")):
		warnings.append("task_test_validation_mutated_item_ids")
	if str(runtime_after.get("world_objects_by_cell", "")) != str(runtime_before.get("world_objects_by_cell", "")):
		warnings.append("task_test_validation_mutated_world_objects_by_cell")
	if str(runtime_after.get("cell_items", "")) != str(runtime_before.get("cell_items", "")):
		warnings.append("task_test_validation_mutated_cell_items")
	if str(runtime_after.get("object_cells", "")) != str(runtime_before.get("object_cells", "")):
		warnings.append("task_test_validation_mutated_object_cells")
	if str(runtime_after.get("item_cells", "")) != str(runtime_before.get("item_cells", "")):
		warnings.append("task_test_validation_mutated_item_cells")
	return warnings

func get_task_test_required_system_coverage_spec() -> Dictionary:
	return {
		"movement": {"required":["runtime_door_passability_checks"],"optional":[],"intentionally_invalid":[]},
		"doors": {"required":["open_mechanical_door","closed_mechanical_door","locked_mechanical_key_door","open_digital_door","locked_digital_key_door","terminal_locked_door","powered_gate","unpowered_gate","damaged_or_jammed_door"],"optional":[],"intentionally_invalid":[]},
		"keys": {"required":["mechanical_key","digital_key_opened","digital_key_encrypted","digital_key_damaged"],"optional":["access_code"],"intentionally_invalid":[]},
		"power": {"required":["power_source","power_socket","power_cable","power_cable_cut","hidden_power_cable","external_power_required"],"optional":[],"intentionally_invalid":["task_test_powered_gate_unpowered","task_test_platform_lift"]},
		"control": {"required":["control_switch","control_terminal","external_control_required"],"optional":[],"intentionally_invalid":["task_test_control_missing_source","task_test_control_invalid_source"]},
		"cooling": {"required":["cooling_device","heat_producer","overheated_device"],"optional":[],"intentionally_invalid":[]},
		"terminals": {"required":["terminal_info","terminal_unpowered","terminal_damaged","terminal_encrypted","terminal_connector_gated","terminal_processor_gated"],"optional":[],"intentionally_invalid":[]},
		"wall_materials": {"required":["wall_outer","wall_brick","wall_concrete","wall_steel","wall_reinforced","wall_grate","wall_damaged"],"optional":[],"intentionally_invalid":[]},
		"scan_visibility": {"required":["scan_xray_hidden","scan_thermal_visible","scan_connector_gated","scan_processor_gated"],"optional":[],"intentionally_invalid":[]},
		"items": {"required":["mechanical_key","digital_key_opened","digital_key_encrypted","digital_key_damaged"],"optional":["access_code","fuse","repair_kit"],"intentionally_invalid":[]},
		"extraction": {"required":["extraction"],"optional":[],"intentionally_invalid":[]},
		"runtime_cell_state": {"required":["door_open_passable","door_closed_not_passable"],"optional":[],"intentionally_invalid":[]},
		"negative_samples": {"required":[],"optional":[],"intentionally_invalid":["task_test_control_missing_source","task_test_control_invalid_source","task_test_powered_gate_unpowered","task_test_platform_lift"]}
	}

func classify_task_test_object_for_audit(object_data: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var object_id: String = str(object_data.get("id", ""))
	var group: String = str(object_data.get("object_group", ""))
	var object_type: String = str(object_data.get("object_type", ""))
	var item_type: String = str(object_data.get("item_type", object_type))
	var state: String = str(object_data.get("state", "")).to_lower()
	var access_type: String = WorldObjectCatalogRef.normalize_access_type(object_data.get("access_type", object_data.get("lock_type", "")))
	if group == "door":
		var is_open := state == "open" or bool(object_data.get("is_open", false))
		var is_closed := state == "closed"
		var is_damaged_or_jammed := state in ["damaged", "jammed"] or bool(object_data.get("damaged", false))
		if is_open:
			tags.append("door_open")
			if str(object_data.get("door_type", "")) == WorldObjectCatalogRef.DOOR_TYPE_MECHANICAL:
				tags.append("open_mechanical_door")
			if str(object_data.get("door_type", "")) == WorldObjectCatalogRef.DOOR_TYPE_DIGITAL:
				tags.append("open_digital_door")
		if is_closed:
			tags.append("door_closed")
			if str(object_data.get("door_type", "")) == WorldObjectCatalogRef.DOOR_TYPE_MECHANICAL:
				tags.append("closed_mechanical_door")
		if access_type == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD:
			tags.append("door_locked_mechanical")
			tags.append("locked_mechanical_key_door")
		if access_type == WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY:
			tags.append("door_locked_digital")
			tags.append("locked_digital_key_door")
		if access_type == WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL:
			tags.append("door_terminal_locked")
			tags.append("terminal_locked_door")
		if bool(object_data.get("requires_external_power", false)):
			tags.append("door_powered_gate")
			tags.append("powered_gate")
		if state == "unpowered" or not bool(object_data.get("is_powered", true)):
			tags.append("door_unpowered")
			tags.append("unpowered_gate")
		if is_damaged_or_jammed:
			tags.append("door_damaged")
			tags.append("damaged_or_jammed_door")
	if group == "item":
		if WorldObjectCatalogRef.is_key_card_item(object_data):
			tags.append("mechanical_key")
			tags.append("key_mechanical")
		if item_type == "digital_key":
			var dstate: String = str(object_data.get("digital_state", "")).to_lower()
			if dstate == "opened":
				tags.append("digital_key_opened")
				tags.append("key_digital_opened")
			if dstate == "encrypted":
				tags.append("digital_key_encrypted")
				tags.append("key_digital_encrypted")
			if dstate == "damaged":
				tags.append("digital_key_damaged")
				tags.append("key_digital_damaged")
	if object_type.begins_with("power_source"): tags.append("power_source")
	if object_type == "power_socket": tags.append("power_socket")
	if object_type == "power_cable":
		tags.append("power_cable")
		if state == "cut" or bool(object_data.get("damaged", false)): tags.append("power_cable_cut")
		if bool(object_data.get("hidden", false)): tags.append("hidden_power_cable")
	if bool(object_data.get("requires_external_power", false)): tags.append("external_power_required")
	if object_type in ["circuit_switch","circuit_breaker","power_switcher"]: tags.append("control_switch")
	if group == "terminal": tags.append("control_terminal")
	if bool(object_data.get("requires_external_control", false)): tags.append("external_control_required")
	if object_id == "task_test_control_missing_source": tags.append("control_missing_expected")
	if object_id == "task_test_control_invalid_source": tags.append("control_invalid_expected")
	if object_data.has("cooling_device_type"): tags.append("cooling_device")
	if int(object_data.get("working_heat", 0)) > 0: tags.append("heat_producer")
	if int(object_data.get("current_heat", 0)) >= int(object_data.get("overheat_threshold", 999999)): tags.append("overheated_device")
	if group == "terminal":
		if str(object_data.get("connection_type", "")) == "info": tags.append("terminal_info")
		if state == "unpowered": tags.append("terminal_unpowered")
		if state == "damaged": tags.append("terminal_damaged")
		if bool(object_data.get("encrypts_data", false)): tags.append("terminal_encrypted")
		if int(object_data.get("required_connector_level", 0)) > 0: tags.append("terminal_connector_gated")
		if int(object_data.get("required_processor_level", 0)) > 0: tags.append("terminal_processor_gated")
	var material: String = str(object_data.get("material", ""))
	if material == "outer_wall": tags.append("wall_outer")
	if material == "brick_wall": tags.append("wall_brick")
	if material == "concrete_wall": tags.append("wall_concrete")
	if material == "steel_wall": tags.append("wall_steel")
	if material == "reinforced_steel_wall": tags.append("wall_reinforced")
	if material == "grate_wall": tags.append("wall_grate")
	if material == "damaged_wall": tags.append("wall_damaged")
	if bool(object_data.get("hidden", false)) and bool(object_data.get("visible_with_xray", false)): tags.append("scan_xray_hidden")
	if bool(object_data.get("visible_with_thermal", false)): tags.append("scan_thermal_visible")
	if int(object_data.get("required_connector_level", 0)) > 0: tags.append("scan_connector_gated")
	if int(object_data.get("required_processor_level", 0)) > 0: tags.append("scan_processor_gated")
	if bool(object_data.get("mission_exit", false)) or bool(object_data.get("extraction", false)): tags.append("extraction")
	if item_type == "access_code": tags.append("access_code")
	if item_type == "fuse": tags.append("fuse")
	if item_type == "repair_kit": tags.append("repair_kit")
	return tags

func get_task_test_system_coverage_report_text() -> String:
	return get_task_test_system_audit_report_text()

func get_task_test_system_coverage_report() -> Dictionary:
	var audit: Dictionary = get_task_test_system_audit_report()
	return {"total_objects": int(audit.get("summary", {}).get("total_objects", 0)), "coverage": Dictionary(audit.get("coverage", {}))}

func get_task_test_system_audit_report() -> Dictionary:
	var object_ids: Dictionary = {}
	var item_ids: Dictionary = {}
	var coverage_hits: Dictionary = {}
	var valid_links: Array[Dictionary] = []
	var invalid_links: Array[Dictionary] = []
	var expected_invalid_links: Array[Dictionary] = []
	var duplicate_cell_warnings: Array[String] = []
	var objects_without_audit_tags: Array[String] = []
	var notes: Array[String] = []
	var occupied: Dictionary = {}
	for object_data in mission_world_objects:
		var object_id: String = str(object_data.get("id", ""))
		object_ids[object_id] = true
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			var item_data: Dictionary = _safe_dictionary(item_variant)
			item_ids[str(item_data.get("id", ""))] = true
	var spec: Dictionary = get_task_test_required_system_coverage_spec()
	var expected_invalid_ids: Dictionary = {}
	for entry_variant in Array(spec.get("negative_samples", {}).get("intentionally_invalid", [])):
		expected_invalid_ids[str(entry_variant)] = true
	var has_open_passable_door: bool = false
	var has_closed_not_passable_door: bool = false
	for object_data in mission_world_objects:
		var object_id: String = str(object_data.get("id", ""))
		var tags: Array[String] = classify_task_test_object_for_audit(object_data)
		var group: String = str(object_data.get("object_group", ""))
		var cell: Vector2i = Vector2i(object_data.get("position", Vector2i.ZERO))
		if group == "door":
			var runtime_state: Dictionary = get_runtime_cell_state(cell)
			var is_passable := bool(runtime_state.get("is_passable", false))
			var state: String = str(object_data.get("state", "")).to_lower()
			var access_type: String = WorldObjectCatalogRef.normalize_access_type(object_data.get("access_type", object_data.get("lock_type", "")))
			if (state == "open" or bool(object_data.get("is_open", false))) and is_passable:
				tags.append("door_open_passable")
				has_open_passable_door = true
			var closed_like := state in ["closed", "locked", "unpowered", "damaged", "jammed"] or bool(object_data.get("is_locked", false))
			if access_type != WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY:
				closed_like = true
			if closed_like and not is_passable:
				tags.append("door_closed_not_passable")
				has_closed_not_passable_door = true
		if tags.is_empty():
			objects_without_audit_tags.append(object_id)
		for tag in tags:
			coverage_hits[str(tag)] = true
		if group != "item":
			if occupied.has(cell):
				duplicate_cell_warnings.append("duplicate_world_object_cell_%s_%s_%s" % [str(cell), str(occupied[cell]), object_id])
			else:
				occupied[cell] = object_id
		for field_name in ["power_network_id", "control_source_id", "linked_terminal_id", "controller_id", "target_door_id", "target_platform_id", "required_key_id"]:
			var ref_id: String = str(object_data.get(field_name, "")).strip_edges()
			if ref_id.is_empty():
				continue
			var exists: bool = object_ids.has(ref_id) or item_ids.has(ref_id) or field_name == "power_network_id"
			var link_row: Dictionary = {"object_id": object_id, "field": field_name, "target_id": ref_id}
			if exists:
				valid_links.append(link_row)
			elif expected_invalid_ids.has(object_id):
				expected_invalid_links.append(link_row)
			else:
				invalid_links.append(link_row)
		var ctrls: Array = Array(object_data.get("controls", []))
		for ctrl_target in ctrls:
			var ctrl_id: String = str(ctrl_target).strip_edges()
			if ctrl_id.is_empty():
				continue
			var ctrl_row: Dictionary = {"object_id": object_id, "field": "controls", "target_id": ctrl_id}
			if object_ids.has(ctrl_id):
				valid_links.append(ctrl_row)
			elif expected_invalid_ids.has(object_id):
				expected_invalid_links.append(ctrl_row)
			else:
				invalid_links.append(ctrl_row)
	if has_open_passable_door and has_closed_not_passable_door:
		coverage_hits["runtime_door_passability_checks"] = true
	var expected_runtime_warnings: Array[String] = []
	var unexpected_runtime_warnings: Array[String] = []
	for runtime_warning in validate_task_test_runtime_cell_states():
		var warning_text: String = str(runtime_warning)
		var matched_expected: bool = false
		for expected_id_variant in expected_invalid_ids.keys():
			var expected_id: String = str(expected_id_variant)
			if not expected_id.is_empty() and warning_text.find(expected_id) != -1:
				matched_expected = true
				break
		if matched_expected:
			expected_runtime_warnings.append(warning_text)
		else:
			unexpected_runtime_warnings.append(warning_text)
	var runtime_cell_warnings: Array[String] = unexpected_runtime_warnings
	var coverage: Dictionary = {}
	var missing_coverage: Array[String] = []
	for section_name in spec.keys():
		var section_spec: Dictionary = Dictionary(spec.get(section_name, {}))
		var required_items: Array = Array(section_spec.get("required", []))
		var covered: Array[String] = []
		var missing: Array[String] = []
		for req in required_items:
			var req_key: String = str(req)
			if coverage_hits.has(req_key):
				covered.append(req_key)
			else:
				missing.append(req_key)
				missing_coverage.append("%s:%s" % [str(section_name), req_key])
		coverage[str(section_name)] = {"ok": missing.is_empty(), "covered": covered, "missing": missing, "object_ids": []}
	var summary: Dictionary = {"total_objects": mission_world_objects.size(), "total_items": item_ids.size(), "missing_coverage_count": missing_coverage.size()}
	var ok: bool = missing_coverage.is_empty() and invalid_links.is_empty() and unexpected_runtime_warnings.is_empty() and duplicate_cell_warnings.is_empty()
	notes.append("Expected invalid links are represented explicitly and do not count as valid.")
	return {"ok": ok, "summary": summary, "coverage": coverage, "missing_coverage": missing_coverage, "valid_links": valid_links, "invalid_links": invalid_links, "expected_invalid_links": expected_invalid_links, "expected_runtime_warnings": expected_runtime_warnings, "unexpected_runtime_warnings": unexpected_runtime_warnings, "runtime_cell_warnings": runtime_cell_warnings, "duplicate_cell_warnings": duplicate_cell_warnings, "objects_without_audit_tags": objects_without_audit_tags, "notes": notes}

func get_task_test_system_audit_report_text() -> String:
	var report: Dictionary = get_task_test_system_audit_report()
	var lines: Array[String] = []
	lines.append("TASK TEST SYSTEM AUDIT")
	lines.append("OK: %s" % str(report.get("ok", false)))
	lines.append("")
	lines.append("Coverage:")
	for section_name in ["movement","doors","keys","power","control","cooling","terminals","wall_materials","scan_visibility","runtime_cell_state","extraction"]:
		var section: Dictionary = Dictionary(Dictionary(report.get("coverage", {})).get(section_name, {}))
		lines.append("- %s: %s missing=%s" % [section_name.capitalize(), "OK" if bool(section.get("ok", false)) else "MISSING", JSON.stringify(section.get("missing", []))])
	lines.append("Invalid links:")
	for row in Array(report.get("invalid_links", [])):
		lines.append("- %s" % JSON.stringify(row))
	lines.append("Expected invalid samples:")
	for row in Array(report.get("expected_invalid_links", [])):
		lines.append("- %s" % JSON.stringify(row))
	for warning in Array(report.get("expected_runtime_warnings", [])):
		lines.append("- %s" % str(warning))
	lines.append("Runtime cell warnings:")
	for warning in Array(report.get("unexpected_runtime_warnings", [])):
		lines.append("- %s" % str(warning))
	lines.append("Objects without audit tags:")
	for object_id in Array(report.get("objects_without_audit_tags", [])):
		lines.append("- %s" % str(object_id))
	return "\n".join(lines)

func validate_task_test_runtime_cell_states() -> Array[String]:
	var warnings: Array[String] = []
	var task_item_ids: Array[String] = []
	var object_ids := {}
	var power_source_network_ids := {}
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var existing_object_id := str(object_data.get("id", "")).strip_edges()
		if not existing_object_id.is_empty():
			object_ids[existing_object_id] = true
		var existing_type := str(object_data.get("object_type", "")).to_lower()
		if existing_type.begins_with("power_source"):
			var existing_network_id := str(object_data.get("power_network_id", "")).strip_edges()
			if not existing_network_id.is_empty():
				power_source_network_ids[existing_network_id] = true
	for cell_variant in cell_items.keys():
		for item_variant in Array(cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			task_item_ids.append(str(_safe_dictionary(item_variant).get("id", "")))
	for object_data in mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var object_id: String = str(object_data.get("id", ""))
		var _object_type: String = str(object_data.get("object_type", "")).to_lower()
		var cell: Vector2i = Vector2i(object_data.get("position", Vector2i.ZERO))
		var runtime_state: Dictionary = get_runtime_cell_state(cell)
		if not bool(runtime_state.get("has_object", false)):
			warnings.append("object_exists_but_runtime_has_no_object_%s" % object_id)
		var state_name: String = str(object_data.get("state", "")).to_lower()
		var canonical_open: bool = state_name == "open" or state_name == "opened" or bool(object_data.get("is_open", false))
		var is_door_object: bool = bool(runtime_state.get("is_door_object", false))
		var is_door: bool = bool(runtime_state.get("is_door_cell", false))
		if is_door_object and canonical_open and not bool(runtime_state.get("is_passable", false)):
			warnings.append("door_open_not_passable_%s" % object_id)
		var blocked_door_state: bool = state_name in ["closed", "locked", "unpowered", "damaged", "broken", "destroyed"] or bool(object_data.get("is_locked", false))
		if is_door_object and blocked_door_state and bool(runtime_state.get("is_passable", false)):
			warnings.append("door_closed_or_locked_but_passable_%s" % object_id)
		if is_door_object:
			var tile_type_value: int = int(runtime_state.get("tile_type", -1))
			if tile_type_value == GridManager.TILE_WALL or tile_type_value == GridManager.TILE_FLOOR or tile_type_value == GridManager.TILE_EXIT:
				warnings.append("door_object_on_non_door_tile_%s" % object_id)
			if not bool(runtime_state.get("is_door_cell", false)):
				warnings.append("door_object_tile_mismatch_%s" % object_id)
		if bool(object_data.get("requires_external_power", false)):
			var power_network_id: String = str(object_data.get("power_network_id", "")).strip_edges()
			if power_network_id.is_empty():
				warnings.append("external_power_missing_network_%s" % object_id)
			elif not power_source_network_ids.has(power_network_id):
				warnings.append("external_power_invalid_network_%s_%s" % [object_id, power_network_id])
		if bool(object_data.get("requires_external_control", false)):
			var ctrl: String = str(object_data.get("control_source_id", object_data.get("linked_terminal_id", object_data.get("controller_id", "")))).strip_edges()
			if ctrl.is_empty():
				warnings.append("external_control_missing_reference_%s" % object_id)
			elif not object_ids.has(ctrl):
				warnings.append("external_control_invalid_reference_%s_%s" % [object_id, ctrl])
		for control_ref_field in ["control_source_id", "linked_terminal_id", "controller_id"]:
			var control_ref_id: String = str(object_data.get(control_ref_field, "")).strip_edges()
			if control_ref_id.is_empty():
				continue
			if not object_ids.has(control_ref_id):
				warnings.append("external_control_invalid_reference_%s_%s" % [object_id, control_ref_id])
		var target_door_id: String = str(object_data.get("target_door_id", "")).strip_edges()
		if not target_door_id.is_empty() and not object_ids.has(target_door_id):
			warnings.append("target_door_missing_%s_%s" % [object_id, target_door_id])
		var target_platform_id: String = str(object_data.get("target_platform_id", "")).strip_edges()
		if not target_platform_id.is_empty() and not object_ids.has(target_platform_id):
			warnings.append("target_platform_missing_%s_%s" % [object_id, target_platform_id])
		var linked_terminal_id: String = str(object_data.get("linked_terminal_id", "")).strip_edges()
		if not linked_terminal_id.is_empty() and not object_ids.has(linked_terminal_id):
			warnings.append("linked_terminal_missing_%s_%s" % [object_id, linked_terminal_id])
		var access_type: String = WorldObjectCatalogRef.normalize_access_type(object_data.get("access_type", object_data.get("lock_type", "")))
		if (bool(object_data.get("requires_key", false)) or access_type in [WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD, WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY]) and str(object_data.get("required_key_id", "")).is_empty():
			warnings.append("key_locked_door_missing_required_key_%s" % object_id)
		var required_key_id: String = str(object_data.get("required_key_id", ""))
		if not required_key_id.is_empty() and not task_item_ids.has(required_key_id):
			warnings.append("required_key_not_in_task_items_%s_%s" % [object_id, required_key_id])
		if bool(object_data.get("blocks_movement", false)) and bool(runtime_state.get("is_passable", false)) and not (is_door and canonical_open):
			warnings.append("blocking_object_marked_passable_%s" % object_id)
	return warnings


func validate_task_test_universal_systems_coverage() -> Array[String]:
	return validate_task_test_system_audit()

func validate_task_test_system_audit() -> Array[String]:
	var warnings: Array[String] = []
	var report: Dictionary = get_task_test_system_audit_report()
	warnings.append_array(Array(report.get("missing_coverage", [])))
	for row in Array(report.get("invalid_links", [])):
		warnings.append("unexpected_invalid_link_%s" % JSON.stringify(row))
	warnings.append_array(Array(report.get("runtime_cell_warnings", [])))
	warnings.append_array(Array(report.get("duplicate_cell_warnings", [])))
	var expected_neutral: Dictionary = {"task_test_scan_normal_visible":true}
	for object_id in Array(report.get("objects_without_audit_tags", [])):
		var tagless_id: String = str(object_id)
		if not expected_neutral.has(tagless_id):
			warnings.append("object_without_audit_tags_%s" % tagless_id)
	return warnings

func get_task_test_mission_validation_text() -> String:
	var warnings: Array[String] = validate_task_test_mission_runtime()
	var base_text: String = "TaskTestValidation: ok"
	if not warnings.is_empty():
		base_text = "TaskTestValidation:\n- " + "\n- ".join(warnings)
	var audit: Dictionary = get_task_test_system_audit_report()
	var audit_summary: String = "Audit: ok=%s missing=%d invalid_links=%d runtime_warnings=%d" % [
		str(audit.get("ok", false)),
		Array(audit.get("missing_coverage", [])).size(),
		Array(audit.get("invalid_links", [])).size(),
		Array(audit.get("runtime_cell_warnings", [])).size()
	]
	return base_text + "\n" + audit_summary




func _build_task_test_module_port_specs() -> Array[Dictionary]:
	# TASK TEST module-port scenario data shared across validation checks.
	return [
		{"id":"task_test_internal_interface_v1","module_id":"internal_interface_v1"},
		{"id":"task_test_external_interface_v1","module_id":"external_interface_v1"},
		{"id":"task_test_power_block_v1","module_id":"power_block_v1"},
		{"id":"task_test_processor_v1","module_id":"processor_v1"},
		{"id":"task_test_processor_v2","module_id":"processor_v2"},
		{"id":"task_test_wired_connector_v1","module_id":"wired_connector_v1"},
		{"id":"task_test_optical_connector_v1","module_id":"optical_connector_v1"},
		{"id":"task_test_extra_external_tool","module_id":"repair_v1"},
		{"id":"task_test_battery_v1","module_id":"battery_v1"},
		{"id":"task_test_cooler_v1","module_id":"cooler_v1"},
		{"id":"task_test_radiator_v1","module_id":"radiator_v1"}
	]

func _simulate_task_test_port_state(specs: Array[Dictionary], active_module_ids: Array[String], internal_ports_total: int, external_ports_total: int, power_ports_total: int) -> Dictionary:
	# Static fallback simulation kept for compatibility/safety when runtime mutation is unavailable.
	var modules: Dictionary = {}
	var sorted_specs := specs.duplicate()
	sorted_specs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := int(active_bipob_ref.call("_get_module_port_priority", str(a.get("module_id", ""))))
		var pb := int(active_bipob_ref.call("_get_module_port_priority", str(b.get("module_id", ""))))
		if pa == pb:
			return str(a.get("id", "")) < str(b.get("id", ""))
		return pa < pb
	)
	var internal_remaining := maxi(0, internal_ports_total)
	var external_remaining := maxi(0, external_ports_total)
	var power_remaining := maxi(0, power_ports_total)
	for spec in sorted_specs:
		var tid := str(spec.get("id", ""))
		var module_id := str(spec.get("module_id", ""))
		if not active_module_ids.has(tid):
			modules[tid] = {"id":tid,"active":false,"inactive_reason":"module_not_installed","port_priority":int(active_bipob_ref.call("_get_module_port_priority", module_id))}
			continue
		var needs_internal := bool(active_bipob_ref.call("_module_requires_internal_interface_port", module_id))
		var needs_external := bool(active_bipob_ref.call("_module_requires_external_interface_port", module_id))
		var needs_power := bool(active_bipob_ref.call("_module_requires_power_block_port", module_id))
		var active := true
		var reason := "ok"
		if needs_internal and internal_remaining <= 0:
			active = false
			reason = "internal_interface_port_missing"
		elif needs_external and external_remaining <= 0:
			active = false
			reason = "external_interface_port_missing"
		elif needs_power and power_remaining <= 0:
			active = false
			reason = "power_block_port_missing"
		if active:
			if needs_internal:
				internal_remaining -= 1
			if needs_external:
				external_remaining -= 1
			if needs_power:
				power_remaining -= 1
		modules[tid] = {"id":tid,"active":active,"inactive_reason":reason,"port_priority":int(active_bipob_ref.call("_get_module_port_priority", module_id))}
	return {"modules":modules, "internal_remaining":internal_remaining, "external_remaining":external_remaining, "power_remaining":power_remaining}

func _active_bipob_has_property(property_name: String) -> bool:
	if active_bipob_ref == null:
		return false
	for property_info in Array(active_bipob_ref.get_property_list()):
		if str(Dictionary(property_info).get("name", "")) == property_name:
			return true
	return false

func _snapshot_installed_modules_for_validation() -> Dictionary:
	if not _active_bipob_has_property("installed_modules"):
		return {"ok": false, "reason": "installed_modules_unavailable"}
	return {"ok": true, "installed_modules": Array(active_bipob_ref.installed_modules).duplicate()}

func _restore_installed_modules_from_snapshot(snapshot: Dictionary) -> bool:
	if not bool(snapshot.get("ok", false)) or not _active_bipob_has_property("installed_modules"):
		return false
	active_bipob_ref.installed_modules = Array(snapshot.get("installed_modules", [])).duplicate()
	return true

func _is_internal_runtime_module_id(module_id: String) -> bool:
	for prefix in ["internal_interface_","external_interface_","power_block_","processor_","memory_","gpu_","hard_drive_","charger_","battery_","cooler_","radiator_","water_tube_","air_duct_"]:
		if module_id.begins_with(prefix):
			return true
	return false

func _build_runtime_modules_by_id(module_ids: Array[String]) -> Array:
	var modules: Array = []
	for module_id in module_ids:
		var module = null
		if _is_internal_runtime_module_id(module_id):
			module = active_bipob_ref.call("create_internal_module", module_id, module_id, Vector3i.ONE)
		else:
			module = active_bipob_ref.call("create_external_module_by_id", module_id)
		if module == null:
			return []
		modules.append(module)
	return modules

func _preview_module_port_activity_for_module_ids(module_ids: Array[String]) -> Dictionary:
	var snapshot := _snapshot_installed_modules_for_validation()
	if not bool(snapshot.get("ok", false)):
		return {"ok": false, "reason": str(snapshot.get("reason", "snapshot_failed"))}
	var runtime_modules := _build_runtime_modules_by_id(module_ids)
	if runtime_modules.is_empty() and not module_ids.is_empty():
		_restore_installed_modules_from_snapshot(snapshot)
		return {"ok": false, "reason": "create_test_modules_failed"}
	active_bipob_ref.installed_modules = runtime_modules
	var state: Dictionary = active_bipob_ref.call("preview_module_port_activity")
	var restored := _restore_installed_modules_from_snapshot(snapshot)
	if not restored:
		return {"ok": false, "reason": "restore_failed", "state": state}
	return {"ok": true, "state": state}

func validate_module_port_network_runtime() -> Array[String]:
	var warnings: Array[String] = []
	if active_bipob_ref == null or not active_bipob_ref.has_method("preview_module_port_activity"):
		return ["active_bipob_missing"]
	for helper_name in ["_get_module_port_priority", "_module_requires_external_interface_port", "_module_requires_internal_interface_port", "_module_requires_power_block_port", "create_external_module_by_id", "create_internal_module"]:
		if not active_bipob_ref.has_method(helper_name):
			warnings.append("module_ports_helper_missing_%s" % helper_name)
	if warnings.any(func(warning: String) -> bool: return warning.begins_with("module_ports_helper_missing_")):
		return warnings

	var baseline: Dictionary = active_bipob_ref.call("preview_module_port_activity")
	for key in ["modules", "internal_interface", "external_interface", "power_block"]:
		if not baseline.has(key):
			warnings.append("module_ports_missing_%s" % key)
	if not active_bipob_ref.has_method("get_module_port_debug_report"):
		warnings.append("module_ports_debug_report_missing")
	if not active_bipob_ref.has_method("get_module_port_debug_report_text"):
		warnings.append("module_ports_debug_report_text_missing")
	if warnings.has("module_ports_debug_report_missing") or warnings.has("module_ports_debug_report_text_missing"):
		return warnings
	var debug_report_a: Dictionary = Dictionary(active_bipob_ref.call("get_module_port_debug_report"))
	var debug_report_b: Dictionary = Dictionary(active_bipob_ref.call("get_module_port_debug_report"))
	for report_key in ["internal_ports_total", "internal_ports_used", "internal_ports_remaining", "external_ports_total", "external_ports_used", "external_ports_remaining", "power_ports_total", "power_ports_used", "power_ports_remaining", "active_modules", "inactive_modules", "modules"]:
		if not debug_report_a.has(report_key):
			warnings.append("module_ports_debug_report_missing_%s" % report_key)
	var debug_text: String = str(active_bipob_ref.call("get_module_port_debug_report_text"))
	if debug_text.strip_edges().is_empty():
		warnings.append("module_ports_debug_report_text_empty")
	if str(debug_report_a) != str(debug_report_b):
		warnings.append("module_ports_debug_report_not_read_only")
	var internal_ports_total: int = int(debug_report_a.get("internal_ports_total", 0))
	var internal_ports_used: int = int(debug_report_a.get("internal_ports_used", 0))
	var internal_ports_remaining: int = int(debug_report_a.get("internal_ports_remaining", 0))
	if internal_ports_remaining != maxi(0, internal_ports_total - internal_ports_used):
		warnings.append("module_ports_debug_report_internal_accounting_mismatch")
	var external_ports_total: int = int(debug_report_a.get("external_ports_total", 0))
	var external_ports_used: int = int(debug_report_a.get("external_ports_used", 0))
	var external_ports_remaining: int = int(debug_report_a.get("external_ports_remaining", 0))
	if external_ports_remaining != maxi(0, external_ports_total - external_ports_used):
		warnings.append("module_ports_debug_report_external_accounting_mismatch")
	var power_ports_total: int = int(debug_report_a.get("power_ports_total", 0))
	var power_ports_used: int = int(debug_report_a.get("power_ports_used", 0))
	var power_ports_remaining: int = int(debug_report_a.get("power_ports_remaining", 0))
	if power_ports_remaining != maxi(0, power_ports_total - power_ports_used):
		warnings.append("module_ports_debug_report_power_accounting_mismatch")
	var external_interface_link_ports_reserved: int = int(debug_report_a.get("external_interface_link_ports_reserved", 0))
	if external_interface_link_ports_reserved > 0 and external_ports_used < external_interface_link_ports_reserved:
		warnings.append("module_ports_debug_report_external_reserved_accounting_mismatch")
	var internal_interface_link_ports_reserved: int = int(debug_report_a.get("internal_interface_link_ports_reserved", 0))
	if internal_interface_link_ports_reserved > 0 and internal_ports_used < internal_interface_link_ports_reserved:
		warnings.append("module_ports_debug_report_internal_reserved_accounting_mismatch")

	var _known_reason_keys := ["ok","connector_missing","connector_level_too_low","processor_missing","processor_level_too_low","internal_interface_missing","internal_interface_port_missing","internal_interface_link_missing","external_interface_missing","external_interface_port_missing","external_interface_link_missing","power_block_missing","power_block_port_missing","power_block_link_missing","power_block_overloaded","module_installed_but_inactive","module_not_installed"]
	var observed_runtime_reason_keys: Dictionary = {}
	var scenarios := [
		{"id":"processor_active","modules":["internal_interface_v1","power_block_v1","processor_v1"],"module":"processor_v1","active":true,"reason":"ok"},
		{"id":"memory_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","memory_v1"],"module":"memory_v1","active":true,"reason":"ok"},
		{"id":"gpu_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","gpu_v1"],"module":"gpu_v1","active":true,"reason":"ok"},
		{"id":"hard_drive_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","hard_drive_v1"],"module":"hard_drive_v1","active":true,"reason":"ok"},
		{"id":"charger_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","charger_v1"],"module":"charger_v1","active":true,"reason":"ok"},
		{"id":"cooler_active_without_external_interface","modules":["internal_interface_v1","power_block_v1","cooler_v1"],"module":"cooler_v1","active":true,"reason":"ok"},
		{"id":"connector_active","modules":["internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1","active":true,"reason":"ok"},
		{"id":"external_interface_missing","modules":["internal_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1","active":false,"reason":"external_interface_missing"},
		{"id":"external_interface_port_missing","modules":["internal_interface_v1","internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","visor_v1","radar_v1"],"module":"radar_v1","active":false,"reason":"external_interface_port_missing"},
		{"id":"internal_interface_missing","modules":["power_block_v1","processor_v1"],"module":"processor_v1","active":false,"reason":"internal_interface_missing"},
		{"id":"internal_interface_port_missing","modules":["internal_interface_v1","power_block_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","cooler_v1"],"module":"cooler_v1","active":false,"reason":"internal_interface_port_missing"},
		{"id":"power_block_missing","modules":["internal_interface_v1","battery_v1"],"module":"battery_v1","active":false,"reason":"power_block_missing"},
		{"id":"power_block_port_missing","modules":["internal_interface_v1","internal_interface_v1","power_block_v1","external_interface_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","charger_v1","cooler_v1","gpu_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","manipulator_arm_v1","visor_v1","radar_v1"],"module":"manipulator_arm_v1","active":false,"reason":"power_block_port_missing"},
		{"id":"radiator_no_internal_or_power","modules":["radiator_v1"],"module":"radiator_v1","active":true,"reason":"ok"},
		{"id":"battery_no_internal_required","modules":["power_block_v1","battery_v1"],"module":"battery_v1","active":true,"reason":"ok"},
		{"id":"power_block_requires_internal_interface","modules":["power_block_v1"],"module":"power_block_v1","active":false,"reason":"internal_interface_missing"},
		{"id":"power_block_active_with_internal_interface","modules":["internal_interface_v1","power_block_v1"],"module":"power_block_v1","active":true,"reason":"ok"},
		{"id":"internal_interface_v1_capacity","modules":["internal_interface_v1"],"internal_ports_total":6},
		{"id":"priority_tie","modules":["internal_interface_v1","power_block_v1","processor_v1","memory_v1","gpu_v1","hard_drive_v1","charger_v1","cooler_v1","processor_v2"],"priority":true}
	]

	for scenario in scenarios:
		var runtime: Dictionary = _preview_module_port_activity_for_module_ids(Array(scenario.get("modules", [])))
		if not bool(runtime.get("ok", false)):
			warnings.append("module_ports_runtime_preview_unavailable_%s" % str(runtime.get("reason", "unknown")))
			break
		var state: Dictionary = Dictionary(runtime.get("state", {}))
		var modules: Dictionary = Dictionary(state.get("modules", {}))
		if scenario.has("internal_ports_total"):
			var internal_interface_state := Dictionary(state.get("internal_interface", {}))
			if int(internal_interface_state.get("ports_total", -1)) != int(scenario.get("internal_ports_total", -1)):
				warnings.append("module_ports_internal_interface_capacity_mismatch_%s" % str(scenario.get("id", "")))
			continue
		if bool(scenario.get("priority", false)):
			var p1 := Dictionary(modules.get("processor_v1", {}))
			var p2 := Dictionary(modules.get("processor_v2", {}))
			var p1_active := bool(p1.get("active", false))
			var p2_active := bool(p2.get("active", false))
			if p1_active and p2_active:
				continue
			if p1_active == p2_active:
				warnings.append("task_test_processor_priority_tie_break_not_deterministic")
				continue
			if not p1_active and p2_active:
				warnings.append("task_test_processor_priority_tie_break_unstable_order")
			continue
		var module_id := str(scenario.get("module", ""))
		var module_state: Dictionary = Dictionary(modules.get(module_id, {}))
		if module_state.is_empty():
			warnings.append("module_not_installed")
			continue
		var expected_active := bool(scenario.get("active", false))
		var expected_reason := str(scenario.get("reason", "ok"))
		if bool(module_state.get("active", false)) != expected_active:
			warnings.append("module_ports_runtime_active_mismatch_%s" % str(scenario.get("id", "")))
		var actual_reason := str(module_state.get("inactive_reason", "module_installed_but_inactive"))
		observed_runtime_reason_keys[actual_reason] = true
		if actual_reason != expected_reason:
			warnings.append("module_ports_runtime_reason_mismatch_%s_%s" % [str(scenario.get("id", "")), actual_reason])
	return warnings

func _get_module_port_reason_coverage_gaps() -> Array[String]:
	if active_bipob_ref == null or not active_bipob_ref.has_method("preview_module_port_activity"):
		return []
	for helper_name in ["_get_module_port_priority", "_module_requires_external_interface_port", "_module_requires_internal_interface_port", "_module_requires_power_block_port", "create_external_module_by_id", "create_internal_module"]:
		if not active_bipob_ref.has_method(helper_name):
			return []

	var known_reason_keys := ["ok","connector_missing","connector_level_too_low","processor_missing","processor_level_too_low","internal_interface_missing","internal_interface_port_missing","internal_interface_link_missing","external_interface_missing","external_interface_port_missing","external_interface_link_missing","power_block_missing","power_block_port_missing","power_block_link_missing","power_block_overloaded","module_installed_but_inactive","module_not_installed"]
	var observed_runtime_reason_keys: Dictionary = {}
	var scenarios := [
		{"modules":["internal_interface_v1","power_block_v1","processor_v1"],"module":"processor_v1"},
		{"modules":["internal_interface_v1","power_block_v1","memory_v1"],"module":"memory_v1"},
		{"modules":["internal_interface_v1","power_block_v1","gpu_v1"],"module":"gpu_v1"},
		{"modules":["internal_interface_v1","power_block_v1","hard_drive_v1"],"module":"hard_drive_v1"},
		{"modules":["internal_interface_v1","power_block_v1","charger_v1"],"module":"charger_v1"},
		{"modules":["internal_interface_v1","power_block_v1","cooler_v1"],"module":"cooler_v1"},
		{"modules":["internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1"},
		{"modules":["internal_interface_v1","power_block_v1","external_interface_connector_v1"],"module":"external_interface_connector_v1"},
		{"modules":["internal_interface_v1","internal_interface_v1","external_interface_v1","power_block_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","visor_v1","radar_v1"],"module":"radar_v1"},
		{"modules":["power_block_v1","processor_v1"],"module":"processor_v1"},
		{"modules":["internal_interface_v1","power_block_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","cooler_v1"],"module":"cooler_v1"},
		{"modules":["internal_interface_v1","battery_v1"],"module":"battery_v1"},
		{"modules":["internal_interface_v1","internal_interface_v1","power_block_v1","external_interface_v1","processor_v1","processor_v2","processor_v3","memory_v1","memory_v2","memory_v3","hard_drive_v1","charger_v1","cooler_v1","gpu_v1","external_interface_connector_v1","optical_connector_v1","wireless_connector_v1","high_bandwidth_connector_v1","manipulator_arm_v1","visor_v1","radar_v1"],"module":"manipulator_arm_v1"},
		{"modules":["radiator_v1"],"module":"radiator_v1"},
		{"modules":["power_block_v1","battery_v1"],"module":"battery_v1"},
		{"modules":["power_block_v1"],"module":"power_block_v1"},
		{"modules":["internal_interface_v1","power_block_v1"],"module":"power_block_v1"},
	]
	for scenario in scenarios:
		var runtime := _preview_module_port_activity_for_module_ids(Array(scenario.get("modules", [])))
		if not bool(runtime.get("ok", false)):
			return []
		var state: Dictionary = Dictionary(runtime.get("state", {}))
		var module_id := str(scenario.get("module", ""))
		var module_state: Dictionary = Dictionary(Dictionary(state.get("modules", {})).get(module_id, {}))
		if module_state.is_empty():
			continue
		var actual_reason := str(module_state.get("inactive_reason", "module_installed_but_inactive"))
		observed_runtime_reason_keys[actual_reason] = true

	var gaps: Array[String] = []
	for reason_key in known_reason_keys:
		if not observed_runtime_reason_keys.has(reason_key):
			gaps.append("module_port_reason_key_coverage_gap_%s" % reason_key)
	return gaps

func get_module_port_reason_coverage_gap_text() -> String:
	var gaps := _get_module_port_reason_coverage_gaps()
	return "ModulePortReasonCoverage: complete" if gaps.is_empty() else "ModulePortReasonCoverage:\n- " + "\n- ".join(gaps)

func get_module_port_network_validation_text() -> String:
	var warnings := validate_module_port_network_runtime()
	var coverage_gaps := _get_module_port_reason_coverage_gaps()
	var lines: Array[String] = ["ModulePortNetworkValidation: ok" if warnings.is_empty() else "ModulePortNetworkValidation:"]
	if not warnings.is_empty():
		lines.append("- " + "\n- ".join(warnings))
	if not coverage_gaps.is_empty():
		lines.append("Coverage gaps (informational):")
		lines.append("- " + "\n- ".join(coverage_gaps))
	if active_bipob_ref != null and active_bipob_ref.has_method("get_module_port_debug_report_text"):
		lines.append("")
		lines.append(str(active_bipob_ref.call("get_module_port_debug_report_text")))
	return "\n".join(lines)

func validate_connector_processor_migration() -> Array[String]:
	var warnings: Array[String] = []
	var caps := get_actor_capability_levels()
	for key in ["processor_level", "connector_level", "connector_types", "modules", "tools", "port_state"]:
		if not caps.has(key):
			warnings.append("capability_report_missing_%s" % key)
	if caps.has("processor_level") and not (caps["processor_level"] is int):
		warnings.append("capability_report_invalid_processor_level_type")
	if caps.has("connector_level") and not (caps["connector_level"] is int):
		warnings.append("capability_report_invalid_connector_level_type")
	if caps.has("connector_types"):
		if not (caps["connector_types"] is Array):
			warnings.append("capability_report_invalid_connector_types_type")
		else:
			for entry in Array(caps["connector_types"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_connector_types_entry")
					break
	if caps.has("modules"):
		if not (caps["modules"] is Array):
			warnings.append("capability_report_invalid_modules_type")
		else:
			for entry in Array(caps["modules"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_modules_entry")
					break
	if caps.has("tools"):
		if not (caps["tools"] is Array):
			warnings.append("capability_report_invalid_tools_type")
		else:
			for entry in Array(caps["tools"]):
				if not (entry is String):
					warnings.append("capability_report_invalid_tools_entry")
					break
			var tools_array: Array = Array(caps["tools"])
			var non_tool_module_ids := {
				"internal_interface_v1": true,
				"power_block_v1": true,
				"processor_v1": true,
				"memory_v1": true,
				"external_interface_v1": true,
				"external_interface_connector_v1": true
			}
			for entry in tools_array:
				var tool_entry: String = str(entry)
				if non_tool_module_ids.has(tool_entry):
					warnings.append("capability_report_tools_contains_non_tool_module_id_%s" % tool_entry)
					break
	if caps.has("port_state") and not (caps["port_state"] is Dictionary):
		warnings.append("capability_report_invalid_port_state_type")

	var cap_port_state: Dictionary = Dictionary(caps.get("port_state", {}))
	var cap_modules_state: Dictionary = Dictionary(cap_port_state.get("modules", {}))
	var external_connector_active := false
	if cap_modules_state.has("external_interface_connector_v1"):
		external_connector_active = bool(Dictionary(cap_modules_state.get("external_interface_connector_v1", {})).get("active", false))
	if external_connector_active and not Array(caps.get("connector_types", [])).has("physical"):
		warnings.append("capability_report_missing_physical_connector_type_for_external_interface")
	for legacy_key in ["cpu_level", "required_cpu_level", "interface_level", "required_interface_level"]:
		if caps.has(legacy_key):
			warnings.append("capability_report_uses_legacy_%s" % legacy_key)

	var task: Dictionary = build_task_test_sandbox_world_objects_for_validation()
	for obj in Array(task.get("objects", [])):
		var obj_dict: Dictionary = Dictionary(obj)
		var obj_id: String = str(obj_dict.get("id", ""))
		if not obj_id.begins_with("task_test_terminal"):
			continue
		if obj_dict.has("required_interface_level"):
			warnings.append("task_test_uses_required_interface_level")
		if obj_dict.has("required_cpu_level"):
			warnings.append("task_test_uses_required_cpu_level")
		if not obj_dict.has("required_connector_level"):
			warnings.append("task_test_terminal_missing_required_connector_level")
		if not obj_dict.has("required_processor_level") and str(obj_dict.get("state", "")).to_lower() not in ["damaged", "unpowered"]:
			warnings.append("task_test_terminal_missing_required_processor_level")

	if active_bipob_ref != null and active_bipob_ref.has_method("get_world_action_module"):
		var module: Dictionary = Dictionary(active_bipob_ref.call("get_world_action_module", "connect", {"connection_type":"wired"}))
		if not str(Dictionary(module).get("id", "")).contains("_connector_v"):
			warnings.append("connect_action_not_connector_id")

	var req: Dictionary = get_terminal_hack_requirements("task_test_terminal_main")
	for key in ["required_connector_level", "required_processor_level", "available_connector_level", "available_processor_level"]:
		if not req.has(key):
			warnings.append("terminal_requirements_missing_%s" % key)
	for legacy_key in ["required_cpu_level", "required_interface_level", "cpu_level", "interface_level"]:
		if req.has(legacy_key):
			warnings.append("terminal_requirements_uses_legacy_%s" % legacy_key)
	if req.is_empty():
		warnings.append("terminal_requirements_empty")
	elif active_bipob_ref != null and (int(caps.get("connector_level", 0)) > 0 or int(caps.get("processor_level", 0)) > 0):
		if int(req.get("available_connector_level", 0)) <= 0 and int(caps.get("connector_level", 0)) > 0:
			warnings.append("terminal_available_connector_level_zero_with_modules")
		if int(req.get("available_processor_level", 0)) <= 0 and int(caps.get("processor_level", 0)) > 0:
			warnings.append("terminal_available_processor_level_zero_with_modules")
	return warnings

func get_connector_processor_migration_validation_text() -> String:
	var warnings := validate_connector_processor_migration()
	return "ConnectorProcessorMigrationValidation: ok" if warnings.is_empty() else "ConnectorProcessorMigrationValidation:
- " + "
- ".join(warnings)

func _to_stable_validation_summary(value: Variant) -> String:
	if value == null:
		return "null"
	if value is Dictionary:
		var dict_value: Dictionary = Dictionary(value)
		var keys: Array[String] = []
		for key_variant in dict_value.keys():
			keys.append(str(key_variant))
		keys.sort()
		var parts: Array[String] = []
		for key in keys:
			parts.append("%s:%s" % [key, _to_stable_validation_summary(dict_value.get(key, null))])
		return "{%s}" % ",".join(parts)
	if value is Array:
		var arr_value: Array = Array(value)
		var items: Array[String] = []
		for item in arr_value:
			items.append(_to_stable_validation_summary(item))
		return "[%s]" % ",".join(items)
	return str(value)

func _build_developer_validation_runtime_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	snapshot["mission_id"] = "unavailable"
	snapshot["mission_state"] = "unavailable"
	snapshot["world_objects"] = _to_stable_validation_summary(mission_world_objects)
	snapshot["inventory"] = _to_stable_validation_summary(runtime_inventory_state)
	snapshot["cell_items"] = _to_stable_validation_summary(cell_items)
	if active_bipob_ref != null and _active_bipob_has_property("installed_modules"):
		snapshot["installed_modules"] = _to_stable_validation_summary(active_bipob_ref.installed_modules)
	else:
		snapshot["installed_modules"] = "unavailable"
	if active_bipob_ref != null and active_bipob_ref.has_method("preview_module_port_activity"):
		snapshot["port_state"] = _to_stable_validation_summary(active_bipob_ref.call("preview_module_port_activity"))
	else:
		snapshot["port_state"] = "unavailable"
	snapshot["capability_report"] = _to_stable_validation_summary(get_actor_capability_levels())
	var task_state: Dictionary = {}
	var property_names: Dictionary = {}
	for property_data in get_property_list():
		var property_dict: Dictionary = Dictionary(property_data)
		var property_name: String = str(property_dict.get("name", ""))
		if property_name.is_empty():
			continue
		property_names[property_name] = true
	for task_field in ["task_test_started", "task_test_completed", "task_test_failed", "task_test_turns_left", "task_test_auto_seeded", "task_test_progress", "task_test_state"]:
		if property_names.has(task_field):
			task_state[task_field] = get(task_field)
	snapshot["task_state"] = _to_stable_validation_summary(task_state)
	return snapshot


func get_developer_systems_logic_audit() -> Dictionary:
	var systems: Array[Dictionary] = [
		{
			"id":"power",
			"display_name":"Power",
			"status":"implemented",
			"has_runtime_logic":true,
			"has_validation":true,
			"has_task_test_coverage":true,
			"related_validation_suite":"power",
			"notes":["Power graph, sources, consumers, and propagation are validated in developer suites."],
			"gaps":[]
		},
		{"id":"cooling","display_name":"Cooling","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"cooling_cable","notes":["Cooling runtime behavior is covered together with cable flow checks."],"gaps":[]},
		{"id":"cable_socket_reel","display_name":"Cable / Socket / Cable Reel","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"cooling_cable","notes":["Cable connectivity, socket linking, and reel interactions are checked by runtime validation."],"gaps":[]},
		{"id":"terminal_hacking","display_name":"Terminal / Hacking","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"terminal_door","notes":["Terminal operations and access interactions are included in terminal/door checks."],"gaps":[]},
		{"id":"doors_access","display_name":"Doors / Access","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"terminal_door","notes":["Door lock/access behavior is covered by runtime door validation."],"gaps":[]},
		{"id":"inventory_items","display_name":"Inventory / Items","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"inventory_tools_modules","notes":["Inventory and item interactions are checked in inventory/tools/modules suite."],"gaps":[]},
		{"id":"tools_modules","display_name":"Tools / Modules","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"inventory_tools_modules","notes":["Tool usage and module workflows have runtime validation coverage."],"gaps":[]},
		{"id":"module_ports","display_name":"Module Ports","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"module_ports","notes":["Module port activation and network mapping are validated."],"gaps":[]},
		{"id":"connector_processor_requirements","display_name":"Connector / Processor Requirements","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"connector_processor_migration","notes":["Connector/processor migration and requirements are validated."],"gaps":[]},
		{"id":"platforms","display_name":"Platforms","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"platform_scan_visibility","notes":["Platform activation, timing, and gating are covered in runtime validation."],"gaps":[]},
		{"id":"scan_visibility_xray","display_name":"Scan / Visibility / X-Ray","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"platform_scan_visibility","notes":["Scanning and visibility logic are covered alongside platform validation."],"gaps":[]},
		{"id":"persistence","display_name":"Persistence","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":false,"related_validation_suite":"persistence","notes":["Runtime persistence consistency is validated."],"gaps":["persistence_task_test_coverage_missing"]},
		{"id":"task_test","display_name":"TASK TEST","status":"implemented","has_runtime_logic":true,"has_validation":true,"has_task_test_coverage":true,"related_validation_suite":"task_test","notes":["TASK TEST scenario and mission checks are part of developer validation."],"gaps":[]},
		{"id":"extraction","display_name":"Extraction","status":"partial","has_runtime_logic":true,"has_validation":false,"has_task_test_coverage":true,"related_validation_suite":"","notes":["Extraction flow exists but is not represented as a dedicated validation suite yet."],"gaps":["extraction_validation_missing"]},
		{"id":"visual_isometric_floor_walls_objects","display_name":"Visual Isometric Floor, Walls, Objects","status":"visual_only","has_runtime_logic":false,"has_validation":false,"has_task_test_coverage":false,"related_validation_suite":"","notes":["Rendering layer is visual-first and intentionally decoupled from gameplay mutation logic."],"gaps":["visual_isometric_objects_validation_missing"]}
	]
	return {"systems": systems}

func validate_developer_systems_logic_audit() -> Array[String]:
	var warnings: Array[String] = []
	var report: Dictionary = get_developer_systems_logic_audit()
	var systems: Array = Array(report.get("systems", []))
	if systems.is_empty():
		warnings.append("audit_report_empty")
		return warnings
	var required_fields: Array[String] = ["id", "display_name", "status", "has_runtime_logic", "has_validation", "has_task_test_coverage", "related_validation_suite", "notes", "gaps"]
	var allowed_status: Dictionary = {"implemented":true, "partial":true, "data_only":true, "visual_only":true, "missing":true}
	var ids: Dictionary = {}
	for entry_variant in systems:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			warnings.append("audit_system_missing_required_field_unknown_id")
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var system_id: String = str(entry.get("id", ""))
		if not system_id.is_empty():
			ids[system_id] = true
		for field_name in required_fields:
			if not entry.has(field_name):
				warnings.append("audit_system_missing_required_field_%s_%s" % [system_id, field_name])
		var status: String = str(entry.get("status", ""))
		if not allowed_status.has(status):
			warnings.append("audit_system_invalid_status_%s" % system_id)
	if not ids.has("power"):
		warnings.append("audit_system_missing_power")
	if not ids.has("terminal_hacking"):
		warnings.append("audit_system_missing_terminal")
	if not ids.has("module_ports"):
		warnings.append("audit_system_missing_module_ports")
	if not ids.has("task_test"):
		warnings.append("audit_system_missing_task_test")
	return warnings

func get_developer_systems_logic_audit_text() -> String:
	var report: Dictionary = get_developer_systems_logic_audit()
	var systems: Array = Array(report.get("systems", []))
	var lines: Array[String] = ["DeveloperSystemsLogicAudit:"]
	var gaps: Array[String] = []
	for entry_variant in systems:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var status: String = str(entry.get("status", "missing"))
		var logic_flag: String = "yes" if bool(entry.get("has_runtime_logic", false)) else "no"
		var validation_flag: String = "yes" if bool(entry.get("has_validation", false)) else "no"
		var task_test_flag: String = "yes" if bool(entry.get("has_task_test_coverage", false)) else "no"
		lines.append("- %s: %s logic=%s validation=%s task_test=%s" % [str(entry.get("id", "unknown")), status, logic_flag, validation_flag, task_test_flag])
		for gap_variant in Array(entry.get("gaps", [])):
			var gap_id: String = str(gap_variant)
			if gap_id.is_empty():
				continue
			if gaps.has(gap_id):
				continue
			gaps.append(gap_id)
	if not gaps.is_empty():
		lines.append("")
		lines.append("Gaps:")
		for gap in gaps:
			lines.append("- %s" % gap)
	return "\n".join(lines)

func validate_developer_validation_no_mutation() -> Array[String]:
	var warnings: Array[String] = []
	var baseline: Dictionary = _build_developer_validation_runtime_snapshot()
	get_developer_validation_suite_text("module_ports")
	get_developer_validation_suite_text("connector_processor_migration")
	_get_developer_validation_suite_text_internal("all", false)
	run_developer_validation_suite("module_ports")
	run_developer_validation_suite("connector_processor_migration")
	_run_developer_validation_suite_internal("all", false)
	var after: Dictionary = _build_developer_validation_runtime_snapshot()
	if str(after.get("mission_id", "")) != str(baseline.get("mission_id", "")):
		warnings.append("developer_validation_mutated_mission_id")
	if str(after.get("mission_state", "")) != str(baseline.get("mission_state", "")):
		warnings.append("developer_validation_mutated_mission_state")
	if str(after.get("world_objects", "")) != str(baseline.get("world_objects", "")):
		warnings.append("developer_validation_mutated_world_objects")
	if str(after.get("inventory", "")) != str(baseline.get("inventory", "")):
		warnings.append("developer_validation_mutated_inventory")
	if str(after.get("installed_modules", "")) != str(baseline.get("installed_modules", "")):
		warnings.append("developer_validation_mutated_installed_modules")
	if str(after.get("port_state", "")) != str(baseline.get("port_state", "")):
		warnings.append("developer_validation_mutated_port_state")
	if str(after.get("capability_report", "")) != str(baseline.get("capability_report", "")):
		warnings.append("developer_validation_mutated_capability_report")
	if str(after.get("task_state", "")) != str(baseline.get("task_state", "")):
		warnings.append("developer_validation_mutated_task_state")
	return warnings

func get_developer_validation_no_mutation_text() -> String:
	var warnings: Array[String] = validate_developer_validation_no_mutation()
	if warnings.is_empty():
		return "DeveloperValidationNoMutation: ok"
	return "DeveloperValidationNoMutation:\n- " + "\n- ".join(warnings)

func run_developer_validation_suite(suite: String = "all") -> Dictionary:
	return _run_developer_validation_suite_internal(suite, true)

func _run_developer_validation_suite_internal(suite: String = "all", include_no_mutation: bool = true) -> Dictionary:
	var suites: Array[String] = ["power", "cooling_cable", "terminal_door", "platform_scan_visibility", "inventory_tools_modules", "persistence", "task_test", "module_ports", "connector_processor_migration", "systems_audit"]
	if include_no_mutation:
		suites.append("no_mutation")
	var selected: Array[String]
	if suite == "all":
		selected = suites
	else:
		selected = [suite]
	var warnings_by_suite: Dictionary = {}
	var suites_run := 0
	for suite_id in selected:
		var warnings: Array[String] = []
		match suite_id:
			"power": warnings = validate_full_power_system_runtime()
			"cooling_cable": warnings = validate_cooling_and_cable_runtime()
			"terminal_door": warnings = validate_terminal_and_door_runtime()
			"platform_scan_visibility": warnings = validate_platform_scan_visibility_runtime()
			"inventory_tools_modules": warnings = validate_inventory_tools_modules_runtime()
			"persistence": warnings = validate_full_runtime_persistence()
			"task_test": warnings = validate_task_test_mission_runtime()
			"module_ports": warnings = validate_module_port_network_runtime()
			"connector_processor_migration": warnings = validate_connector_processor_migration()
			"systems_audit": warnings = validate_developer_systems_logic_audit()
			"no_mutation": warnings = validate_developer_validation_no_mutation()
			_: warnings = ["suite_missing"]
		warnings_by_suite[suite_id] = warnings
		suites_run += 1
	var warnings_count: int = 0
	for k in warnings_by_suite.keys():
		warnings_count += Array(warnings_by_suite[k]).size()
	return {"suite": suite, "suites_run": suites_run, "warnings_count": warnings_count, "warnings_by_suite": warnings_by_suite}

func get_developer_validation_menu_text() -> String:
	return "Validation suites: all, power, cooling_cable, terminal_door, platform_scan_visibility, inventory_tools_modules, persistence, task_test, module_ports, connector_processor_migration, systems_audit, no_mutation"

func get_developer_validation_suite_text(suite: String = "all") -> String:
	return _get_developer_validation_suite_text_internal(suite, true)

func _get_developer_validation_suite_text_internal(suite: String = "all", include_no_mutation: bool = true) -> String:
	if suite == "no_mutation":
		return get_developer_validation_no_mutation_text()
	if suite == "systems_audit":
		return get_developer_systems_logic_audit_text()
	var report: Dictionary = _run_developer_validation_suite_internal(suite, include_no_mutation)
	var lines: Array[String] = ["DeveloperValidation suite=%s suites_run=%d warnings=%d" % [suite, int(report.get("suites_run", 0)), int(report.get("warnings_count", 0))]]
	var by_suite: Dictionary = Dictionary(report.get("warnings_by_suite", {}))
	for suite_id_variant in by_suite.keys():
		var suite_id: String = str(suite_id_variant)
		var suite_warnings: Array = Array(by_suite.get(suite_id_variant, []))
		lines.append("- %s: %d warning(s)" % [suite_id, suite_warnings.size()])
		for warning in suite_warnings:
			lines.append("  • %s" % str(warning))
	return "\n".join(lines)

var _map_constructor_last_kit_snapshot: Dictionary = {}
var _map_constructor_last_template_snapshot: Dictionary = {}

func _map_constructor_transform_template_offset(offset: Vector2i, options: Dictionary = {}) -> Vector2i:
	var transformed: Vector2i = Vector2i(offset)
	if bool(options.get("mirror_x", false)):
		transformed.x = -transformed.x
	if bool(options.get("mirror_y", false)):
		transformed.y = -transformed.y
	var rotation: int = int(options.get("rotation", 0))
	match rotation:
		0:
			return transformed
		90:
			return Vector2i(-transformed.y, transformed.x)
		180:
			return Vector2i(-transformed.x, -transformed.y)
		270:
			return Vector2i(transformed.y, -transformed.x)
		_:
			push_warning("Map constructor template: unsupported rotation=%d; treated as 0." % rotation)
			return transformed

func _map_constructor_filter_entry_rows(entries: Array, warnings: Array[String], removed_missing_ids: Array[String]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	var catalog_ids: Dictionary = {}
	for catalog_row in get_map_constructor_prefab_catalog():
		var catalog_entry: Dictionary = Dictionary(catalog_row)
		catalog_ids[str(catalog_entry.get("id", ""))] = true
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var prefab_id: String = str(entry.get("prefab_id", "")).strip_edges()
		var canonical_prefab_id: String = WorldObjectCatalogRef.canonical_object_type(prefab_id)
		if not catalog_ids.has(prefab_id) and not catalog_ids.has(canonical_prefab_id):
			if not removed_missing_ids.has(prefab_id):
				removed_missing_ids.append(prefab_id)
			continue
		filtered.append(entry)
	if not removed_missing_ids.is_empty():
		warnings.append("Removed missing prefab ids: %s" % ", ".join(removed_missing_ids))
	return filtered

func get_map_constructor_prefab_kits() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "kits": [], "message": "Prefab kits are available only in TASK TEST constructor mode."}
	var kits: Array[Dictionary] = [
		{"id":"locked_door_kit","display_name":"Locked Door Kit","category":"security","description":"Door + terminal + access key.","tags":["door","terminal","key"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"door","offset":Vector2i(0,0),"wall_side":"","properties":{"door_type":"digital","material":"energy","access_type":"access_code"},"link_group":"door_a"},{"prefab_id":"terminal","offset":Vector2i(-1,0),"wall_side":"","properties":{"terminal_type":"control","controlled_target_type":"door"},"link_group":"door_a"},{"prefab_id":"item","offset":Vector2i(-2,0),"wall_side":"","properties":{"item_class":"access_code"},"link_group":""}]},
		{"id":"power_gate_kit","display_name":"Power Gate Kit","category":"power","description":"Power chain to powered gate.","tags":["power","gate"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"power_source_class_1","offset":Vector2i(-2,0),"wall_side":"","properties":{},"link_group":""},{"prefab_id":"power_cable","offset":Vector2i(-1,0),"wall_side":"","properties":{},"link_group":""},{"prefab_id":"power_socket","offset":Vector2i(0,0),"wall_side":"","properties":{},"link_group":""},{"prefab_id":"door","offset":Vector2i(1,0),"wall_side":"","properties":{"door_type":"powered","material":"energy","access_type":"no_key","power_type":"external"},"link_group":""}]},
		{"id":"wall_terminal_kit","display_name":"Wall Terminal Kit","category":"control","description":"Wall-mounted terminal chain.","tags":["wall_mounted","terminal"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"terminal","offset":Vector2i(0,0),"wall_side":"north","properties":{"terminal_type":"control","controlled_target_type":"door"},"link_group":"terminal_group"}]},
		{"id":"diagnostic_device_kit","display_name":"Diagnostic Device Kit","category":"diagnostic","description":"Diagnostic fixtures.","tags":["diagnostic"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"firewall","offset":Vector2i(0,0),"wall_side":"east","properties":{},"link_group":""}]},
		{"id":"expected_invalid_refs_kit","display_name":"Expected Invalid Refs Kit","category":"expected_invalid","description":"Creates expected invalid test rows.","tags":["expected_invalid"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"broken_reference_probe","offset":Vector2i(0,0),"wall_side":"","properties":{},"link_group":""}],"warning":"Some entries unavailable"},
		{"id":"cooling_test_kit","display_name":"Cooling Test Kit","category":"power","description":"Cooling and power test objects.","tags":["cooling","power"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"terminal","offset":Vector2i(0,0),"wall_side":"south","properties":{"terminal_type":"control","controlled_target_type":"cooling"},"link_group":""}]},
		{"id":"control_chain_kit","display_name":"Control Chain Kit","category":"control","description":"Control + power chain.","tags":["control","power"],"default_options":{"allow_overwrite":false},"entries":[{"prefab_id":"circuit_breaker","offset":Vector2i(0,0),"wall_side":"","properties":{},"link_group":"control_a"},{"prefab_id":"light_switch","offset":Vector2i(1,0),"wall_side":"west","properties":{},"link_group":"control_a"}]}
	]
	var filtered_kits: Array[Dictionary] = []
	for kit_variant in kits:
		var kit: Dictionary = Dictionary(kit_variant).duplicate(true)
		var row_warnings: Array[String] = []
		var entries: Array = Array(kit.get("entries", []))
		var removed_missing_ids: Array[String] = []
		kit["entries"] = _map_constructor_filter_entry_rows(entries, row_warnings, removed_missing_ids)
		if not row_warnings.is_empty():
			var existing_warning: String = str(kit.get("warning", "")).strip_edges()
			var joined_warnings: String = "; ".join(row_warnings)
			kit["warning"] = joined_warnings if existing_warning.is_empty() else "%s; %s" % [existing_warning, joined_warnings]
		if Array(kit.get("entries", [])).is_empty():
			continue
		filtered_kits.append(kit)
	return {"ok":true,"kits":filtered_kits,"message":"OK"}

func preview_map_constructor_prefab_kit(kit_id: String, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "kit_id": kit_id, "anchor_cell": anchor_cell, "affected": [], "warnings": [], "conflicts": [], "can_apply": false, "message": "Kit preview is available only in TASK TEST constructor mode."}
	var kits: Array = Array(get_map_constructor_prefab_kits().get("kits", []))
	var kit: Dictionary = {}
	for row in kits:
		if str(row.get("id", "")) == kit_id:
			kit = Dictionary(row)
			break
	if kit.is_empty():
		return {"ok":false,"kit_id":kit_id,"anchor_cell":anchor_cell,"affected":[],"warnings":[],"conflicts":[],"can_apply":false,"message":"Kit not found."}
	var preview: Dictionary = _preview_map_constructor_entry_set(Array(kit.get("entries", [])), anchor_cell, options)
	preview["kit_id"] = kit_id
	return preview

func apply_map_constructor_prefab_kit(kit_id: String, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Kit apply is available only in TASK TEST constructor mode."}
	var kits: Array = Array(get_map_constructor_prefab_kits().get("kits", []))
	var kit: Dictionary = {}
	for row in kits:
		if str(Dictionary(row).get("id", "")) == kit_id:
			kit = Dictionary(row)
			break
	if kit.is_empty():
		return {"ok": false, "message": "Kit not found."}
	_map_constructor_last_kit_snapshot = {"mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true)}
	var apply_result: Dictionary = _apply_map_constructor_entry_set(Array(kit.get("entries", [])), anchor_cell, options)
	if not bool(apply_result.get("ok", false)):
		return apply_result
	var placed: int = int(apply_result.get("placed_count", 0))
	_record_map_constructor_change("kit", {"summary":"Applied kit %s: %d entries" % [kit_id, placed]})
	return {"ok":true,"message":"Kit applied.","placed_count":placed,"warnings":Array(apply_result.get("warnings", []))}

func undo_last_map_constructor_prefab_kit() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Kit undo is available only in TASK TEST constructor mode."}
	if _map_constructor_last_kit_snapshot.is_empty():
		return {"ok":false,"message":"No kit snapshot."}
	mission_world_objects = Array(_map_constructor_last_kit_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_kit_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_kit_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	_map_constructor_last_kit_snapshot.clear()
	_record_map_constructor_change("kit_undo", {"summary":"Undid last kit."})
	return {"ok":true,"message":"Kit undo completed."}

func get_map_constructor_room_templates() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "templates": [], "message": "Room templates are available only in TASK TEST constructor mode."}
	var templates: Array[Dictionary] = [
		{"id":"small_locked_room","display_name":"Small Locked Room","category":"room","description":"Compact room with locked door.","size":Vector2i(4,4),"entries":[{"prefab_id":"door","offset":Vector2i(1,0),"wall_side":"","properties":{"door_type":"digital","material":"energy","access_type":"terminal","state":"locked"},"link_group":"d"},{"prefab_id":"terminal","offset":Vector2i(0,1),"wall_side":"north","properties":{"terminal_type":"control","controlled_target_type":"door"},"link_group":"d"}],"tile_edits":[],"tags":["room"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"power_room","display_name":"Power Room","category":"room","description":"Small power setup.","size":Vector2i(4,4),"entries":[{"prefab_id":"power_source_class_1","offset":Vector2i(1,1),"wall_side":"","properties":{},"link_group":""}],"tile_edits":[],"tags":["power"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"corridor_with_door","display_name":"Corridor With Door","category":"corridor","description":"Corridor section with a door.","size":Vector2i(5,3),"entries":[{"prefab_id":"door","offset":Vector2i(2,1),"wall_side":"","properties":{"door_type":"digital","material":"energy"},"link_group":""}],"tile_edits":[],"tags":["corridor"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"terminal_alcove","display_name":"Terminal Alcove","category":"room","description":"Alcove with wall terminal.","size":Vector2i(3,3),"entries":[{"prefab_id":"terminal","offset":Vector2i(1,1),"wall_side":"east","properties":{"terminal_type":"information","controlled_target_type":"none"},"link_group":""}],"tile_edits":[],"tags":["terminal"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"diagnostic_test_bay","display_name":"Diagnostic Test Bay","category":"test","description":"Diagnostics layout.","size":Vector2i(5,4),"entries":[{"prefab_id":"firewall","offset":Vector2i(2,1),"wall_side":"west","properties":{},"link_group":""}],"tile_edits":[],"tags":["diagnostic"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}},
		{"id":"empty_test_chamber","display_name":"Empty Test Chamber","category":"test","description":"Open chamber with tile edits only.","size":Vector2i(4,4),"entries":[],"tile_edits":[{"offset":Vector2i(1,1),"tile_id":0}],"tags":["empty"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":true}},
		{"id":"wall_mounted_test_wall","display_name":"Wall-mounted Test Wall","category":"test","description":"Wall-mounted placement checks.","size":Vector2i(4,2),"entries":[{"prefab_id":"terminal","offset":Vector2i(1,0),"wall_side":"north","properties":{"terminal_type":"control","controlled_target_type":"door"},"link_group":"wall"}],"tile_edits":[],"tags":["wall_mounted"],"default_options":{"rotation":0,"mirror_x":false,"mirror_y":false,"allow_overwrite":false}}
	]
	var filtered_templates: Array[Dictionary] = []
	for template_variant in templates:
		var template: Dictionary = Dictionary(template_variant).duplicate(true)
		var template_warnings: Array[String] = []
		var removed_missing_ids: Array[String] = []
		template["entries"] = _map_constructor_filter_entry_rows(Array(template.get("entries", [])), template_warnings, removed_missing_ids)
		if not template_warnings.is_empty():
			template["warning"] = "; ".join(template_warnings)
		if Array(template.get("entries", [])).is_empty() and Array(template.get("tile_edits", [])).is_empty():
			continue
		filtered_templates.append(template)
	return {"ok":true,"templates":filtered_templates,"message":"OK"}

func preview_map_constructor_room_template(template_id: String, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "template_id": template_id, "anchor_cell": anchor_cell, "affected": [], "warnings": [], "conflicts": [], "can_apply": false, "message": "Template preview is available only in TASK TEST constructor mode."}
	var tpls: Array = Array(get_map_constructor_room_templates().get("templates", []))
	for t in tpls:
		if str(Dictionary(t).get("id", "")) == template_id:
			var template: Dictionary = Dictionary(t)
			var preview: Dictionary = _preview_map_constructor_entry_set(Array(template.get("entries", [])), anchor_cell, options)
			var tile_edits_preview: Dictionary = preview_map_constructor_tile_edits(Array(template.get("tile_edits", [])), anchor_cell, options)
			preview["affected"] = Array(preview.get("affected", [])) + Array(tile_edits_preview.get("affected", []))
			preview["warnings"] = Array(preview.get("warnings", [])) + Array(tile_edits_preview.get("warnings", []))
			preview["conflicts"] = Array(preview.get("conflicts", [])) + Array(tile_edits_preview.get("conflicts", []))
			preview["can_apply"] = bool(preview.get("can_apply", false)) and bool(tile_edits_preview.get("can_apply", false))
			preview["template_id"] = template_id
			return preview
	return {"ok":false,"template_id":template_id,"anchor_cell":anchor_cell,"affected":[],"warnings":[],"conflicts":[],"can_apply":false,"message":"Template not found."}

func apply_map_constructor_room_template(template_id: String, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Template apply is available only in TASK TEST constructor mode."}
	var templates: Array = Array(get_map_constructor_room_templates().get("templates", []))
	var template: Dictionary = {}
	for row in templates:
		if str(Dictionary(row).get("id", "")) == template_id:
			template = Dictionary(row)
			break
	if template.is_empty():
		return {"ok": false, "message": "Template not found."}
	var tile_snapshot: Array[Dictionary] = []
	if not Array(template.get("tile_edits", [])).is_empty():
		if grid_manager == null or not grid_manager.has_method("get_tile"):
			return {"ok": false, "message": "Tile edits not applied: safe tile snapshot getter unavailable.", "warnings": ["Tile edits not applied: safe tile snapshot getter unavailable."]}
		var seen_cells: Dictionary = {}
		for tile_edit_variant in Array(template.get("tile_edits", [])):
			var tile_edit: Dictionary = Dictionary(tile_edit_variant)
			var transformed_offset: Vector2i = _map_constructor_transform_template_offset(Vector2i(tile_edit.get("offset", Vector2i.ZERO)), options)
			var target_cell: Vector2i = anchor_cell + transformed_offset
			var cell_key: String = _serialize_cell_key(target_cell)
			if seen_cells.has(cell_key):
				continue
			seen_cells[cell_key] = true
			tile_snapshot.append({"cell": target_cell, "tile_id": int(grid_manager.call("get_tile", target_cell))})
	_map_constructor_last_template_snapshot = {"mission_world_objects": mission_world_objects.duplicate(true), "cell_items": cell_items.duplicate(true), "world_objects_by_cell": world_objects_by_cell.duplicate(true), "tile_snapshot": tile_snapshot}
	var result: Dictionary = _apply_map_constructor_entry_set(Array(template.get("entries", [])), anchor_cell, options)
	if not bool(result.get("ok", false)):
		return result
	var tile_apply: Dictionary = apply_map_constructor_tile_edits(Array(template.get("tile_edits", [])), anchor_cell, options)
	result["warnings"] = Array(result.get("warnings", [])) + Array(tile_apply.get("warnings", []))
	if not bool(tile_apply.get("ok", false)):
		result["ok"] = false
		result["message"] = str(tile_apply.get("message", "Template tile edits failed."))
		return result
	if bool(result.get("ok", false)):
		_record_map_constructor_change("template", {"summary":"Applied template %s" % template_id})
	return result

func preview_map_constructor_tile_edits(tile_edits: Array, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	var allow_overwrite: bool = bool(options.get("allow_overwrite", false))
	var affected: Array[Dictionary] = []
	var conflicts: Array[Dictionary] = []
	var warnings: Array[String] = []
	var rotation: int = int(options.get("rotation", 0))
	if rotation != 0 and rotation != 90 and rotation != 180 and rotation != 270:
		warnings.append("Unsupported rotation=%d treated as 0." % rotation)
	for tile_edit_variant in tile_edits:
		var tile_edit: Dictionary = Dictionary(tile_edit_variant)
		var offset: Vector2i = Vector2i(tile_edit.get("offset", Vector2i.ZERO))
		var cell: Vector2i = anchor_cell + _map_constructor_transform_template_offset(offset, options)
		var conflict_reason: String = ""
		var object_here: Dictionary = Dictionary(world_objects_by_cell.get(cell, {}))
		if not allow_overwrite and not object_here.is_empty():
			conflict_reason = "cell_has_world_object"
		var items_here: Array[Dictionary] = get_items_at_cell(cell)
		if conflict_reason.is_empty() and not allow_overwrite and not items_here.is_empty():
			conflict_reason = "cell_has_items"
		if not conflict_reason.is_empty():
			conflicts.append({"operation":"tile_edit","cell":cell,"reason":conflict_reason,"message":"Tile edit blocked at %s." % str(cell)})
		affected.append({"operation":"tile_edit","cell":cell,"tile_id":int(tile_edit.get("tile_id", GridManager.TILE_FLOOR))})
	return {"ok": true, "affected": affected, "warnings": warnings, "conflicts": conflicts, "can_apply": conflicts.is_empty() or allow_overwrite}

func apply_map_constructor_tile_edits(tile_edits: Array, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if grid_manager == null or not grid_manager.has_method("set_tile"):
		return {"ok": false, "warnings": ["Tile edits not applied: safe tile setter unavailable."], "message": "Tile edits not applied: safe tile setter unavailable."}
	if grid_manager == null or not grid_manager.has_method("get_tile"):
		return {"ok": false, "warnings": ["Tile edits not applied: safe tile snapshot getter unavailable."], "message": "Tile edits not applied: safe tile snapshot getter unavailable."}
	var preview: Dictionary = preview_map_constructor_tile_edits(tile_edits, anchor_cell, options)
	if not bool(preview.get("can_apply", false)):
		return {"ok": false, "warnings": [], "message": "Tile edits blocked by conflicts.", "conflicts": Array(preview.get("conflicts", []))}
	for affected_variant in Array(preview.get("affected", [])):
		var affected_row: Dictionary = Dictionary(affected_variant)
		grid_manager.call("set_tile", Vector2i(affected_row.get("cell", Vector2i(-1, -1))), int(affected_row.get("tile_id", GridManager.TILE_FLOOR)))
	return {"ok": true, "warnings": [], "message": "Tile edits applied."}

func undo_last_map_constructor_room_template() -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Template undo is available only in TASK TEST constructor mode."}
	if _map_constructor_last_template_snapshot.is_empty():
		return {"ok":false,"message":"No template snapshot."}
	mission_world_objects = Array(_map_constructor_last_template_snapshot.get("mission_world_objects", [])).duplicate(true)
	cell_items = Dictionary(_map_constructor_last_template_snapshot.get("cell_items", {})).duplicate(true)
	world_objects_by_cell = Dictionary(_map_constructor_last_template_snapshot.get("world_objects_by_cell", {})).duplicate(true)
	var warnings: Array[String] = []
	var tile_snapshot: Array = Array(_map_constructor_last_template_snapshot.get("tile_snapshot", []))
	if not tile_snapshot.is_empty():
		if grid_manager == null or not grid_manager.has_method("set_tile"):
			warnings.append("Template undo warning: tile snapshot exists but safe tile setter unavailable.")
		else:
			for snapshot_variant in tile_snapshot:
				var snapshot_row: Dictionary = Dictionary(snapshot_variant)
				grid_manager.call("set_tile", Vector2i(snapshot_row.get("cell", Vector2i(-1, -1))), int(snapshot_row.get("tile_id", GridManager.TILE_FLOOR)))
			if grid_manager.has_method("recalculate_visibility"):
				grid_manager.call("recalculate_visibility")
			if grid_manager.has_method("request_visual_refresh"):
				grid_manager.call("request_visual_refresh")
	_map_constructor_last_template_snapshot.clear()
	_record_map_constructor_change("template_undo", {"summary":"Undid last template."})
	if not warnings.is_empty():
		return {"ok": false, "warnings": warnings, "message": "Template undo partial: tile restore unavailable."}
	return {"ok":true,"warnings":[],"message":"Template undo completed."}

func get_room_visual_preset_summary() -> Dictionary:
	var active_preset_lookup: Dictionary = {}
	var wall_material_counts: Dictionary = {}
	var door_visual_counts: Dictionary = {}
	var terminal_visual_counts: Dictionary = {}
	var affected_cell_lookup: Dictionary = {}
	var wall_count: int = 0
	var floor_summary: Dictionary = get_map_constructor_floor_material_summary()
	var floor_material_counts: Dictionary = Dictionary(floor_summary.get("material_counts", {}))
	for key_variant in _map_constructor_wall_material_overrides.keys():
		var key: String = str(key_variant)
		var row: Dictionary = Dictionary(_map_constructor_wall_material_overrides.get(key, {}))
		if not bool(row.get("created_by_room_visual_preset", false)):
			continue
		wall_count += 1
		var material_id: String = str(row.get("material_id", "")).strip_edges()
		if material_id.is_empty():
			material_id = "unknown"
		wall_material_counts[material_id] = int(wall_material_counts.get(material_id, 0)) + 1
		var preset_id: String = str(row.get("room_visual_preset_id", "")).strip_edges()
		if not preset_id.is_empty():
			active_preset_lookup[preset_id] = true
		var cell: Vector2i = Vector2i(row.get("cell", Vector2i(-1, -1)))
		if cell.x >= 0 and cell.y >= 0:
			affected_cell_lookup[_serialize_cell_key(cell)] = cell
	for object_id_variant in map_constructor_door_visual_preset_overrides.keys():
		var door_object_id: String = str(object_id_variant)
		var row_door: Dictionary = Dictionary(map_constructor_door_visual_preset_overrides.get(door_object_id, {}))
		var hint: String = str(row_door.get("visual_hint", "")).strip_edges()
		if hint.is_empty():
			hint = "none"
		door_visual_counts[hint] = int(door_visual_counts.get(hint, 0)) + 1
		var preset_id_door: String = str(row_door.get("preset_id", "")).strip_edges()
		if not preset_id_door.is_empty():
			active_preset_lookup[preset_id_door] = true
		var door_object: Dictionary = get_world_object_by_id(door_object_id)
		var door_cell: Vector2i = Vector2i(door_object.get("position", Vector2i(-1, -1)))
		if door_cell.x >= 0 and door_cell.y >= 0:
			affected_cell_lookup[_serialize_cell_key(door_cell)] = door_cell
	for terminal_id_variant in map_constructor_terminal_visual_preset_overrides.keys():
		var terminal_id: String = str(terminal_id_variant)
		var row_terminal: Dictionary = Dictionary(map_constructor_terminal_visual_preset_overrides.get(terminal_id, {}))
		var terminal_hint: String = str(row_terminal.get("visual_hint", "")).strip_edges()
		if terminal_hint.is_empty():
			terminal_hint = "none"
		terminal_visual_counts[terminal_hint] = int(terminal_visual_counts.get(terminal_hint, 0)) + 1
		var preset_id_terminal: String = str(row_terminal.get("preset_id", "")).strip_edges()
		if not preset_id_terminal.is_empty():
			active_preset_lookup[preset_id_terminal] = true
		var terminal_object: Dictionary = get_world_object_by_id(terminal_id)
		var terminal_cell: Vector2i = Vector2i(terminal_object.get("position", Vector2i(-1, -1)))
		if terminal_cell.x >= 0 and terminal_cell.y >= 0:
			affected_cell_lookup[_serialize_cell_key(terminal_cell)] = terminal_cell
	for floor_cell_variant in Array(floor_summary.get("affected_cells", [])):
		var floor_cell: Vector2i = Vector2i(floor_cell_variant)
		if floor_cell.x >= 0 and floor_cell.y >= 0:
			affected_cell_lookup[_serialize_cell_key(floor_cell)] = floor_cell
	var active_preset_ids: Array[String] = []
	for preset_id_variant in active_preset_lookup.keys():
		active_preset_ids.append(str(preset_id_variant))
	active_preset_ids.sort()
	var affected_cells: Array = []
	for cell_key_variant in affected_cell_lookup.keys():
		affected_cells.append(Vector2i(affected_cell_lookup[cell_key_variant]))
	affected_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return {
		"active_preset_ids": active_preset_ids,
		"wall_material_counts": wall_material_counts,
		"floor_material_counts": floor_material_counts,
		"door_visual_counts": door_visual_counts,
		"terminal_visual_counts": terminal_visual_counts,
		"preset_generated_wall_override_count": wall_count,
		"preset_generated_floor_override_count": int(floor_summary.get("preset_generated_floor_override_count", 0)),
		"preset_generated_door_override_count": map_constructor_door_visual_preset_overrides.size(),
		"preset_generated_terminal_override_count": map_constructor_terminal_visual_preset_overrides.size(),
		"affected_cells": affected_cells
	}

func get_map_constructor_object_grounding_summary() -> Dictionary:
	var summary: Dictionary = {"object_count": 0, "item_count": 0, "floor_standing_count": 0, "wall_mounted_count": 0, "door_insert_count": 0, "floor_pickup_count": 0, "unknown_grounding_count": 0, "missing_anchor_count": 0, "missing_wall_mount_count": 0}
	for object_variant in mission_world_objects:
		var data: Dictionary = _safe_dictionary(object_variant)
		summary["object_count"] = int(summary.get("object_count", 0)) + 1
		var _object_type: String = str(data.get("object_type", data.get("type", ""))).to_lower().strip_edges()
		var entity_kind: String = str(_map_constructor_entity_kind(data)).to_lower().strip_edges()
		if entity_kind == "item":
			summary["item_count"] = int(summary.get("item_count", 0)) + 1
		var placement_mode: String = str(data.get("placement_mode", "")).to_lower().strip_edges()
		var anchor: Vector2i = _deserialize_cell_variant(data.get("anchor_floor_cell", data.get("position", Vector2i(-1, -1))))
		if anchor.x < 0 or anchor.y < 0:
			summary["missing_anchor_count"] = int(summary.get("missing_anchor_count", 0)) + 1
		if placement_mode == "wall_mounted":
			summary["wall_mounted_count"] = int(summary.get("wall_mounted_count", 0)) + 1
			var attached: Vector2i = _deserialize_cell_variant(data.get("attached_wall_cell", Vector2i(-1, -1)))
			if attached.x < 0 or attached.y < 0 or str(data.get("wall_side", "")).strip_edges().is_empty():
				summary["missing_wall_mount_count"] = int(summary.get("missing_wall_mount_count", 0)) + 1
		elif _object_type.contains("door") or _object_type.contains("gate"):
			summary["door_insert_count"] = int(summary.get("door_insert_count", 0)) + 1
		elif entity_kind == "item" or _object_type.contains("key") or _object_type.contains("kit") or _object_type.contains("card") or _object_type.contains("code") or _object_type.contains("fuse") or _object_type.contains("item") or str(data.get("item_type", "")).strip_edges() != "":
			summary["floor_pickup_count"] = int(summary.get("floor_pickup_count", 0)) + 1
		else:
			summary["floor_standing_count"] = int(summary.get("floor_standing_count", 0)) + 1
	return summary

func export_map_constructor_design_notes(_options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "message": "Design notes export is available only in TASK TEST constructor mode."}
	var patch_export: Dictionary = export_map_constructor_runtime_patch()
	var readiness: Dictionary = get_map_constructor_mission_readiness_report()
	var validation: Array = get_map_constructor_validation_issues()
	var wall_overrides: Array = Array(get_map_constructor_wall_material_overrides().get("overrides", []))
	var floor_overrides: Array = Array(get_map_constructor_floor_material_overrides().get("overrides", []))
	var floor_summary: Dictionary = get_map_constructor_floor_material_summary()
	var wall_topology_summary: Dictionary = get_map_constructor_wall_topology_summary()
	var wall_mounted_anchor_zone_summary: Dictionary = get_map_constructor_wall_mounted_anchor_zone_summary()
	var door_opening_summary: Dictionary = get_map_constructor_door_opening_summary()
	var wall_counts: Dictionary = {}
	for row_variant in wall_overrides:
		var row: Dictionary = Dictionary(row_variant)
		var material_id: String = str(row.get("material_id", "unknown")).to_lower()
		wall_counts[material_id] = int(wall_counts.get(material_id, 0)) + 1
	var door_visual_summary: Dictionary = {"counts_by_state": {}, "doors": []}
	var terminal_visual_summary: Dictionary = {"counts_by_type": {}, "counts_by_state": {}, "terminals": []}
	var door_rows: Array[Dictionary] = []
	var terminal_rows: Array[Dictionary] = []
	var visual_diagnostics: Array[Dictionary] = []
	var object_ids: Dictionary = {}
	for object_variant in mission_world_objects:
		var object_data_indexed: Dictionary = _safe_dictionary(object_variant)
		var indexed_id: String = str(object_data_indexed.get("id", "")).strip_edges()
		if not indexed_id.is_empty():
			object_ids[indexed_id] = true
	for object_variant in mission_world_objects:
		var object_data: Dictionary = _safe_dictionary(object_variant)
		var object_id: String = str(object_data.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges()
		var cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
		var normalized_type: String = object_type.to_lower()
		if normalized_type.find("door") >= 0 or normalized_type.find("gate") >= 0:
			var door_visual: Dictionary = get_map_constructor_door_visual_state(object_id)
			var door_state: String = str(door_visual.get("state", "unknown"))
			var door_badges: Array[String] = []
			for badge_variant in Array(door_visual.get("badges", [])):
				door_badges.append(str(badge_variant))
			var count_state: String = door_state.to_lower()
			door_visual_summary["counts_by_state"][count_state] = int(door_visual_summary["counts_by_state"].get(count_state, 0)) + 1
			door_rows.append({"object_id": object_id, "cell": cell, "object_type": object_type, "state": door_state, "badges": door_badges})
			if count_state == "unknown":
				visual_diagnostics.append(_make_map_constructor_issue("door_visual_unknown_%s" % object_id, "warning", "Door visual state unknown for %s." % object_id, cell, "world_object", "world_object", object_id, "Set valid door state metadata."))
		if normalized_type.find("terminal") >= 0:
			var terminal_visual: Dictionary = get_map_constructor_terminal_visual_state(object_id)
			var terminal_type: String = str(terminal_visual.get("terminal_type", "unknown"))
			var terminal_state: String = str(terminal_visual.get("state", "unknown"))
			var terminal_badges: Array[String] = []
			for terminal_badge_variant in Array(terminal_visual.get("badges", [])):
				terminal_badges.append(str(terminal_badge_variant))
			var count_type: String = terminal_type.to_lower()
			var count_terminal_state: String = terminal_state.to_lower()
			terminal_visual_summary["counts_by_type"][count_type] = int(terminal_visual_summary["counts_by_type"].get(count_type, 0)) + 1
			terminal_visual_summary["counts_by_state"][count_terminal_state] = int(terminal_visual_summary["counts_by_state"].get(count_terminal_state, 0)) + 1
			terminal_rows.append({"object_id": object_id, "cell": cell, "object_type": object_type, "terminal_type": terminal_type, "state": terminal_state, "badges": terminal_badges})
			if count_type == "unknown":
				visual_diagnostics.append(_make_map_constructor_issue("terminal_visual_type_unknown_%s" % object_id, "warning", "Terminal visual type unknown for %s." % object_id, cell, "world_object", "world_object", object_id, "Set valid terminal_type metadata."))
			var linked_target_id: String = str(object_data.get("linked_object_id", object_data.get("target_object_id", ""))).strip_edges()
			if not linked_target_id.is_empty() and not object_ids.has(linked_target_id):
				visual_diagnostics.append(_make_map_constructor_issue("terminal_missing_link_target_%s" % object_id, "warning", "Terminal %s references missing linked target %s." % [object_id, linked_target_id], cell, "world_object", "world_object", object_id, "Fix linked target id or add the target object."))
	door_visual_summary["doors"] = door_rows
	terminal_visual_summary["terminals"] = terminal_rows
	var visual_catalog: Dictionary = get_visual_texture_asset_catalog()
	var visual_summary: Dictionary = _build_visual_asset_summary(Dictionary(visual_catalog))
	var notes: Dictionary = {"schema_version":1,"source":"task_test_map_constructor","mission_id":get_task_test_source_id(),"source_mission_id":get_task_test_source_id(),"generated_at_runtime":str(Time.get_unix_time_from_system()),"summary":{"object_count":mission_world_objects.size(),"wall_material_override_count":wall_overrides.size(),"wall_material_counts":wall_counts,"floor_material_override_count":floor_overrides.size(),"floor_material_summary":floor_summary,"wall_topology_summary":wall_topology_summary,"wall_mounted_anchor_zone_summary":wall_mounted_anchor_zone_summary,"door_opening_summary":door_opening_summary,"object_grounding_summary":get_map_constructor_object_grounding_summary()},"visual_asset_summary":visual_summary,"readiness":readiness,"validation":{"issues":validation,"visual_diagnostics":visual_diagnostics},"objects":mission_world_objects.duplicate(true),"items":cell_items.values(),"tile_edits":Array(patch_export.get("patch", {}).get("tile_edits", [])),"links":Array(patch_export.get("patch", {}).get("links", [])),"patch":Dictionary(patch_export.get("patch", {})),"wall_material_overrides":wall_overrides,"floor_material_overrides":floor_overrides,"floor_material_summary":floor_summary,"wall_topology_summary":wall_topology_summary,"wall_mounted_anchor_zone_summary":wall_mounted_anchor_zone_summary,"door_opening_summary":door_opening_summary,"object_grounding_summary":get_map_constructor_object_grounding_summary(),"door_visual_summary":door_visual_summary,"terminal_visual_summary":terminal_visual_summary,"history_summary":Array(get_map_constructor_change_history(20).get("history", [])),"overview_summary":Dictionary(get_map_constructor_overview_data().get("summary", {})),"room_visual_preset_summary":get_room_visual_preset_summary(),"recommended_next_steps":["Manual promotion required. No mission files were modified."]}
	var text: String = "# Design Notes\nMission: %s\nReadiness: %s\nValidation issues: %d\nPatch summary: objects=%d items=%d tiles=%d\nManual promotion required. No mission files were modified." % [get_task_test_source_id(), str(readiness.get("status", "unknown")), validation.size(), int(patch_export.get("object_count", 0)), int(patch_export.get("item_count", 0)), int(patch_export.get("tile_edit_count", 0))]
	return {"ok":true,"message":"OK","notes":notes,"text":text}

func get_map_constructor_production_pipeline_report(_options: Dictionary = {}) -> Dictionary:
	if not _is_task_test_constructor_context():
		return {"ok": false, "status": "blocked", "message": "Production pipeline report is available only in TASK TEST constructor mode.", "checks": []}
	var readiness: Dictionary = get_map_constructor_mission_readiness_report()
	var notes: Dictionary = export_map_constructor_design_notes()
	var patch_export: Dictionary = export_map_constructor_runtime_patch()
	var checks: Array[Dictionary] = []
	var validation_issues: Array = Array(get_map_constructor_validation_issues())
	var non_expected_errors: int = 0
	var warning_count: int = 0
	for issue_variant in validation_issues:
		var issue: Dictionary = Dictionary(issue_variant)
		var severity: String = str(issue.get("severity", "warning")).to_lower()
		var expected: bool = bool(issue.get("expected_invalid", false))
		if severity == "error" and not expected:
			non_expected_errors += 1
		if severity == "warning":
			warning_count += 1
	checks.append({"label":"TASK TEST constructor context active","status":"pass"})
	checks.append({"label":"readiness playable","status":"pass" if str(readiness.get("status", "")) == "playable" else "fail"})
	checks.append({"label":"validation blocking errors","status":"pass" if non_expected_errors <= 0 else "fail"})
	checks.append({"label":"patch export ok","status":"pass" if bool(patch_export.get("ok", false)) else "fail"})
	checks.append({"label":"design notes ok","status":"pass" if bool(notes.get("ok", false)) else "fail"})
	checks.append({"label":"validation warnings","status":"warning" if warning_count > 0 else "pass"})
	checks.append({"label":"readiness diagnostics","status":"info","message":"not checked"})
	var blocked: bool = str(readiness.get("status", "")) == "blocked" or not bool(readiness.get("ok", true)) or not bool(patch_export.get("ok", false)) or not bool(notes.get("ok", false)) or non_expected_errors > 0
	var has_warnings: bool = warning_count > 0
	var status: String = "blocked" if blocked else ("warning" if has_warnings else "ready")
	var notes_payload: Dictionary = Dictionary(notes.get("notes", {}))
	return {"ok":true,"status":status,"message":"Manual promotion required. No mission files were modified.","checks":checks,"promotion_package":{"patch":Dictionary(patch_export.get("patch", {})),"design_notes":notes_payload,"summary":{"readiness":str(readiness.get("status", "unknown")),"wall_material_overrides":Array(get_map_constructor_wall_material_overrides().get("overrides", [])),"floor_material_summary":Dictionary(notes_payload.get("floor_material_summary", {})),"wall_topology_summary":Dictionary(notes_payload.get("wall_topology_summary", {})),"wall_mounted_anchor_zone_summary":Dictionary(notes_payload.get("wall_mounted_anchor_zone_summary", {})),"door_opening_summary":Dictionary(notes_payload.get("door_opening_summary", {})),"door_visual_summary":Dictionary(notes_payload.get("door_visual_summary", {})),"terminal_visual_summary":Dictionary(notes_payload.get("terminal_visual_summary", {})),"visual_asset_summary":Dictionary(notes_payload.get("visual_asset_summary", {})),"room_visual_preset_summary":Dictionary(notes_payload.get("room_visual_preset_summary", {})),"object_grounding_summary":Dictionary(notes_payload.get("object_grounding_summary", {}))},"manual_steps":["Review design notes","Review patch JSON","Promote manually in controlled pipeline"],"warnings":[]},"recommended_actions":[]}

func get_map_constructor_wall_mounted_anchor_zone_summary() -> Dictionary:
	var summary: Dictionary = {"wall_count": 0, "visible_side_count": 0, "mountable_zone_count": 0, "zones_by_side": {"north": 0, "east": 0, "south": 0, "west": 0}, "wall_mass_ratio": 0.7, "mount_band_ratio": 0.3, "wall_mounted_object_count": 0, "unanchored_wall_mounted_object_count": 0}
	if grid_manager == null or not grid_manager.has_method("get_tile"):
		return summary
	var width: int = int(grid_manager.get_map_width())
	var height: int = int(grid_manager.get_map_height())
	if width <= 0 or height <= 0:
		return summary
	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			if int(grid_manager.call("get_tile", cell)) != GridManager.TILE_WALL:
				continue
			summary["wall_count"] = int(summary.get("wall_count", 0)) + 1
			for side in ["north", "east", "south", "west"]:
				var neighbor: Vector2i = cell + _get_map_constructor_wall_side_delta(side)
				var visible: bool = false
				var mountable: bool = false
				if _is_valid_grid_cell(neighbor):
					var tile_type: int = int(grid_manager.call("get_tile", neighbor))
					visible = _is_wall_mount_neighbor_tile_type(tile_type)
					mountable = visible and tile_type != GridManager.TILE_DOOR and tile_type != GridManager.TILE_DIGITAL_DOOR and tile_type != GridManager.TILE_POWERED_GATE
				else:
					visible = true
				if visible:
					summary["visible_side_count"] = int(summary.get("visible_side_count", 0)) + 1
				if mountable:
					summary["mountable_zone_count"] = int(summary.get("mountable_zone_count", 0)) + 1
					var by_side: Dictionary = Dictionary(summary.get("zones_by_side", {}))
					by_side[side] = int(by_side.get(side, 0)) + 1
					summary["zones_by_side"] = by_side
	for object_data in mission_world_objects:
		var data: Dictionary = _safe_dictionary(object_data)
		if str(data.get("placement_mode", "")).to_lower().strip_edges() != "wall_mounted":
			continue
		summary["wall_mounted_object_count"] = int(summary.get("wall_mounted_object_count", 0)) + 1
		if str(data.get("wall_side", "")).strip_edges().is_empty():
			summary["unanchored_wall_mounted_object_count"] = int(summary.get("unanchored_wall_mounted_object_count", 0)) + 1
	return summary

func get_map_constructor_wall_topology_summary() -> Dictionary:
	var empty: Dictionary = {"wall_count": 0, "topology_counts": {}, "material_counts": {}, "door_adjacent_wall_count": 0, "boundary_wall_count": 0}
	if grid_manager == null or not grid_manager.has_method("get_width") or not grid_manager.has_method("get_height") or not grid_manager.has_method("get_tile"):
		return empty
	var width: int = int(grid_manager.call("get_width"))
	var height: int = int(grid_manager.call("get_height"))
	if width <= 0 or height <= 0:
		return empty
	var topology_counts: Dictionary = {}
	var material_counts: Dictionary = {}
	var wall_count: int = 0
	var door_adjacent_wall_count: int = 0
	var boundary_wall_count: int = 0
	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = int(grid_manager.call("get_tile", cell))
			if tile_type != GridManager.TILE_WALL:
				continue
			wall_count += 1
			var material_row: Dictionary = Dictionary(get_map_constructor_wall_material_for_wall_cell(cell).get("material", {}))
			var material_id: String = str(material_row.get("id", "default_wall")).strip_edges()
			if material_id.is_empty():
				material_id = "default_wall"
			material_counts[material_id] = int(material_counts.get(material_id, 0)) + 1
			var north: bool = y > 0 and int(grid_manager.call("get_tile", Vector2i(x, y - 1))) == GridManager.TILE_WALL
			var east: bool = x < width - 1 and int(grid_manager.call("get_tile", Vector2i(x + 1, y))) == GridManager.TILE_WALL
			var south: bool = y < height - 1 and int(grid_manager.call("get_tile", Vector2i(x, y + 1))) == GridManager.TILE_WALL
			var west: bool = x > 0 and int(grid_manager.call("get_tile", Vector2i(x - 1, y))) == GridManager.TILE_WALL
			var neighbor_count: int = int(north) + int(east) + int(south) + int(west)
			var topology: String = "isolated"
			if x <= 0 or y <= 0 or x >= width - 1 or y >= height - 1:
				topology = "boundary_wall"
				boundary_wall_count += 1
			elif _is_map_constructor_wall_adjacent_to_door(cell, width, height):
				topology = "door_adjacent"
				door_adjacent_wall_count += 1
			elif neighbor_count == 4:
				topology = "cross_junction"
			elif neighbor_count == 3:
				topology = "t_junction"
			elif neighbor_count == 2 and north and south:
				topology = "vertical_run"
			elif neighbor_count == 2 and east and west:
				topology = "horizontal_run"
			elif neighbor_count == 2 and north and east:
				topology = "corner_ne"
			elif neighbor_count == 2 and north and west:
				topology = "corner_nw"
			elif neighbor_count == 2 and south and east:
				topology = "corner_se"
			elif neighbor_count == 2 and south and west:
				topology = "corner_sw"
			elif neighbor_count == 1 and north:
				topology = "cap_north"
			elif neighbor_count == 1 and east:
				topology = "cap_east"
			elif neighbor_count == 1 and south:
				topology = "cap_south"
			elif neighbor_count == 1 and west:
				topology = "cap_west"
			topology_counts[topology] = int(topology_counts.get(topology, 0)) + 1
	return {"wall_count": wall_count, "topology_counts": topology_counts, "material_counts": material_counts, "door_adjacent_wall_count": door_adjacent_wall_count, "boundary_wall_count": boundary_wall_count}

func _is_map_constructor_wall_adjacent_to_door(cell: Vector2i, width: int, height: int) -> bool:
	var directions: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for delta in directions:
		var neighbor: Vector2i = cell + delta
		if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height:
			continue
		var neighbor_tile: int = int(grid_manager.call("get_tile", neighbor))
		if neighbor_tile == GridManager.TILE_DOOR or neighbor_tile == GridManager.TILE_DIGITAL_DOOR or neighbor_tile == GridManager.TILE_POWERED_GATE:
			return true
	return false

func _build_visual_asset_summary(catalog: Dictionary) -> Dictionary:
	var assets: Array = Array(catalog.get("assets", []))
	var missing_optional_count: int = 0
	var missing_required_count: int = 0
	var unknown_reference_count: int = 0
	var category_counts: Dictionary = {}
	for row_variant in assets:
		var row: Dictionary = Dictionary(row_variant)
		var category: String = str(row.get("category", "unknown"))
		category_counts[category] = int(category_counts.get(category, 0)) + 1
		var resolved: Dictionary = resolve_visual_texture_asset(str(row.get("id", "")))
		if bool(resolved.get("ok", false)) and not bool(resolved.get("has_texture", false)):
			if bool(row.get("is_optional", true)):
				missing_optional_count += 1
			else:
				missing_required_count += 1
	var reference_diagnostics: Dictionary = get_visual_texture_asset_reference_diagnostics()
	unknown_reference_count = Array(reference_diagnostics.get("unknown_references", [])).size()
	missing_optional_count = maxi(missing_optional_count, Array(reference_diagnostics.get("missing_optional", [])).size())
	missing_required_count = maxi(missing_required_count, Array(reference_diagnostics.get("missing_required", [])).size())
	return {
		"asset_count": assets.size(),
		"unknown_reference_count": unknown_reference_count,
		"missing_optional_count": missing_optional_count,
		"missing_required_count": missing_required_count,
		"fallback_count": missing_optional_count + missing_required_count,
		"categories": category_counts,
		"placeholder_assets": Array(reference_diagnostics.get("placeholder_assets", []))
	}

func _preview_map_constructor_entry_set(entries: Array, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	var conflicts: Array[Dictionary] = []
	var affected: Array[Dictionary] = []
	var warnings: Array[String] = []
	var allow_overwrite: bool = bool(options.get("allow_overwrite", false))
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var transformed_offset: Vector2i = _map_constructor_transform_template_offset(Vector2i(entry.get("offset", Vector2i.ZERO)), options)
		var cell: Vector2i = anchor_cell + transformed_offset
		var wall_side: String = str(entry.get("wall_side", ""))
		if bool(MAP_CONSTRUCTOR_WALL_MOUNTED_PREFABS.get(str(entry.get("prefab_id", "")), false)) and wall_side.is_empty():
			conflicts.append({"prefab_id":str(entry.get("prefab_id", "")), "cell": cell, "reason":"missing_wall_side", "message":"Wall-mounted prefab requires wall_side."})
			continue
		var check: Dictionary = can_place_map_constructor_prefab(str(entry.get("prefab_id", "")), cell, wall_side)
		if not bool(check.get("ok", false)):
			conflicts.append({"prefab_id":str(entry.get("prefab_id", "")),"cell":cell,"reason":str(check.get("reason", "blocked")),"message":str(check.get("message", "Blocked."))})
		affected.append({"prefab_id":str(entry.get("prefab_id", "")), "cell": cell})
		if not str(entry.get("link_group", "")).is_empty():
			warnings.append("Link group metadata preserved for %s; link resolver not applied." % str(entry.get("prefab_id", "")))
	return {"ok": true, "anchor_cell": anchor_cell, "affected": affected, "warnings": warnings, "conflicts": conflicts, "can_apply": conflicts.is_empty() or allow_overwrite, "message": "Preview ready."}

func _apply_map_constructor_entry_set(entries: Array, anchor_cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = _preview_map_constructor_entry_set(entries, anchor_cell, options)
	var warnings: Array[String] = Array(preview.get("warnings", []))
	if not bool(preview.get("can_apply", false)):
		preview["ok"] = false
		preview["message"] = "Apply blocked by conflicts."
		return preview
	var placed_count: int = 0
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var transformed_offset: Vector2i = _map_constructor_transform_template_offset(Vector2i(entry.get("offset", Vector2i.ZERO)), options)
		var cell: Vector2i = anchor_cell + transformed_offset
		var wall_side: String = str(entry.get("wall_side", ""))
		var placed: Dictionary = place_map_constructor_prefab(str(entry.get("prefab_id", "")), cell, wall_side)
		if bool(placed.get("ok", false)):
			placed_count += 1
			var properties: Dictionary = Dictionary(entry.get("properties", {}))
			if not properties.is_empty():
				var placed_object_id: String = str(placed.get("object_id", ""))
				if placed_object_id.is_empty():
					warnings.append("Properties not applied: placement result did not include entity id.")
				else:
					for property_name_variant in properties.keys():
						var property_name: String = str(property_name_variant)
						var update_result: Dictionary = apply_map_constructor_property_update("world_object", placed_object_id, property_name, properties.get(property_name_variant))
						if not bool(update_result.get("ok", false)):
							warnings.append("Property '%s' not applied for %s." % [property_name, placed_object_id])
	return {"ok": true, "placed_count": placed_count, "warnings": warnings}

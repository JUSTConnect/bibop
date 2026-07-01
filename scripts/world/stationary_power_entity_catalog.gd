extends RefCounted
class_name StationaryPowerEntityCatalog

const FAMILY_IDS: Array[String] = [
	"power_source", "power_cable", "fuse_box", "power_switcher", "power_socket", "light"
]

const COMPUTED_POWER_FIELDS: Array[String] = [
	"power_state", "is_powered", "resolved_source_id", "resolved_circuit_id",
	"physical_connection_source_id", "power_unavailable_reason", "source_load",
	"source_capacity", "source_overloaded", "control_state", "control_available",
	"local_control_available", "remote_control_available", "resolved_controller_id",
	"control_reason_code"
]

const LEGACY_AUTHORING_FIELDS: Array[String] = [
	"state", "status", "durability", "durability_current", "durability_max",
	"damaged", "broken", "destroyed", "cut", "is_on", "switch_state", "fuse_present", "fuse_installed", "fuse_present", "fuse_installed",
	"power_source_id", "main_power_net", "power_network_id", "connection_id",
	"source_object_id", "sink_object_id", "socket_id", "endpoint_a_id", "endpoint_b_id",
	"connected_device_ids", "linked_terminal_id", "control_terminal_id",
	"target_light_ids", "linked_light_ids", "wall_side", "wall_side_1", "wall_side_2",
	"cable_health_state", "cable_install_mode", "route_surface", "hidden_installation",
	"is_hidden", "has_connected_cable", "connected_endpoint_count",
	"socket_connected_endpoint_count", "is_connected", "connected", "disconnected",
	"connected_side", "power_required", "power_received"
]

const ALIASES: Dictionary = {
	"power_source_class_1":"power_source",
	"power_source_class_2":"power_source",
	"power_source_class_3":"power_source",
	"circuit_breaker":"power_switcher",
	"circuit_switch":"power_switcher",
	"power_breaker":"power_switcher",
	"power_switch":"power_switcher",
	"light_switch":"power_switcher",
	"light_switcher":"power_switcher",
	"power_switcher_floor_off":"power_switcher",
	"power_switcher_floor_on":"power_switcher",
	"power_switcher_wall_off":"power_switcher",
	"power_switcher_wall_on":"power_switcher",
	"fuse_box_installed":"fuse_box",
	"fuse_box_empty":"fuse_box",
	"legacy_fuse_box_library":"fuse_box",
	"fuse_block":"fuse_box",
	"outlet":"power_socket",
	"socket":"power_socket",
	"legacy_light_library":"light"
}

const ALIAS_DEFAULTS: Dictionary = {
	"power_source_class_1":{"power_source_class":1, "outlet_capacity":4},
	"power_source_class_2":{"power_source_class":2, "outlet_capacity":5},
	"power_source_class_3":{"power_source_class":3, "outlet_capacity":6},
	"circuit_breaker":{"switcher_type":"power_breaker", "intent_state":"on", "mount":"wall"},
	"circuit_switch":{"switcher_type":"power_switcher", "intent_state":"off"},
	"power_breaker":{"switcher_type":"power_breaker"},
	"power_switch":{"switcher_type":"power_breaker"},
	"light_switch":{"switcher_type":"light_switcher", "mount":"wall"},
	"light_switcher":{"switcher_type":"light_switcher", "mount":"wall"},
	"power_switcher_floor_off":{"intent_state":"off", "mount":"floor"},
	"power_switcher_floor_on":{"intent_state":"on", "mount":"floor"},
	"power_switcher_wall_off":{"intent_state":"off", "mount":"wall"},
	"power_switcher_wall_on":{"intent_state":"on", "mount":"wall"},
	"fuse_box_installed":{"has_fuse":true, "operational_state":"installed"},
	"fuse_box_empty":{"has_fuse":false, "operational_state":"empty"},
	"legacy_fuse_box_library":{"has_fuse":true, "operational_state":"installed"},
	"fuse_block":{"has_fuse":true, "operational_state":"installed"}
}

const DEFINITIONS: Dictionary = {
	"power_source":{
		"entity_contract":{"scope":"entity", "entity_type":"object", "entity_subtype":"power_source", "status_profile":"object_thermal", "property_profile":"definition_schema", "interaction_profile":"standard_object", "notification_profile":"standard_action", "power_profile":"internal_only", "control_profile":"none", "access_profile":"none", "binding_profile":"none", "runtime_presentation_profile":"standard_object", "editor_presentation_profile":"standard_object", "validation_fixture":"default", "capabilities":{"state":true, "power":true, "health":true, "energy":false, "overheat":true, "control":false, "access":false, "bindings":false, "mount":false, "side":false, "routing":false, "test_override":true}},
		"archetype_id":"power_source", "object_group":"power", "object_type":"power_source", "palette_label":"Power Source", "display_name_template":"Power Source C{power_source_class}",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false,
		"configurable":true, "interactable":true, "blocks_movement":true, "blocks_vision":false,
		"intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"active",
		"power_mode":"internal", "generic_power_role":"power_source", "power_source_class":1, "outlet_capacity":4, "circuit_id":"",
		"visual_family":"power_source", "visual_surface":"floor", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true,
		"property_schema":[
			{"field":"power_source_class", "type":"enum", "values":[1,2,3], "default":1, "labels":{"1":"Class 1", "2":"Class 2", "3":"Class 3"}},
			{"field":"outlet_capacity", "type":"int", "default":4, "min":1},
			{"field":"circuit_id", "type":"string", "default":""}
		]
	},
	"power_cable":{
		"entity_contract":{"scope":"entity", "entity_type":"cable", "entity_subtype":"power_cable", "status_profile":"cable_standard", "property_profile":"definition_schema", "interaction_profile":"cable", "notification_profile":"standard_action", "power_profile":"none", "control_profile":"none", "access_profile":"none", "binding_profile":"none", "runtime_presentation_profile":"standard_cable", "editor_presentation_profile":"standard_cable", "validation_fixture":"default", "capabilities":{"state":true, "power":false, "health":true, "energy":false, "overheat":false, "control":false, "access":false, "bindings":false, "mount":true, "side":false, "routing":true, "test_override":true}},
		"archetype_id":"power_cable", "object_group":"power", "object_type":"power_cable", "palette_label":"Power Cable", "display_name_template":"Power Cable",
		"placement_mode":"object", "placement_surfaces":["floor","wall"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":true,
		"configurable":true, "interactable":true, "blocks_movement":false, "blocks_vision":false,
		"health_state":"healthy", "operational_state":"connected", "mount":"floor", "route_visibility":"external", "circuit_id":"",
		"generic_power_role":"cable_link", "physical_topology_only":true,
		"property_schema":[
			{"field":"mount", "type":"enum", "values":["floor","wall"], "default":"floor", "labels":{"floor":"Floor", "wall":"Wall"}},
			{"field":"route_visibility", "type":"enum", "values":["external","internal"], "default":"external", "labels":{"external":"External", "internal":"Internal"}},
			{"field":"circuit_id", "type":"string", "default":""}
		]
	},
	"fuse_box":{
		"entity_contract":{"scope":"entity", "entity_type":"object", "entity_subtype":"fuse_box", "status_profile":"object_standard", "property_profile":"definition_schema", "interaction_profile":"standard_object", "notification_profile":"standard_action", "power_profile":"external_only", "control_profile":"none", "access_profile":"none", "binding_profile":"none", "runtime_presentation_profile":"standard_object", "editor_presentation_profile":"standard_object", "validation_fixture":"default", "capabilities":{"state":true, "power":true, "health":true, "energy":false, "overheat":false, "control":false, "access":false, "bindings":false, "mount":true, "side":true, "routing":false, "test_override":true}},
		"archetype_id":"fuse_box", "object_group":"power", "object_type":"fuse_box", "palette_label":"Fuse Box", "display_name_template":"Fuse Box",
		"placement_mode":"object", "placement_surfaces":["floor","wall"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":true,
		"configurable":true, "interactable":true, "blocks_movement":false, "blocks_vision":false,
		"health_state":"healthy", "operational_state":"empty", "power_mode":"external", "has_fuse":false, "mount":"floor", "facing_side":"SW", "circuit_id":"",
		"generic_power_role":"fuse_route", "physical_topology_only":true, "visual_family":"fuse_box", "visual_state_policy":"fuse_box_line_power_state", "variant_policy":"fuse_presence",
		"property_schema":[
			{"field":"facing_side", "type":"enum", "values":["SW","SE"], "default":"SW", "labels":{"SW":"SW", "SE":"SE"}},
			{"field":"mount", "type":"enum", "values":["floor","wall"], "default":"floor", "labels":{"floor":"Floor", "wall":"Wall"}},
			{"field":"has_fuse", "type":"bool", "default":false},
			{"field":"circuit_id", "type":"string", "default":""}
		]
	},
	"power_switcher":{
		"entity_contract":{"scope":"entity", "entity_type":"object", "entity_subtype":"power_switcher", "status_profile":"object_standard", "property_profile":"definition_schema", "interaction_profile":"standard_object", "notification_profile":"standard_action", "power_profile":"external_only", "control_profile":"internal_only", "access_profile":"none", "binding_profile":"standard", "runtime_presentation_profile":"standard_object", "editor_presentation_profile":"standard_object", "validation_fixture":"default", "capabilities":{"state":true, "power":true, "health":true, "energy":false, "overheat":false, "control":true, "access":false, "bindings":true, "mount":true, "side":true, "routing":false, "test_override":true}},
		"archetype_id":"power_switcher", "object_group":"power", "object_type":"power_switcher", "palette_label":"Power Switcher", "display_name_template":"Power Switcher",
		"placement_mode":"object", "placement_surfaces":["floor","wall"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":true,
		"configurable":true, "interactable":true, "blocks_movement":false, "blocks_vision":false,
		"intent_state":"off", "health_state":"healthy", "operational_state":"active", "power_mode":"external", "control_mode":"internal",
		"switcher_type":"power_breaker", "mount":"floor", "facing_side":"SW", "circuit_id":"", "active_line_id":"", "switcher_lines":[],
		"generic_power_role":"switch_route", "physical_topology_only":true, "visual_family":"power_switcher", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true,
		"property_schema":[
			{"field":"facing_side", "type":"enum", "values":["SW","SE"], "default":"SW", "labels":{"SW":"SW", "SE":"SE"}},
			{"field":"mount", "type":"enum", "values":["floor","wall"], "default":"floor", "labels":{"floor":"Floor", "wall":"Wall"}},
			{"field":"switcher_type", "type":"enum", "values":["light_switcher","power_breaker","power_switcher"], "default":"power_breaker"},
			{"field":"intent_state", "type":"enum", "values":["off","on"], "default":"off"},
			{"field":"active_line_id", "type":"string", "default":""},
			{"field":"circuit_id", "type":"string", "default":""}
		]
	},
	"power_socket":{
		"entity_contract":{"scope":"entity", "entity_type":"object", "entity_subtype":"power_socket", "status_profile":"object_standard", "property_profile":"definition_schema", "interaction_profile":"standard_object", "notification_profile":"standard_action", "power_profile":"external_only", "control_profile":"none", "access_profile":"none", "binding_profile":"none", "runtime_presentation_profile":"standard_object", "editor_presentation_profile":"standard_object", "validation_fixture":"default", "capabilities":{"state":true, "power":true, "health":true, "energy":false, "overheat":false, "control":false, "access":false, "bindings":false, "mount":true, "side":true, "routing":true, "test_override":true}},
		"archetype_id":"power_socket", "object_group":"power", "object_type":"power_socket", "palette_label":"Power Socket", "display_name_template":"Power Socket",
		"placement_mode":"object", "placement_surfaces":["floor","wall"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":true,
		"configurable":true, "interactable":true, "blocks_movement":false, "blocks_vision":false,
		"health_state":"healthy", "operational_state":"available", "power_mode":"external", "mount":"floor", "facing_side":"SW", "circuit_id":"",
		"generic_power_role":"socket_input", "socket_role":"socket_input", "can_connect_cable":true, "accepts_runtime_power_reel":true, "power_input_profiles":["runtime_reel_feed"], "physical_topology_only":true,
		"visual_family":"power_socket", "visual_state_policy":"power_socket_connection_state", "power_visual_state_enabled":false,
		"property_schema":[
			{"field":"facing_side", "type":"enum", "values":["SW","SE"], "default":"SW", "labels":{"SW":"SW", "SE":"SE"}},
			{"field":"mount", "type":"enum", "values":["floor","wall"], "default":"floor", "labels":{"floor":"Floor", "wall":"Wall"}},
			{"field":"circuit_id", "type":"string", "default":""}
		]
	},
	"light":{
		"entity_contract":{"scope":"entity", "entity_type":"light", "entity_subtype":"light", "status_profile":"light_standard", "property_profile":"definition_schema", "interaction_profile":"light", "notification_profile":"standard_action", "power_profile":"external_only", "control_profile":"internal_only", "access_profile":"none", "binding_profile":"standard", "runtime_presentation_profile":"standard_light", "editor_presentation_profile":"standard_light", "validation_fixture":"default", "capabilities":{"state":true, "power":true, "health":true, "energy":false, "overheat":true, "control":true, "access":false, "bindings":true, "mount":true, "side":true, "routing":false, "test_override":true}},
		"archetype_id":"light", "object_group":"power", "object_type":"light", "palette_label":"Light", "display_name_template":"Light",
		"placement_mode":"wall_mounted", "placement_surfaces":["wall"], "default_placement_surface":"wall", "requires_floor_anchor_when_wall_mounted":true,
		"configurable":true, "interactable":true, "blocks_movement":false, "blocks_vision":false,
		"intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"active", "power_mode":"external", "control_mode":"internal",
		"mount":"wall", "facing_side":"SW", "light_group_id":"", "circuit_id":"", "visual_family":"light", "visual_surface":"wall", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true,
		"property_schema":[
			{"field":"facing_side", "type":"enum", "values":["SW","SE"], "default":"SW", "labels":{"SW":"SW", "SE":"SE"}},
			{"field":"light_group_id", "type":"string", "default":""},
			{"field":"circuit_id", "type":"string", "default":""}
		]
	}
}

static func is_family(value: String) -> bool:
	return FAMILY_IDS.has(value.strip_edges().to_lower())

static func is_alias(value: String) -> bool:
	return ALIASES.has(value.strip_edges().to_lower())

static func canonical_id(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	return str(ALIASES.get(normalized, normalized))

static func alias_defaults(value: String) -> Dictionary:
	var normalized: String = value.strip_edges().to_lower()
	return Dictionary(ALIAS_DEFAULTS.get(normalized, {})).duplicate(true)

static func definition(value: String) -> Dictionary:
	var id: String = canonical_id(value)
	return Dictionary(DEFINITIONS.get(id, {})).duplicate(true)

static func normalize_new_record(record: Dictionary, requested_id: String = "") -> Dictionary:
	var source: Dictionary = record.duplicate(true)
	var token: String = requested_id.strip_edges().to_lower()
	if token.is_empty():
		token = str(source.get("archetype_id", source.get("object_type", ""))).strip_edges().to_lower()
	var id: String = canonical_id(token)
	if not is_family(id):
		return source
	var defaults: Dictionary = definition(id)
	for key in defaults.keys():
		if key in ["entity_contract", "property_schema", "palette_label", "display_name_template"]:
			continue
		if not source.has(key):
			source[key] = defaults[key]
	for key in alias_defaults(token).keys():
		source[key] = alias_defaults(token)[key]
	_apply_legacy_axis_values(source, id)
	_strip_authoring_double_truth(source)
	source["archetype_id"] = id
	source["object_type"] = id
	source["object_group"] = "power"
	source["entity_contract_id"] = id
	source["entity_contract_scope"] = "entity"
	source["entity_type"] = str(Dictionary(defaults.get("entity_contract", {})).get("entity_type", "object"))
	source["entity_subtype"] = str(Dictionary(defaults.get("entity_contract", {})).get("entity_subtype", id))
	if id == "power_source":
		source["power_mode"] = "internal"
		source["outlet_capacity"] = maxi(1, int(source.get("outlet_capacity", int(source.get("power_source_class", 1)) + 3)))
	if id in ["fuse_box", "power_switcher", "power_socket", "light"]:
		source["power_mode"] = "external"
	if id == "power_switcher":
		source["control_mode"] = "internal"
	if id == "light":
		source["control_mode"] = "internal"
	if id == "fuse_box":
		source["has_fuse"] = bool(source.get("has_fuse", false))
		source["operational_state"] = "installed" if bool(source["has_fuse"]) else "empty"
	return source

static func adapt_legacy_read_only(record: Dictionary) -> Dictionary:
	var source_before: Dictionary = record.duplicate(true)
	var token: String = str(record.get("map_constructor_prefab_id", record.get("legacy_prefab_id", record.get("archetype_id", record.get("object_type", ""))))).strip_edges().to_lower()
	var adapted_source: Dictionary = record.duplicate(true)
	_apply_legacy_axis_values(adapted_source, canonical_id(token))
	var result: Dictionary = normalize_new_record(adapted_source, token)
	result["legacy_adapter"] = true
	result["legacy_source_unchanged"] = record == source_before
	return result

static func _apply_legacy_axis_values(record: Dictionary, id: String) -> void:
	var legacy_state: String = str(record.get("state", record.get("status", ""))).strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	if not record.has("intent_state"):
		if record.has("is_on"):
			record["intent_state"] = "on" if bool(record.get("is_on", false)) else "off"
		elif legacy_state in ["off", "switch_off"]:
			record["intent_state"] = "off"
		elif id in ["power_source", "power_switcher", "light"]:
			record["intent_state"] = "on"
	if not record.has("health_state"):
		record["health_state"] = "broken" if bool(record.get("broken", false)) or bool(record.get("destroyed", false)) or legacy_state in ["broken", "destroyed"] else "damaged" if bool(record.get("damaged", false)) or legacy_state == "damaged" else "healthy"
	if id in ["power_source", "light"] and not record.has("thermal_state"):
		record["thermal_state"] = "overheated" if bool(record.get("overheated", false)) or legacy_state in ["overheat", "overheated"] else "normal"
	if not record.has("operational_state"):
		match id:
			"power_cable":
				record["operational_state"] = "broken" if str(record.get("health_state", "healthy")) == "broken" else "disconnected" if bool(record.get("disconnected", false)) or (record.has("connected") and not bool(record.get("connected", true))) else "connected"
			"fuse_box":
				var present: bool = bool(record.get("has_fuse", record.get("fuse_present", record.get("fuse_installed", legacy_state == "installed"))))
				record["has_fuse"] = present
				record["operational_state"] = "installed" if present else "empty"
			_:
				record["operational_state"] = "active"
	if record.has("power_network_id") and not record.has("circuit_id"):
		var legacy_circuit: String = str(record.get("power_network_id", "")).strip_edges()
		if not legacy_circuit.is_empty() and legacy_circuit != "main_power_net":
			record["circuit_id"] = legacy_circuit
	if record.has("cable_install_mode") and not record.has("mount"):
		var legacy_mount: String = str(record.get("cable_install_mode", "floor")).strip_edges().to_lower()
		record["mount"] = "wall" if legacy_mount == "wall" else "floor"

static func _strip_authoring_double_truth(record: Dictionary) -> void:
	for field_name in COMPUTED_POWER_FIELDS:
		record.erase(field_name)
	for field_name in LEGACY_AUTHORING_FIELDS:
		record.erase(field_name)

extends RefCounted

class_name TaskTestWorldBuilder

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

static func build_world_objects() -> Array[Dictionary]:
	var validation_data: Dictionary = build_validation_world_objects()
	var source_objects: Array = Array(validation_data.get("objects", []))
	var objects: Array[Dictionary] = []
	for object_variant in source_objects:
		var object_data: Dictionary = Dictionary(object_variant).duplicate(true)
		objects.append(object_data)
	return objects

static func build_validation_world_objects() -> Dictionary:
	var warnings: Array[String] = []
	var objects: Array[Dictionary] = []
	var specs: Array[Dictionary] = [
		# Basic doors
		{"type":"door","id":"task_test_door_open_mechanical","pos":Vector2i(2, 1),"extra":{"door_type":"mechanical","material":"steel","access_type":"key_card","state":"open"}},
		{"type":"door","id":"task_test_door_closed_mechanical","pos":Vector2i(3, 1),"extra":{"door_type":"mechanical","material":"steel","access_type":"key_card","state":"closed"}},
		{"type":"door","id":"task_test_door_jammed","pos":Vector2i(4, 1),"extra":{"door_type":"mechanical","material":"steel","access_type":"no_key","state":"jammed","damaged":true}},
		# Mechanical key doors
		{"type":"door","id":"task_test_door_locked_mechanical","pos":Vector2i(6, 1),"extra":{"door_type":"mechanical","material":"steel","access_type":"key_card","state":"locked","required_key_id":"task_test_item_mechanical_keycard"}},
		# Digital key doors
		{"type":"door","id":"task_test_door_open_digital","pos":Vector2i(8, 1),"extra":{"door_type":"digital","material":"energy","access_type":"digital_key","state":"open","required_key_id":"task_test_item_digital_key_opened","power_network_id":"task_test_power_main"}},
		{"type":"door","id":"task_test_door_locked_digital","pos":Vector2i(9, 1),"extra":{"door_type":"digital","material":"energy","access_type":"digital_key","state":"locked","required_key_id":"task_test_item_digital_key_encrypted","power_network_id":"task_test_power_main"}},
		# Terminal-controlled doors
		{"type":"door","id":"task_test_door_terminal_locked","pos":Vector2i(11, 1),"extra":{"door_type":"digital","material":"reinforced_steel","access_type":"terminal","state":"locked","linked_terminal_id":"task_test_terminal_basic_door"}},
		{"type":"terminal","id":"task_test_terminal_basic_door","pos":Vector2i(12, 1),"extra":{"terminal_type":"control","controlled_target_type":"door","state":"active","is_powered":true,"target_door_id":"task_test_door_terminal_locked"}},
		# Powered gates
		{"type":"door","id":"task_test_powered_gate_main","pos":Vector2i(2, 3),"extra":{"door_type":"powered","material":"energy","access_type":"no_key","power_behavior":"opens_when_unpowered","power_type":"external","state":"closed","requires_external_power":true,"power_network_id":"task_test_power_main"}},
		{"type":"door","id":"task_test_powered_gate_unpowered","pos":Vector2i(3, 3),"extra":{"door_type":"powered","material":"energy","access_type":"no_key","power_behavior":"opens_when_unpowered","power_type":"external","state":"unpowered","requires_external_power":true,"is_powered":false,"power_network_id":"task_test_power_missing"}},
		{"type":"door","id":"task_test_power_required_door","pos":Vector2i(4, 3),"extra":{"door_type":"powered","material":"energy","access_type":"no_key","power_behavior":"requires_power_to_open","power_type":"external","state":"unpowered","requires_external_power":true,"is_powered":false,"power_network_id":"task_test_power_missing"}},
		# Power network
		{"type":"power_source_class_1","id":"task_test_source_class_1","pos":Vector2i(5, 3),"extra":{"power_network_id":"task_test_power_main","connected_device_ids":["task_test_powered_gate_main"]}},
		{"type":"power_source_class_2","id":"task_test_source_class_2","pos":Vector2i(6, 3),"extra":{"power_network_id":"task_test_power_main","connected_device_ids":["task_test_terminal_basic_door"],"current_heat":2,"working_heat":3,"overheat_threshold":6}},
		{"type":"power_source_class_3","id":"task_test_source_class_3","pos":Vector2i(7, 3),"extra":{"power_network_id":"task_test_power_main","connected_device_ids":["task_test_terminal_connector_gate"]}},
		{"type":"power_source_class_3","id":"task_test_source_overheated","pos":Vector2i(8, 3),"extra":{"power_network_id":"task_test_power_main","state":"overheated","current_heat":8,"working_heat":4,"overheat_threshold":4}},
		{"type":"circuit_breaker","id":"task_test_breaker","pos":Vector2i(9, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"circuit_switch","id":"task_test_switch","pos":Vector2i(10, 3),"extra":{"power_network_id":"task_test_power_main","target_door_id":"task_test_control_switch_door"}},
		{"type":"fuse_box_empty","id":"task_test_fuse_box_empty","pos":Vector2i(11, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"fuse_box_installed","id":"task_test_fuse_box_installed","pos":Vector2i(12, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"power_socket","id":"task_test_power_socket_a","pos":Vector2i(13, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"power_cable","id":"task_test_power_cable_main","pos":Vector2i(14, 3),"extra":{"power_network_id":"task_test_power_main"}},
		{"type":"power_cable","id":"task_test_power_cable_cut","pos":Vector2i(14, 4),"extra":{"power_network_id":"task_test_power_main","state":"broken","cable_health_state":"broken","health_state":"broken","broken":true,"is_broken":true,"damaged":true,"cut":false}},
		{"type":"power_cable","id":"task_test_hidden_cable","pos":Vector2i(13, 4),"extra":{"hidden":true,"visible_with_xray":true,"power_network_id":"task_test_power_main"}},
		{"type":"power_socket","id":"task_test_hidden_socket","pos":Vector2i(12, 4),"extra":{"hidden":true,"visible_with_xray":true,"power_network_id":"task_test_power_main"}},
		# Generic cable/socket/power runtime smoke chain (PR-GEN-02)
		{"type":"power_source_class_1","id":"task_test_generic_power_source","pos":Vector2i(2, 9),"extra":{"generic_power_runtime":true,"generic_power_role":"power_source","power_network_id":"task_test_generic_power_smoke","connection_id":"task_test_generic_conn_valid","source_object_id":"task_test_generic_power_source","is_connected":true,"connected":true,"power_state":"source_on","power_received":1}},
		{"type":"power_socket","id":"task_test_generic_socket_input","pos":Vector2i(3, 9),"extra":{"generic_power_runtime":true,"generic_power_role":"socket_input","socket_role":"socket_input","power_network_id":"task_test_generic_power_smoke","connection_id":"task_test_generic_conn_valid","source_object_id":"task_test_generic_power_source","endpoint_b_id":"task_test_generic_cable_link","is_connected":true,"connected":true,"disconnected":false,"state":"connected"}},
		{"type":"power_cable","id":"task_test_generic_cable_link","pos":Vector2i(4, 9),"extra":{"generic_power_runtime":true,"generic_power_role":"cable_link","power_network_id":"task_test_generic_power_smoke","connection_id":"task_test_generic_conn_valid","source_object_id":"task_test_generic_power_source","endpoint_a_id":"task_test_generic_socket_input","endpoint_b_id":"task_test_generic_socket_output","is_connected":true,"connected":true,"state":"ok"}},
		{"type":"power_socket","id":"task_test_generic_socket_output","pos":Vector2i(5, 9),"extra":{"generic_power_runtime":true,"generic_power_role":"socket_output","socket_role":"socket_output","power_network_id":"task_test_generic_power_smoke","connection_id":"task_test_generic_conn_valid","source_object_id":"task_test_generic_power_source","socket_id":"task_test_generic_socket_input","endpoint_a_id":"task_test_generic_cable_link","sink_object_id":"task_test_generic_powered_device","is_connected":true,"connected":true,"disconnected":false,"state":"connected"}},
		{"type":"terminal","id":"task_test_generic_powered_device","pos":Vector2i(6, 9),"extra":{"generic_power_runtime":true,"generic_power_role":"powered_device","terminal_type":"information","power_mode":"external_power","power_type":"external","power_network_id":"task_test_generic_power_smoke","connection_id":"task_test_generic_conn_valid","source_object_id":"task_test_generic_power_source","socket_id":"task_test_generic_socket_output","endpoint_a_id":"task_test_generic_socket_output","power_required":true,"is_connected":true,"connected":true,"is_powered":false,"power_state":"unpowered","state":"unpowered","status":"unpowered"}},
		{"type":"terminal","id":"task_test_generic_unpowered_device","pos":Vector2i(7, 9),"extra":{"generic_power_runtime":true,"generic_power_role":"powered_device","terminal_type":"information","power_mode":"external_power","power_type":"external","power_network_id":"task_test_generic_power_smoke","connection_id":"task_test_generic_conn_incomplete","source_object_id":"task_test_generic_missing_source","socket_id":"task_test_generic_missing_socket","power_required":true,"is_connected":true,"connected":true,"is_powered":false,"power_state":"unpowered","state":"unpowered","status":"unpowered"}},
		# Generic fan/airflow/cooling runtime smoke chain (PR-GEN-03)
		{"type":"external_air_cooler","id":"task_test_generic_airflow_fan","pos":Vector2i(9, 9),"extra":{"generic_airflow_runtime":true,"generic_airflow_role":"fan","airflow_roles":["fan","airflow_source"],"airflow_network_id":"task_test_generic_airflow_smoke","fan_object_id":"task_test_generic_airflow_fan","fan_enabled":true,"fan_direction":"right","facing_dir":"right","fan_speed":3,"airflow_range":4,"cooling_output":2,"linked_cooling_ids":["task_test_generic_airflow_target","task_test_generic_uncooled_target"],"cooling_state":"uncooled"}},
		{"type":"light","id":"task_test_generic_airflow_path_cell","pos":Vector2i(10, 9),"extra":{"generic_airflow_runtime":true,"generic_airflow_role":"airflow_path_cell","airflow_roles":["airflow_path_cell"],"airflow_network_id":"task_test_generic_airflow_smoke","blocks_movement":false,"blocks_airflow":false,"state":"active","light_enabled":false,"is_on":false}},
		{"type":"terminal","id":"task_test_generic_airflow_target","pos":Vector2i(11, 9),"extra":{"generic_airflow_runtime":true,"generic_airflow_role":"cooling_target","airflow_roles":["cooling_target","heat_sensitive_terminal"],"airflow_network_id":"task_test_generic_airflow_smoke","terminal_type":"information","state":"active","is_powered":true,"working_heat":2,"current_heat":2,"overheat_threshold":3,"cooling_required":true,"cooling_received":0,"is_cooled":false,"cooling_state":"uncooled"}},
		{"type":"steel_box","id":"task_test_generic_airflow_blocker","pos":Vector2i(12, 9),"extra":{"generic_airflow_runtime":true,"generic_airflow_role":"airflow_blocker","airflow_roles":["airflow_blocker"],"airflow_network_id":"task_test_generic_airflow_smoke","blocks_airflow":true,"blocks_movement":true,"state":"active"}},
		{"type":"terminal","id":"task_test_generic_uncooled_target","pos":Vector2i(13, 9),"extra":{"generic_airflow_runtime":true,"generic_airflow_role":"cooling_target","airflow_roles":["cooling_target","heat_sensitive_terminal"],"airflow_network_id":"task_test_generic_airflow_smoke","terminal_type":"information","state":"active","is_powered":true,"working_heat":2,"current_heat":2,"overheat_threshold":3,"cooling_required":true,"cooling_received":0,"is_cooled":false,"cooling_state":"uncooled"}},
		# Cooling network
		{"type":"external_radiator","id":"task_test_radiator","pos":Vector2i(2, 5),"extra":{"cooling_device_type":"radiator","cooling_output":3}},
		{"type":"external_air_cooler","id":"task_test_air_cooler","pos":Vector2i(3, 5),"extra":{"cooling_device_type":"air_cooler","cooling_output":2,"directed_airflow":true,"facing_dir":"right"}},
		{"type":"metal_cooling_block","id":"task_test_cooling_block","pos":Vector2i(4, 5),"extra":{"cooling_device_type":"block","cooling_output":1}},
		{"type":"terminal","id":"task_test_terminal_heat_device","pos":Vector2i(5, 5),"extra":{"state":"active","is_powered":true,"working_heat":4,"current_heat":6,"overheat_threshold":9,"cooling_received":1,"overheated_state_before":false}},
		{"type":"terminal","id":"task_test_terminal_overheated","pos":Vector2i(6, 5),"extra":{"status":"active","state":"active","is_powered":true,"working_heat":3,"current_heat":7,"overheat_threshold":5,"cooling_received":0,"overheated_state_before":true}},
		# Control network
		{"type":"door","id":"task_test_control_switch_door","pos":Vector2i(8, 5),"extra":{"door_type":"mechanical","material":"steel","access_type":"no_key","state":"closed","control_type":"external","control_source_id":"task_test_switch","requires_external_control":true}},
		{"type":"lifting_platform","id":"task_test_control_terminal_platform","pos":Vector2i(9, 5),"extra":{"platform_id":"task_test_control_terminal_platform","platform_cells":[[9, 5]],"control_type":"terminal","linked_terminal_id":"task_test_terminal_control","requires_external_control":true,"requires_terminal_enabled":true}},
		{"type":"terminal","id":"task_test_terminal_control","pos":Vector2i(10, 5),"extra":{"terminal_type":"control","controlled_target_type":"platform","linked_platform_ids":["task_test_control_terminal_platform"],"state":"active","is_powered":true,"target_platform_id":"task_test_control_terminal_platform"}},
		{"type":"rotating_platform","id":"task_test_control_missing_source","pos":Vector2i(11, 5),"extra":{"platform_id":"task_test_control_missing_source","platform_cells":[[11, 5]],"requires_external_control":true}},
		{"type":"rotating_platform","id":"task_test_control_invalid_source","pos":Vector2i(12, 5),"extra":{"platform_id":"task_test_control_invalid_source","platform_cells":[[12, 5]],"requires_external_control":true,"control_source_id":"task_test_missing_controller"}},
		{"type":"rotating_platform","id":"task_test_control_valid_source","pos":Vector2i(13, 5),"extra":{"platform_id":"task_test_control_valid_source","platform_cells":[[13, 5]],"requires_external_control":true,"control_source_id":"task_test_switch"}},
		# Wall material samples
		{"type":"outer_wall","id":"task_test_outer_wall_sample","pos":Vector2i(2, 7),"extra":{"material":"outer_wall","durability":99999,"blocks_movement":true,"blocks_vision":true,"destructible":false}},
		{"type":"brick_wall","id":"task_test_brick_wall_sample","pos":Vector2i(3, 7),"extra":{"material":"brick","durability":6,"blocks_movement":true,"blocks_vision":true,"destructible":true}},
		{"type":"concrete_wall","id":"task_test_concrete_wall_sample","pos":Vector2i(4, 7),"extra":{"material":"concrete","durability":8,"blocks_movement":true,"blocks_vision":true,"destructible":true}},
		{"type":"steel_wall","id":"task_test_steel_wall_sample","pos":Vector2i(5, 7),"extra":{"material":"steel","durability":12,"blocks_movement":true,"blocks_vision":true,"destructible":true}},
		{"type":"reinforced_steel_wall","id":"task_test_reinforced_wall_sample","pos":Vector2i(6, 7),"extra":{"material":"reinforced_steel","durability":18,"blocks_movement":true,"blocks_vision":true,"destructible":false}},
		{"type":"grate_wall","id":"task_test_grate_wall_sample","pos":Vector2i(7, 7),"extra":{"material":"grate","durability":4,"blocks_movement":true,"blocks_vision":false,"destructible":true}},
		{"type":"damaged_wall","id":"task_test_damaged_wall_sample","pos":Vector2i(8, 7),"extra":{"material":"concrete","durability":2,"blocks_movement":true,"blocks_vision":false,"destructible":true,"hidden_content":"wiring_fragment"}},
		# Scan visibility samples
		{"type":"power_cable","id":"task_test_scan_hidden_object","pos":Vector2i(10, 7),"extra":{"hidden":true,"visible_with_xray":true,"scan_level":1}},
		{"type":"terminal","id":"task_test_scan_thermal_object","pos":Vector2i(11, 7),"extra":{"visible_with_thermal":true,"current_heat":5,"working_heat":2}},
		{"type":"terminal","id":"task_test_scan_connector_gated","pos":Vector2i(12, 7),"extra":{"required_connector_level":2,"state":"active","is_powered":true}},
		{"type":"terminal","id":"task_test_scan_processor_gated","pos":Vector2i(13, 7),"extra":{"required_processor_level":2,"state":"active","is_powered":true}},
		{"type":"light","id":"task_test_scan_normal_visible","pos":Vector2i(14, 8),"extra":{"hidden":false,"light_enabled":true,"is_on":true,"state":"active"}},
		# Terminals coverage + extraction
		{"type":"terminal","id":"task_test_terminal_info","pos":Vector2i(1, 8),"extra":{"terminal_type":"information","controlled_target_type":"none","connection_type":"info","state":"active","is_powered":true}},
		{"type":"terminal","id":"task_test_terminal_unpowered","pos":Vector2i(2, 8),"extra":{"status":"unpowered","state":"unpowered","is_powered":false}},
		{"type":"terminal","id":"task_test_terminal_damaged","pos":Vector2i(3, 8),"extra":{"status":"damaged","state":"damaged","damaged":true,"is_powered":false}},
		{"type":"terminal","id":"task_test_terminal_encrypted","pos":Vector2i(4, 8),"extra":{"state":"active","is_powered":true,"encrypts_data":true,"drain_pool":2}},
		{"type":"terminal","id":"task_test_terminal_connector_gate","pos":Vector2i(5, 8),"extra":{"state":"active","is_powered":true,"required_connector_level":1}},
		{"type":"terminal","id":"task_test_terminal_processor_gate","pos":Vector2i(6, 8),"extra":{"state":"active","is_powered":true,"required_processor_level":1}},
		
		{"type":"terminal","id":"task_test_terminal_main","pos":Vector2i(7, 8),"extra":{"terminal_type":"control","controlled_target_type":"door","state":"active","is_powered":true,"required_connector_level":1,"required_processor_level":1,"target_door_id":"task_test_door_terminal_locked"}},
		{"type":"door","id":"task_test_door_mechanical","pos":Vector2i(5, 1),"extra":{"door_type":"mechanical","material":"steel","access_type":"key_card","state":"locked","required_key_id":"task_test_item_mechanical_keycard"}},
		{"type":"lifting_platform","id":"task_test_platform_lift","pos":Vector2i(8, 8),"extra":{"platform_id":"task_test_platform_lift","platform_cells":[[8, 8]],"is_powered":false,"requires_external_power":true,"power_network_id":"task_test_power_missing"}},
		{"type":"lifting_platform","id":"task_test_platform_self_control","pos":Vector2i(9, 8),"extra":{"platform_id":"task_test_platform_self_control","object_group":"platform","object_type":"platform","platform_mode":"elevator","platform_type":"lifting","platform_cells":[[9, 8]],"control_mode":"cell","control_type":"internal","power_mode":"internal","power_type":"internal","operation":"toggle","platform_action":"raise","control_cell":Vector2i(9, 8),"control_cell_x":9,"control_cell_y":8,"platform_level":0,"current_level":0,"height_level":0,"max_level":1,"max_height_level":1,"is_powered":true,"blocks_movement":false,"walkable":true}},
		{"type":"power_cable","id":"task_test_xray_route_marker","pos":Vector2i(9, 7),"extra":{"hidden":true,"visible_with_xray":true}},
{"type":"door","id":"task_test_extraction_door","pos":Vector2i(14, 7),"extra":{"door_type":"digital","material":"energy","access_type":"digital_key","state":"open","mission_exit":true,"extraction":true}}
	]
	for spec in specs:
		var obj: Dictionary = WorldObjectCatalogRef.create_world_object(str(spec.get("type", "")), str(spec.get("id", "")))
		if obj.is_empty():
			warnings.append("catalog_create_failed_%s" % str(spec.get("id", "")))
			continue
		obj["position"] = Vector2i(spec.get("pos", Vector2i.ZERO))
		var extra: Dictionary = Dictionary(spec.get("extra", {}))
		for key_variant in extra.keys():
			var key_name: String = str(key_variant)
			obj[key_name] = extra[key_variant]
		obj = WorldObjectCatalogRef.normalize_door_state_fields(WorldObjectCatalogRef.normalize_world_object_contract(obj))
		objects.append(obj)

	var items_by_cell: Dictionary = {}
	var key_specs: Array[Dictionary] = [
		{"type":"item","id":"task_test_item_mechanical_keycard","cell":Vector2i(1, 1),"extra":{"item_class":"key_card"}},
		{"type":"item","id":"task_test_item_digital_key_opened","cell":Vector2i(1, 3),"extra":{"item_class":"digital_key","digital_state":"opened"}},
		{"type":"item","id":"task_test_item_digital_key_encrypted","cell":Vector2i(1, 5),"extra":{"item_class":"digital_key","digital_state":"encrypted"}},
		{"type":"item","id":"task_test_item_digital_key_damaged","cell":Vector2i(1, 6),"extra":{"item_class":"digital_key","digital_state":"damaged"}},
		{"type":"item","id":"task_test_item_access_code","cell":Vector2i(1, 7),"extra":{"item_class":"access_code"}},
		{"type":"fuse","id":"task_test_item_fuse","cell":Vector2i(1, 2),"extra":{}},
		{"type":"power_cable_reel","id":"task_test_cable_reel","cell":Vector2i(2, 2),"extra":{}},
		{"type":"repair_kit","id":"task_test_item_repair_kit","cell":Vector2i(2, 6),"extra":{}}
	]
	for item_spec in key_specs:
		var item: Dictionary = WorldObjectCatalogRef.create_world_object(str(item_spec.get("type", "")), str(item_spec.get("id", "")))
		if item.is_empty():
			warnings.append("catalog_create_failed_%s" % str(item_spec.get("id", "")))
			continue
		var extra_item: Dictionary = Dictionary(item_spec.get("extra", {}))
		for item_key_variant in extra_item.keys():
			var item_key: String = str(item_key_variant)
			item[item_key] = extra_item[item_key_variant]
		item = WorldObjectCatalogRef.normalize_item_contract(WorldObjectCatalogRef.normalize_archetype_object(WorldObjectCatalogRef.normalize_world_object_contract(item)))
		var cell: Vector2i = Vector2i(item_spec.get("cell", Vector2i.ZERO))
		if not items_by_cell.has(cell):
			items_by_cell[cell] = []
		var local_cell_items: Array = Array(items_by_cell[cell])
		local_cell_items.append(item)
		items_by_cell[cell] = local_cell_items
	return {"objects": objects.duplicate(true), "items_by_cell": items_by_cell.duplicate(true), "warnings": warnings.duplicate()}


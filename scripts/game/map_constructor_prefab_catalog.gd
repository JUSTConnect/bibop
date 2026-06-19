extends RefCounted

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

# Ownership boundary:
# WorldObjectCatalog owns constructor gameplay/domain placement contracts.
# MapConstructorPrefabCatalog owns constructor palette presentation metadata only.
# MissionManager owns runtime orchestration, filtering, validation, geometry, occupancy, and mission state.

static func _get_presentation_catalog() -> Dictionary:
	var metadata: Dictionary = {
		"floor": {"display_name":"Floor","category":"Structural","subcategory":"Configurable Floor","system_roles":["navigation"],"tags":["floor","walkable","structural","configurable","archetype"],"description":"Configurable Floor archetype. Choose material, covering, visual style, and state properties in the inspector.","placement_hint":"Place the base Floor, then configure properties.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"stepped_floor": {"display_name":"Stepped Floor","category":"Structural","subcategory":"Floor","system_roles":["navigation"],"tags":["floor","walkable","elevation"],"description":"Walkable stepped floor tile.","placement_hint":"Use for alternate floor visuals.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"external_wall": {"display_name":"External Wall","category":"Structural","subcategory":"Wall","system_roles":["blocking"],"tags":["wall","solid","boundary","fixed_archetype"],"description":"Fixed external structural wall. Gameplay parameters are not editable.","placement_hint":"Place the fixed external wall archetype.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"wall": {"display_name":"Wall","category":"Structural","subcategory":"Wall","system_roles":["blocking"],"tags":["wall","obstacle","configurable","archetype"],"description":"Configurable internal wall. Choose material in the inspector.","placement_hint":"Place Wall, then configure its canonical material property.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"door": {"display_name":"Door","category":"Door","subcategory":"Configurable","system_roles":["navigation","access_control"],"tags":["door","configurable","archetype"],"description":"Configurable door archetype. Choose material, access, power, control, and state properties in the inspector.","placement_hint":"Place the base Door, then configure properties.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"terminal": {"display_name":"Terminal","category":"Terminal","subcategory":"Configurable","system_roles":["terminal_interaction","signal_control"],"tags":["terminal","configurable","archetype"],"description":"Configurable terminal archetype. Choose role, target, class, power, control, status, and links in the inspector.","placement_hint":"Place the base Terminal, then configure properties.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"item": {"display_name":"Item","category":"Item","subcategory":"Configurable","system_roles":["item"],"tags":["item","configurable","archetype"],"description":"Configurable Item archetype. Choose item class, storage route, state, and optional door link in the inspector.","placement_hint":"Place the base Item, then configure properties.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{}},
		"firewall": {"display_name":"Firewall Node","category":"Control","subcategory":"Security","system_roles":["signal_control"],"tags":["firewall","security","control"],"description":"Floor security node controlled through terminal links.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"power_source_class_1": {"display_name":"Power Source C1","category":"Power","subcategory":"Source","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Primary local power source.","placement_hint":"Set power_network_id in inspector after placement.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"state":"on","power_mode":"internal","control_mode":"internal","is_powered":true,"power_source_class":1,"outlet_capacity":4}},
		"power_source_class_2": {"display_name":"Power Source C2","category":"Power","subcategory":"Source","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Class 2 power source.","placement_hint":"Place beside wires/outlets.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"state":"on","power_mode":"internal","control_mode":"internal","is_powered":true,"power_source_class":2,"outlet_capacity":5}},
		"power_source_class_3": {"display_name":"Power Source C3","category":"Power","subcategory":"Source","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Class 3 power source.","placement_hint":"Place beside wires/outlets.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"state":"on","power_mode":"internal","control_mode":"internal","is_powered":true,"power_source_class":3,"outlet_capacity":6}},
		"power_socket": {"display_name":"Power Socket","category":"Power","subcategory":"Connector","system_roles":["power_network","power_consumer"],"tags":["power","socket","connector"],"description":"Power connector point for devices.","placement_hint":"Set power_network_id in inspector after placement. Wall placement is optional.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"power_cable": {"display_name":"Power Cable","category":"Power","subcategory":"Network","system_roles":["power_network"],"tags":["power","cable","network"],"description":"Cable segment for power routing.","placement_hint":"Set power_network_id in inspector after placement. Wall placement is optional.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"wall_routing_mode":"outer"}},
		"circuit_switch": {"display_name":"Circuit Switch","category":"Control","subcategory":"Power","system_roles":["signal_control","power_network"],"tags":["switch","circuit","control"],"description":"Switch controlling power state.","placement_hint":"Configure links in inspector after placement.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"circuit_breaker": {"display_name":"Circuit Breaker","category":"Power","subcategory":"Protection","system_roles":["power_network","signal_control"],"tags":["breaker","power","wall"],"description":"Wall-mounted power safety breaker.","placement_hint":"Requires a valid adjacent wall side.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"light": {"display_name":"Light","category":"Power","subcategory":"Lighting","system_roles":["lighting","power_consumer"],"tags":["light","lighting","wall"],"description":"Wall light linked logically to a power source.","placement_hint":"Requires a wall cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{"brightness":"1.0","color":"#ffffff"}},
		"external_air_duct": {"display_name":"External Air Duct","category":"Cooling System","subcategory":"Wall-mounted","constructor_group":"cooling_system","constructor_category":"Cooling System","constructor_tab":"cooling_system","system_roles":["cooling","airflow"],"tags":["air","duct","wall"],"description":"Wall-mounted external air duct.","placement_hint":"Requires a wall cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{"route_mode":"inner","wall_routing_mode":"inner","routing_kind":"air_duct","cooling_system_type":"air_duct","cooling_contour_mode":"auto","cooling_contour_id":"","cooling_contour_member_ids":[],"wall_side_1":"NW","wall_side_2":"SE"}},
		"external_water_pipe": {"display_name":"External Water Pipe","category":"Cooling System","subcategory":"Wall-mounted","constructor_group":"cooling_system","constructor_category":"Cooling System","constructor_tab":"cooling_system","system_roles":["cooling","water"],"tags":["water","pipe","wall"],"description":"Wall-mounted external water pipe.","placement_hint":"Requires a wall cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{"route_mode":"inner","wall_routing_mode":"inner","routing_kind":"water_pipe","cooling_system_type":"water_pipe","cooling_contour_mode":"auto","cooling_contour_id":"","cooling_contour_member_ids":[],"wall_side_1":"NW","wall_side_2":"SE"}},
		"light_switch": {"display_name":"Light Switch","category":"Control","subcategory":"Lighting","system_roles":["signal_control","power_consumer"],"tags":["switch","light","wall"],"description":"Wall-mounted switch for lights/devices.","placement_hint":"Requires a valid adjacent wall side.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"power_switcher": {"display_name":"Power Switcher","category":"Power","subcategory":"Control","system_roles":["signal_control","power_network"],"tags":["switch","power","configurable"],"description":"Logical power switcher. Configure mount=floor/wall and switch_state=on/off in the inspector.","placement_hint":"Place on floor by default; set mount to wall for wall art and wall-mounted behavior.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{"mount":"floor","switch_state":"off","state":"switch_off","is_on":false}},
		"fuse_box": {"display_name":"Fuse Box","category":"Power","subcategory":"Protection","system_roles":["power_network","power_consumer"],"tags":["fuse","power","configurable"],"description":"Logical fuse box. Configure mount=floor/wall and fuse_present=true/false in the inspector.","placement_hint":"Place on floor by default; set mount to wall for wall art and wall-mounted behavior.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{"mount":"floor","fuse_present":true,"fuse_installed":true}},

		"light_switcher": {"display_name":"Light Switcher","category":"Power","subcategory":"Lighting","system_roles":["signal_control","power_consumer"],"tags":["switch","light","wall"],"description":"Wall-mounted switch for lights/devices.","placement_hint":"Requires a valid adjacent wall side.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"metal_cooling_block": {"display_name":"Cooling block","category":"Cooling System","subcategory":"Cooling","system_roles":["cooling"],"tags":["cooling","block"],"description":"Cooling block.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"crate": {"display_name":"Crate","category":"Objects","subcategory":"Movable","system_roles":["movable"],"tags":["crate","movable"],"description":"Movable crate.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"platform": {"display_name":"Platform","category":"Structural","subcategory":"Platform","system_roles":["navigation"],"tags":["platform","floor"],"description":"Placeable platform.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{}},
		"station": {"display_name":"Station","category":"Objects","subcategory":"Station","system_roles":["station"],"tags":["station"],"description":"Placeable station.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"digital_item": {"display_name":"Digital Item","category":"Item","subcategory":"Digital","system_roles":["item"],"tags":["item","digital"],"description":"Digital item.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{}},
		"access_item": {"display_name":"Access Item","category":"Item","subcategory":"Access","system_roles":["item","access"],"tags":["item","access","key"],"description":"Access item.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{}},
		"physical_item": {"display_name":"Physical Item","category":"Item","subcategory":"Physical","system_roles":["item"],"tags":["item","physical"],"description":"Physical item.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{}},
		"module_item": {"display_name":"Module Item","category":"Item","subcategory":"Module","system_roles":["item","module"],"tags":["item","module"],"description":"Module item.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{}},
		"turret": {"display_name":"Turret","category":"Traps","subcategory":"Defense","system_roles":["threat"],"tags":["turret","trap"],"description":"Placeable turret.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"enemy": {"display_name":"Enemy","category":"Robots","subcategory":"Robot","system_roles":["enemy"],"tags":["enemy","robot"],"description":"Enemy robot.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"bipob": {"display_name":"Bipob","category":"Robots","subcategory":"Robot","system_roles":["player"],"tags":["bipob","robot"],"description":"Bipob start robot.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"debris": {"display_name":"Debris","category":"Objects","subcategory":"Prop","system_roles":["prop"],"tags":["debris","object"],"description":"Debris object.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"barrel": {"display_name":"Barrel","category":"Objects","subcategory":"Movable","system_roles":["movable"],"tags":["barrel","movable","configurable"],"description":"Movable barrel. Configure variant=normal/fire in the inspector.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{"variant":"normal"}},
		"steel_box": {"display_name":"Steel Box","category":"Objects","subcategory":"Movable","system_roles":["movable"],"tags":["steel","box","movable"],"description":"Heavy movable steel box.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"case": {"display_name":"Case","category":"Objects","subcategory":"Prop","system_roles":["prop"],"tags":["case","object"],"description":"Simple placeable case object.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"power_source": {"display_name":"Power Source","category":"Power","subcategory":"Source","system_roles":["power_source","power_network"],"tags":["power","source"],"description":"Logical power source using the unified object asset.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"state":"on","is_powered":true}},
		"radiator": {"display_name":"Radiator","category":"Objects","subcategory":"Cooling","system_roles":["cooling"],"tags":["radiator","cooling"],"description":"External floor radiator.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"power_cable_reel": {"display_name":"Cable Reel","category":"Power","subcategory":"Power Utility","system_roles":["power_network"],"tags":["power","cable","reel","floor","wall","utility"],"description":"Cable reel utility node. Use the inspector mount parameter to choose floor or wall visual mode.","placement_hint":"Place the unified Cable Reel, then choose Floor or Wall in the inspector.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{"mount":"floor","install_mode":"floor","cable_install_mode":"floor","wall_routing_mode":"outer"}},
	}
	return metadata


static func get_prefab_presentation(prefab_id: String) -> Dictionary:
	var id: String = prefab_id.strip_edges().to_lower()
	if id.is_empty():
		return {}
	var catalog: Dictionary = _get_presentation_catalog()
	if not catalog.has(id):
		return {}
	var row: Dictionary = Dictionary(catalog[id]).duplicate(true)
	row["id"] = id
	row["prefab_id"] = id
	return row

static func normalize_presentation_row(row: Dictionary) -> Dictionary:
	var normalized: Dictionary = row.duplicate(true)
	var prefab_id: String = str(normalized.get("id", normalized.get("prefab_id", ""))).strip_edges().to_lower()
	if prefab_id.is_empty():
		return {}
	var placement_contract: Dictionary = WorldObjectCatalogRef.get_constructor_placement_contract(prefab_id)
	if placement_contract.is_empty():
		return {"id": prefab_id, "prefab_id": prefab_id, "placement_contract_valid": false, "validation_reason": "missing_placement_contract", "canonical_prefab_id": prefab_id, "supports_floor": false, "supports_wall": false, "floor_only": false, "wall_only": false, "requires_floor": false, "requires_wall": false, "requires_floor_anchor_when_wall_mounted": false, "requires_floor_anchor": false}
	var canonical_prefab_id: String = str(placement_contract.get("canonical_prefab_id", prefab_id))
	normalized["placement_contract_valid"] = true
	normalized["canonical_prefab_id"] = canonical_prefab_id
	normalized["requested_prefab_id"] = str(placement_contract.get("requested_prefab_id", prefab_id))
	normalized["placement_mode"] = str(placement_contract.get("default_placement_mode", "object"))
	normalized["default_placement_mode"] = str(placement_contract.get("default_placement_mode", "object"))
	normalized["default_placement_surface"] = str(placement_contract.get("default_placement_surface", "floor"))
	normalized["placement_surfaces"] = Array(placement_contract.get("placement_surfaces", []))
	for field_name in ["supports_floor", "supports_wall", "floor_only", "wall_only", "requires_floor", "requires_wall", "requires_floor_anchor", "requires_floor_anchor_when_wall_mounted", "changes_passability"]:
		normalized[field_name] = bool(placement_contract.get(field_name, false))
	var palette_group: String = WorldObjectCatalogRef.get_constructor_palette_group_for_prefab(prefab_id)
	if not palette_group.is_empty():
		normalized["category"] = palette_group
		normalized["constructor_group"] = palette_group
		normalized["constructor_tab"] = palette_group
		normalized["palette_group"] = palette_group
	normalized["prefab_id"] = prefab_id
	return normalized

static func get_catalog_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var seen_prefab_ids: Dictionary = {}
	for row in WorldObjectCatalogRef.get_constructor_palette_rows():
		var prefab_id: String = str(row.get("prefab_id", "")).strip_edges().to_lower()
		if prefab_id.is_empty() or seen_prefab_ids.has(prefab_id):
			continue
		var presentation: Dictionary = get_prefab_presentation(prefab_id)
		if presentation.is_empty():
			continue
		var catalog_row: Dictionary = row.duplicate(true)
		for key in presentation.keys():
			catalog_row[key] = presentation[key]
		catalog_row = normalize_presentation_row(catalog_row)
		if catalog_row.is_empty() or not bool(catalog_row.get("placement_contract_valid", false)):
			continue
		catalog_row["id"] = prefab_id
		entries.append(catalog_row)
		seen_prefab_ids[prefab_id] = true
	return entries

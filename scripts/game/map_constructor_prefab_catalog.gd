extends RefCounted

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

const CATEGORY_ORDER: Array[String] = [
	"Recent",
	"Power",
	"Cooling system",
	"Movable",
	"Environments",
	"Item",
	"Traps",
	"Robots",
	"Control",
	"Other"
]

const PREFAB_ORDER: Array[String] = [
	"power_cable_reel",
	"power_source",
	"power_cable",
	"power_socket",
	"fuse_box",
	"power_switcher",
	"light",
	"light_switcher",
	"radiator",
	"external_water_pipe",
	"external_air_duct",
	"metal_cooling_block",
	"crate",
	"barrel",
	"wall",
	"floor",
	"platform",
	"station",
	"digital_item",
	"access_item",
	"physical_item",
	"module_item",
	"turret",
	"enemy",
	"bipob",
	"terminal",
	"door",
	"firewall",
	"debris",
	"case"
]

const CATEGORY_BY_PREFAB: Dictionary = {
	"power_cable_reel": "Power",
	"power_source": "Power",
	"power_cable": "Power",
	"power_socket": "Power",
	"fuse_box": "Power",
	"power_switcher": "Power",
	"light": "Power",
	"light_switcher": "Power",
	"radiator": "Cooling system",
	"external_water_pipe": "Cooling system",
	"external_air_duct": "Cooling system",
	"metal_cooling_block": "Cooling system",
	"crate": "Movable",
	"barrel": "Movable",
	"wall": "Environments",
	"floor": "Environments",
	"platform": "Environments",
	"station": "Environments",
	"digital_item": "Item",
	"access_item": "Item",
	"physical_item": "Item",
	"module_item": "Item",
	"turret": "Traps",
	"enemy": "Robots",
	"bipob": "Robots",
	"terminal": "Control",
	"door": "Control",
	"firewall": "Control",
	"debris": "Other",
	"case": "Other"
}


# Ownership boundary:
# WorldObjectCatalog owns constructor gameplay/domain placement contracts.
# MapConstructorPrefabCatalog owns constructor palette presentation metadata only.
# MissionManager owns runtime orchestration, filtering, validation, geometry, occupancy, and mission state.

static var _presentation_catalog_cache: Dictionary = {}
static var _entity_contract_diagnostics_cache: Array[Dictionary] = []

static func _build_presentation_catalog() -> Dictionary:
	var metadata: Dictionary = {
		"floor": {"display_name":"Floor","category":"Structural","subcategory":"Configurable Floor","system_roles":["navigation"],"tags":["floor","walkable","structural","configurable","archetype"],"description":"Configurable Floor archetype. Choose material, covering, visual style, and state properties in the inspector.","placement_hint":"Place the base Floor, then configure properties.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"stepped_floor": {"display_name":"Stepped Floor","category":"Structural","subcategory":"Floor","system_roles":["navigation"],"tags":["floor","walkable","elevation"],"description":"Walkable stepped floor tile.","placement_hint":"Use for alternate floor visuals.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"external_wall": {"display_name":"External Wall","category":"Structural","subcategory":"Wall","system_roles":["blocking"],"tags":["wall","solid","boundary","fixed_archetype"],"description":"Fixed external structural wall. Gameplay parameters are not editable.","placement_hint":"Place the fixed external wall archetype.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"wall": {"display_name":"Wall","category":"Structural","subcategory":"Wall","system_roles":["blocking"],"tags":["wall","obstacle","configurable","archetype"],"description":"Configurable internal wall. Choose material in the inspector.","placement_hint":"Place Wall, then configure its canonical material property.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"door": {"display_name":"Door","category":"Door","subcategory":"Configurable","system_roles":["navigation","access_control"],"tags":["door","configurable","archetype"],"description":"Configurable door archetype. Choose material, access, power, control, and state properties in the inspector.","placement_hint":"Place the base Door, then configure properties.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"terminal": {"display_name":"Terminal","category":"Terminal","subcategory":"Configurable","system_roles":["terminal_interaction","signal_control"],"tags":["terminal","configurable","archetype"],"description":"Configurable terminal archetype. Choose role, target, class, power, control, status, and links in the inspector.","placement_hint":"Place the base Terminal, then configure properties.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"item": {"display_name":"Item","category":"Item","subcategory":"Configurable","system_roles":["item"],"tags":["item","configurable","archetype"],"description":"Configurable Item archetype. Choose item class, storage route, state, and optional door link in the inspector.","placement_hint":"Place the base Item, then configure properties.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":true,"default_state":{}},
		"firewall": {"display_name":"Firewall Node","category":"Control","subcategory":"Security","system_roles":["signal_control"],"tags":["firewall","security","control"],"description":"Floor security node controlled through terminal links.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"power_source_class_1": {"display_name":"Power Source C1","category":"Power","subcategory":"Source","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Primary local power source.","placement_hint":"Set power_network_id in inspector after placement.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"power_source_class_2": {"display_name":"Power Source C2","category":"Power","subcategory":"Source","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Class 2 power source.","placement_hint":"Place beside wires/outlets.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"power_source_class_3": {"display_name":"Power Source C3","category":"Power","subcategory":"Source","system_roles":["power_source","power_network"],"tags":["power","source","generator"],"description":"Class 3 power source.","placement_hint":"Place beside wires/outlets.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"power_socket": {"display_name":"Power Socket","category":"Power","subcategory":"Connector","system_roles":["power_network","power_consumer"],"tags":["power","socket","connector"],"description":"Power connector point for devices.","placement_hint":"Set power_network_id in inspector after placement. Wall placement is optional.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"power_cable": {"display_name":"Power Cable","category":"Power","subcategory":"Network","system_roles":["power_network"],"tags":["power","cable","network"],"description":"Cable segment for power routing.","placement_hint":"Set power_network_id in inspector after placement. Wall placement is optional.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"circuit_switch": {"display_name":"Circuit Switch","category":"Control","subcategory":"Power","system_roles":["signal_control","power_network"],"tags":["switch","circuit","control"],"description":"Switch controlling power state.","placement_hint":"Configure links in inspector after placement.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"circuit_breaker": {"display_name":"Circuit Breaker","category":"Power","subcategory":"Protection","system_roles":["power_network","signal_control"],"tags":["breaker","power","wall"],"description":"Wall-mounted power safety breaker.","placement_hint":"Requires a valid adjacent wall side.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"light": {"display_name":"Light","category":"Power","subcategory":"Lighting","system_roles":["lighting","power_consumer"],"tags":["light","lighting","wall"],"description":"Wall light linked logically to a power source.","placement_hint":"Requires a wall cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"external_air_duct": {"display_name":"External Air Duct","category":"Cooling System","subcategory":"Wall-mounted","constructor_group":"cooling_system","constructor_category":"Cooling System","constructor_tab":"cooling_system","system_roles":["cooling","airflow"],"tags":["air","duct","wall"],"description":"Wall-mounted external air duct.","placement_hint":"Requires a wall cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"external_water_pipe": {"display_name":"External Water Pipe","category":"Cooling System","subcategory":"Wall-mounted","constructor_group":"cooling_system","constructor_category":"Cooling System","constructor_tab":"cooling_system","system_roles":["cooling","water"],"tags":["water","pipe","wall"],"description":"Wall-mounted external water pipe.","placement_hint":"Requires a wall cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"light_switch": {"display_name":"Light Switch","category":"Control","subcategory":"Lighting","system_roles":["signal_control","power_consumer"],"tags":["switch","light","wall"],"description":"Wall-mounted switch for lights/devices.","placement_hint":"Requires a valid adjacent wall side.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"power_switcher": {"display_name":"Power Switcher","category":"Power","subcategory":"Control","system_roles":["signal_control","power_network"],"tags":["switch","power","configurable"],"description":"Logical power switcher. Configure mount=floor/wall and switch_state=on/off in the inspector.","placement_hint":"Place on floor by default; set mount to wall for wall art and wall-mounted behavior.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},
		"fuse_box": {"display_name":"Fuse Box","category":"Power","subcategory":"Protection","system_roles":["power_network","power_consumer"],"tags":["fuse","power","configurable"],"description":"Logical fuse box. Configure mount=floor/wall and fuse_present=true/false in the inspector.","placement_hint":"Place on floor by default; set mount to wall for wall art and wall-mounted behavior.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":true,"default_state":{}},

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
		"barrel": {"display_name":"Barrel","category":"Objects","subcategory":"Movable","system_roles":["movable"],"tags":["barrel","movable","configurable"],"description":"Movable barrel. Configure variant=normal/fire in the inspector.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"steel_box": {"display_name":"Steel Box","category":"Objects","subcategory":"Movable","system_roles":["movable"],"tags":["steel","box","movable"],"description":"Heavy movable steel box.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"case": {"display_name":"Case","category":"Objects","subcategory":"Prop","system_roles":["prop"],"tags":["case","object"],"description":"Simple placeable case object.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"power_source": {"display_name":"Power Source","category":"Power","subcategory":"Source","system_roles":["power_source","power_network"],"tags":["power","source"],"description":"Logical power source using the unified object asset.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
		"radiator": {"display_name":"Radiator","category":"Objects","subcategory":"Cooling","system_roles":["cooling"],"tags":["radiator","cooling"],"description":"External floor radiator.","placement_hint":"Place on a floor cell.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":false,"can_have_links":false,"default_state":{}},
		"power_cable_reel": {"display_name":"Cable Reel","category":"Power","subcategory":"Power Utility","system_roles":["power_network"],"tags":["power","cable","reel","floor","wall","utility"],"description":"Cable reel utility node. Use the inspector mount parameter to choose floor or wall visual mode.","placement_hint":"Place the unified Cable Reel, then choose Floor or Wall in the inspector.","is_destructive":false,"is_diagnostic":false,"is_expected_invalid_tool":false,"can_have_power_network":true,"can_have_links":false,"default_state":{}},
	}
	return metadata

static func _presentation_catalog() -> Dictionary:
	if _presentation_catalog_cache.is_empty():
		_presentation_catalog_cache = _build_presentation_catalog()
	return _presentation_catalog_cache


static func get_category_order() -> Array[String]:
	return CATEGORY_ORDER.duplicate()

static func get_prefab_order() -> Array[String]:
	return PREFAB_ORDER.duplicate()

static func get_presentation_catalog_snapshot() -> Dictionary:
	return _presentation_catalog().duplicate(true)

static func get_prefab_presentation(prefab_id: String) -> Dictionary:
	var requested_id: String = prefab_id.strip_edges().to_lower()
	if requested_id.is_empty():
		return {}
	var placement_contract: Dictionary = WorldObjectCatalogRef.get_constructor_placement_contract(requested_id)
	if placement_contract.is_empty():
		return {}
	var canonical_id: String = str(placement_contract.get("canonical_prefab_id", WorldObjectCatalogRef.canonical_prefab_id(requested_id))).strip_edges().to_lower()
	var catalog: Dictionary = _presentation_catalog()
	var base_row: Dictionary = {}
	if catalog.has(canonical_id):
		base_row = Dictionary(catalog[canonical_id]).duplicate(true)
	elif catalog.has(requested_id):
		base_row = Dictionary(catalog[requested_id]).duplicate(true)
	else:
		return {"id": requested_id, "prefab_id": requested_id, "requested_prefab_id": requested_id, "canonical_prefab_id": canonical_id, "presentation_missing": true, "placement_contract_valid": false, "validation_reason": "missing_presentation"}
	if requested_id != canonical_id and catalog.has(requested_id):
		var alias_row: Dictionary = Dictionary(catalog[requested_id]).duplicate(true)
		for key in alias_row.keys():
			base_row[key] = alias_row[key]
	base_row["id"] = requested_id
	base_row["prefab_id"] = requested_id
	base_row["requested_prefab_id"] = requested_id
	base_row["canonical_prefab_id"] = canonical_id
	return base_row

static func normalize_presentation_row(row: Dictionary) -> Dictionary:
	var normalized: Dictionary = row.duplicate(true)
	var prefab_id: String = str(normalized.get("requested_prefab_id", normalized.get("id", normalized.get("prefab_id", "")))).strip_edges().to_lower()
	if prefab_id.is_empty():
		return {}
	var placement_contract: Dictionary = WorldObjectCatalogRef.get_constructor_placement_contract(prefab_id)
	if placement_contract.is_empty():
		var missing_entity_report: Dictionary = WorldObjectCatalogRef.validate_entity_definition_contract(prefab_id)
		var missing_error_codes: Array[String] = []
		for missing_error_variant in Array(missing_entity_report.get("errors", [])):
			if missing_error_variant is Dictionary:
				missing_error_codes.append(str(Dictionary(missing_error_variant).get("code", "")))
		return {"id": prefab_id, "prefab_id": prefab_id, "requested_prefab_id": prefab_id, "placement_contract_valid": false, "validation_reason": "missing_placement_contract", "canonical_prefab_id": prefab_id, "supports_floor": false, "supports_wall": false, "floor_only": false, "wall_only": false, "requires_floor": false, "requires_wall": false, "requires_floor_anchor_when_wall_mounted": false, "requires_floor_anchor": false, "entity_contract_valid": bool(missing_entity_report.get("valid", false)), "entity_contract_scope": str(missing_entity_report.get("scope", "")), "entity_type": str(missing_entity_report.get("entity_type", "")), "entity_subtype": str(missing_entity_report.get("entity_subtype", "")), "entity_capabilities": Dictionary(missing_entity_report.get("capabilities", {})).duplicate(true), "entity_contract_error_codes": missing_error_codes}
	var canonical_prefab_id: String = str(placement_contract.get("canonical_prefab_id", prefab_id))
	var entity_report: Dictionary = WorldObjectCatalogRef.validate_entity_definition_contract(canonical_prefab_id)
	normalized["entity_contract_valid"] = bool(entity_report.get("valid", false))
	normalized["entity_contract_scope"] = str(entity_report.get("scope", ""))
	normalized["entity_type"] = str(entity_report.get("entity_type", ""))
	normalized["entity_subtype"] = str(entity_report.get("entity_subtype", ""))
	normalized["entity_capabilities"] = Dictionary(entity_report.get("capabilities", {})).duplicate(true)
	var error_codes: Array[String] = []
	for error_variant in Array(entity_report.get("errors", [])):
		if error_variant is Dictionary:
			error_codes.append(str(Dictionary(error_variant).get("code", "")))
	normalized["entity_contract_error_codes"] = error_codes
	normalized["placement_contract_valid"] = true
	normalized["canonical_prefab_id"] = canonical_prefab_id
	normalized["requested_prefab_id"] = prefab_id
	normalized["placement_mode"] = str(placement_contract.get("default_placement_mode", "object"))
	normalized["default_placement_mode"] = str(placement_contract.get("default_placement_mode", "object"))
	normalized["default_placement_surface"] = str(placement_contract.get("default_placement_surface", "floor"))
	normalized["placement_surfaces"] = Array(placement_contract.get("placement_surfaces", []))
	for field_name in ["supports_floor", "supports_wall", "floor_only", "wall_only", "requires_floor", "requires_wall", "requires_floor_anchor", "requires_floor_anchor_when_wall_mounted", "changes_passability", "blocks_movement"]:
		normalized[field_name] = bool(placement_contract.get(field_name, false))
	var palette_group: String = str(CATEGORY_BY_PREFAB.get(canonical_prefab_id, normalized.get("category", "Other")))
	normalized["category"] = palette_group
	normalized["constructor_group"] = palette_group
	normalized["constructor_tab"] = palette_group
	normalized["palette_group"] = palette_group
	normalized["prefab_id"] = prefab_id
	normalized["id"] = prefab_id
	normalized["canonical_object_type"] = WorldObjectCatalogRef.canonical_object_type(prefab_id)
	var prefab_definition: Dictionary = WorldObjectCatalogRef.get_constructor_prefab_definition(canonical_prefab_id)
	if not prefab_definition.is_empty():
		normalized["archetype_id"] = canonical_prefab_id
		normalized["object_group"] = str(prefab_definition.get("object_group", prefab_definition.get("group", normalized.get("object_group", ""))))
		normalized["configurable"] = bool(prefab_definition.get("configurable", false))
		normalized["property_schema"] = WorldObjectCatalogRef.get_constructor_prefab_property_schema(canonical_prefab_id)
	if not normalized.has("label") or str(normalized.get("label", "")).is_empty():
		normalized["label"] = str(normalized.get("display_name", prefab_id.capitalize()))
	if not normalized.has("display_name") or str(normalized.get("display_name", "")).is_empty():
		normalized["display_name"] = str(normalized.get("label", prefab_id.capitalize()))
	normalized["label"] = str(normalized.get("display_name", normalized.get("label", prefab_id.capitalize())))
	return normalized

static func get_catalog_entries(prefab_order: Array[String] = []) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	_entity_contract_diagnostics_cache = []
	var seen_prefab_ids: Dictionary = {}
	var requested_prefab_order: Array[String] = PREFAB_ORDER.duplicate() if prefab_order.is_empty() else prefab_order.duplicate()
	for prefab_id in requested_prefab_order:
		if seen_prefab_ids.has(prefab_id):
			continue
		var presentation: Dictionary = get_prefab_presentation(prefab_id)
		var catalog_row: Dictionary = normalize_presentation_row(presentation)
		if catalog_row.is_empty() or not bool(catalog_row.get("placement_contract_valid", false)):
			var missing_canonical_id: String = str(catalog_row.get("canonical_prefab_id", WorldObjectCatalogRef.canonical_prefab_id(prefab_id)))
			var missing_report: Dictionary = WorldObjectCatalogRef.validate_entity_definition_contract(missing_canonical_id)
			var missing_errors: Array = Array(missing_report.get("errors", [])).duplicate(true)
			missing_errors.append({"code":"placement_contract.missing", "field":"placement_contract", "message":"Entity definition is missing a canonical constructor placement contract."})
			_entity_contract_diagnostics_cache.append({"prefab_id": prefab_id, "canonical_prefab_id": missing_canonical_id, "errors": missing_errors})
			continue
		if not bool(catalog_row.get("entity_contract_valid", false)):
			var canonical_prefab_id: String = str(catalog_row.get("canonical_prefab_id", WorldObjectCatalogRef.canonical_prefab_id(prefab_id)))
			var diag_report: Dictionary = WorldObjectCatalogRef.validate_entity_definition_contract(canonical_prefab_id)
			_entity_contract_diagnostics_cache.append({"prefab_id": prefab_id, "canonical_prefab_id": canonical_prefab_id, "errors": Array(diag_report.get("errors", [])).duplicate(true)})
			continue
		entries.append(catalog_row)
		seen_prefab_ids[prefab_id] = true
	return entries

static func get_entity_contract_diagnostics() -> Array[Dictionary]:
	if _entity_contract_diagnostics_cache.is_empty():
		get_catalog_entries()
	return _entity_contract_diagnostics_cache.duplicate(true)

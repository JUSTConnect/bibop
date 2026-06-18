extends Node
class_name ObjectStatusLayerService

const STATUS_SECTION_NAME := "ObjectStatusLayerSection"
const SCAN_INTERVAL := 0.65

const STATE_OPTIONS: Array[String] = ["on", "off", "broken", "overheat"]
const POWER_STATE_OPTIONS: Array[String] = ["powered", "unpowered", "none"]
const CONTROL_STATE_OPTIONS: Array[String] = ["internal", "external", "none"]
const ACCESS_STATE_OPTIONS: Array[String] = ["access_code", "key_card", "digital_key", "terminal", "none"]
const MOUNT_STATE_OPTIONS: Array[String] = ["floor", "wall"]
const SIDE_STATE_OPTIONS: Array[String] = ["SW", "SE", "NE", "NW"]
const ROUTING_MODE_OPTIONS: Array[String] = ["inner", "outer"]

const EXCLUDED_OBJECT_GROUPS: Array[String] = ["wall", "floor", "item", "bipob", "robot", "robots", "enemy", "enemies", "threat", "cable"]
const EXCLUDED_OBJECT_TYPES: Array[String] = ["wall", "floor", "bipob", "robot", "enemy", "power_cable", "power_cable_reel", "cable", "crate", "barrel"]
const EXCLUDED_PREFAB_TOKENS: Array[String] = ["power_cable", "cable_reel", "normal_crate", "heavy_crate", "steel_box", "barrel", "fire_barrel", "vagus", "bug"]

var _scan_timer: float = 0.0

func _ready() -> void:
	_scan_scene_tree()
	if get_tree() != null and not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)


func _process(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = SCAN_INTERVAL
		_scan_scene_tree()


func _on_tree_node_added(_node: Node) -> void:
	call_deferred("_scan_scene_tree")


func _scan_scene_tree() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	_scan_node(get_tree().root)


func _scan_node(node: Node) -> void:
	if node == null:
		return
	_try_normalize_manager_on_node(node)
	_try_decorate_inspector_on_node(node)
	for child in node.get_children():
		_scan_node(child)


func _try_normalize_manager_on_node(node: Node) -> void:
	if node == null:
		return
	if not _object_has_property(node, "mission_world_objects"):
		return
	var mission_objects: Variant = node.get("mission_world_objects")
	if not (mission_objects is Array):
		return
	var changed: bool = false
	var objects_array: Array = mission_objects
	for index in range(objects_array.size()):
		if not (objects_array[index] is Dictionary):
			continue
		var object_data: Dictionary = Dictionary(objects_array[index])
		var normalized: Dictionary = normalize_object_status(object_data)
		if _status_signature(normalized) != _status_signature(object_data):
			objects_array[index] = normalized
			changed = true
	if changed:
		node.set("mission_world_objects", objects_array)


func _try_decorate_inspector_on_node(node: Node) -> void:
	if node == null:
		return
	if not _object_has_property(node, "runtime_map_constructor_inspector_panel"):
		return
	var panel_variant: Variant = node.get("runtime_map_constructor_inspector_panel")
	if panel_variant == null or not is_instance_valid(panel_variant):
		return
	var panel: Control = panel_variant as Control
	if panel == null:
		return
	var entity_kind: String = _get_ui_string(node, "selected_map_constructor_entity_kind")
	var entity_id: String = _get_ui_string(node, "selected_map_constructor_entity_id")
	if entity_kind != "world_object" or entity_id.is_empty():
		return
	var manager: Object = _get_object_property(node, "mission_manager_runtime") as Object
	if manager == null or not is_instance_valid(manager) or not manager.has_method("get_map_constructor_entity_by_id"):
		return
	var entity_info_variant: Variant = manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
	if not (entity_info_variant is Dictionary):
		return
	var entity_info: Dictionary = Dictionary(entity_info_variant)
	if not bool(entity_info.get("ok", false)):
		return
	var data: Dictionary = Dictionary(entity_info.get("data", {}))
	if not applies_to_object(data):
		return
	data = normalize_object_status(data)
	var content: VBoxContainer = _find_inspector_content(panel)
	if content == null or not is_instance_valid(content):
		return
	if content.get_node_or_null(STATUS_SECTION_NAME) != null:
		return
	var section: VBoxContainer = _build_status_section(node, manager, entity_kind, entity_id, data)
	if section == null:
		return
	content.add_child(section)
	var insert_index: int = _find_insert_index_after_identity(content)
	content.move_child(section, insert_index)


func applies_to_object(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	if bool(object_data.get("object_status_layer_excluded", false)):
		return false
	var object_group: String = _norm(object_data.get("object_group", object_data.get("group", "")))
	var object_type: String = _norm(object_data.get("object_type", object_data.get("type", "")))
	var archetype_id: String = _norm(object_data.get("archetype_id", ""))
	var prefab_id: String = _norm(object_data.get("map_constructor_prefab_id", object_data.get("prefab_id", "")))
	var joined: String = "%s %s %s %s" % [object_group, object_type, archetype_id, prefab_id]

	if object_group == "cooling" or object_group == "cooling_system":
		return object_type == "cooling_box" or archetype_id == "cooling_box" or prefab_id == "cooling_box"
	if object_group in EXCLUDED_OBJECT_GROUPS:
		return false
	if object_type in EXCLUDED_OBJECT_TYPES or archetype_id in EXCLUDED_OBJECT_TYPES:
		return false
	if bool(object_data.get("movable", false)) or bool(object_data.get("heavy_claw_movable", false)):
		return false
	for token in EXCLUDED_PREFAB_TOKENS:
		if joined.contains(token):
			return false
	return true


func normalize_object_status(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var applies: bool = applies_to_object(data)
	data["object_status_layer_applies"] = applies
	if not applies:
		return data

	data["object_state"] = _normalize_choice(data.get("object_state", _infer_object_state(data)), STATE_OPTIONS, "on")
	data["object_power_state"] = _normalize_choice(data.get("object_power_state", _infer_power_state(data)), POWER_STATE_OPTIONS, "none")
	data["object_health_max"] = clampi(_int_value(data.get("object_health_max", data.get("durability_max", data.get("durability", 5))), 5), 1, 999)
	data["object_health_current"] = clampi(_int_value(data.get("object_health_current", data.get("durability_current", data.get("durability", data.get("object_health_max", 5)))), int(data.get("object_health_max", 5))), 0, int(data["object_health_max"]))
	data["energy_capacity_enabled"] = bool(data.get("energy_capacity_enabled", data.has("object_energy_capacity_max") or data.has("energy_capacity_max")))
	data["object_energy_capacity_max"] = clampi(_int_value(data.get("object_energy_capacity_max", data.get("energy_capacity_max", 25)), 25), 10, 50)
	data["object_energy_capacity_current"] = clampi(_int_value(data.get("object_energy_capacity_current", data.get("energy_capacity_current", data.get("object_energy_capacity_max", 25))), int(data.get("object_energy_capacity_max", 25))), 0, int(data["object_energy_capacity_max"]))
	data["overheat_enabled"] = bool(data.get("overheat_enabled", data.has("object_overheat_max") or data.has("overheat_threshold") or data.has("current_heat")))
	data["object_overheat_max"] = clampi(_int_value(data.get("object_overheat_max", data.get("overheat_threshold", 5)), 5), 1, 5)
	data["object_overheat_current"] = clampi(_int_value(data.get("object_overheat_current", data.get("current_heat", 0)), 0), 0, int(data["object_overheat_max"]))
	data["object_class"] = clampi(_int_value(data.get("object_class", data.get("door_class", data.get("terminal_class", data.get("power_source_class", 1)))), 1), 1, 3)
	data["test_override_enabled"] = bool(data.get("test_override_enabled", false))
	data["object_control_state"] = _normalize_choice(data.get("object_control_state", _infer_control_state(data)), CONTROL_STATE_OPTIONS, "none")
	data["object_access_state"] = _normalize_choice(data.get("object_access_state", _infer_access_state(data)), ACCESS_STATE_OPTIONS, "none")
	data["object_mount_state"] = _normalize_choice(data.get("object_mount_state", data.get("mount", data.get("install_mode", "floor"))), MOUNT_STATE_OPTIONS, "floor")
	data["object_side_state"] = _normalize_side(data.get("object_side_state", data.get("wall_side", data.get("interaction_side", "SW"))))
	data["object_routing_mode_state"] = _normalize_choice(data.get("object_routing_mode_state", data.get("wall_routing_mode", data.get("routing_mode", "outer"))), ROUTING_MODE_OPTIONS, "outer")

	var summary: Dictionary = build_status_summary(data)
	data["object_status_warnings"] = Array(summary.get("warnings", [])).duplicate()
	data["object_total_state"] = str(summary.get("total_state", "ready"))
	return data


func build_status_summary(object_data: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	if not applies_to_object(object_data):
		return {"applies": false, "total_state": "none", "warnings": []}
	var object_state: String = _normalize_choice(object_data.get("object_state", _infer_object_state(object_data)), STATE_OPTIONS, "on")
	var power_state: String = _normalize_choice(object_data.get("object_power_state", _infer_power_state(object_data)), POWER_STATE_OPTIONS, "none")
	var health_current: int = _int_value(object_data.get("object_health_current", object_data.get("durability_current", object_data.get("durability", 1))), 1)
	var health_max: int = maxi(1, _int_value(object_data.get("object_health_max", object_data.get("durability_max", object_data.get("durability", 1))), 1))
	var overheat_enabled: bool = bool(object_data.get("overheat_enabled", false))
	var overheat_current: int = _int_value(object_data.get("object_overheat_current", object_data.get("current_heat", 0)), 0)
	var overheat_max: int = maxi(1, _int_value(object_data.get("object_overheat_max", object_data.get("overheat_threshold", 5)), 5))
	if object_state in ["broken", "overheat", "off"]:
		warnings.append("state_%s" % object_state)
	if power_state == "unpowered":
		warnings.append("unpowered")
	if health_current <= 0:
		warnings.append("health_empty")
	elif health_current < health_max:
		warnings.append("health_not_full")
	if overheat_enabled and overheat_current >= overheat_max:
		warnings.append("overheat_limit")
	var unique_warnings: Array[String] = []
	for warning in warnings:
		if not unique_warnings.has(warning):
			unique_warnings.append(warning)
	return {"applies": true, "total_state": "not_ready" if not unique_warnings.is_empty() else "ready", "warnings": unique_warnings}


func get_status_display_lines(object_data: Dictionary) -> Array[String]:
	var data: Dictionary = normalize_object_status(object_data)
	if not bool(data.get("object_status_layer_applies", false)):
		return []
	var lines: Array[String] = []
	lines.append("State: %s" % str(data.get("object_state", "on")).capitalize())
	lines.append("Power state: %s" % str(data.get("object_power_state", "none")).capitalize())
	lines.append("Health state: %d/%d" % [int(data.get("object_health_current", 0)), int(data.get("object_health_max", 0))])
	if bool(data.get("energy_capacity_enabled", false)):
		lines.append("Energy capacity: %d/%d" % [int(data.get("object_energy_capacity_current", 0)), int(data.get("object_energy_capacity_max", 0))])
	else:
		lines.append("Energy capacity: none")
	if bool(data.get("overheat_enabled", false)):
		lines.append("Current overheat: %d/%d" % [int(data.get("object_overheat_current", 0)), int(data.get("object_overheat_max", 0))])
	else:
		lines.append("Current overheat: none")
	lines.append("Class: %d" % int(data.get("object_class", 1)))
	lines.append("Control state: %s" % str(data.get("object_control_state", "none")))
	lines.append("Access state: %s" % str(data.get("object_access_state", "none")))
	lines.append("Mount state: %s" % str(data.get("object_mount_state", "floor")))
	if str(data.get("object_mount_state", "floor")) == "wall":
		lines.append("Side state: %s" % str(data.get("object_side_state", "SW")))
	lines.append("Routing mode state: %s" % str(data.get("object_routing_mode_state", "outer")))
	lines.append("Total state: %s" % _format_total_state(str(data.get("object_total_state", "ready"))))
	return lines


func _build_status_section(ui: Object, manager: Object, entity_kind: String, entity_id: String, data: Dictionary) -> VBoxContainer:
	var normalized: Dictionary = normalize_object_status(data)
	var section := VBoxContainer.new()
	section.name = STATUS_SECTION_NAME
	section.add_theme_constant_override("separation", 4)
	var header := Label.new()
	header.text = "2. Object Status Layer"
	header.add_theme_color_override("font_color", _ui_color(ui, "UI_COLOR_ACCENT", Color(0.2, 0.76, 0.95, 1.0)))
	section.add_child(header)

	_add_total_state_row(ui, section, normalized)
	_add_enum_row(ui, section, "State", manager, entity_kind, entity_id, "object_state", str(normalized.get("object_state", "on")), STATE_OPTIONS, bool(normalized.get("test_override_enabled", false)), {"state":"__same__", "status":"__same__"})
	_add_enum_row(ui, section, "Power state", manager, entity_kind, entity_id, "object_power_state", str(normalized.get("object_power_state", "none")), POWER_STATE_OPTIONS, true, {"is_powered":"__power_bool__", "power_state":"__same__"})
	_add_int_row(ui, section, "Health current", manager, entity_kind, entity_id, "object_health_current", int(normalized.get("object_health_current", 5)), 0, int(normalized.get("object_health_max", 5)))
	_add_int_row(ui, section, "Health max", manager, entity_kind, entity_id, "object_health_max", int(normalized.get("object_health_max", 5)), 1, 999)
	_add_bool_row(ui, section, "Energy capacity", manager, entity_kind, entity_id, "energy_capacity_enabled", bool(normalized.get("energy_capacity_enabled", false)))
	if bool(normalized.get("energy_capacity_enabled", false)):
		_add_int_row(ui, section, "Energy current", manager, entity_kind, entity_id, "object_energy_capacity_current", int(normalized.get("object_energy_capacity_current", 25)), 0, int(normalized.get("object_energy_capacity_max", 25)))
		_add_int_row(ui, section, "Energy max", manager, entity_kind, entity_id, "object_energy_capacity_max", int(normalized.get("object_energy_capacity_max", 25)), 10, 50)
	_add_bool_row(ui, section, "Current overheat", manager, entity_kind, entity_id, "overheat_enabled", bool(normalized.get("overheat_enabled", false)))
	if bool(normalized.get("overheat_enabled", false)):
		_add_int_row(ui, section, "Overheat current", manager, entity_kind, entity_id, "object_overheat_current", int(normalized.get("object_overheat_current", 0)), 0, int(normalized.get("object_overheat_max", 5)))
		_add_int_row(ui, section, "Overheat max", manager, entity_kind, entity_id, "object_overheat_max", int(normalized.get("object_overheat_max", 5)), 1, 5)
	_add_enum_row(ui, section, "Class", manager, entity_kind, entity_id, "object_class", str(int(normalized.get("object_class", 1))), ["1", "2", "3"])
	_add_bool_row(ui, section, "Test status", manager, entity_kind, entity_id, "test_override_enabled", bool(normalized.get("test_override_enabled", false)))
	_add_enum_row(ui, section, "Control state", manager, entity_kind, entity_id, "object_control_state", str(normalized.get("object_control_state", "none")), CONTROL_STATE_OPTIONS, true, {"control_type":"__same__", "control_mode":"__same__"})
	_add_enum_row(ui, section, "Access state", manager, entity_kind, entity_id, "object_access_state", str(normalized.get("object_access_state", "none")), ACCESS_STATE_OPTIONS, true, {"access_type":"__access_alias__"})
	_add_enum_row(ui, section, "Mount state", manager, entity_kind, entity_id, "object_mount_state", str(normalized.get("object_mount_state", "floor")), MOUNT_STATE_OPTIONS, true, {"mount":"__same__", "install_mode":"__same__"})
	if str(normalized.get("object_mount_state", "floor")) == "wall":
		_add_enum_row(ui, section, "Side state", manager, entity_kind, entity_id, "object_side_state", str(normalized.get("object_side_state", "SW")), SIDE_STATE_OPTIONS, true, {"wall_side":"__side_lower__", "interaction_side":"__side_lower__"})
	_add_enum_row(ui, section, "Routing mode state", manager, entity_kind, entity_id, "object_routing_mode_state", str(normalized.get("object_routing_mode_state", "outer")), ROUTING_MODE_OPTIONS, true, {"wall_routing_mode":"__same__", "routing_mode":"__same__"})
	return section


func _add_total_state_row(ui: Object, section: VBoxContainer, data: Dictionary) -> void:
	var summary: Dictionary = build_status_summary(data)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var warnings: Array = Array(summary.get("warnings", []))
	label.text = "%s%s" % [_format_total_state(str(summary.get("total_state", "ready"))), "\nWarnings: %s" % ", ".join(PackedStringArray(warnings)) if not warnings.is_empty() else ""]
	label.add_theme_color_override("font_color", _ui_color(ui, "UI_COLOR_OK", Color(0.25, 0.85, 0.48, 1.0)) if warnings.is_empty() else _ui_color(ui, "UI_COLOR_WARNING", Color(0.95, 0.72, 0.18, 1.0)))
	section.add_child(_create_property_row(ui, "Total state", label))


func _add_enum_row(ui: Object, section: VBoxContainer, label_text: String, manager: Object, entity_kind: String, entity_id: String, field_name: String, current_value: String, values: Array[String], enabled: bool = true, aliases: Dictionary = {}) -> void:
	var option := OptionButton.new()
	option.disabled = not enabled
	var selected_index: int = 0
	for value in values:
		option.add_item(value.replace("_", " ").capitalize())
		var index: int = option.item_count - 1
		option.set_item_metadata(index, value)
		if value.to_lower() == current_value.to_lower():
			selected_index = index
	option.select(selected_index)
	option.item_selected.connect(func(index: int) -> void:
		var value: String = str(option.get_item_metadata(index))
		var updates: Dictionary = {field_name: _value_for_field(field_name, value)}
		for alias_key_variant in aliases.keys():
			var alias_key: String = str(alias_key_variant)
			updates[alias_key] = _resolve_alias_value(str(aliases[alias_key_variant]), value)
		_apply_status_updates(ui, manager, entity_kind, entity_id, updates)
	)
	section.add_child(_create_property_row(ui, label_text, option))


func _add_bool_row(ui: Object, section: VBoxContainer, label_text: String, manager: Object, entity_kind: String, entity_id: String, field_name: String, current_value: bool) -> void:
	var check := CheckBox.new()
	check.button_pressed = current_value
	check.text = "Enabled" if current_value else "Disabled"
	check.toggled.connect(func(pressed: bool) -> void:
		check.text = "Enabled" if pressed else "Disabled"
		_apply_status_updates(ui, manager, entity_kind, entity_id, {field_name: pressed})
	)
	section.add_child(_create_property_row(ui, label_text, check))


func _add_int_row(ui: Object, section: VBoxContainer, label_text: String, manager: Object, entity_kind: String, entity_id: String, field_name: String, current_value: int, min_value: int, max_value: int) -> void:
	var spin := SpinBox.new()
	spin.step = 1
	spin.min_value = min_value
	spin.max_value = max_value
	spin.value = clampi(current_value, min_value, max_value)
	spin.value_changed.connect(func(value: float) -> void:
		_apply_status_updates(ui, manager, entity_kind, entity_id, {field_name: int(value)})
	)
	section.add_child(_create_property_row(ui, label_text, spin))


func _apply_status_updates(ui: Object, manager: Object, entity_kind: String, entity_id: String, updates: Dictionary) -> void:
	if manager == null or not is_instance_valid(manager) or entity_kind != "world_object":
		return
	if not manager.has_method("get_map_constructor_entity_by_id") or not manager.has_method("update_world_object_by_id"):
		return
	var entity_info_variant: Variant = manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
	if not (entity_info_variant is Dictionary):
		return
	var entity_info: Dictionary = Dictionary(entity_info_variant)
	if not bool(entity_info.get("ok", false)):
		return
	var data: Dictionary = Dictionary(entity_info.get("data", {})).duplicate(true)
	for key_variant in updates.keys():
		data[str(key_variant)] = updates[key_variant]
	data = normalize_object_status(data)
	manager.call("update_world_object_by_id", entity_id, data)
	if manager.has_method("refresh_world_cooling_received"):
		manager.call("refresh_world_cooling_received")
	if ui != null and is_instance_valid(ui):
		if ui.has_method("show_hint"):
			ui.call("show_hint", "Object status updated.")
		if ui.has_method("_refresh_map_constructor_panels"):
			ui.call_deferred("_refresh_map_constructor_panels")
		elif ui.has_method("update_status"):
			ui.call_deferred("update_status")


func _find_inspector_content(panel: Control) -> VBoxContainer:
	var scroll: ScrollContainer = _find_first_scroll(panel)
	if scroll == null:
		return null
	for child in scroll.get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null


func _find_first_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node as ScrollContainer
	for child in node.get_children():
		var result: ScrollContainer = _find_first_scroll(child)
		if result != null:
			return result
	return null


func _find_insert_index_after_identity(content: VBoxContainer) -> int:
	for index in range(content.get_child_count()):
		var child: Node = content.get_child(index)
		if child == null:
			continue
		var first_label: Label = _find_first_label(child)
		if first_label != null and str(first_label.text).begins_with("1."):
			return mini(index + 1, content.get_child_count() - 1)
	return 0


func _find_first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child in node.get_children():
		var result: Label = _find_first_label(child)
		if result != null:
			return result
	return null


func _create_property_row(ui: Object, label_text: String, control: Control) -> Control:
	if ui != null and is_instance_valid(ui) and ui.has_method("_create_property_row"):
		return ui.call("_create_property_row", label_text, control)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _status_signature(data: Dictionary) -> String:
	var keys: Array[String] = ["object_status_layer_applies", "object_state", "object_power_state", "object_health_current", "object_health_max", "energy_capacity_enabled", "object_energy_capacity_current", "object_energy_capacity_max", "overheat_enabled", "object_overheat_current", "object_overheat_max", "object_class", "test_override_enabled", "object_control_state", "object_access_state", "object_mount_state", "object_side_state", "object_routing_mode_state", "object_total_state"]
	var parts: Array[String] = []
	for key in keys:
		parts.append("%s=%s" % [key, str(data.get(key, ""))])
	return "|".join(parts)


func _value_for_field(field_name: String, value: String) -> Variant:
	if field_name == "object_class":
		return int(value)
	return value


func _resolve_alias_value(alias_rule: String, value: String) -> Variant:
	match alias_rule:
		"__same__":
			return value
		"__power_bool__":
			return value == "powered"
		"__access_alias__":
			return "no_key" if value == "none" else value
		"__side_lower__":
			return value.to_lower()
		_:
			return alias_rule


func _infer_object_state(data: Dictionary) -> String:
	var state: String = _norm(data.get("state", data.get("status", "on")))
	if bool(data.get("broken", false)) or bool(data.get("damaged", false)) or state in ["broken", "damaged", "destroyed", "disabled"]:
		return "broken"
	if state in ["overheat", "overheated"]:
		return "overheat"
	if state in ["off", "inactive", "closed", "empty", "disconnected", "unpowered"] or not bool(data.get("is_on", true)):
		return "off"
	return "on"


func _infer_power_state(data: Dictionary) -> String:
	var power_mode: String = _norm(data.get("power_type", data.get("power_mode", ""))).trim_suffix("_power")
	if power_mode == "none":
		return "none"
	var raw_power: String = _norm(data.get("power_state", ""))
	if raw_power in ["powered", "source_on", "on"]:
		return "powered"
	if raw_power in ["unpowered", "source_off", "off"]:
		return "unpowered"
	if data.has("is_powered"):
		return "powered" if bool(data.get("is_powered", false)) else "unpowered"
	return "none"


func _infer_control_state(data: Dictionary) -> String:
	var control: String = _norm(data.get("control_type", data.get("control_mode", "none"))).trim_suffix("_control")
	if control in CONTROL_STATE_OPTIONS:
		return control
	return "none"


func _infer_access_state(data: Dictionary) -> String:
	var access: String = _norm(data.get("access_type", data.get("lock_type", "none")))
	match access:
		"access_code", "code", "password":
			return "access_code"
		"key_card", "mechanical_key", "mechanical_keycard", "keycard":
			return "key_card"
		"digital_key":
			return "digital_key"
		"terminal", "terminal_lock":
			return "terminal"
		_:
			return "none"


func _normalize_choice(value: Variant, options: Array[String], fallback: String) -> String:
	var normalized: String = _norm(value)
	if normalized == "inner" or normalized == "innear":
		normalized = "inner"
	if normalized in options:
		return normalized
	return fallback


func _normalize_side(value: Variant) -> String:
	var side: String = str(value).strip_edges().to_upper().replace("-", "_").replace(" ", "_")
	if side in SIDE_STATE_OPTIONS:
		return side
	match side.to_lower():
		"south_west", "southwest", "south", "west", "sw":
			return "SW"
		"south_east", "southeast", "east", "se":
			return "SE"
		"north_east", "northeast", "ne":
			return "NE"
		"north_west", "northwest", "nw":
			return "NW"
	return "SW"


func _format_total_state(value: String) -> String:
	return "Not ready" if value == "not_ready" else "Ready"


func _norm(value: Variant) -> String:
	return str(value).strip_edges().to_lower().replace("-", "_").replace(" ", "_")


func _int_value(value: Variant, fallback: int = 0) -> int:
	match typeof(value):
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			var text: String = str(value).strip_edges()
			if text.is_valid_int():
				return int(text)
	return fallback


func _get_ui_string(ui: Object, property_name: String) -> String:
	return str(_get_object_property(ui, property_name)).strip_edges()


func _get_object_property(target: Object, property_name: String) -> Variant:
	if target == null:
		return null
	return target.get(property_name)


func _object_has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return true
	return false


func _ui_color(ui: Object, property_name: String, fallback: Color) -> Color:
	var value: Variant = _get_object_property(ui, property_name)
	if value is Color:
		return value
	return fallback

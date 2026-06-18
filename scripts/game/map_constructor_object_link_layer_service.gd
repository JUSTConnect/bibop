extends Node
class_name MapConstructorObjectLinkLayerService

const SECTION_NAME := "MapConstructorObjectLinkLayerSection"
const SCAN_INTERVAL := 0.45

const LINK_POWER_SOURCE := "power_source"
const LINK_POWER_NETWORK := "power_network"
const LINK_CONTROL_TERMINAL := "control_terminal"
const LINK_ACCESS_TERMINAL := "access_terminal"
const LINK_REQUIRED_KEY := "required_key"
const LINK_ACCESS_CODE := "access_code"

const ACCESS_NONE := "none"
const ACCESS_CODE := "access_code"
const ACCESS_DIGITAL_KEY := "digital_key"
const ACCESS_KEY_CARD := "key_card"
const ACCESS_TERMINAL := "terminal"

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
	_try_decorate_inspector(node)
	for child in node.get_children():
		_scan_node(child)


func _try_decorate_inspector(ui: Node) -> void:
	if ui == null or not _object_has_property(ui, "runtime_map_constructor_inspector_panel"):
		return
	var panel: Control = _get_object_property(ui, "runtime_map_constructor_inspector_panel") as Control
	if panel == null or not is_instance_valid(panel):
		return
	var manager: Object = _get_object_property(ui, "mission_manager_runtime") as Object
	if manager == null or not is_instance_valid(manager) or not manager.has_method("get_map_constructor_entity_by_id"):
		return
	var entity_kind: String = str(_get_object_property(ui, "selected_map_constructor_entity_kind")).strip_edges()
	var entity_id: String = str(_get_object_property(ui, "selected_map_constructor_entity_id")).strip_edges()
	if entity_kind.is_empty() or entity_id.is_empty():
		return
	var entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id))
	if not bool(entity.get("ok", false)):
		return
	var data: Dictionary = _as_dictionary(entity.get("data", {}))
	var model: Dictionary = build_links_model(manager, str(entity.get("entity_kind", entity_kind)), entity_id, data)
	if not bool(model.get("has_visible_sections", false)):
		return
	var content: VBoxContainer = _find_inspector_content(panel)
	if content == null or not is_instance_valid(content):
		return
	_remove_stale_or_legacy_sections(content, entity_id)
	if content.get_node_or_null(SECTION_NAME) != null:
		return
	var section: VBoxContainer = _build_links_section(ui, manager, model)
	content.add_child(section)
	var insert_index: int = _find_insert_index_before_warnings(content)
	content.move_child(section, insert_index)


func build_links_model(manager: Object, entity_kind: String, entity_id: String, source_data: Dictionary = {}) -> Dictionary:
	var data: Dictionary = source_data.duplicate(true)
	if data.is_empty() and manager != null and manager.has_method("get_map_constructor_entity_by_id"):
		var entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id))
		data = _as_dictionary(entity.get("data", {}))
	var model: Dictionary = {
		"ok": true,
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"power": _build_power_model(manager, entity_kind, entity_id, data),
		"control": _build_control_model(manager, entity_kind, entity_id, data),
		"access": _build_access_model(manager, entity_kind, entity_id, data),
		"has_visible_sections": false
	}
	for key in ["power", "control", "access"]:
		if bool(Dictionary(model.get(key, {})).get("visible", false)):
			model["has_visible_sections"] = true
	return model


func apply_link(manager: Object, entity_kind: String, entity_id: String, link_kind: String, payload: Dictionary) -> Dictionary:
	if manager == null or not is_instance_valid(manager):
		return {"ok": false, "message": "Mission manager unavailable."}
	match link_kind:
		LINK_POWER_SOURCE:
			var source_id: String = str(payload.get("target_id", "")).strip_edges()
			return _apply_link_field(manager, entity_kind, entity_id, "power_source_id", source_id, LINK_POWER_SOURCE)
		LINK_POWER_NETWORK:
			var network_id: String = str(payload.get("target_id", "")).strip_edges()
			return _apply_link_field(manager, entity_kind, entity_id, "power_network_id", network_id, LINK_POWER_NETWORK)
		LINK_CONTROL_TERMINAL:
			var terminal_id: String = str(payload.get("target_id", "")).strip_edges()
			var result: Dictionary = _apply_link_field(manager, entity_kind, entity_id, "control_terminal_id", terminal_id, LINK_CONTROL_TERMINAL)
			if bool(result.get("ok", false)):
				_sync_terminal_backlink(manager, terminal_id, entity_id, "control")
			return result
		LINK_ACCESS_TERMINAL:
			var access_terminal_id: String = str(payload.get("target_id", "")).strip_edges()
			var access_result: Dictionary = _apply_link_field(manager, entity_kind, entity_id, "access_terminal_id", access_terminal_id, LINK_ACCESS_TERMINAL)
			if bool(access_result.get("ok", false)):
				_sync_access_terminal_storage(manager, access_terminal_id, entity_kind, entity_id, payload)
			return access_result
		LINK_REQUIRED_KEY:
			var key_id: String = str(payload.get("target_id", "")).strip_edges()
			return _apply_required_key(manager, entity_kind, entity_id, key_id, payload)
		LINK_ACCESS_CODE:
			return _apply_access_code(manager, entity_kind, entity_id, str(payload.get("code", "")).strip_edges())
		_:
			return {"ok": false, "message": "Unsupported link kind: %s" % link_kind}


func _build_power_model(manager: Object, entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	var power_type: String = _normalize_power_type(data)
	var current_source_id: String = _first_string(data, ["power_source_id", "source_object_id", "linked_power_source_id", "external_power_source_id"])
	var current_network_id: String = _first_string(data, ["power_network_id", "power_circuit_id", "network_id", "circuit_id"])
	var model: Dictionary = {"visible": power_type == "external", "type": power_type, "source_id": current_source_id, "network_id": current_network_id, "sources": [], "networks": [], "message": ""}
	if not bool(model.get("visible", false)):
		model["message"] = "Power links hidden for %s power." % power_type
		return model
	model["sources"] = _get_targets_for_field(manager, entity_kind, entity_id, "power_source_id")
	model["networks"] = _filter_power_networks_for_source(manager, _get_targets_for_field(manager, entity_kind, entity_id, "power_network_id"), current_source_id, current_network_id)
	return model


func _build_control_model(manager: Object, entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	var control_type: String = _normalize_control_type(data)
	var current_id: String = _first_string(data, ["control_terminal_id", "linked_terminal_id", "required_terminal_id", "control_source_id"])
	var model: Dictionary = {"visible": control_type == "external", "type": control_type, "terminal_id": current_id, "terminals": [], "message": ""}
	if not bool(model.get("visible", false)):
		model["message"] = "Control links hidden for %s control." % control_type
		return model
	model["terminals"] = _filter_terminal_targets(manager, _get_targets_for_field(manager, entity_kind, entity_id, "control_terminal_id"), "control")
	return model


func _build_access_model(manager: Object, entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	var access_type: String = _normalize_access_type(data)
	var model: Dictionary = {"visible": access_type != ACCESS_NONE, "type": access_type, "required_key_id": _first_string(data, ["required_key_id", "linked_key_id"]), "access_terminal_id": _first_string(data, ["access_terminal_id", "information_terminal_id", "storage_terminal_id"]), "code": _first_string(data, ["access_code_value", "access_code", "stored_access_code", "password"]), "keys": [], "terminals": [], "message": ""}
	if not bool(model.get("visible", false)):
		model["message"] = "Access links hidden for none access."
		return model
	if access_type in [ACCESS_KEY_CARD, ACCESS_DIGITAL_KEY, ACCESS_CODE]:
		model["keys"] = _filter_key_targets(manager, _get_targets_for_field(manager, entity_kind, entity_id, "required_key_id"), access_type)
	if access_type in [ACCESS_CODE, ACCESS_DIGITAL_KEY, ACCESS_TERMINAL]:
		model["terminals"] = _filter_terminal_targets(manager, _get_targets_for_field(manager, entity_kind, entity_id, "access_terminal_id"), "information" if access_type in [ACCESS_CODE, ACCESS_DIGITAL_KEY] else "terminal")
	return model


func _build_links_section(ui: Node, manager: Object, model: Dictionary) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = SECTION_NAME
	section.set_meta("entity_id", str(model.get("entity_id", "")))
	section.add_theme_constant_override("separation", 6)
	var header := Label.new()
	header.text = "6. Links Layer"
	header.add_theme_color_override("font_color", _ui_color(ui, "UI_COLOR_ACCENT", Color(0.2, 0.76, 0.95, 1.0)))
	section.add_child(header)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Unified power / control / access bindings. Reverse links are synchronized here."
	note.add_theme_color_override("font_color", _ui_color(ui, "UI_COLOR_MUTED", Color(0.55, 0.68, 0.72, 1.0)))
	section.add_child(note)
	var entity_kind: String = str(model.get("entity_kind", ""))
	var entity_id: String = str(model.get("entity_id", ""))
	var power_model: Dictionary = Dictionary(model.get("power", {}))
	if bool(power_model.get("visible", false)):
		_add_power_section(ui, section, manager, entity_kind, entity_id, power_model)
	var control_model: Dictionary = Dictionary(model.get("control", {}))
	if bool(control_model.get("visible", false)):
		_add_control_section(ui, section, manager, entity_kind, entity_id, control_model)
	var access_model: Dictionary = Dictionary(model.get("access", {}))
	if bool(access_model.get("visible", false)):
		_add_access_section(ui, section, manager, entity_kind, entity_id, access_model)
	return section


func _add_power_section(ui: Node, parent: VBoxContainer, manager: Object, entity_kind: String, entity_id: String, model: Dictionary) -> void:
	var box := _make_subsection("Links Power")
	_add_target_picker(ui, box, manager, entity_kind, entity_id, "Power source", LINK_POWER_SOURCE, str(model.get("source_id", "")), Array(model.get("sources", [])), {})
	if not str(model.get("source_id", "")).strip_edges().is_empty():
		_add_target_picker(ui, box, manager, entity_kind, entity_id, "Power circuit", LINK_POWER_NETWORK, str(model.get("network_id", "")), Array(model.get("networks", [])), {})
	else:
		box.add_child(_make_hint_label("Select a power source to choose source circuit or main."))
	parent.add_child(box)


func _add_control_section(ui: Node, parent: VBoxContainer, manager: Object, entity_kind: String, entity_id: String, model: Dictionary) -> void:
	var box := _make_subsection("Links Control")
	_add_target_picker(ui, box, manager, entity_kind, entity_id, "Control terminal", LINK_CONTROL_TERMINAL, str(model.get("terminal_id", "")), Array(model.get("terminals", [])), {})
	parent.add_child(box)


func _add_access_section(ui: Node, parent: VBoxContainer, manager: Object, entity_kind: String, entity_id: String, model: Dictionary) -> void:
	var access_type: String = str(model.get("type", ACCESS_NONE))
	var box := _make_subsection("Links Accesses: %s" % access_type.replace("_", " ").capitalize())
	if access_type == ACCESS_CODE:
		_add_access_code_row(ui, box, manager, entity_kind, entity_id, str(model.get("code", "")))
		_add_target_picker(ui, box, manager, entity_kind, entity_id, "Code storage terminal", LINK_ACCESS_TERMINAL, str(model.get("access_terminal_id", "")), Array(model.get("terminals", [])), {"access_type": ACCESS_CODE, "code": str(model.get("code", ""))})
	elif access_type == ACCESS_DIGITAL_KEY:
		_add_target_picker(ui, box, manager, entity_kind, entity_id, "Digital key", LINK_REQUIRED_KEY, str(model.get("required_key_id", "")), Array(model.get("keys", [])), {"access_type": ACCESS_DIGITAL_KEY})
		_add_target_picker(ui, box, manager, entity_kind, entity_id, "Key storage terminal", LINK_ACCESS_TERMINAL, str(model.get("access_terminal_id", "")), Array(model.get("terminals", [])), {"access_type": ACCESS_DIGITAL_KEY, "key_id": str(model.get("required_key_id", ""))})
	elif access_type == ACCESS_KEY_CARD:
		_add_target_picker(ui, box, manager, entity_kind, entity_id, "Key-card", LINK_REQUIRED_KEY, str(model.get("required_key_id", "")), Array(model.get("keys", [])), {"access_type": ACCESS_KEY_CARD})
	elif access_type == ACCESS_TERMINAL:
		_add_target_picker(ui, box, manager, entity_kind, entity_id, "Access terminal", LINK_ACCESS_TERMINAL, str(model.get("access_terminal_id", "")), Array(model.get("terminals", [])), {"access_type": ACCESS_TERMINAL})
	else:
		box.add_child(_make_hint_label("Unsupported access link type: %s" % access_type))
	parent.add_child(box)


func _add_target_picker(ui: Node, parent: VBoxContainer, manager: Object, entity_kind: String, entity_id: String, label_text: String, link_kind: String, current_id: String, targets: Array, payload_extra: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_item("(none)")
	option.set_item_metadata(0, {"id": ""})
	if current_id.is_empty():
		option.select(0)
	var current_found := current_id.is_empty()
	for target_variant in targets:
		var target: Dictionary = _as_dictionary(target_variant)
		var target_id: String = str(target.get("id", "")).strip_edges()
		if target_id.is_empty() or target_id == "__none__":
			continue
		option.add_item(str(target.get("label", target_id)))
		var idx: int = option.item_count - 1
		option.set_item_metadata(idx, target)
		option.set_item_tooltip(idx, target_id)
		if bool(target.get("disabled", false)):
			option.set_item_disabled(idx, true)
		if target_id == current_id:
			current_found = true
			option.select(idx)
	if not current_found:
		option.add_item(current_id)
		var current_idx: int = option.item_count - 1
		option.set_item_metadata(current_idx, {"id": current_id})
		option.select(current_idx)
	option.item_selected.connect(func(index: int) -> void:
		var selected: Dictionary = _as_dictionary(option.get_item_metadata(index))
		var payload: Dictionary = payload_extra.duplicate(true)
		payload["target_id"] = str(selected.get("id", "")).strip_edges()
		var result: Dictionary = apply_link(manager, entity_kind, entity_id, link_kind, payload)
		_notify_and_refresh(ui, result)
	)
	row.add_child(option)
	var jump := Button.new()
	jump.text = "Jump"
	jump.disabled = current_id.is_empty()
	jump.pressed.connect(func() -> void:
		_jump_to_target(ui, manager, current_id)
	)
	row.add_child(jump)
	parent.add_child(row)


func _add_access_code_row(ui: Node, parent: VBoxContainer, manager: Object, entity_kind: String, entity_id: String, current_code: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = "Access code"
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = "4 digits"
	edit.max_length = 4
	edit.text = current_code
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var apply_code := func() -> void:
		var result: Dictionary = apply_link(manager, entity_kind, entity_id, LINK_ACCESS_CODE, {"code": edit.text})
		_notify_and_refresh(ui, result)
	edit.text_submitted.connect(func(_value: String) -> void:
		apply_code.call()
	)
	edit.focus_exited.connect(func() -> void:
		apply_code.call()
	)
	row.add_child(edit)
	parent.add_child(row)


func _apply_link_field(manager: Object, entity_kind: String, entity_id: String, field_name: String, target_id: String, link_type: String = "") -> Dictionary:
	if manager.has_method("apply_map_constructor_link_target"):
		return _as_dictionary(manager.call("apply_map_constructor_link_target", entity_kind, entity_id, field_name, target_id))
	if manager.has_method("set_map_constructor_entity_link") and not link_type.is_empty():
		return _as_dictionary(manager.call("set_map_constructor_entity_link", entity_kind, entity_id, link_type, target_id))
	if manager.has_method("update_map_constructor_entity_properties"):
		return _as_dictionary(manager.call("update_map_constructor_entity_properties", entity_kind, entity_id, {field_name: target_id}))
	return {"ok": false, "message": "No link mutation method available."}


func _apply_access_code(manager: Object, entity_kind: String, entity_id: String, code: String) -> Dictionary:
	if not _is_four_digit_code(code):
		return {"ok": false, "message": "Access code must be exactly 4 digits."}
	return _apply_property_updates(manager, entity_kind, entity_id, {"access_code_value": code, "access_code": code, "stored_access_code": code})


func _apply_required_key(manager: Object, entity_kind: String, entity_id: String, key_id: String, payload: Dictionary) -> Dictionary:
	var clear_previous: bool = false
	var entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)) if manager.has_method("get_map_constructor_entity_by_id") else {}
	var data: Dictionary = _as_dictionary(entity.get("data", {}))
	var previous_key_id: String = _first_string(data, ["required_key_id", "linked_key_id"])
	if not previous_key_id.is_empty() and previous_key_id != key_id:
		clear_previous = true
	if clear_previous and manager.has_method("set_map_constructor_entity_link"):
		manager.call("set_map_constructor_entity_link", "item", previous_key_id, "key_door", "")
	var result: Dictionary = _apply_link_field(manager, entity_kind, entity_id, "required_key_id", key_id, LINK_REQUIRED_KEY)
	if bool(result.get("ok", false)) and not key_id.is_empty():
		_sync_key_backlink(manager, key_id, entity_id, str(payload.get("access_type", "")))
		if manager.has_method("set_map_constructor_entity_link"):
			manager.call("set_map_constructor_entity_link", "item", key_id, "key_door", entity_id)
	return result


func _apply_property_updates(manager: Object, entity_kind: String, entity_id: String, updates: Dictionary) -> Dictionary:
	if manager == null or not is_instance_valid(manager):
		return {"ok": false, "message": "Mission manager unavailable."}
	if manager.has_method("update_map_constructor_entity_properties"):
		return _as_dictionary(manager.call("update_map_constructor_entity_properties", entity_kind, entity_id, updates))
	if entity_kind == "world_object" and manager.has_method("get_map_constructor_entity_by_id") and manager.has_method("update_world_object_by_id"):
		var entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id))
		var data: Dictionary = _as_dictionary(entity.get("data", {})).duplicate(true)
		for key in updates.keys():
			data[str(key)] = updates[key]
		manager.call("update_world_object_by_id", entity_id, data)
		return {"ok": true, "message": "Updated."}
	return {"ok": false, "message": "No property mutation method available."}


func _sync_terminal_backlink(manager: Object, terminal_id: String, object_id: String, channel: String) -> void:
	if terminal_id.is_empty() or manager == null or not manager.has_method("get_map_constructor_entity_by_id"):
		return
	var terminal_entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", "world_object", terminal_id))
	if not bool(terminal_entity.get("ok", false)):
		return
	var terminal_data: Dictionary = _as_dictionary(terminal_entity.get("data", {})).duplicate(true)
	var field_name: String = "linked_control_object_ids" if channel == "control" else "linked_access_object_ids"
	var linked: Array = Array(terminal_data.get(field_name, [])).duplicate()
	if not linked.has(object_id):
		linked.append(object_id)
	terminal_data[field_name] = linked
	if channel == "control":
		terminal_data["controlled_target_id"] = object_id
	else:
		terminal_data["access_target_id"] = object_id
	if manager.has_method("update_world_object_by_id"):
		manager.call("update_world_object_by_id", terminal_id, terminal_data)


func _sync_access_terminal_storage(manager: Object, terminal_id: String, entity_kind: String, entity_id: String, payload: Dictionary) -> void:
	if terminal_id.is_empty() or manager == null or not manager.has_method("get_map_constructor_entity_by_id"):
		return
	var terminal_entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", "world_object", terminal_id))
	if not bool(terminal_entity.get("ok", false)):
		return
	var terminal_data: Dictionary = _as_dictionary(terminal_entity.get("data", {})).duplicate(true)
	var access_type: String = _normalize_access_type({"access_type": payload.get("access_type", ACCESS_TERMINAL)})
	terminal_data["terminal_type"] = "information" if access_type in [ACCESS_CODE, ACCESS_DIGITAL_KEY] else str(terminal_data.get("terminal_type", "control"))
	if access_type == ACCESS_CODE:
		var code: String = str(payload.get("code", "")).strip_edges()
		if code.is_empty():
			var entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id))
			code = _first_string(_as_dictionary(entity.get("data", {})), ["access_code_value", "access_code", "stored_access_code"])
		terminal_data["stored_data_type"] = "access_code"
		terminal_data["digital_payload_type"] = "access_code"
		terminal_data["access_code_value"] = code
		terminal_data["stored_access_code"] = code
		terminal_data["access_code"] = code
	elif access_type == ACCESS_DIGITAL_KEY:
		var key_id: String = str(payload.get("key_id", "")).strip_edges()
		terminal_data["stored_data_type"] = "digital_key"
		terminal_data["digital_payload_type"] = "digital_key"
		terminal_data["stored_digital_key_id"] = key_id
		terminal_data["stored_key_id"] = key_id
		terminal_data["stored_item_id"] = key_id
	terminal_data["access_target_id"] = entity_id
	var linked: Array = Array(terminal_data.get("linked_access_object_ids", [])).duplicate()
	if not linked.has(entity_id):
		linked.append(entity_id)
	terminal_data["linked_access_object_ids"] = linked
	if manager.has_method("update_world_object_by_id"):
		manager.call("update_world_object_by_id", terminal_id, terminal_data)


func _sync_key_backlink(manager: Object, key_id: String, object_id: String, access_type: String) -> void:
	if key_id.is_empty() or manager == null or not manager.has_method("get_map_constructor_entity_by_id"):
		return
	var key_kind: String = "item"
	var key_entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", key_kind, key_id))
	if not bool(key_entity.get("ok", false)):
		key_kind = "world_object"
		key_entity = _as_dictionary(manager.call("get_map_constructor_entity_by_id", key_kind, key_id))
	if not bool(key_entity.get("ok", false)):
		return
	var updates: Dictionary = {"linked_door_id": object_id, "unlocks_object_id": object_id, "linked_access_object_id": object_id}
	if access_type == ACCESS_DIGITAL_KEY:
		updates["key_type"] = "digital_key"
		updates["key_kind"] = "digital_key"
	elif access_type == ACCESS_KEY_CARD:
		updates["key_type"] = "key_card"
		updates["key_kind"] = "key_card"
	_apply_property_updates(manager, key_kind, key_id, updates)


func _get_targets_for_field(manager: Object, entity_kind: String, entity_id: String, field_name: String) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if manager == null:
		return targets
	if manager.has_method("get_map_constructor_link_targets_for_field"):
		var model: Dictionary = _as_dictionary(manager.call("get_map_constructor_link_targets_for_field", entity_kind, entity_id, field_name))
		for row_variant in Array(model.get("targets", [])):
			var row: Dictionary = _as_dictionary(row_variant)
			if row.is_empty():
				continue
			row["label"] = _target_label(manager, row)
			targets.append(row)
	return targets


func _filter_power_networks_for_source(manager: Object, targets: Array[Dictionary], source_id: String, current_network_id: String) -> Array[Dictionary]:
	if source_id.is_empty():
		return targets
	var source_network_id: String = ""
	if manager != null and manager.has_method("get_map_constructor_entity_by_id"):
		var source_entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", "world_object", source_id))
		var source_data: Dictionary = _as_dictionary(source_entity.get("data", {}))
		source_network_id = _first_string(source_data, ["power_network_id", "power_circuit_id", "network_id", "circuit_id"])
		if source_network_id.is_empty() and not source_id.is_empty():
			source_network_id = "%s_net" % source_id
	var filtered: Array[Dictionary] = []
	for row in targets:
		var id: String = str(row.get("id", "")).strip_edges()
		if id in ["main", "main_power_net", source_network_id, current_network_id]:
			filtered.append(row)
	return filtered if not filtered.is_empty() else targets


func _filter_terminal_targets(manager: Object, targets: Array[Dictionary], mode: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for row in targets:
		var target_id: String = str(row.get("id", "")).strip_edges()
		if target_id.is_empty() or target_id == "__none__":
			continue
		var data: Dictionary = _lookup_target_data(manager, target_id, "world_object")
		var terminal_type: String = str(data.get("terminal_type", data.get("terminal_mode", ""))).strip_edges().to_lower().replace("-", "_").replace(" ", "_")
		var is_terminal: bool = str(data.get("object_type", "")).to_lower().contains("terminal") or str(data.get("object_group", data.get("group", ""))).to_lower().contains("terminal")
		if not is_terminal:
			continue
		if mode == "control" and terminal_type in ["", "control", "controller", "control_terminal"]:
			filtered.append(row)
		elif mode == "information" and terminal_type in ["information", "info", "storage", "data"]:
			filtered.append(row)
		elif mode == "terminal":
			filtered.append(row)
	return filtered if not filtered.is_empty() else targets


func _filter_key_targets(manager: Object, targets: Array[Dictionary], access_type: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for row in targets:
		var target_id: String = str(row.get("id", "")).strip_edges()
		if target_id.is_empty() or target_id == "__none__":
			continue
		var entity_kind: String = str(row.get("entity_kind", row.get("kind", "item"))).strip_edges()
		var data: Dictionary = _lookup_target_data(manager, target_id, entity_kind)
		var key_type: String = _normalize_key_type(data)
		if access_type == ACCESS_DIGITAL_KEY and key_type == ACCESS_DIGITAL_KEY:
			filtered.append(row)
		elif access_type == ACCESS_KEY_CARD and key_type == ACCESS_KEY_CARD:
			filtered.append(row)
		elif access_type == ACCESS_CODE and key_type == ACCESS_CODE:
			filtered.append(row)
	return filtered if not filtered.is_empty() else targets


func _lookup_target_data(manager: Object, target_id: String, entity_kind: String) -> Dictionary:
	if manager == null or not manager.has_method("get_map_constructor_entity_by_id"):
		return {}
	for kind in [entity_kind, "world_object", "item"]:
		var entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", kind, target_id))
		if bool(entity.get("ok", false)):
			return _as_dictionary(entity.get("data", {}))
	return {}


func _target_label(manager: Object, row: Dictionary) -> String:
	var id: String = str(row.get("id", "")).strip_edges()
	if id == "__none__":
		return "(none)"
	var label: String = str(row.get("label", "")).strip_edges()
	if not label.is_empty() and label != id:
		return label
	var kind: String = str(row.get("entity_kind", row.get("kind", "world_object"))).strip_edges()
	var data: Dictionary = _lookup_target_data(manager, id, kind)
	var display_name: String = _first_string(data, ["display_name", "name", "palette_label"])
	if display_name.is_empty():
		display_name = id
	var cell: Vector2i = _as_vector2i(row.get("cell", data.get("position", Vector2i(-1, -1))))
	if cell.x >= 0 and cell.y >= 0:
		return "%s %s" % [display_name, str(cell)]
	return display_name


func _normalize_power_type(data: Dictionary) -> String:
	var value: String = str(data.get("power_type", data.get("power_mode", data.get("object_power_type", "")))).strip_edges().to_lower().replace("-", "_").replace(" ", "_").trim_suffix("_power")
	if value.is_empty():
		value = "external" if bool(data.get("requires_external_power", false)) else "internal"
	if value in ["external", "internal", "none"]:
		return value
	return "external" if value.contains("external") else "none" if value == "no" else "internal"


func _normalize_control_type(data: Dictionary) -> String:
	var value: String = str(data.get("control_type", data.get("control_mode", data.get("object_control_state", "")))).strip_edges().to_lower().replace("-", "_").replace(" ", "_").trim_suffix("_control")
	if value.is_empty():
		value = "external" if bool(data.get("requires_external_control", false)) else "internal"
	if value in ["external", "internal", "none"]:
		return value
	if value == "terminal":
		return "external"
	return "external" if value.contains("external") else "none" if value == "no" else "internal"


func _normalize_access_type(value: Variant) -> String:
	var raw: String = ""
	if value is Dictionary:
		var data: Dictionary = Dictionary(value)
		raw = str(data.get("object_access_state", data.get("access_type", data.get("lock_type", ""))))
	else:
		raw = str(value)
	var normalized: String = raw.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	match normalized:
		"", "none", "no_key", "open": return ACCESS_NONE
		"access_code", "code", "pin", "pin_code": return ACCESS_CODE
		"digital_key", "digital", "digital_access": return ACCESS_DIGITAL_KEY
		"key_card", "keycard", "mechanical_key", "mechanical", "physical_key": return ACCESS_KEY_CARD
		"terminal", "terminal_access", "access_terminal": return ACCESS_TERMINAL
	return normalized


func _normalize_key_type(data: Dictionary) -> String:
	var joined: String = "%s %s %s %s %s" % [str(data.get("access_type", "")), str(data.get("key_type", "")), str(data.get("key_kind", "")), str(data.get("item_type", data.get("object_type", ""))), str(data.get("id", ""))]
	joined = joined.to_lower().replace("-", "_").replace(" ", "_")
	if joined.contains("digital"):
		return ACCESS_DIGITAL_KEY
	if joined.contains("access_code") or joined.contains("pin") or joined.contains("code"):
		return ACCESS_CODE
	if joined.contains("key_card") or joined.contains("keycard") or joined.contains("mechanical") or joined.contains("_key"):
		return ACCESS_KEY_CARD
	return ACCESS_KEY_CARD


func _remove_stale_or_legacy_sections(content: VBoxContainer, entity_id: String) -> void:
	for child in content.get_children():
		if child.name == SECTION_NAME:
			if str(child.get_meta("entity_id", "")) != entity_id:
				child.queue_free()
			continue
		var first_label: Label = _find_first_label(child)
		if first_label != null and str(first_label.text).strip_edges() == "6. Links":
			child.queue_free()


func _find_insert_index_before_warnings(content: VBoxContainer) -> int:
	for index in range(content.get_child_count()):
		var first_label: Label = _find_first_label(content.get_child(index))
		if first_label != null and str(first_label.text).find("Warnings") >= 0:
			return index
	return content.get_child_count() - 1


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


func _find_first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child in node.get_children():
		var result: Label = _find_first_label(child)
		if result != null:
			return result
	return null


func _make_subsection(title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = title
	box.add_child(label)
	return box


func _make_hint_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _notify_and_refresh(ui: Node, result: Dictionary) -> void:
	if ui != null and is_instance_valid(ui):
		if ui.has_method("show_hint"):
			ui.call("show_hint", str(result.get("message", "Link updated.")))
		if ui.has_method("_refresh_map_constructor_panels"):
			ui.call_deferred("_refresh_map_constructor_panels")
		if ui.has_method("_show_map_constructor_inspector"):
			var cell: Vector2i = _as_vector2i(_get_object_property(ui, "selected_map_constructor_entity_cell"))
			ui.call_deferred("_show_map_constructor_inspector", cell, str(_get_object_property(ui, "selected_map_constructor_entity_kind")), str(_get_object_property(ui, "selected_map_constructor_entity_id")))
		var field_runtime: Object = _get_object_property(ui, "field_runtime") as Object
		if field_runtime != null and is_instance_valid(field_runtime) and field_runtime.has_method("request_visual_refresh"):
			field_runtime.call_deferred("request_visual_refresh")


func _jump_to_target(ui: Node, manager: Object, target_id: String) -> void:
	if target_id.is_empty() or ui == null or manager == null or not manager.has_method("get_map_constructor_entity_by_id"):
		return
	for kind in ["world_object", "item"]:
		var entity: Dictionary = _as_dictionary(manager.call("get_map_constructor_entity_by_id", kind, target_id))
		if bool(entity.get("ok", false)):
			var cell: Vector2i = _as_vector2i(entity.get("cell", Vector2i(-1, -1)))
			if ui.has_method("_focus_map_constructor_cell") and cell.x >= 0 and cell.y >= 0:
				ui.call("_focus_map_constructor_cell", cell)
			if ui.has_method("_show_map_constructor_inspector"):
				ui.call("_show_map_constructor_inspector", cell, kind, target_id)
			return


func _first_string(data: Dictionary, fields: Array[String]) -> String:
	for field in fields:
		var value: String = str(data.get(field, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""


func _is_four_digit_code(value: Variant) -> bool:
	var text: String = str(value).strip_edges()
	if text.length() != 4:
		return false
	for i in range(text.length()):
		var codepoint: int = text.unicode_at(i)
		if codepoint < 48 or codepoint > 57:
			return false
	return true


func _as_dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _as_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	return Vector2i(-1, -1)


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

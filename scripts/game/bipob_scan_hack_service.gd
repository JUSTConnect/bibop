extends RefCounted
class_name BipobScanHackService

const ScanSystemRef = preload("res://scripts/world/scan_system.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const DIGITAL_RECORD_INFO_KEY := "info_key"

static func get_facing_device_diagnostic_result(controller: Variant) -> Dictionary:
	if controller.mission_manager == null or not controller.mission_manager.has_method("build_device_diagnostic_result"):
		return {}
	var target_cell: Vector2i = controller.get_facing_device_position()
	var target_variant: Variant = controller.mission_manager.get_world_object_at_cell(target_cell)
	if typeof(target_variant) != TYPE_DICTIONARY or Dictionary(target_variant).is_empty():
		return {}
	var target_object: Dictionary = Dictionary(target_variant)
	var diagnostic_variant: Variant = controller.mission_manager.call("build_device_diagnostic_result", target_object, target_cell)
	if typeof(diagnostic_variant) != TYPE_DICTIONARY:
		return {}
	var diagnostic: Dictionary = diagnostic_variant
	if controller.mission_manager.has_method("build_device_interaction_preflight"):
		var view_model: Dictionary = controller.build_runtime_action_view_model(target_object, target_cell)
		var primary_action_id: String = String(view_model.get("primary_action_id", ""))
		if not primary_action_id.is_empty():
			var actor: Dictionary = controller._build_runtime_action_actor(target_object, target_cell)
			var preflight_variant: Variant = controller.mission_manager.call("build_device_interaction_preflight", target_object, target_cell, primary_action_id, actor)
			if typeof(preflight_variant) == TYPE_DICTIONARY:
				var preflight: Dictionary = preflight_variant
				diagnostic["interaction_preflight"] = preflight.duplicate(true)
				if not bool(preflight.get("preflight_ok", false)):
					diagnostic["summary"] = "Device blocked: %s" % String(preflight.get("message", "Action unavailable."))
	return diagnostic

static func get_facing_device_interaction_preflight(controller: Variant, action_id: String = "") -> Dictionary:
	if controller.mission_manager == null or not controller.mission_manager.has_method("build_device_interaction_preflight"):
		return {}
	var target_data: Dictionary = controller.get_facing_world_action_target()
	var target_variant: Variant = target_data.get("target_object", {})
	if typeof(target_variant) != TYPE_DICTIONARY:
		return {}
	var target_object: Dictionary = target_variant
	var target_cell: Vector2i = Vector2i(target_data.get("target_position", controller.get_facing_device_position()))
	var resolved_action_id: String = action_id
	if resolved_action_id.is_empty():
		var view_model_variant: Variant = target_data.get("action_view_model", {})
		if typeof(view_model_variant) == TYPE_DICTIONARY:
			resolved_action_id = String(Dictionary(view_model_variant).get("primary_action_id", ""))
	var actor: Dictionary = controller._build_runtime_action_actor(target_object, target_cell)
	var preflight_variant: Variant = controller.mission_manager.call("build_device_interaction_preflight", target_object, target_cell, resolved_action_id, actor)
	return Dictionary(preflight_variant) if typeof(preflight_variant) == TYPE_DICTIONARY else {}

static func get_facing_device_interaction_state_flow(controller: Variant, action_id: String = "") -> Dictionary:
	if controller.mission_manager == null or not controller.mission_manager.has_method("build_device_interaction_state_flow"):
		return {}
	var target_data: Dictionary = controller.get_facing_world_action_target()
	var target_variant: Variant = target_data.get("target_object", {})
	if typeof(target_variant) != TYPE_DICTIONARY:
		return {}
	var target_object: Dictionary = target_variant
	var target_cell: Vector2i = Vector2i(target_data.get("target_position", controller.get_facing_device_position()))
	var resolved_action_id: String = action_id
	if resolved_action_id.is_empty():
		var view_model_variant: Variant = target_data.get("action_view_model", {})
		if typeof(view_model_variant) == TYPE_DICTIONARY:
			resolved_action_id = String(Dictionary(view_model_variant).get("primary_action_id", ""))
	var actor: Dictionary = controller._build_runtime_action_actor(target_object, target_cell)
	var flow_variant: Variant = controller.mission_manager.call("build_device_interaction_state_flow", target_object, target_cell, resolved_action_id, actor)
	return Dictionary(flow_variant) if typeof(flow_variant) == TYPE_DICTIONARY else {}

static func evaluate_facing_device_capability(controller: Variant) -> DiagnosticResult:
	var device: DeviceDefinition = controller.get_facing_device_definition()
	controller.last_diagnostic_result = controller.evaluate_device_capability(device)
	print(
		"Capability check | Status: ",
		controller.last_diagnostic_result.status,
		" | Device: ",
		controller.last_diagnostic_result.device_name,
		" | Action: ",
		controller.last_diagnostic_result.supported_action
	)
	return controller.last_diagnostic_result

static func scan_device(controller: Variant) -> void:
	if controller.mission_finished:
		return

	var facing_cell: Vector2i = controller.get_facing_device_position()
	if controller.mission_manager != null:
		var world_object: Dictionary = Dictionary(controller.mission_manager.get_world_object_at_cell(facing_cell))
		if not world_object.is_empty():
			if not controller.can_spend_action(1, 1):
				return
			# Scan spends action first; then temporary heat is applied.
			# If GPU overheats, the attempted scan still costs action and reveals no new data.
			controller.spend_action(1, 1)
			var scan_type: String = controller.get_world_scan_type_from_installed_modules()
			var overheat_action_id := ""
			if scan_type == "xray":
				overheat_action_id = "xray"
			elif scan_type == "thermal":
				overheat_action_id = "thermal_scan"
			if not overheat_action_id.is_empty():
				var overheat_result: Dictionary = controller.apply_internal_overheat_if_needed(overheat_action_id, controller.get_internal_action_temporary_heat_context(overheat_action_id))
				if bool(overheat_result.get("failed", false)):
					for overheat_message in overheat_result.get("messages", []):
						controller.hint_requested.emit(String(overheat_message))
					controller.status_changed.emit()
					return
			var result: Dictionary = ScanSystemRef.scan_object(world_object, scan_type, controller.get_effective_visor_level())
			world_object["scan_level"] = int(result.get("scan_level", 1))
			if scan_type == "xray" and world_object.get("object_group", "") == "wall" and not Array(world_object.get("hidden_content", [])).is_empty():
				world_object["revealed_hidden_content"] = true
			controller.mission_manager.set_world_object_at_cell(facing_cell, world_object)
			controller.refresh_world_object_overlay()
			controller.update_threat_detection_preview()
			var diagnostic: Dictionary = get_facing_device_diagnostic_result(controller)
			var state_flow: Dictionary = get_facing_device_interaction_state_flow(controller)
			controller.hint_requested.emit(_format_scan_device_hint(diagnostic, state_flow, world_object))
			controller.clear_selected_world_action_if_invalid(world_object, facing_cell)
			controller.emit_facing_world_object_hint()
			controller.refresh_world_action_panel()
			controller.status_changed.emit()
			return

	if not controller.can_spend_action(1, 1):
		return

	var device: DeviceDefinition = controller.get_facing_device_definition()
	if device == null:
		var blocked_result := DiagnosticResult.new()
		blocked_result.status = DiagnosticResult.STATUS_BLOCKED
		blocked_result.device_name = "Unknown"
		blocked_result.reason = "No digital device detected."
		blocked_result.recommendation = "Face a terminal or digital door and scan again."
		blocked_result.estimated_risk = "none"
		controller.last_diagnostic_result = blocked_result
		controller.hint_requested.emit("No digital device detected. Face a terminal or digital door, then scan.")
		controller.status_changed.emit()
		return

	controller.spend_action(1, 1)
	evaluate_facing_device_capability(controller)
	if controller.last_diagnostic_result.status == DiagnosticResult.STATUS_BLOCKED:
		controller.hint_requested.emit("Scan complete: BLOCKED. Check Diagnostic panel for missing requirements.")
	else:
		controller.hint_requested.emit("Scan complete: " + controller.last_diagnostic_result.get_status_text() + ". Check Diagnostic panel, then use Hack Device if READY.")
	controller.status_changed.emit()

static func hack_device(controller: Variant) -> void:
	if controller.mission_finished:
		return

	if controller.last_diagnostic_result == null:
		controller.hint_requested.emit("Scan device first.")
		controller.status_changed.emit()
		return

	if not controller.last_diagnostic_result.is_action_allowed():
		controller.hint_requested.emit("Hack blocked. Check Diagnostic panel.")
		controller.status_changed.emit()
		return

	var device: DeviceDefinition = controller.get_facing_device_definition()
	if device == null:
		controller.hint_requested.emit("No digital device detected. Face a terminal or digital door, then scan.")
		controller.status_changed.emit()
		return

	if device.device_type != controller.last_diagnostic_result.device_type \
	or device.supported_action != controller.last_diagnostic_result.supported_action:
		controller.hint_requested.emit("Device changed. Scan this device again.")
		controller.status_changed.emit()
		return

	if not controller.can_spend_action(1, 1):
		return
	# Hack checks action availability first. Temporary heat is only applied for an actual attempt.
	# With "affected" scope, only processor-heated modules can break for hack.
	var overheat_result: Dictionary = controller.apply_internal_overheat_if_needed("hack", controller.get_internal_action_temporary_heat_context("hack"))
	if bool(overheat_result.get("failed", false)):
		controller.spend_action(1, 1)
		for overheat_message in overheat_result.get("messages", []):
			controller.hint_requested.emit(String(overheat_message))
		controller.status_changed.emit()
		return
	var hack_world_object: Dictionary = Dictionary(controller.mission_manager.get_world_object_at_cell(controller.get_facing_device_position()))
	if not hack_world_object.is_empty() and String(hack_world_object.get("object_group", "")) == "terminal":
		if not controller._is_terminal_powered_for_interaction(hack_world_object):
			controller.hint_requested.emit("Terminal is unpowered.")
			controller.status_changed.emit()
			return
		WorldObjectCatalogRef.update_world_object_heat_state(hack_world_object)
		if String(hack_world_object.get("state", "")) == "overheated":
			controller.spend_action(1, 1)
			controller.mission_manager.update_world_object_by_id(String(hack_world_object.get("id", "")), hack_world_object)
			controller.hint_requested.emit("Terminal overheated. Hack failed.")
			controller.status_changed.emit()
			return
		var hack_heat := maxi(0, int(hack_world_object.get("hack_heat", 1)))
		if WorldObjectCatalogRef.would_world_object_overheat_with_temporary_heat(hack_world_object, hack_heat):
			controller.spend_action(1, 1)
			hack_world_object["current_heat"] = WorldObjectCatalogRef.get_world_object_current_heat(hack_world_object)
			WorldObjectCatalogRef.update_world_object_heat_state(hack_world_object)
			controller.mission_manager.update_world_object_by_id(String(hack_world_object.get("id", "")), hack_world_object)
			controller.hint_requested.emit("Terminal overheated. Hack failed.")
			controller.status_changed.emit()
			return

	match device.supported_action:
		"download_info_key":
			if not controller.can_spend_action(1, 1):
				return
			controller.spend_action(1, 1)
			if controller.is_legacy_mission2_terminal_tutorial_active():
				# TODO(legacy_mission_retirement): old terminal calibration story branch.
				controller.hint_requested.emit("Terminal is silent. Interface calibration required. Return to the box.")
				controller.complete_legacy_mission_from_story_glue("mission2_scan_hack_terminal")
				return
			controller.has_info_key = true
			controller.store_digital_record(DIGITAL_RECORD_INFO_KEY, "Info-Key", "Digital authorization record for opening a digital door.")
			controller.hint_requested.emit("Info-Key downloaded. Now find the digital door, scan it, then hack it.")
			controller.status_changed.emit()
			return
		"open_digital_door":
			if not controller.has_info_key and not controller.use_digital_record(DIGITAL_RECORD_INFO_KEY):
				controller.hint_requested.emit("Digital door requires Info-Key. Hack the terminal first.")
				controller.status_changed.emit()
				return
			if not controller.can_spend_action(1, 1):
				return
			controller.spend_action(1, 1)
			controller.grid_manager.set_tile(controller.get_facing_device_position(), GridManager.TILE_FLOOR)
			controller.hint_requested.emit("Digital door opened. Info-Key remains stored.")
			controller.status_changed.emit()
			return
		"unlock_airflow_terminal":
			if not controller.can_spend_action(1, 1):
				return
			controller.spend_action(1, 1)
			controller.complete_legacy_mission8_airflow_terminal_hack()
			controller.hint_requested.emit("Airflow Terminal hacked. Path opened.")
			controller.status_changed.emit()
			return
		"stabilize_hot_node":
			var energy_cost := 1
			if controller.last_diagnostic_result.status == DiagnosticResult.STATUS_RISKY:
				energy_cost = 3
			if not controller.can_spend_action(1, energy_cost):
				return
			controller.spend_action(1, energy_cost)
			var hot_node_position: Vector2i = controller.get_facing_device_position()
			controller.grid_manager.set_tile(hot_node_position, GridManager.TILE_FLOOR)
			var adjacent_offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for offset in adjacent_offsets:
				var adjacent_position := hot_node_position + offset
				if controller.grid_manager.get_tile(adjacent_position) == GridManager.TILE_DIGITAL_DOOR:
					controller.grid_manager.set_tile(adjacent_position, GridManager.TILE_FLOOR)
			if controller.last_diagnostic_result.status == DiagnosticResult.STATUS_RISKY:
				controller.hint_requested.emit("Risky hack succeeded, but Bipob spent extra energy.")
			else:
				controller.hint_requested.emit("Hot Node stabilized.")
			controller.status_changed.emit()
			return
		_:
			controller.hint_requested.emit("Unsupported hack action.")
			controller.status_changed.emit()
			return

static func _format_scan_device_hint(diagnostic: Dictionary, state_flow: Dictionary, fallback_target: Dictionary) -> String:
	var target_name: String = String(diagnostic.get("target_name", fallback_target.get("display_name", fallback_target.get("name", fallback_target.get("object_type", "Unknown object"))))).strip_edges()
	if target_name.is_empty():
		target_name = "Unknown object"
	var lines: Array[String] = ["Scan: %s" % target_name]
	var state_parts: Array[String] = []
	for state_key in ["state", "power_state"]:
		var state_text: String = String(diagnostic.get(state_key, "")).strip_edges()
		if not state_text.is_empty() and not state_parts.has(state_text):
			state_parts.append(state_text)
	if not state_parts.is_empty():
		lines.append("State: %s" % " / ".join(state_parts))
	if bool(state_flow.get("is_applicable", false)):
		var next_message: String = String(state_flow.get("message", "")).strip_edges()
		if not next_message.is_empty():
			lines.append("Next: %s" % next_message)
	return "\n".join(lines)

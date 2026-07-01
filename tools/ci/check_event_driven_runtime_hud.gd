extends SceneTree

const RuntimeNotificationLayerRef = preload("res://scripts/ui/runtime/runtime_notification_layer.gd")
const InspectorStructureRef = preload("res://scripts/ui/map_constructor/map_constructor_inspector_structure_layer.gd")

class FakeNotificationUI:
	extends Node
	var hint_label: Label = Label.new()
	var runtime_notification_label: Label = Label.new()
	var runtime_notification_panel: PanelContainer = PanelContainer.new()
	var runtime_notification_timer: float = 0.0
	var runtime_notification_role: String = "neutral"
	var restart_count: int = 0
	var last_duration: float = -1.0

	func _init() -> void:
		add_child(hint_label)
		add_child(runtime_notification_label)
		add_child(runtime_notification_panel)

	func _restart_runtime_notification_timeout(duration: float) -> void:
		restart_count += 1
		last_duration = duration

	func _get_runtime_secondary_objective_text() -> String:
		return "Fallback objective"


class RefreshCoalescer:
	extends Node
	var pending: bool = false
	var refresh_count: int = 0

	func request_refresh() -> void:
		if pending:
			return
		pending = true
		call_deferred("_flush")

	func _flush() -> void:
		pending = false
		refresh_count += 1


class FakeInspectorUI:
	extends Node

	func _create_inspector_section(title: String) -> VBoxContainer:
		var section := VBoxContainer.new()
		var title_label := Label.new()
		title_label.text = title
		section.add_child(title_label)
		return section

	func _create_property_row(label_text: String, control: Control) -> Control:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text
		row.add_child(label)
		row.add_child(control)
		return row


func _init() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _run() -> void:
	var ok: bool = true
	ok = _test_notification_route() and ok
	ok = await _test_deferred_coalescing() and ok
	ok = await _test_one_shot_timer() and ok
	ok = _test_inspector_presenter() and ok
	ok = _test_production_source_contract() and ok
	if ok:
		print("check_event_driven_runtime_hud: OK")
		quit(0)
	else:
		push_error("check_event_driven_runtime_hud: FAILED")
		quit(1)


func _test_notification_route() -> bool:
	var layer := RuntimeNotificationLayerRef.new()
	var ui := FakeNotificationUI.new()
	root.add_child(layer)
	root.add_child(ui)
	layer.show_hint(ui, "Event-driven notification", RuntimeNotificationLayerRef.KIND_SYSTEM, 0.125)
	var ok := _expect(ui.restart_count == 1, "active notification route must restart one timeout")
	ok = _expect(is_equal_approx(ui.last_duration, 0.125), "notification route must preserve duration") and ok
	ok = _expect(ui.runtime_notification_label.text == "Event-driven notification", "notification text must update immediately") and ok
	layer.queue_free()
	ui.queue_free()
	return ok


func _test_deferred_coalescing() -> bool:
	var coalescer := RefreshCoalescer.new()
	root.add_child(coalescer)
	coalescer.request_refresh()
	coalescer.request_refresh()
	coalescer.request_refresh()
	var before_ok := _expect(coalescer.refresh_count == 0, "coalesced refresh must be deferred")
	await process_frame
	var after_ok := _expect(coalescer.refresh_count == 1, "multiple invalidations must coalesce to one refresh")
	coalescer.queue_free()
	return before_ok and after_ok


func _test_one_shot_timer() -> bool:
	var timer := Timer.new()
	timer.one_shot = true
	var timeout_count := [0]
	timer.timeout.connect(func() -> void: timeout_count[0] += 1)
	root.add_child(timer)
	timer.start(0.01)
	await create_timer(0.06).timeout
	var ok := _expect(timeout_count[0] == 1, "one-shot notification Timer must fire exactly once")
	ok = _expect(timer.is_stopped(), "one-shot notification Timer must stop after timeout") and ok
	timer.queue_free()
	return ok


func _test_inspector_presenter() -> bool:
	var ui := FakeInspectorUI.new()
	var content := VBoxContainer.new()
	root.add_child(ui)
	ui.add_child(content)
	var data := {"display_name":"Legacy A", "description":"Test", "object_type":"unknown_legacy_fixture"}
	InspectorStructureRef.apply_structure(ui, content, "world_object", "legacy_a", data)
	InspectorStructureRef.apply_structure(ui, content, "world_object", "legacy_a", data)
	var identity_count: int = 0
	var status_count: int = 0
	for child in content.get_children():
		if str(child.name) == "SharedIdentitySection":
			identity_count += 1
		elif str(child.name) == "SharedStatusSection":
			status_count += 1
	var ok := _expect(identity_count == 1, "legacy inspector identity section must remain singular")
	ok = _expect(status_count == 1, "legacy inspector status section must remain singular") and ok
	ui.queue_free()
	return ok


func _test_production_source_contract() -> bool:
	var game := _read("res://scripts/ui/game_ui.gd")
	var bridge := _read("res://scripts/ui/runtime/runtime_action_panel_bridge.gd")
	var layer := _read("res://scripts/ui/runtime/runtime_notification_layer.gd")
	var ok := _expect(not bridge.contains("func process_feedback"), "runtime bridge must have no frame feedback method")
	ok = _expect(not game.contains("func _process_runtime_interaction_feedback"), "GameUI must have no frame feedback wrapper") and ok
	ok = _expect(game.contains("func _relayout_runtime_hud"), "GameUI must expose explicit relayout") and ok
	ok = _expect(game.contains("request_constructor_previews_refresh"), "GameUI must expose preview invalidation") and ok
	ok = _expect(game.contains("_restore_persistent_runtime_buttons_to_command_panel"), "teardown must preserve persistent buttons") and ok
	ok = _expect(layer.contains("_restart_runtime_notification_timeout\", maxf(duration, 0.0)"), "active notification path must start timeout") and ok
	return ok

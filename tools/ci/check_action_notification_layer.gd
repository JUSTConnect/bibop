extends SceneTree

const Layer = preload("res://scripts/ui/runtime/runtime_notification_layer.gd")
const Contract = preload("res://scripts/game/actions/action_result_contract.gd")

class FakeUI:
	extends Node
	var hint_label: Label = Label.new()
	var runtime_notification_label: Label = Label.new()
	var runtime_notification_panel: PanelContainer = PanelContainer.new()
	var runtime_notification_timer: float = 0.0
	var runtime_notification_role: String = "neutral"
	var restart_count: int = 0
	var localized_keys: Array[String] = []

	func _init() -> void:
		add_child(hint_label)
		add_child(runtime_notification_label)
		add_child(runtime_notification_panel)

	func _restart_runtime_notification_timeout(_duration: float) -> void:
		restart_count += 1

	func _localize_runtime_message(message_key: String, _details: Dictionary) -> String:
		localized_keys.append(message_key)
		if message_key == "door.open.success":
			return "Localized door opened"
		return ""

var failures: Array[String] = []
var pushed_events: Array[Dictionary] = []

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func event(id: String, result: String, fallback: String, player_action: bool = true, message_key: String = "") -> Dictionary:
	return Contract.notification_event(Contract.make(id, "door.open.%s" % result, result, "bipob", "door", "door.open", message_key, fallback), player_action)

func run() -> void:
	await process_frame
	var layer = Layer.new()
	var ui = FakeUI.new()
	root.add_child(layer)
	root.add_child(ui)
	layer.notification_event_pushed.connect(func(value: Dictionary, _kind: String, _message: String, _duration: float) -> void: pushed_events.append(value.duplicate(true)))

	var first: Dictionary = layer.publish_event(ui, event("action_1", Contract.RESULT_SUCCESS, "Door opened."), 0.2)
	check(bool(first.get("published", false)), "first event was not published")
	check(ui.runtime_notification_label.text == "Door opened.", "fallback message not rendered")
	check(ui.runtime_notification_role == Layer.KIND_POSITIVE, "success kind changed")
	check(ui.restart_count == 1, "notification timeout not restarted")

	var duplicate: Dictionary = layer.publish_event(ui, event("action_1", Contract.RESULT_SUCCESS, "Different text"), 0.2)
	check(not bool(duplicate.get("published", true)), "same action id published twice")
	check(str(duplicate.get("code", "")) == "notification.duplicate_ignored", "duplicate code changed")
	check(pushed_events.size() == 1, "duplicate emitted event")

	var same_text_new_id: Dictionary = layer.publish_event(ui, event("action_2", Contract.RESULT_SUCCESS, "Door opened."), 0.2)
	check(bool(same_text_new_id.get("published", false)), "same text with new id was suppressed")
	check(pushed_events.size() == 2, "second action event missing")

	var autonomous: Dictionary = layer.publish_event(ui, event("world_tick_1", Contract.RESULT_NO_CHANGE, "Power restored.", false), 0.2)
	check(not bool(autonomous.get("published", true)), "autonomous change created popup")
	check(str(autonomous.get("code", "")) == "notification.autonomous_ignored", "autonomous code changed")
	check(pushed_events.size() == 2, "autonomous event emitted popup")

	var localized: Dictionary = layer.publish_event(ui, event("action_3", Contract.RESULT_SUCCESS, "Fallback localized", true, "door.open.success"), 0.2)
	check(bool(localized.get("published", false)), "localized event not published")
	check(ui.runtime_notification_label.text == "Localized door opened", "localization callback ignored")

	var unknown_key: Dictionary = layer.publish_event(ui, event("action_4", Contract.RESULT_BLOCKED, "Credential required.", true, "unknown.key"), 0.2)
	check(bool(unknown_key.get("published", false)), "unknown localization key rejected")
	check(ui.runtime_notification_label.text == "Credential required.", "unknown key did not use fallback")
	check(ui.runtime_notification_role == Layer.KIND_SYSTEM_NEGATIVE, "blocked kind changed")

	var source: String = FileAccess.get_file_as_string("res://scripts/ui/runtime/runtime_notification_layer.gd")
	check(not source.contains("DUPLICATE_SUPPRESS_MS"), "timer-based duplicate suppression remains")
	check(not source.contains("Time.get_ticks_msec"), "notification layer still deduplicates by time")
	check(not source.contains("_contains_any"), "notification layer still parses text")
	check(source.contains("LegacyActionResultAdapterRef"), "legacy adapter is not isolated")

	layer.queue_free()
	ui.queue_free()
	if failures.is_empty():
		print("ACTION_NOTIFICATION_LAYER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ACTION_NOTIFICATION_LAYER_GATE: FAIL: %s" % failure)
	quit(1)

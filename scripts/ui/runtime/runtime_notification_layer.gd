extends CanvasLayer
class_name RuntimeNotificationLayer

signal notification_pushed(kind: String, message: String, duration: float)
signal notification_event_pushed(event: Dictionary, kind: String, message: String, duration: float)

const LegacyActionResultAdapterRef = preload("res://scripts/game/actions/legacy_action_result_adapter.gd")
const ActionResultContractRef = preload("res://scripts/game/actions/action_result_contract.gd")

const KIND_SYSTEM := "system"
const KIND_SYSTEM_NEGATIVE := "system_negative"
const KIND_POSITIVE := "positive"
const KIND_NEGATIVE := "negative"
const DEFAULT_DURATION := 2.8

const COLOR_SYSTEM_BG := Color(0.055, 0.105, 0.160, 0.96)
const COLOR_SYSTEM_BORDER := Color(0.200, 0.760, 0.950, 0.90)
const COLOR_SYSTEM_TEXT := Color(0.760, 0.930, 1.000, 1.00)
const COLOR_SYSTEM_NEGATIVE_BG := Color(0.200, 0.120, 0.035, 0.96)
const COLOR_SYSTEM_NEGATIVE_BORDER := Color(0.950, 0.640, 0.230, 0.92)
const COLOR_SYSTEM_NEGATIVE_TEXT := Color(1.000, 0.780, 0.440, 1.00)
const COLOR_POSITIVE_BG := Color(0.045, 0.150, 0.095, 0.96)
const COLOR_POSITIVE_BORDER := Color(0.250, 0.850, 0.480, 0.92)
const COLOR_POSITIVE_TEXT := Color(0.650, 1.000, 0.780, 1.00)
const COLOR_NEGATIVE_BG := Color(0.200, 0.050, 0.050, 0.96)
const COLOR_NEGATIVE_BORDER := Color(0.950, 0.250, 0.250, 0.92)
const COLOR_NEGATIVE_TEXT := Color(1.000, 0.650, 0.650, 1.00)
const COLOR_DEFAULT_BG := Color(0.070, 0.080, 0.095, 0.96)
const COLOR_DEFAULT_BORDER := Color(0.120, 0.220, 0.280, 0.75)
const COLOR_DEFAULT_TEXT := Color(0.820, 0.900, 0.920, 1.00)

var _processed_event_ids: Dictionary = {}
var _legacy_adapter = LegacyActionResultAdapterRef.new()

func _ready() -> void:
	layer = -128
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false

func publish_event(ui_owner: Object, event: Dictionary, duration: float = DEFAULT_DURATION) -> Dictionary:
	var event_id: String = str(event.get("event_id", event.get("action_id", ""))).strip_edges()
	if event_id.is_empty():
		return _publish_result(false, "notification.event_id_missing", event_id)
	if not bool(event.get("player_action", false)):
		return _publish_result(false, "notification.autonomous_ignored", event_id)
	if _processed_event_ids.has(event_id):
		return _publish_result(false, "notification.duplicate_ignored", event_id)
	var result_value: String = str(event.get("result", ActionResultContractRef.RESULT_FAILED)).strip_edges().to_lower()
	if result_value not in ActionResultContractRef.RESULTS:
		return _publish_result(false, "notification.result_invalid", event_id)
	var message: String = _resolve_event_message(ui_owner, event)
	if message.is_empty():
		return _publish_result(false, "notification.message_missing", event_id)
	var kind: String = _kind_for_result(result_value)
	_processed_event_ids[event_id] = true
	var emitted_event: Dictionary = event.duplicate(true)
	emitted_event["event_id"] = event_id
	notification_event_pushed.emit(emitted_event, kind, message, duration)
	notification_pushed.emit(kind, message, duration)
	_sync_legacy_ui_hint_target(ui_owner, message, kind, duration)
	return {"ok":true, "success":true, "code":"notification.published", "reason_code":"notification.published", "event_id":event_id, "published":true, "kind":kind, "message":message}

func notify(message: String, kind: String = KIND_SYSTEM, duration: float = DEFAULT_DURATION) -> void:
	var clean_message: String = message.strip_edges()
	if clean_message.is_empty():
		return
	var event: Dictionary = _legacy_adapter.adapt_message(clean_message, kind)
	publish_event(null, event, duration)

func show_hint(ui_owner: Object, message: String, kind: String = "", duration: float = DEFAULT_DURATION) -> void:
	var clean_message: String = message.strip_edges()
	if clean_message.is_empty():
		return
	var event: Dictionary = _legacy_adapter.adapt_message(clean_message, kind)
	publish_event(ui_owner, event, duration)

func system(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, KIND_SYSTEM, duration)

func system_negative(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, KIND_SYSTEM_NEGATIVE, duration)

func positive(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, KIND_POSITIVE, duration)

func negative(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, KIND_NEGATIVE, duration)

func from_legacy_hint(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, classify_legacy_hint(message), duration)

func has_processed_event(event_id: String) -> bool:
	return _processed_event_ids.has(event_id.strip_edges())

func clear_processed_events() -> void:
	_processed_event_ids.clear()

func refresh_runtime_notification_fallback(ui_owner: Object) -> void:
	if ui_owner == null or not is_instance_valid(ui_owner):
		return
	var runtime_label: Label = _get_object_property(ui_owner, "runtime_notification_label") as Label
	if runtime_label == null or not is_instance_valid(runtime_label):
		return
	if _object_has_property(ui_owner, "runtime_notification_timer"):
		ui_owner.set("runtime_notification_timer", 0.0)
	if _object_has_property(ui_owner, "runtime_notification_role"):
		ui_owner.set("runtime_notification_role", "neutral")
	runtime_label.modulate = Color.WHITE
	var secondary_text: String = "No active objective"
	if ui_owner.has_method("_get_runtime_secondary_objective_text"):
		secondary_text = str(ui_owner.call("_get_runtime_secondary_objective_text")).strip_edges()
		if secondary_text.is_empty():
			secondary_text = "No active objective"
	runtime_label.text = secondary_text
	runtime_label.add_theme_color_override("font_color", _get_ui_color(ui_owner, "UI_COLOR_TEXT_DIM", COLOR_DEFAULT_TEXT))
	var runtime_panel: PanelContainer = _get_object_property(ui_owner, "runtime_notification_panel") as PanelContainer
	if runtime_panel != null and is_instance_valid(runtime_panel):
		runtime_panel.add_theme_stylebox_override("panel", _make_style(_get_ui_color(ui_owner, "UI_COLOR_PANEL_DARK", COLOR_DEFAULT_BG), _get_ui_color(ui_owner, "UI_COLOR_BORDER_DIM", COLOR_DEFAULT_BORDER)))

func get_runtime_notification_role(message: String) -> String:
	return LegacyActionResultAdapterRef.runtime_role(message)

func show_runtime_notification(ui_owner: Object, message: String) -> void:
	show_hint(ui_owner, message, classify_legacy_hint(message), 7.0)

func classify_legacy_hint(message: String) -> String:
	return LegacyActionResultAdapterRef.classify_message(message)

func _resolve_event_message(ui_owner: Object, event: Dictionary) -> String:
	var message_key: String = str(event.get("message_key", "")).strip_edges()
	var details: Dictionary = Dictionary(event.get("details", {})).duplicate(true)
	if not message_key.is_empty() and ui_owner != null and is_instance_valid(ui_owner) and ui_owner.has_method("_localize_runtime_message"):
		var localized: String = str(ui_owner.call("_localize_runtime_message", message_key, details)).strip_edges()
		if not localized.is_empty():
			return localized
	return str(event.get("fallback", "")).strip_edges()

func _kind_for_result(result_value: String) -> String:
	match result_value:
		ActionResultContractRef.RESULT_SUCCESS:
			return KIND_POSITIVE
		ActionResultContractRef.RESULT_BLOCKED:
			return KIND_SYSTEM_NEGATIVE
		ActionResultContractRef.RESULT_FAILED:
			return KIND_NEGATIVE
		ActionResultContractRef.RESULT_NO_CHANGE, ActionResultContractRef.RESULT_CANCELLED:
			return KIND_SYSTEM
	return KIND_SYSTEM

func _sync_legacy_ui_hint_target(ui_owner: Object, message: String, kind: String, duration: float) -> void:
	if ui_owner == null or not is_instance_valid(ui_owner):
		return
	var colors: Dictionary = _get_colors(kind)
	var hint_label: Label = _get_object_property(ui_owner, "hint_label") as Label
	if hint_label != null and is_instance_valid(hint_label):
		hint_label.text = message
	var runtime_label: Label = _get_object_property(ui_owner, "runtime_notification_label") as Label
	if runtime_label != null and is_instance_valid(runtime_label):
		runtime_label.text = message
		runtime_label.modulate = Color.WHITE
		runtime_label.add_theme_color_override("font_color", colors["text"])
	var runtime_panel: PanelContainer = _get_object_property(ui_owner, "runtime_notification_panel") as PanelContainer
	if runtime_panel != null and is_instance_valid(runtime_panel):
		runtime_panel.visible = true
		runtime_panel.add_theme_stylebox_override("panel", _make_style(colors["bg"], colors["border"]))
	if _object_has_property(ui_owner, "runtime_notification_timer"):
		ui_owner.set("runtime_notification_timer", duration)
	if _object_has_property(ui_owner, "runtime_notification_role"):
		ui_owner.set("runtime_notification_role", kind)
	if ui_owner.has_method("_restart_runtime_notification_timeout"):
		ui_owner.call("_restart_runtime_notification_timeout", maxf(duration, 0.0))

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _get_colors(kind: String) -> Dictionary:
	match kind:
		KIND_SYSTEM:
			return {"bg":COLOR_SYSTEM_BG, "border":COLOR_SYSTEM_BORDER, "text":COLOR_SYSTEM_TEXT}
		KIND_SYSTEM_NEGATIVE:
			return {"bg":COLOR_SYSTEM_NEGATIVE_BG, "border":COLOR_SYSTEM_NEGATIVE_BORDER, "text":COLOR_SYSTEM_NEGATIVE_TEXT}
		KIND_POSITIVE:
			return {"bg":COLOR_POSITIVE_BG, "border":COLOR_POSITIVE_BORDER, "text":COLOR_POSITIVE_TEXT}
		KIND_NEGATIVE:
			return {"bg":COLOR_NEGATIVE_BG, "border":COLOR_NEGATIVE_BORDER, "text":COLOR_NEGATIVE_TEXT}
	return {"bg":COLOR_DEFAULT_BG, "border":COLOR_DEFAULT_BORDER, "text":COLOR_DEFAULT_TEXT}

func _get_object_property(target: Object, property_name: String) -> Variant:
	if target == null or not _object_has_property(target, property_name):
		return null
	return target.get(property_name)

func _object_has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return true
	return false

func _get_ui_color(target: Object, property_name: String, fallback: Color) -> Color:
	var value: Variant = _get_object_property(target, property_name)
	return value if value is Color else fallback

func _publish_result(published: bool, code: String, event_id: String) -> Dictionary:
	return {"ok":true, "success":true, "code":code, "reason_code":code, "event_id":event_id, "published":published}

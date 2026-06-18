extends CanvasLayer
class_name RuntimeNotificationLayer

signal notification_pushed(kind: String, message: String, duration: float)

const KIND_SYSTEM := "system"
const KIND_SYSTEM_NEGATIVE := "system_negative"
const KIND_POSITIVE := "positive"
const KIND_NEGATIVE := "negative"

const DEFAULT_DURATION := 2.8
const DUPLICATE_SUPPRESS_MS := 120

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

var _last_notification_message: String = ""
var _last_notification_kind: String = ""
var _last_notification_msec: int = 0

func _ready() -> void:
	# This singleton is now a compatibility adapter for GameUI's existing HUD.
	# It intentionally does not create a separate CanvasLayer stack and does not scan the whole scene tree.
	layer = -128
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false


func notify(message: String, kind: String = KIND_SYSTEM, duration: float = DEFAULT_DURATION) -> void:
	var clean_message := message.strip_edges()
	if clean_message.is_empty():
		return
	var normalized_kind: String = _normalize_kind(kind)
	if normalized_kind.is_empty():
		normalized_kind = KIND_SYSTEM
	if _is_recent_duplicate(clean_message, normalized_kind):
		return
	_store_last_notification(clean_message, normalized_kind)
	notification_pushed.emit(normalized_kind, clean_message, duration)


func show_hint(ui_owner: Object, message: String, kind: String = "", duration: float = DEFAULT_DURATION) -> void:
	var clean_message := message.strip_edges()
	if clean_message.is_empty():
		return
	var resolved_kind: String = _normalize_kind(kind)
	if resolved_kind.is_empty():
		resolved_kind = classify_legacy_hint(clean_message)
	if not _is_recent_duplicate(clean_message, resolved_kind):
		_store_last_notification(clean_message, resolved_kind)
		notification_pushed.emit(resolved_kind, clean_message, duration)
	_sync_legacy_ui_hint_target(ui_owner, clean_message, resolved_kind, duration)


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


func process_runtime_notification_timer(ui_owner: Object, delta: float) -> void:
	if ui_owner == null or not is_instance_valid(ui_owner):
		return
	var timer: float = float(_get_object_property(ui_owner, "runtime_notification_timer"))
	var runtime_label: Label = _get_object_property(ui_owner, "runtime_notification_label") as Label
	if timer > 0.0:
		timer = maxf(0.0, timer - delta)
		if _object_has_property(ui_owner, "runtime_notification_timer"):
			ui_owner.set("runtime_notification_timer", timer)
		if runtime_label != null and is_instance_valid(runtime_label):
			var pulse: float = 0.70 + 0.30 * abs(sin(float(Time.get_ticks_msec()) / 180.0))
			runtime_label.modulate = Color(1, 1, 1, pulse)
	elif runtime_label != null and is_instance_valid(runtime_label):
		refresh_runtime_notification_fallback(ui_owner)


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
	var text_color: Color = _get_ui_color(ui_owner, "UI_COLOR_TEXT_DIM", COLOR_DEFAULT_TEXT)
	runtime_label.add_theme_color_override("font_color", text_color)
	var runtime_panel: PanelContainer = _get_object_property(ui_owner, "runtime_notification_panel") as PanelContainer
	if runtime_panel != null and is_instance_valid(runtime_panel):
		var panel_bg: Color = _get_ui_color(ui_owner, "UI_COLOR_PANEL_DARK", COLOR_DEFAULT_BG)
		var border: Color = _get_ui_color(ui_owner, "UI_COLOR_BORDER_DIM", COLOR_DEFAULT_BORDER)
		runtime_panel.add_theme_stylebox_override("panel", _make_style(panel_bg, border))


func get_runtime_notification_role(message: String) -> String:
	var lower: String = message.to_lower()
	for token in ["collected", "unlocked", "opened", "closed", "complete", "success", "stored", "picked up"]:
		if lower.find(token) != -1:
			return "ok"
	for token in ["too heavy", "required", "locked", "no ", "cannot", "failed", "missing", "not enough", "blocked", "rejected", "occupied"]:
		if lower.find(token) != -1:
			return "danger"
	return "info"


func show_runtime_notification(ui_owner: Object, message: String) -> void:
	var role: String = get_runtime_notification_role(message)
	var kind: String = KIND_SYSTEM
	if role == "ok":
		kind = KIND_POSITIVE
	elif role == "danger":
		kind = KIND_NEGATIVE
	show_hint(ui_owner, message, kind, 7.0)


func classify_legacy_hint(message: String) -> String:
	var lower_message := message.strip_edges().to_lower()
	if lower_message.is_empty():
		return KIND_SYSTEM
	if _contains_any(lower_message, ["overheat", "thermal critical", "critical", "broken", "damaged", "failed", "mission failed", "disabled", "shutdown", "destroyed"]):
		return KIND_NEGATIVE
	if _contains_any(lower_message, ["blocked", "locked", "missing", "unavailable", "invalid", "insufficient", "no ", "cannot", "can't", "warning", "low battery"]):
		return KIND_SYSTEM_NEGATIVE
	if _contains_any(lower_message, ["charged", "completed", "success", "scan", "scanned", "hack", "hacked", "activated", "enabled", "opened", "closed", "connected"]):
		return KIND_POSITIVE
	return KIND_SYSTEM


func _sync_legacy_ui_hint_target(ui_owner: Object, message: String, kind: String, duration: float) -> void:
	if ui_owner == null or not is_instance_valid(ui_owner):
		return
	var colors := _get_colors(kind)
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
			return {"bg": COLOR_SYSTEM_BG, "border": COLOR_SYSTEM_BORDER, "text": COLOR_SYSTEM_TEXT}
		KIND_SYSTEM_NEGATIVE:
			return {"bg": COLOR_SYSTEM_NEGATIVE_BG, "border": COLOR_SYSTEM_NEGATIVE_BORDER, "text": COLOR_SYSTEM_NEGATIVE_TEXT}
		KIND_POSITIVE:
			return {"bg": COLOR_POSITIVE_BG, "border": COLOR_POSITIVE_BORDER, "text": COLOR_POSITIVE_TEXT}
		KIND_NEGATIVE:
			return {"bg": COLOR_NEGATIVE_BG, "border": COLOR_NEGATIVE_BORDER, "text": COLOR_NEGATIVE_TEXT}
		_:
			return {"bg": COLOR_DEFAULT_BG, "border": COLOR_DEFAULT_BORDER, "text": COLOR_DEFAULT_TEXT}


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
	if value is Color:
		return value
	return fallback


func _normalize_kind(kind: String) -> String:
	var clean_kind := kind.strip_edges().to_lower()
	if clean_kind in [KIND_SYSTEM, KIND_SYSTEM_NEGATIVE, KIND_POSITIVE, KIND_NEGATIVE]:
		return clean_kind
	if clean_kind in ["info", "blue", "system_positive"]:
		return KIND_SYSTEM
	if clean_kind in ["warning", "orange"]:
		return KIND_SYSTEM_NEGATIVE
	if clean_kind in ["ok", "success", "green"]:
		return KIND_POSITIVE
	if clean_kind in ["danger", "error", "red"]:
		return KIND_NEGATIVE
	return ""


func _is_recent_duplicate(message: String, kind: String) -> bool:
	var now_msec: int = Time.get_ticks_msec()
	return message == _last_notification_message and kind == _last_notification_kind and now_msec - _last_notification_msec <= DUPLICATE_SUPPRESS_MS


func _store_last_notification(message: String, kind: String) -> void:
	_last_notification_message = message
	_last_notification_kind = kind
	_last_notification_msec = Time.get_ticks_msec()


func _contains_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false

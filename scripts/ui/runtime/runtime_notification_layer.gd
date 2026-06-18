extends CanvasLayer
class_name RuntimeNotificationLayer

signal notification_pushed(kind: String, message: String, duration: float)

const KIND_SYSTEM := "system"
const KIND_SYSTEM_NEGATIVE := "system_negative"
const KIND_POSITIVE := "positive"
const KIND_NEGATIVE := "negative"

const DEFAULT_DURATION := 2.8
const MAX_VISIBLE := 4
const HINT_SOURCE_SCAN_INTERVAL := 0.45
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

var _root: Control = null
var _stack: VBoxContainer = null
var _items: Array[Dictionary] = []
var _hint_source_ids: Dictionary = {}
var _hint_source_scan_timer: float = 0.0
var _last_notification_message: String = ""
var _last_notification_kind: String = ""
var _last_notification_msec: int = 0

func _ready() -> void:
	layer = 128
	_ensure_layout()
	_scan_hint_sources()
	if get_tree() != null and not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)


func notify(message: String, kind: String = KIND_SYSTEM, duration: float = DEFAULT_DURATION) -> void:
	var clean_message := message.strip_edges()
	if clean_message.is_empty():
		return
	var normalized_kind: String = _normalize_kind(kind)
	if normalized_kind.is_empty():
		normalized_kind = KIND_SYSTEM
	if _is_recent_duplicate(clean_message, normalized_kind):
		return
	_ensure_layout()
	var item := _build_item(clean_message, normalized_kind)
	_stack.add_child(item)
	_items.append({"node": item, "ttl": maxf(duration, 0.1)})
	while _items.size() > MAX_VISIBLE:
		_remove_item(0)
	_store_last_notification(clean_message, normalized_kind)
	notification_pushed.emit(normalized_kind, clean_message, duration)


func show_hint(ui_owner: Object, message: String, kind: String = "", duration: float = DEFAULT_DURATION) -> void:
	var clean_message := message.strip_edges()
	if clean_message.is_empty():
		return
	var resolved_kind: String = _normalize_kind(kind)
	if resolved_kind.is_empty():
		resolved_kind = classify_legacy_hint(clean_message)
	notify(clean_message, resolved_kind, duration)
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
	runtime_label.add_theme_color_override("font_color", COLOR_DEFAULT_TEXT)
	var runtime_panel: PanelContainer = _get_object_property(ui_owner, "runtime_notification_panel") as PanelContainer
	if runtime_panel != null and is_instance_valid(runtime_panel):
		runtime_panel.add_theme_stylebox_override("panel", _make_style(COLOR_DEFAULT_BG, COLOR_DEFAULT_BORDER))


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


func _process(delta: float) -> void:
	_hint_source_scan_timer -= delta
	if _hint_source_scan_timer <= 0.0:
		_hint_source_scan_timer = HINT_SOURCE_SCAN_INTERVAL
		_scan_hint_sources()
	for i in range(_items.size() - 1, -1, -1):
		var item: Dictionary = _items[i]
		item["ttl"] = float(item.get("ttl", 0.0)) - delta
		_items[i] = item
		if float(item.get("ttl", 0.0)) <= 0.0:
			_remove_item(i)


func _ensure_layout() -> void:
	if _root != null and is_instance_valid(_root):
		return
	_root = Control.new()
	_root.name = "RuntimeNotificationLayerRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_stack = VBoxContainer.new()
	_stack.name = "RuntimeNotificationStack"
	_stack.anchor_left = 0.5
	_stack.anchor_right = 0.5
	_stack.anchor_top = 0.0
	_stack.anchor_bottom = 0.0
	_stack.offset_left = -230.0
	_stack.offset_right = 230.0
	_stack.offset_top = 18.0
	_stack.offset_bottom = 18.0
	_stack.add_theme_constant_override("separation", 6)
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stack)


func _build_item(message: String, kind: String) -> PanelContainer:
	var colors := _get_colors(kind)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460.0, 44.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_style(colors["bg"], colors["border"]))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", colors["text"])
	margin.add_child(label)
	return panel


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


func _remove_item(index: int) -> void:
	if index < 0 or index >= _items.size():
		return
	var node: Node = _items[index].get("node", null)
	_items.remove_at(index)
	if node != null and is_instance_valid(node):
		node.queue_free()


func _scan_hint_sources() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	_connect_hint_source_recursive(get_tree().root)


func _connect_hint_source_recursive(node: Node) -> void:
	_connect_hint_source(node)
	for child in node.get_children():
		_connect_hint_source_recursive(child)


func _on_tree_node_added(node: Node) -> void:
	_connect_hint_source(node)


func _connect_hint_source(node: Node) -> void:
	if node == null or node == self:
		return
	if not node.has_signal("hint_requested"):
		return
	var instance_id := node.get_instance_id()
	if _hint_source_ids.has(instance_id):
		return
	var callback := Callable(self, "_on_legacy_hint_requested")
	if not node.is_connected("hint_requested", callback):
		node.connect("hint_requested", callback)
	_hint_source_ids[instance_id] = true


func _on_legacy_hint_requested(message: String) -> void:
	from_legacy_hint(message)


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
		runtime_label.add_theme_color_override("font_color", colors["text"])
	var runtime_panel: PanelContainer = _get_object_property(ui_owner, "runtime_notification_panel") as PanelContainer
	if runtime_panel != null and is_instance_valid(runtime_panel):
		runtime_panel.visible = true
		runtime_panel.add_theme_stylebox_override("panel", _make_style(colors["bg"], colors["border"]))
	if _object_has_property(ui_owner, "runtime_notification_timer"):
		ui_owner.set("runtime_notification_timer", duration)
	if _object_has_property(ui_owner, "runtime_notification_role"):
		ui_owner.set("runtime_notification_role", kind)


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

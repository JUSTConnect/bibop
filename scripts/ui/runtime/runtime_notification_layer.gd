extends CanvasLayer
class_name RuntimeNotificationLayer

signal notification_pushed(kind: String, message: String, duration: float)

const KIND_SYSTEM := "system"
const KIND_SYSTEM_NEGATIVE := "system_negative"
const KIND_POSITIVE := "positive"
const KIND_NEGATIVE := "negative"

const DEFAULT_DURATION := 2.8
const MAX_VISIBLE := 4

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

func _ready() -> void:
	layer = 128
	_ensure_layout()


func notify(message: String, kind: String = KIND_SYSTEM, duration: float = DEFAULT_DURATION) -> void:
	var clean_message := message.strip_edges()
	if clean_message.is_empty():
		return
	_ensure_layout()
	var item := _build_item(clean_message, kind)
	_stack.add_child(item)
	_items.append({"node": item, "ttl": maxf(duration, 0.1)})
	while _items.size() > MAX_VISIBLE:
		_remove_item(0)
	notification_pushed.emit(kind, clean_message, duration)


func system(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, KIND_SYSTEM, duration)


func system_negative(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, KIND_SYSTEM_NEGATIVE, duration)


func positive(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, KIND_POSITIVE, duration)


func negative(message: String, duration: float = DEFAULT_DURATION) -> void:
	notify(message, KIND_NEGATIVE, duration)


func _process(delta: float) -> void:
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

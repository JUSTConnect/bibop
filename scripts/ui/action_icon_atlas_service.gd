extends RefCounted
class_name ActionIconAtlasService

const ATLAS_PATH: String = "res://assets/visual/isometric/icons/action/icon_menu_action.png"
const ATLAS_COLUMNS: int = 8
const ATLAS_ROWS: int = 8
const SOURCE_ICON_SIZE: Vector2i = Vector2i(128, 128)
const CONTROL_ICON_SIZE: Vector2i = Vector2i(32, 32)
const CONTROL_BUTTON_MIN_SIZE: Vector2i = Vector2i(40, 40)
const SUBMENU_ICON_SIZE: Vector2i = Vector2i(32, 32)
const SUBMENU_BUTTON_MIN_SIZE: Vector2i = Vector2i(40, 40)
const ITEM_ACTION_ICON_SIZE: Vector2i = Vector2i(32, 32)
const ITEM_ACTION_BUTTON_MIN_SIZE: Vector2i = Vector2i(40, 32)
const ICON_TEXTURE_RECT_NAME: String = "ActionIconAtlasTextureRect"

const ACTION_ICON_CELLS: Dictionary = {
	"physical_break_in": Vector2i(1, 1), "hack": Vector2i(1, 2), "unlock": Vector2i(1, 3), "lock": Vector2i(1, 4), "light_off": Vector2i(1, 5), "light_on": Vector2i(1, 6), "reinforcement_attack": Vector2i(1, 7), "flexible_manipulator_action": Vector2i(1, 8),
	"platform_rotate_right": Vector2i(2, 1), "platform_rotate_left": Vector2i(2, 2), "door_close": Vector2i(2, 3), "door_open": Vector2i(2, 4), "platform_raise": Vector2i(2, 5), "platform_lower": Vector2i(2, 6), "extract_fuse": Vector2i(2, 7), "telescopic_manipulator_action": Vector2i(2, 8),
	"manipulator_action": Vector2i(3, 1), "end_turn": Vector2i(3, 2), "drop_item": Vector2i(3, 3), "cancel": Vector2i(3, 4), "heavy_claw_break": Vector2i(3, 5), "sledgehammer_attack": Vector2i(3, 6), "insert_fuse": Vector2i(3, 7), "magnetic_manipulator_action": Vector2i(3, 8),
	"heavy_claw_pull": Vector2i(4, 1), "heavy_claw_push": Vector2i(4, 2), "move_forward": Vector2i(4, 3), "move_backward": Vector2i(4, 4), "heavy_claw_action": Vector2i(4, 5), "repair_unknown": Vector2i(4, 6), "flamethrower": Vector2i(4, 7), "plasma_cutter": Vector2i(4, 8),
	"connect_cable_to_socket": Vector2i(5, 1), "turn_on_device": Vector2i(5, 2), "take_cable_end_from_reel": Vector2i(5, 3), "delete_file": Vector2i(5, 4), "wired_connector": Vector2i(5, 5), "pickup_item": Vector2i(5, 6), "disconnect_cable_from_socket": Vector2i(5, 7), "xray": Vector2i(5, 8),
	"thermal_vision": Vector2i(6, 1), "device_scanner": Vector2i(6, 2), "enter_code": Vector2i(6, 3), "decrypt": Vector2i(6, 4), "repair": Vector2i(6, 5), "laser": Vector2i(6, 6), "move_file_to_firewall": Vector2i(6, 7), "unknown_action": Vector2i(6, 8),
	"rotate_bipob_right": Vector2i(7, 1), "rotate_bipob_left": Vector2i(7, 2), "switch_circuit_1": Vector2i(7, 3), "switch_circuit_2": Vector2i(7, 4), "switch_circuit_3": Vector2i(7, 5), "cooler_off": Vector2i(7, 6), "cooler_on": Vector2i(7, 7), "shocker": Vector2i(7, 8),
	"wireless_connector": Vector2i(8, 1), "optical_connector": Vector2i(8, 2), "saw": Vector2i(8, 3), "radar": Vector2i(8, 4)
}

const ACTION_ICON_ALIASES: Dictionary = {
	"act": "manipulator_action", "action": "manipulator_action", "interact": "manipulator_action", "break_in": "physical_break_in", "physical_hack": "physical_break_in", "breach": "physical_break_in", "break_breachable_wall": "heavy_claw_break", "force_open": "physical_break_in",
	"digital_hack": "hack", "hack_terminal": "hack", "download": "hack", "unlock_door": "unlock", "unlock_lock": "unlock", "lock_door": "lock", "lock_lock": "lock", "turn_light_off": "light_off", "switch_light_off": "light_off", "turn_light_on": "light_on", "switch_light_on": "light_on", "switch": "switch_circuit_1",
	"open": "door_open", "open_door": "door_open", "close": "door_close", "close_door": "door_close", "activate_platform": "turn_on_device", "raise_platform": "platform_raise", "lower_platform": "platform_lower", "rotate_platform_right": "platform_rotate_right", "rotate_platform_left": "platform_rotate_left",
	"end": "end_turn", "end_turn_button": "end_turn", "skip_turn": "end_turn", "drop": "drop_item", "drop_selected_item": "drop_item", "drop_item_button": "drop_item", "drop_button": "drop_item", "pick_up": "pickup_item", "pickup": "pickup_item", "delete": "delete_file", "delete_item": "delete_file", "remove_item": "delete_file", "trash": "delete_file", "cancel_action": "cancel", "cancel_button": "cancel", "close_menu": "cancel", "back_button": "cancel", "back": "cancel",
	"connect": "wired_connector", "connect_cable": "connect_cable_to_socket", "plug_in": "connect_cable_to_socket", "connect_wire_end": "connect_cable_to_socket", "connect_wire_1": "connect_cable_to_socket", "connect_wire_2": "connect_cable_to_socket", "disconnect_cable": "disconnect_cable_from_socket", "plug_out": "disconnect_cable_from_socket", "disconnect_power_wire": "disconnect_cable_from_socket", "disconnect_wire_1": "disconnect_cable_from_socket", "disconnect_wire_2": "disconnect_cable_from_socket",
	"device_scan": "device_scanner", "scan_device": "device_scanner", "scan": "device_scanner", "input_password": "enter_code", "apply_digital_key": "unlock", "repair_unknown": "repair_unknown", "cut": "plasma_cutter", "impact": "sledgehammer_attack", "take_end_1": "take_cable_end_from_reel", "take_end_2": "take_cable_end_from_reel",
	"turn_cooler_off": "cooler_off", "turn_cooler_on": "cooler_on", "push": "heavy_claw_push", "pull": "heavy_claw_pull", "claw": "heavy_claw_action", "heavy_claw": "heavy_claw_action", "forward": "move_forward", "move_forward_button": "move_forward", "backward": "move_backward", "move_backward_button": "move_backward", "left": "rotate_bipob_left", "l": "rotate_bipob_left", "turn_left": "rotate_bipob_left", "right": "rotate_bipob_right", "r": "rotate_bipob_right", "turn_right": "rotate_bipob_right"
}

static var _atlas_texture: Texture2D = null
static var _icon_cache: Dictionary = {}
static var _logged_missing_ids: Dictionary = {}
static var _white_icon_material: ShaderMaterial = null

static func atlas_region(row: int, col: int) -> Rect2:
	return Rect2(float((col - 1) * SOURCE_ICON_SIZE.x), float((row - 1) * SOURCE_ICON_SIZE.y), SOURCE_ICON_SIZE.x, SOURCE_ICON_SIZE.y)

static func canonical_action_id(action_id: String) -> String:
	var normalized: String = action_id.strip_edges().to_lower()
	return str(ACTION_ICON_ALIASES.get(normalized, normalized))

static func get_icon_texture(action_id: String) -> Texture2D:
	var canonical_id: String = canonical_action_id(action_id)
	if canonical_id.is_empty() or not ACTION_ICON_CELLS.has(canonical_id):
		_log_missing_icon_once(action_id)
		return null
	if _icon_cache.has(canonical_id):
		return _icon_cache[canonical_id]
	if _atlas_texture == null:
		_atlas_texture = load(ATLAS_PATH)
	if _atlas_texture == null:
		return null
	var cell: Vector2i = ACTION_ICON_CELLS[canonical_id]
	var icon: AtlasTexture = AtlasTexture.new()
	icon.atlas = _atlas_texture
	icon.region = atlas_region(cell.x, cell.y)
	_icon_cache[canonical_id] = icon
	return icon

static func apply_icon_to_button(
	button: Button,
	action_id: String,
	fallback_label: String,
	icon_size: Vector2i = CONTROL_ICON_SIZE,
	button_min_size: Vector2i = CONTROL_BUTTON_MIN_SIZE,
	icon_only: bool = true,
	force_white: bool = true
) -> void:
	if button == null:
		return
	var icon_texture: Texture2D = get_icon_texture(action_id)
	if icon_texture == null:
		_remove_icon_rect(button)
		button.icon = null
		button.text = fallback_label
		button.tooltip_text = fallback_label if button.tooltip_text.is_empty() else button.tooltip_text
		return
	button.icon = null
	if icon_only:
		button.text = ""
	else:
		button.text = fallback_label
	button.tooltip_text = fallback_label if button.tooltip_text.is_empty() else button.tooltip_text
	button.custom_minimum_size = Vector2(button_min_size)
	_ensure_icon_rect(button, icon_texture, icon_size, force_white)

static func _ensure_icon_rect(button: Button, icon_texture: Texture2D, icon_size: Vector2i, force_white: bool) -> void:
	var icon_rect: TextureRect = button.get_node_or_null(ICON_TEXTURE_RECT_NAME) as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = ICON_TEXTURE_RECT_NAME
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon_rect)
	icon_rect.texture = icon_texture
	icon_rect.custom_minimum_size = Vector2(icon_size)
	icon_rect.size = Vector2(icon_size)
	icon_rect.material = _get_white_icon_material() if force_white else null
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.anchor_left = 0.5
	icon_rect.anchor_top = 0.5
	icon_rect.anchor_right = 0.5
	icon_rect.anchor_bottom = 0.5
	icon_rect.offset_left = -float(icon_size.x) * 0.5
	icon_rect.offset_top = -float(icon_size.y) * 0.5
	icon_rect.offset_right = float(icon_size.x) * 0.5
	icon_rect.offset_bottom = float(icon_size.y) * 0.5

static func _get_white_icon_material() -> ShaderMaterial:
	if _white_icon_material != null:
		return _white_icon_material
	var shader: Shader = Shader.new()
	shader.code = """shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.01) {
		discard;
	}
	COLOR = vec4(1.0, 1.0, 1.0, tex.a * COLOR.a);
}
"""
	_white_icon_material = ShaderMaterial.new()
	_white_icon_material.shader = shader
	return _white_icon_material

static func _remove_icon_rect(button: Button) -> void:
	var existing_icon_rect: Node = button.get_node_or_null(ICON_TEXTURE_RECT_NAME)
	if existing_icon_rect != null:
		existing_icon_rect.queue_free()

static func _log_missing_icon_once(action_id: String) -> void:
	if action_id.strip_edges().is_empty() or _logged_missing_ids.has(action_id):
		return
	_logged_missing_ids[action_id] = true
	if OS.is_debug_build():
		print("Missing action icon mapping for action_id: %s" % action_id)

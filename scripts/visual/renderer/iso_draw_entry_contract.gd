extends RefCounted
class_name IsoDrawEntryContract

const KEY_CELL: String = "cell"
const KEY_LAYER: String = "layer"
const KEY_LAYER_BIAS: String = "layer_bias"
const KEY_KIND: String = "kind"
const KEY_DEPTH: String = "depth_key"
const KEY_SUB_ORDER: String = "sub_order"
const KEY_PAYLOAD: String = "payload"

const LAYER_BIAS_FLOOR: float = 0.0
const LAYER_BIAS_CABLE: float = 0.05
const LAYER_BIAS_ITEM: float = 0.1
const LAYER_BIAS_DOOR: float = 0.2
const LAYER_BIAS_WALL: float = 0.4
const LAYER_BIAS_WALL_MOUNTED: float = 0.55
const LAYER_BIAS_TERMINAL: float = 0.6
const LAYER_BIAS_ACTOR: float = 0.8
const LAYER_BIAS_OVERLAY: float = 1.0

const SUB_ORDER_FLOOR: float = 0.0
const SUB_ORDER_GROUND: float = 0.02
const SUB_ORDER_PLATFORM_SURFACE: float = 0.05
const SUB_ORDER_CABLE: float = 0.08
const SUB_ORDER_ITEM: float = 0.14
const SUB_ORDER_DOOR: float = 0.22
const SUB_ORDER_WALL_BODY: float = 0.40
const SUB_ORDER_WALL_TOP: float = 0.46
const SUB_ORDER_WALL_MOUNTED: float = 0.56
const SUB_ORDER_TERMINAL: float = 0.62
const SUB_ORDER_OVERLAY: float = 1.0

static func make_entry(
	cell: Vector2i,
	layer: String,
	kind: String,
	depth_key: float,
	sub_order: float,
	payload: Dictionary = {},
	layer_bias: Variant = null
) -> Dictionary:
	var entry: Dictionary = {
		KEY_CELL: cell,
		KEY_LAYER: layer,
		KEY_KIND: kind,
		KEY_DEPTH: depth_key,
		KEY_SUB_ORDER: sub_order,
		KEY_PAYLOAD: payload
	}
	if layer_bias != null:
		entry[KEY_LAYER_BIAS] = float(layer_bias)
	return entry

static func less(a: Dictionary, b: Dictionary, fallback_depth_a: float, fallback_depth_b: float) -> bool:
	var depth_a: float = float(a.get(KEY_DEPTH, fallback_depth_a))
	var depth_b: float = float(b.get(KEY_DEPTH, fallback_depth_b))
	if is_equal_approx(depth_a, depth_b):
		var sub_a: float = float(a.get(KEY_SUB_ORDER, a.get(KEY_LAYER_BIAS, 0.0)))
		var sub_b: float = float(b.get(KEY_SUB_ORDER, b.get(KEY_LAYER_BIAS, 0.0)))
		if is_equal_approx(sub_a, sub_b):
			var cell_a: Vector2i = Vector2i(a.get(KEY_CELL, Vector2i.ZERO))
			var cell_b: Vector2i = Vector2i(b.get(KEY_CELL, Vector2i.ZERO))
			if cell_a.y == cell_b.y:
				if cell_a.x == cell_b.x:
					return false
				return cell_a.x < cell_b.x
			return cell_a.y < cell_b.y
		return sub_a < sub_b
	return depth_a < depth_b

static func validate_entry(entry: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in [KEY_CELL, KEY_LAYER, KEY_KIND, KEY_DEPTH, KEY_SUB_ORDER, KEY_PAYLOAD]:
		if not entry.has(key):
			errors.append("missing_%s" % key)
	if entry.has(KEY_CELL) and not (entry[KEY_CELL] is Vector2i):
		errors.append("cell_must_be_vector2i")
	if entry.has(KEY_PAYLOAD) and not (entry[KEY_PAYLOAD] is Dictionary):
		errors.append("payload_must_be_dictionary")
	return errors

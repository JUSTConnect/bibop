extends RefCounted
class_name MapConstructorUiSafe


static func safe_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	return str(value)


static func safe_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


static func safe_array(value: Variant) -> Array:
	if value is Array:
		return value
	if value is PackedByteArray or value is PackedInt32Array or value is PackedInt64Array or value is PackedFloat32Array or value is PackedFloat64Array or value is PackedStringArray or value is PackedVector2Array or value is PackedVector3Array or value is PackedColorArray or value is PackedVector4Array:
		return Array(value)
	return []


static func safe_vector2i(value: Variant, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Dictionary:
		var row: Dictionary = value
		if row.has("x") and row.has("y"):
			return Vector2i(safe_int(row.get("x"), fallback.x), safe_int(row.get("y"), fallback.y))
	if value is Array:
		var values: Array = value
		if values.size() >= 2:
			return Vector2i(safe_int(values[0], fallback.x), safe_int(values[1], fallback.y))
	return fallback


static func safe_int(value: Variant, fallback: int = 0) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String and value.is_valid_int():
		return value.to_int()
	return fallback

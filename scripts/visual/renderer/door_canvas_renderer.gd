extends RefCounted
class_name DoorCanvasRenderer

static func normalize_state(raw_state: String) -> String:
	var door_state: String = raw_state.to_lower().strip_edges()
	if door_state == "broken" or door_state == "jammed" or door_state == "destroyed":
		return "damaged"
	if door_state in ["open", "closed", "locked", "powered", "unpowered", "damaged"]:
		return door_state
	return "closed"

static func build_visual_profile(door_kind: String, door_state: String) -> Dictionary:
	var normalized_state: String = normalize_state(door_state)
	var base_color: Color = Color(0.27, 0.24, 0.22, 0.96)
	var frame_color: Color = Color(0.12, 0.14, 0.16, 0.98)
	var accent_color: Color = Color(0.88, 0.72, 0.36, 0.98)
	var warning_color: Color = Color(1.0, 0.3, 0.22, 0.98)
	var threshold_color: Color = Color(0.16, 0.18, 0.2, 0.82)
	var alpha: float = 0.96
	if door_kind == "digital_door":
		base_color = Color(0.13, 0.2, 0.28, 0.96)
		accent_color = Color(0.38, 0.88, 1.0, 0.98)
	elif door_kind == "powered_gate":
		base_color = Color(0.09, 0.14, 0.2, 0.9)
		accent_color = Color(0.48, 0.96, 1.0, 0.98)
	if normalized_state == "open":
		alpha = 0.38
		base_color = base_color.darkened(0.18)
		accent_color = Color(0.58, 0.9, 0.98, 0.92)
	elif normalized_state == "locked":
		accent_color = Color(1.0, 0.72, 0.22, 0.99)
		warning_color = Color(1.0, 0.86, 0.24, 0.99)
	elif normalized_state == "powered":
		accent_color = Color(0.32, 0.92, 1.0, 0.99)
	elif normalized_state == "unpowered":
		base_color = Color(0.18, 0.19, 0.21, 0.86)
		accent_color = Color(0.48, 0.54, 0.58, 0.86)
		alpha = 0.72
	elif normalized_state == "damaged":
		accent_color = Color(1.0, 0.34, 0.22, 0.99)
		warning_color = Color(1.0, 0.18, 0.12, 0.99)
	return {"door_state": normalized_state, "door_kind": door_kind, "base_color": base_color, "frame_color": frame_color, "accent_color": accent_color, "warning_color": warning_color, "threshold_color": threshold_color, "alpha": alpha, "frame_enabled": true, "threshold_enabled": true, "state_badge_enabled": normalized_state != "closed", "damage_overlay_enabled": normalized_state == "damaged"}

static func _read_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2: return Vector2(value)
	if value is Vector2i: return Vector2(Vector2i(value))
	return fallback

static func _read_vector2_array(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array: return PackedVector2Array(value)
	var result := PackedVector2Array()
	if value is Array:
		for item in Array(value):
			if item is Vector2 or item is Vector2i:
				result.append(_read_vector2(item, Vector2.ZERO))
	return result

static func _read_dictionary(value: Variant) -> Dictionary:
	return Dictionary(value) if value is Dictionary else {}

static func _read_color(value: Variant, fallback: Color) -> Color:
	return Color(value) if value is Color else fallback

static func _read_float(value: Variant, fallback: float) -> float:
	return float(value) if value is float or value is int else fallback

static func _read_bool(value: Variant, fallback: bool) -> bool:
	return bool(value) if value is bool else fallback

static func _cmd(kind: String, order: int, data: Dictionary) -> Dictionary:
	var command := data.duplicate(true)
	command["kind"] = kind
	command["order"] = order
	if kind == "line" and not command.has("antialiased"):
		command["antialiased"] = false
	return command

static func _profile(context: Dictionary) -> Dictionary:
	return _read_dictionary(context.get("profile", {}))

static func _final_base(profile: Dictionary) -> Color:
	var color := _read_color(profile.get("base_color", Color(0.25, 0.25, 0.28, 0.96)), Color(0.25, 0.25, 0.28, 0.96))
	color.a *= _read_float(profile.get("alpha", 0.96), 0.96)
	return color

static func _final_accent(profile: Dictionary) -> Color:
	var color := _read_color(profile.get("accent_color", Color(0.8, 0.8, 0.72, 0.98)), Color(0.8, 0.8, 0.72, 0.98))
	color.a *= maxf(_read_float(profile.get("alpha", 0.96), 0.96), 0.55)
	return color

static func build_threshold_commands(context: Dictionary) -> Array[Dictionary]:
	var profile := _profile(context)
	if not _read_bool(profile.get("threshold_enabled", true), true) or _read_bool(context.get("threshold_texture_succeeded", false), false): return []
	var polygon := _read_vector2_array(context.get("threshold_polygon", PackedVector2Array()))
	if polygon.size() < 3: return []
	var commands: Array[Dictionary] = [_cmd("polygon", 0, {"points": polygon, "color": _read_color(profile.get("threshold_color", Color(0.14, 0.16, 0.18, 0.82)), Color(0.14, 0.16, 0.18, 0.82))})]
	var edge_color := _final_accent(profile).darkened(0.25)
	for i in range(polygon.size()): commands.append(_cmd("line", commands.size(), {"start": polygon[i], "end": polygon[(i + 1) % polygon.size()], "color": edge_color, "width": 1.0, "antialiased": false}))
	return commands

static func build_frame_commands(context: Dictionary) -> Array[Dictionary]:
	var profile := _profile(context)
	var polygon := _read_vector2_array(context.get("door_frame_polygon", PackedVector2Array()))
	if not _read_bool(profile.get("frame_enabled", true), true) or polygon.size() < 4: return []
	var frame_color := _read_color(profile.get("frame_color", Color(0.1, 0.12, 0.14, 0.98)), Color(0.1, 0.12, 0.14, 0.98))
	var commands: Array[Dictionary] = [_cmd("polygon", 0, {"points": polygon, "color": Color(frame_color.r, frame_color.g, frame_color.b, 0.72)})]
	for i in range(polygon.size()): commands.append(_cmd("line", commands.size(), {"start": polygon[i], "end": polygon[(i + 1) % polygon.size()], "color": frame_color.lightened(0.18), "width": 2.0, "antialiased": false}))
	if context.get("valid_jamb_centers", []) is Array:
		for center_variant in Array(context.get("valid_jamb_centers", [])):
			if center_variant is Vector2 or center_variant is Vector2i:
				var center := _read_vector2(center_variant, Vector2.ZERO)
				commands.append(_cmd("line", commands.size(), {"start": center + Vector2(0.0, -10.0), "end": center + Vector2(0.0, 13.0), "color": frame_color.lightened(0.24), "width": 3.0, "antialiased": false}))
	return commands

static func _axes(orientation: String) -> Dictionary:
	if orientation == "axis_y": return {"along": Vector2(0.78, 0.39).normalized(), "up": Vector2(0.0, -1.0)}
	return {"along": Vector2(0.78, -0.39).normalized(), "up": Vector2(0.0, -1.0)}

static func build_body_commands(context: Dictionary) -> Array[Dictionary]:
	var profile := _profile(context); var center := _read_vector2(context.get("door_insert_center", Vector2.ZERO), Vector2.ZERO)
	var kind := str(profile.get("door_kind", "mechanical_door")); var state := str(profile.get("door_state", "closed"))
	var base := _final_base(profile); var accent := _final_accent(profile); var frame := _read_color(profile.get("frame_color", Color(0.1, 0.12, 0.14, 0.98)), Color(0.1, 0.12, 0.14, 0.98))
	var commands: Array[Dictionary] = []
	if _read_bool(context.get("door_texture_succeeded", false), false):
		if kind == "digital_door":
			commands.append(_cmd("line", commands.size(), {"start": center + Vector2(10.0, -43.0), "end": center + Vector2(10.0, -13.0), "color": accent, "width": 2.6}))
			commands.append(_cmd("circle", commands.size(), {"center": center + Vector2(10.0, -28.0), "radius": 2.4, "color": accent.lightened(0.2)}))
		elif kind == "powered_gate":
			for i in range(3): commands.append(_cmd("line", commands.size(), {"start": center + Vector2(-13.0, -38.0 + float(i) * 10.0), "end": center + Vector2(13.0, -38.0 + float(i) * 10.0), "color": accent, "width": 1.8}))
		else:
			commands.append(_cmd("line", commands.size(), {"start": center + Vector2(-9.0, -24.0), "end": center + Vector2(9.0, -24.0), "color": accent, "width": 2.0}))
		commands.append(_cmd("circle", commands.size(), {"center": center + Vector2(0.0, -31.0), "radius": 2.5, "color": accent}))
		return commands
	var axes := _axes(str(context.get("orientation", "unknown"))); var along: Vector2 = axes["along"]; var up: Vector2 = axes["up"]
	var half_width := _read_vector2(context.get("tile_half_size", Vector2(64.0, 35.5)), Vector2(64.0, 35.5)).x * 0.24
	var panel_bottom := center + Vector2(0.0, 12.0); var panel_top := panel_bottom + up * (_read_float(context.get("wall_height", 48.0), 48.0) * 0.58)
	var panel := PackedVector2Array([panel_top - along * half_width, panel_top + along * half_width, panel_bottom + along * half_width, panel_bottom - along * half_width])
	if state == "open":
		var split := along * half_width * 0.58
		commands.append(_cmd("polygon", commands.size(), {"points": PackedVector2Array([panel[0] - split, panel[0], panel[3], panel[3] - split]), "color": base}))
		commands.append(_cmd("polygon", commands.size(), {"points": PackedVector2Array([panel[1], panel[1] + split, panel[2] + split, panel[2]]), "color": base}))
	else:
		commands.append(_cmd("polygon", commands.size(), {"points": panel, "color": base}))
	if kind == "digital_door":
		var s := panel_top + along * half_width * 0.58; var e := panel_bottom + along * half_width * 0.58
		commands.append(_cmd("line", commands.size(), {"start": s, "end": e, "color": accent, "width": 3.2})); commands.append(_cmd("circle", commands.size(), {"center": s.lerp(e, 0.35), "radius": 2.8, "color": accent.lightened(0.2)}))
	elif kind == "powered_gate":
		for i in range(4):
			var bc := panel_top.lerp(panel_bottom, 0.2 + float(i) * 0.2)
			commands.append(_cmd("line", commands.size(), {"start": bc - along * half_width * 0.84, "end": bc + along * half_width * 0.84, "color": accent, "width": 1.8})); commands.append(_cmd("circle", commands.size(), {"center": bc, "radius": 1.6, "color": accent.lightened(0.18)}))
	else:
		commands.append(_cmd("line", commands.size(), {"start": panel[0].lerp(panel[3], 0.5), "end": panel[1].lerp(panel[2], 0.5), "color": accent, "width": 1.6}))
	if _read_bool(context.get("debug_outlines", false), false):
		for i in range(panel.size()): commands.append(_cmd("line", commands.size(), {"start": panel[i], "end": panel[(i + 1) % panel.size()], "color": frame.lightened(0.28), "width": 1.0}))
	return commands

static func build_state_overlay_commands(context: Dictionary) -> Array[Dictionary]:
	var profile := _profile(context)
	var center := _read_vector2(context.get("door_insert_center", Vector2.ZERO), Vector2.ZERO)
	var state := str(profile.get("door_state", "closed")); var frame := _read_color(profile.get("frame_color", Color(0.1, 0.12, 0.14, 0.98)), Color(0.1, 0.12, 0.14, 0.98))
	var accent := _final_accent(profile); var warning := _read_color(profile.get("warning_color", Color(1.0, 0.28, 0.2, 0.98)), Color(1.0, 0.28, 0.2, 0.98))
	var commands: Array[Dictionary] = []
	if _read_bool(profile.get("state_badge_enabled", false), false):
		var badge := center + Vector2(18.0, -22.0); var badge_color := warning if state == "locked" or state == "damaged" else accent
		commands.append(_cmd("circle", commands.size(), {"center": badge, "radius": 4.2, "color": badge_color}))
		if state == "locked": commands.append(_cmd("line", commands.size(), {"start": badge + Vector2(-2.0, -1.0), "end": badge + Vector2(2.0, -1.0), "color": frame, "width": 1.2}))
		elif state == "unpowered": commands.append(_cmd("line", commands.size(), {"start": badge + Vector2(-2.8, 2.0), "end": badge + Vector2(2.8, -2.0), "color": frame, "width": 1.4}))
	if _read_bool(profile.get("damage_overlay_enabled", false), false):
		commands.append(_cmd("line", commands.size(), {"start": center + Vector2(-12.0, -36.0), "end": center + Vector2(-2.0, -23.0), "color": warning, "width": 1.8}))
		commands.append(_cmd("line", commands.size(), {"start": center + Vector2(-2.0, -23.0), "end": center + Vector2(-8.0, -14.0), "color": warning, "width": 1.4}))
	return commands

extends RefCounted
class_name ObjectPrimitiveRenderer

static func get_visual_profiles() -> Dictionary:
	# Visual-only object profile mapping for BIP-Visual-007.
	# Final asset rendering and gameplay metadata wiring will be added later.
	return {
		"door": {"base": Color(0.33, 0.22, 0.12, 0.96), "accent": Color(0.98, 0.74, 0.26, 0.98), "outline": Color(0.2, 0.13, 0.07, 0.94), "label": "Door", "shape": "door_panel"},
		"digital_door": {"base": Color(0.15, 0.25, 0.33, 0.95), "accent": Color(0.36, 0.73, 0.88, 0.95), "outline": Color(0.08, 0.15, 0.2, 0.92), "label": "Digital Door", "shape": "slab"},
		"powered_gate": {"base": Color(0.17, 0.22, 0.3, 0.95), "accent": Color(0.43, 0.81, 0.94, 0.95), "outline": Color(0.1, 0.15, 0.2, 0.92), "label": "Powered Gate", "shape": "slab"},
		"terminal": {"base": Color(0.14, 0.24, 0.29, 0.96), "accent": Color(0.34, 0.95, 1.0, 0.98), "outline": Color(0.07, 0.14, 0.18, 0.94), "label": "Terminal", "shape": "terminal_console"},
		"airflow_terminal": {"base": Color(0.14, 0.22, 0.28, 0.96), "accent": Color(0.5, 0.88, 0.98, 0.98), "outline": Color(0.07, 0.13, 0.17, 0.94), "label": "Airflow Terminal", "shape": "terminal_console"},
		"door_terminal": {"base": Color(0.15, 0.23, 0.28, 0.97), "accent": Color(0.4, 0.94, 1.0, 0.99), "outline": Color(0.08, 0.14, 0.18, 0.94), "label": "Door Terminal", "shape": "wall_terminal_panel"},
		"platform_terminal": {"base": Color(0.16, 0.27, 0.24, 0.97), "accent": Color(0.48, 0.98, 0.78, 0.99), "outline": Color(0.08, 0.16, 0.14, 0.94), "label": "Platform Terminal", "shape": "wall_terminal_panel"},
		"cooling_terminal": {"base": Color(0.14, 0.21, 0.29, 0.97), "accent": Color(0.58, 0.85, 1.0, 0.99), "outline": Color(0.08, 0.13, 0.18, 0.94), "label": "Cooling Terminal", "shape": "wall_terminal_panel"},
		"firewall": {"base": Color(0.32, 0.16, 0.14, 0.97), "accent": Color(1.0, 0.54, 0.2, 0.99), "outline": Color(0.22, 0.1, 0.08, 0.94), "label": "Firewall", "shape": "wall_firewall_panel"},
		"circuit_breaker": {"base": Color(0.22, 0.23, 0.24, 0.97), "accent": Color(0.95, 0.88, 0.52, 0.99), "outline": Color(0.13, 0.14, 0.15, 0.94), "label": "Circuit Breaker", "shape": "wall_breaker_box"},
		"fuse_box": {"base": Color(0.2, 0.21, 0.24, 0.97), "accent": Color(0.72, 0.82, 0.92, 0.99), "outline": Color(0.12, 0.13, 0.16, 0.94), "label": "Fuse Box", "shape": "wall_fuse_box"},
		"light_switch": {"base": Color(0.26, 0.25, 0.23, 0.97), "accent": Color(0.98, 0.94, 0.75, 0.99), "outline": Color(0.14, 0.13, 0.12, 0.94), "label": "Light Switch", "shape": "wall_light_switch"},
		"power_switcher": {"base": Color(0.26, 0.25, 0.23, 0.97), "accent": Color(0.98, 0.94, 0.75, 0.99), "outline": Color(0.14, 0.13, 0.12, 0.94), "label": "Power Switcher", "shape": "wall_light_switch"},
		"power_breaker": {"base": Color(0.22, 0.23, 0.24, 0.97), "accent": Color(0.95, 0.72, 0.30, 0.99), "outline": Color(0.13, 0.14, 0.15, 0.94), "label": "Power Breaker", "shape": "wall_breaker_box"},
		"light_switcher": {"base": Color(0.25, 0.24, 0.18, 0.97), "accent": Color(1.0, 0.96, 0.54, 0.99), "outline": Color(0.14, 0.13, 0.10, 0.94), "label": "Light Switcher", "shape": "wall_light_switch"},
		"power_socket": {"base": Color(0.21, 0.22, 0.25, 0.97), "accent": Color(0.78, 0.88, 1.0, 0.99), "outline": Color(0.11, 0.12, 0.15, 0.94), "label": "Power Socket", "shape": "wall_socket"},
		"light": {"base": Color(0.92, 0.86, 0.48, 0.97), "accent": Color(1.0, 0.96, 0.65, 0.99), "outline": Color(0.42, 0.36, 0.14, 0.94), "label": "Light", "shape": "wall_light"},
		"power_cable_reel": {"base": Color(0.2, 0.2, 0.22, 0.97), "accent": Color(0.89, 0.76, 0.47, 0.99), "outline": Color(0.11, 0.11, 0.12, 0.94), "label": "Power Cable Reel", "shape": "wall_cable_reel"},
		"exit": {"base": Color(0.14, 0.3, 0.21, 0.95), "accent": Color(0.48, 0.95, 0.69, 0.95), "outline": Color(0.07, 0.16, 0.11, 0.92), "label": "Exit", "shape": "slab"},
		"key": {"base": Color(0.31, 0.26, 0.12, 0.95), "accent": Color(0.95, 0.83, 0.35, 0.95), "outline": Color(0.2, 0.16, 0.08, 0.92), "label": "Key", "shape": "small_marker"},
		"component": {"base": Color(0.25, 0.25, 0.3, 0.95), "accent": Color(0.72, 0.72, 0.85, 0.95), "outline": Color(0.14, 0.14, 0.17, 0.92), "label": "Component", "shape": "pillar"},
		"hidden_route_node": {"base": Color(0.17, 0.18, 0.27, 0.95), "accent": Color(0.6, 0.58, 0.92, 0.95), "outline": Color(0.1, 0.1, 0.18, 0.92), "label": "Hidden Route Node", "shape": "small_marker"},
		"route_gate": {"base": Color(0.2, 0.2, 0.31, 0.95), "accent": Color(0.64, 0.62, 0.95, 0.95), "outline": Color(0.11, 0.11, 0.2, 0.92), "label": "Route Gate", "shape": "slab"},
		"hot_node": {"base": Color(0.35, 0.15, 0.11, 0.95), "accent": Color(0.96, 0.48, 0.2, 0.95), "outline": Color(0.24, 0.1, 0.08, 0.92), "label": "Hot Node", "shape": "heat_marker"},
		"fan_platform": {"base": Color(0.18, 0.24, 0.29, 0.95), "accent": Color(0.58, 0.78, 0.89, 0.95), "outline": Color(0.1, 0.14, 0.18, 0.92), "label": "Fan Platform", "shape": "slab"},
		"platform_control": {"base": Color(0.2, 0.29, 0.29, 0.95), "accent": Color(0.56, 0.92, 0.88, 0.95), "outline": Color(0.1, 0.16, 0.16, 0.92), "label": "Platform Control", "shape": "small_marker"},
		"fan_control": {"base": Color(0.19, 0.25, 0.29, 0.95), "accent": Color(0.57, 0.82, 0.93, 0.95), "outline": Color(0.1, 0.14, 0.17, 0.92), "label": "Fan Control", "shape": "small_marker"},
		"fan_speed_control": {"base": Color(0.23, 0.26, 0.3, 0.95), "accent": Color(0.77, 0.88, 0.95, 0.95), "outline": Color(0.12, 0.14, 0.18, 0.92), "label": "Fan Speed Control", "shape": "small_marker"},
		"airflow": {"base": Color(0.15, 0.21, 0.26, 0.95), "accent": Color(0.67, 0.89, 0.97, 0.95), "outline": Color(0.09, 0.13, 0.17, 0.92), "label": "Airflow", "shape": "line"},
		"cable_reel": {"base": Color(0.2, 0.2, 0.22, 0.95), "accent": Color(0.74, 0.7, 0.62, 0.95), "outline": Color(0.11, 0.11, 0.12, 0.92), "label": "Cable Reel", "shape": "small_marker"},
		"socket": {"base": Color(0.22, 0.22, 0.25, 0.95), "accent": Color(0.78, 0.85, 0.95, 0.95), "outline": Color(0.12, 0.12, 0.15, 0.92), "label": "Socket", "shape": "small_marker"},
		"power_source": {"base": Color(0.25, 0.28, 0.2, 0.97), "accent": Color(0.95, 0.88, 0.34, 0.99), "outline": Color(0.14, 0.16, 0.1, 0.94), "label": "Power Source", "shape": "slab"},
		"crate": {"base": Color(0.35, 0.23, 0.13, 0.97), "accent": Color(0.86, 0.62, 0.3, 0.99), "outline": Color(0.2, 0.12, 0.07, 0.94), "label": "Crate", "shape": "slab"},
		"barrel": {"base": Color(0.2, 0.3, 0.34, 0.97), "accent": Color(0.57, 0.84, 0.92, 0.99), "outline": Color(0.1, 0.16, 0.19, 0.94), "label": "Barrel", "shape": "pillar"},
		"vagus": {"base": Color(0.25, 0.12, 0.32, 0.97), "accent": Color(0.84, 0.38, 1.0, 0.99), "outline": Color(0.13, 0.06, 0.18, 0.94), "label": "Vagus", "shape": "pillar"},
		"bug": {"base": Color(0.12, 0.32, 0.16, 0.97), "accent": Color(0.55, 0.95, 0.38, 0.99), "outline": Color(0.06, 0.18, 0.08, 0.94), "label": "Bug", "shape": "small_marker"},
		"cable": {"base": Color(0.36, 0.04, 0.04, 0.95), "accent": Color(0.98, 0.12, 0.12, 0.99), "outline": Color(0.18, 0.02, 0.02, 0.92), "label": "Cable", "shape": "line"},
		"generic_object": {"base": Color(0.24, 0.24, 0.28, 0.95), "accent": Color(0.78, 0.8, 0.9, 0.95), "outline": Color(0.14, 0.14, 0.17, 0.92), "label": "Generic Object", "shape": "small_marker"}
	}


static func get_profile(profile_key: String) -> Dictionary:
	var profiles: Dictionary = get_visual_profiles()
	var safe_key: String = profile_key.strip_edges().to_lower()
	if safe_key.is_empty() or not profiles.has(safe_key):
		safe_key = "generic_object"
	var profile: Dictionary = Dictionary(profiles.get(safe_key, profiles.get("generic_object", {})))
	return {
		"base": Color(profile.get("base", Color(0.24, 0.24, 0.28, 0.95))),
		"accent": Color(profile.get("accent", Color(0.78, 0.8, 0.9, 0.95))),
		"outline": Color(profile.get("outline", Color(0.14, 0.14, 0.17, 0.92))),
		"label": str(profile.get("label", "Generic Object")),
		"shape": str(profile.get("shape", "small_marker"))
	}


static func _cmd(kind: String, order: int, data: Dictionary) -> Dictionary:
	var command: Dictionary = data.duplicate(true)
	command["kind"] = kind
	command["order"] = order
	return command

static func _profile_color(profile: Dictionary, key: String, fallback: Color) -> Color:
	return Color(profile.get(key, fallback))

static func _ordered(commands: Array[Dictionary]) -> Array[Dictionary]:
	for idx in range(commands.size()):
		commands[idx]["order"] = idx
	return commands

static func build_floor_base_commands(context: Dictionary) -> Array[Dictionary]:
	if bool(context.get("is_wall_visual", false)):
		return []
	var commands: Array[Dictionary] = []
	var shadow: PackedVector2Array = PackedVector2Array(context.get("shadow_polygon", PackedVector2Array()))
	if shadow.size() >= 3:
		commands.append(_cmd("polygon", commands.size(), {"points": shadow, "color": Color(0.03, 0.05, 0.08, 0.26)}))
	var footprint: PackedVector2Array = PackedVector2Array(context.get("footprint_polygon", PackedVector2Array()))
	if footprint.size() >= 3:
		commands.append(_cmd("polygon", commands.size(), {"points": footprint, "color": Color(0.2, 0.24, 0.28, 0.2)}))
	return commands

static func build_texture_accent_commands(context: Dictionary) -> Array[Dictionary]:
	if not bool(context.get("enabled", true)):
		return []
	var center: Vector2 = Vector2(context.get("visual_center", Vector2.ZERO))
	var marker_height: float = float(context.get("marker_height", 18.0))
	var accent: Color = Color(context.get("accent", Color.WHITE))
	return _ordered([
		{"kind":"circle", "center": center + Vector2(0.0, -marker_height - 8.0), "radius": 2.4, "color": accent},
		{"kind":"line", "start": center + Vector2(-4.0, -marker_height - 3.0), "end": center + Vector2(4.0, -marker_height - 3.0), "color": accent, "width": 1.5},
	])

static func build_shape_commands(shape: String, context: Dictionary) -> Array[Dictionary]:
	match shape:
		"slab": return _build_slab(context)
		"door_panel": return _build_door_panel(context)
		"pillar": return _build_pillar(context)
		"terminal_console": return _build_terminal_console(context)
		"line": return _build_line(context)
		"heat_marker": return _build_heat_marker(context)
		"small_marker": return _build_small_marker(context)
	return []

static func _base_context(context: Dictionary) -> Dictionary:
	return {"center": Vector2(context.get("visual_center", Vector2.ZERO)), "diamond": PackedVector2Array(context.get("diamond", PackedVector2Array())), "half_size": Vector2(context.get("half_size", Vector2(64,35.5))), "marker_height": maxf(float(context.get("marker_height", 18.0)), 1.0), "profile": Dictionary(context.get("profile", {})), "outlines": bool(context.get("outlines", false))}

static func _outline_poly(commands: Array[Dictionary], points: PackedVector2Array, color: Color) -> void:
	for i in range(points.size()):
		commands.append({"kind":"line", "start": points[i], "end": points[(i + 1) % points.size()], "color": color, "width": 1.0})

static func _build_slab(context: Dictionary) -> Array[Dictionary]:
	var c:=_base_context(context)
	var diamond:PackedVector2Array=c["diamond"]
	if diamond.size() < 4:
		return []
	var center:Vector2=c["center"]
	var pts:=PackedVector2Array()
	for p in diamond:
		pts.append(center + (p - center) * 0.38 + Vector2(0, -8))
	var prof:Dictionary=c["profile"]
	var cmds:Array[Dictionary]=[]
	cmds.append({"kind":"polygon","points":pts,"color":_profile_color(prof,"base",Color.WHITE)})
	cmds.append({"kind":"line","start":pts[3].lerp(pts[0],0.5),"end":pts[0].lerp(pts[1],0.5),"color":_profile_color(prof,"accent",Color.WHITE),"width":2.0})
	if c["outlines"]:
		_outline_poly(cmds, pts, _profile_color(prof,"outline",Color.WHITE))
	return _ordered(cmds)

static func _build_pillar(context: Dictionary) -> Array[Dictionary]:
	var c:=_base_context(context)
	var center:Vector2=c["center"]
	var h:float=c["marker_height"]
	var hw:float=maxf(c["half_size"].x*0.12,3.0)
	var bb:=center+Vector2(0,-3)
	var bt:=bb+Vector2(0,-h)
	var pts:=PackedVector2Array([bt+Vector2(-hw,0),bt+Vector2(hw,0),bb+Vector2(hw,0),bb+Vector2(-hw,0)])
	var prof:Dictionary=c["profile"]
	var cmds:Array[Dictionary]=[{"kind":"polygon","points":pts,"color":_profile_color(prof,"base",Color.WHITE)},{"kind":"line","start":pts[0],"end":pts[1],"color":_profile_color(prof,"accent",Color.WHITE),"width":2.0}]
	if c["outlines"]:
		_outline_poly(cmds, pts, _profile_color(prof,"outline",Color.WHITE))
	return _ordered(cmds)

static func _build_door_panel(context: Dictionary) -> Array[Dictionary]:
	var c:=_base_context(context)
	var center:Vector2=c["center"]
	var h:float=maxf(c["marker_height"]+12,18)
	var hw:float=maxf(c["half_size"].x*0.11,6)
	var bottom:=center+Vector2(0,-5)
	var top:=bottom+Vector2(0,-h)
	var body:=PackedVector2Array([top+Vector2(-hw,0),top+Vector2(hw,0),bottom+Vector2(hw,0),bottom+Vector2(-hw,0)])
	var frame:=PackedVector2Array([top+Vector2(-hw-3,-1),top+Vector2(hw+3,-1),bottom+Vector2(hw+3,0),bottom+Vector2(-hw-3,0)])
	var prof:Dictionary=c["profile"]
	var accent:=_profile_color(prof,"accent",Color.WHITE)
	var outline:=_profile_color(prof,"outline",Color.WHITE)
	var cmds:Array[Dictionary]=[]
	cmds.append({"kind":"polygon","points":frame,"color":outline.lightened(0.2).darkened(0.15)})
	cmds.append({"kind":"polygon","points":body,"color":_profile_color(prof,"base",Color.WHITE)})
	cmds.append({"kind":"line","start":body[3],"end":body[0],"color":accent,"width":2.2})
	cmds.append({"kind":"line","start":body[2],"end":body[1],"color":accent,"width":2.2})
	cmds.append({"kind":"line","start":body[0].lerp(body[1],0.2),"end":body[3].lerp(body[2],0.2),"color":accent,"width":1.2})
	cmds.append({"kind":"line","start":body[0].lerp(body[1],0.8),"end":body[3].lerp(body[2],0.8),"color":accent,"width":1.2})
	if c["outlines"]:
		_outline_poly(cmds, body, outline)
	return _ordered(cmds)

static func _build_terminal_console(context: Dictionary) -> Array[Dictionary]:
	var c:=_base_context(context)
	var center:Vector2=c["center"]
	var h:float=maxf(c["marker_height"]+2,12)
	var hw:float=maxf(c["half_size"].x*0.11,5)
	var bottom:=center+Vector2(0,-3)
	var top:=bottom+Vector2(0,-h)
	var body:=PackedVector2Array([top+Vector2(-hw,0),top+Vector2(hw,0),bottom+Vector2(hw,0),bottom+Vector2(-hw,0)])
	var screen:=Rect2(center+Vector2(-hw+1,-h+2),Vector2(hw*2-2,h*0.36))
	var prof:Dictionary=c["profile"]
	var accent:=_profile_color(prof,"accent",Color.WHITE)
	var cmds:Array[Dictionary]=[{"kind":"polygon","points":body,"color":_profile_color(prof,"base",Color.WHITE)},{"kind":"rect","rect":screen,"color":accent,"filled":true},{"kind":"line","start":screen.position+Vector2(0,screen.size.y),"end":screen.position+screen.size,"color":accent.lightened(0.25),"width":1.4}]
	if c["outlines"]:
		_outline_poly(cmds, body, _profile_color(prof, "outline", Color.WHITE))
		cmds.append({"kind":"rect","rect":screen,"color":_profile_color(prof,"outline",Color.WHITE),"filled":false,"width":1.0})
	return _ordered(cmds)

static func _build_small_marker(context: Dictionary) -> Array[Dictionary]:
	var c:=_base_context(context)
	var center:Vector2=c["center"]+Vector2(0,-6)
	var r:float=maxf(c["half_size"].y*0.16,3)
	var prof:Dictionary=c["profile"]
	var cmds:Array[Dictionary]=[{"kind":"circle","center":center,"radius":r,"color":_profile_color(prof,"base",Color.WHITE)},{"kind":"circle","center":center+Vector2(0,-r*0.3),"radius":r*0.45,"color":_profile_color(prof,"accent",Color.WHITE)}]
	if c["outlines"]:
		cmds.append({"kind":"arc","center":center,"radius":r,"start_angle":0.0,"end_angle":PI*2.0,"point_count":24,"color":_profile_color(prof,"outline",Color.WHITE),"width":1.0})
	return _ordered(cmds)

static func _build_line(context: Dictionary) -> Array[Dictionary]:
	var c:=_base_context(context)
	var center:Vector2=c["center"]+Vector2(0,-4)
	var hw:float=maxf(c["half_size"].x*0.26,8)
	var prof:Dictionary=c["profile"]
	var cmds:Array[Dictionary]=[{"kind":"line","start":center+Vector2(-hw,0),"end":center+Vector2(hw,0),"color":_profile_color(prof,"base",Color.WHITE),"width":3.0},{"kind":"line","start":center+Vector2(-hw*0.6,-2),"end":center+Vector2(hw*0.6,-2),"color":_profile_color(prof,"accent",Color.WHITE),"width":1.6}]
	if c["outlines"]:
		cmds.append({"kind":"line","start":center+Vector2(-hw,0),"end":center+Vector2(hw,0),"color":_profile_color(prof,"outline",Color.WHITE),"width":1.0})
	return _ordered(cmds)

static func _build_heat_marker(context: Dictionary) -> Array[Dictionary]:
	var c:=_base_context(context)
	var center:Vector2=c["center"]+Vector2(0,-7)
	var r:float=maxf(c["half_size"].y*0.18,3.5)
	var prof:Dictionary=c["profile"]
	var cmds:Array[Dictionary]=[{"kind":"circle","center":center,"radius":r,"color":_profile_color(prof,"base",Color.WHITE)},{"kind":"circle","center":center,"radius":r*0.58,"color":_profile_color(prof,"accent",Color.WHITE)}]
	if c["outlines"]:
		cmds.append({"kind":"arc","center":center,"radius":r,"start_angle":0.0,"end_angle":PI*2.0,"point_count":24,"color":_profile_color(prof,"outline",Color.WHITE),"width":1.0})
	return _ordered(cmds)

static func build_wall_mounted_commands(profile_key: String, context: Dictionary) -> Array[Dictionary]:
	var center: Vector2 = Vector2(context.get("visual_center", Vector2.ZERO))
	var profile: Dictionary = Dictionary(context.get("profile", {}))
	var outlines: bool = bool(context.get("outlines", false))
	match profile_key:
		"door_terminal": return _wall_terminal(center, profile, Color(0.36, 0.95, 1.0, 0.98), "door", outlines)
		"platform_terminal": return _wall_terminal(center, profile, Color(1.0, 0.72, 0.24, 0.98), "platform", outlines)
		"cooling_terminal": return _wall_terminal(center, profile, Color(0.54, 0.82, 1.0, 0.98), "cooling", outlines)
		"firewall": return _wall_terminal(center, profile, Color(1.0, 0.26, 0.22, 0.99), "firewall", outlines)
		"circuit_breaker": return _wall_breaker_box(center, profile, outlines)
		"fuse_box": return _wall_fuse_box(center, profile, outlines)
		"light_switch", "power_switcher": return _wall_light_switch(center, profile, outlines)
		"power_socket": return _wall_socket(center, profile, outlines)
		"light": return _wall_light(center, profile, outlines)
		"power_cable_reel": return _wall_cable_reel(center, profile, outlines)
	return []

static func _wall_terminal(center: Vector2, profile: Dictionary, screen_tint: Color, variant: String, outlines: bool) -> Array[Dictionary]:
	var base: Color = _profile_color(profile, "base", Color.WHITE)
	var accent: Color = _profile_color(profile, "accent", Color.WHITE)
	var outline: Color = _profile_color(profile, "outline", Color.WHITE)
	var body: Rect2 = Rect2(center + Vector2(-8.0, -18.0), Vector2(16.0, 16.0))
	var screen: Rect2 = Rect2(body.position + Vector2(2.0, 3.0), Vector2(body.size.x - 4.0, 6.0))
	var cmds: Array[Dictionary] = []
	cmds.append({"kind":"rect", "rect":body, "color":base, "filled":true})
	cmds.append({"kind":"rect", "rect":screen, "color":screen_tint, "filled":true})
	cmds.append({"kind":"line", "start":screen.position + Vector2(0.0, screen.size.y), "end":screen.position + screen.size, "color":accent, "width":1.2})
	if outlines:
		cmds.append({"kind":"rect", "rect":body, "color":outline, "filled":false, "width":1.0})
		cmds.append({"kind":"rect", "rect":screen, "color":outline, "filled":false, "width":1.0})
	if variant == "door":
		var glow: Rect2 = Rect2(center + Vector2(-5.0, -8.0), Vector2(10.0, 2.0))
		cmds.append({"kind":"rect", "rect":glow, "color":Color(0.62, 1.0, 1.0, 0.94), "filled":true})
		if outlines:
			cmds.append({"kind":"rect", "rect":glow, "color":outline, "filled":false, "width":1.0})
	elif variant == "platform":
		var indicator_y: float = center.y - 8.5
		cmds.append({"kind":"line", "start":center + Vector2(-5.6, indicator_y - center.y), "end":center + Vector2(5.6, indicator_y - center.y), "color":Color(1.0, 0.86, 0.45, 0.92), "width":1.5})
		cmds.append({"kind":"circle", "center":center + Vector2(4.8, -14.0), "radius":1.1, "color":Color(1.0, 0.56, 0.18, 0.95)})
		if outlines:
			cmds.append({"kind":"arc", "center":center + Vector2(4.8, -14.0), "radius":1.1, "start_angle":0.0, "end_angle":PI * 2.0, "point_count":12, "color":outline, "width":1.0})
	elif variant == "cooling":
		for i in range(3):
			var fin_x: float = center.x - 4.0 + float(i) * 3.8
			cmds.append({"kind":"line", "start":Vector2(fin_x, center.y - 14.8), "end":Vector2(fin_x, center.y - 4.8), "color":Color(0.82, 0.94, 1.0, 0.78), "width":1.1})
	elif variant == "firewall":
		var top: Vector2 = center + Vector2(0.0, -17.0)
		cmds.append({"kind":"line", "start":top + Vector2(-5.0, 9.0), "end":top, "color":Color(1.0, 0.9, 0.34, 0.98), "width":1.5})
		cmds.append({"kind":"line", "start":top, "end":top + Vector2(5.0, 9.0), "color":Color(1.0, 0.9, 0.34, 0.98), "width":1.5})
		cmds.append({"kind":"line", "start":top + Vector2(5.0, 9.0), "end":top + Vector2(-5.0, 9.0), "color":Color(1.0, 0.9, 0.34, 0.98), "width":1.5})
	return _ordered(cmds)

static func _wall_breaker_box(center: Vector2, profile: Dictionary, outlines: bool) -> Array[Dictionary]:
	var box: Rect2 = Rect2(center + Vector2(-7.0, -16.0), Vector2(14.0, 13.0))
	var pivot: Vector2 = box.position + Vector2(box.size.x * 0.35, box.size.y * 0.45)
	var accent: Color = _profile_color(profile, "accent", Color.WHITE)
	var cmds: Array[Dictionary] = [{"kind":"rect", "rect":box, "color":_profile_color(profile, "base", Color.WHITE), "filled":true}, {"kind":"circle", "center":pivot, "radius":1.4, "color":accent}, {"kind":"line", "start":pivot, "end":pivot + Vector2(4.2, -3.4), "color":accent, "width":2.0}]
	if outlines:
		cmds.append({"kind":"rect", "rect":box, "color":_profile_color(profile, "outline", Color.WHITE), "filled":false, "width":1.0})
	return _ordered(cmds)

static func _wall_fuse_box(center: Vector2, profile: Dictionary, outlines: bool) -> Array[Dictionary]:
	var box: Rect2 = Rect2(center + Vector2(-8.0, -16.0), Vector2(16.0, 13.0))
	var accent: Color = _profile_color(profile, "accent", Color.WHITE).darkened(0.2)
	var cmds: Array[Dictionary] = [{"kind":"rect", "rect":box, "color":_profile_color(profile, "base", Color.WHITE), "filled":true}]
	for i in range(3):
		cmds.append({"kind":"rect", "rect":Rect2(Vector2(box.position.x + 3.0 + float(i) * 4.2, box.position.y + 3.0), Vector2(2.6, 7.0)), "color":accent, "filled":true})
	if outlines:
		cmds.append({"kind":"rect", "rect":box, "color":_profile_color(profile, "outline", Color.WHITE), "filled":false, "width":1.0})
	return _ordered(cmds)

static func _wall_light_switch(center: Vector2, profile: Dictionary, outlines: bool) -> Array[Dictionary]:
	var plate: Rect2 = Rect2(center + Vector2(-4.0, -12.0), Vector2(8.0, 10.0))
	var switch_rect: Rect2 = Rect2(plate.position + Vector2(2.5, 2.2), Vector2(3.0, 4.6))
	var cmds: Array[Dictionary] = [{"kind":"rect", "rect":plate, "color":_profile_color(profile, "base", Color.WHITE), "filled":true}, {"kind":"rect", "rect":switch_rect, "color":_profile_color(profile, "accent", Color.WHITE), "filled":true}]
	if outlines:
		cmds.append({"kind":"rect", "rect":plate, "color":_profile_color(profile, "outline", Color.WHITE), "filled":false, "width":1.0})
	return _ordered(cmds)

static func _wall_socket(center: Vector2, profile: Dictionary, outlines: bool) -> Array[Dictionary]:
	var plate: Rect2 = Rect2(center + Vector2(-5.0, -13.0), Vector2(10.0, 9.0))
	var accent: Color = _profile_color(profile, "accent", Color.WHITE)
	var cmds: Array[Dictionary] = [{"kind":"rect", "rect":plate, "color":_profile_color(profile, "base", Color.WHITE), "filled":true}, {"kind":"circle", "center":plate.position + Vector2(3.2, 4.5), "radius":1.1, "color":accent}, {"kind":"circle", "center":plate.position + Vector2(6.8, 4.5), "radius":1.1, "color":accent}]
	if outlines:
		cmds.append({"kind":"rect", "rect":plate, "color":_profile_color(profile, "outline", Color.WHITE), "filled":false, "width":1.0})
	return _ordered(cmds)

static func _wall_light(center: Vector2, profile: Dictionary, outlines: bool) -> Array[Dictionary]:
	var lamp: Vector2 = center + Vector2(0.0, -11.0)
	var outline: Color = _profile_color(profile, "outline", Color.WHITE)
	var cmds: Array[Dictionary] = [{"kind":"circle", "center":lamp, "radius":5.0, "color":_profile_color(profile, "base", Color.WHITE)}, {"kind":"circle", "center":lamp, "radius":2.7, "color":_profile_color(profile, "accent", Color.WHITE)}, {"kind":"line", "start":lamp + Vector2(-5.0, 4.0), "end":lamp + Vector2(5.0, 4.0), "color":outline, "width":1.0}]
	if outlines:
		cmds.append({"kind":"arc", "center":lamp, "radius":5.0, "start_angle":0.0, "end_angle":PI * 2.0, "point_count":24, "color":outline, "width":1.0})
	return _ordered(cmds)

static func _wall_cable_reel(center: Vector2, profile: Dictionary, outlines: bool) -> Array[Dictionary]:
	var reel: Vector2 = center + Vector2(0.0, -10.0)
	var accent: Color = _profile_color(profile, "accent", Color.WHITE)
	var cmds: Array[Dictionary] = [{"kind":"circle", "center":reel, "radius":6.0, "color":_profile_color(profile, "base", Color.WHITE)}, {"kind":"arc", "center":reel, "radius":5.0, "start_angle":0.0, "end_angle":PI * 1.75, "point_count":20, "color":accent, "width":1.8}, {"kind":"arc", "center":reel, "radius":3.0, "start_angle":0.0, "end_angle":PI * 1.75, "point_count":20, "color":accent, "width":1.5}, {"kind":"circle", "center":reel, "radius":1.4, "color":accent}]
	if outlines:
		cmds.append({"kind":"arc", "center":reel, "radius":6.0, "start_angle":0.0, "end_angle":PI * 2.0, "point_count":24, "color":_profile_color(profile, "outline", Color.WHITE), "width":1.0})
	return _ordered(cmds)

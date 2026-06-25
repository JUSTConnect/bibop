extends SceneTree

const RendererScript = preload("res://scripts/field/room_visual_renderer.gd")
const ProjectionService = preload("res://scripts/visual/renderer/iso_projection_service.gd")
const DrawEntryContract = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
const FloorRenderer = preload("res://scripts/visual/renderer/floor_renderer.gd")
const WallRenderer = preload("res://scripts/visual/renderer/wall_renderer.gd")
const ObjectRenderer = preload("res://scripts/visual/renderer/object_renderer.gd")
const DoorCanvasRenderer = preload("res://scripts/visual/renderer/door_canvas_renderer.gd")
const RouteRenderer = preload("res://scripts/visual/renderer/route_renderer.gd")
const CableCanvasRenderer = preload("res://scripts/visual/renderer/cable_canvas_renderer.gd")
const OverlayRenderer = preload("res://scripts/visual/renderer/overlay_renderer.gd")
const MapConstructorOverlayRenderer = preload("res://scripts/visual/renderer/map_constructor_overlay_renderer.gd")
const RuntimeDebugOverlayRenderer = preload("res://scripts/visual/renderer/runtime_debug_overlay_renderer.gd")
const FogRenderer = preload("res://scripts/visual/renderer/fog_renderer.gd")
const AlignmentPolicy = preload("res://scripts/visual/renderer/iso_asset_alignment_policy.gd")
const ObjectTextureDispatchPolicy = preload("res://scripts/visual/renderer/object_texture_dispatch_policy.gd")

class TaskTestGrid:
	extends RefCounted
	var map_data: Array = [
		[0, 0, 0, 0],
		[0, 1, 1, 0],
		[0, 1, 2, 0],
		[0, 0, 0, 0],
	]

	func get_map_width() -> int:
		return int(map_data[0].size())

	func get_map_height() -> int:
		return int(map_data.size())

	func is_in_bounds(cell: Vector2i) -> bool:
		return cell.x >= 0 and cell.y >= 0 and cell.x < get_map_width() and cell.y < get_map_height()

	func get_tile(cell: Vector2i) -> int:
		if not is_in_bounds(cell):
			return -1
		return int(map_data[cell.y][cell.x])

var failures: Array[String] = []
var report: Dictionary = {}

func _initialize() -> void:
	_check_floor_and_connected_walls()
	_check_wall_mount_and_door_ordering()
	_check_door_route_and_bridge_commands()
	_check_selection_constructor_debug_and_fog()
	_check_asset_fallback_and_alignment()
	_check_renderer_coordinator_order()
	if failures.is_empty():
		print("TASK TEST renderer smoke contract OK: %s" % JSON.stringify(report))
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_floor_and_connected_walls() -> void:
	var grid := TaskTestGrid.new()
	var half_size := Vector2(64.0, 35.5)
	var floor_entries: Array[Dictionary] = FloorRenderer.build_draw_entries(grid, Callable(), Vector2.ZERO, half_size)
	var wall_entries: Array[Dictionary] = WallRenderer.build_draw_entries(grid, Vector2.ZERO, half_size, 8.0)
	_expect(floor_entries.size() == 13, "TASK TEST floor entry count changed")
	_expect(wall_entries.size() == 3, "TASK TEST wall entry count changed")
	var topology: Dictionary = WallRenderer.get_render_topology(grid, Vector2i(1, 1))
	_expect(str(topology.get("shape", "isolated")) != "isolated", "connected wall topology collapsed to isolated")
	_expect(bool(Dictionary(topology.get("neighbors", {})).get("east", false)), "connected wall lost east neighbor")
	_expect(bool(Dictionary(topology.get("neighbors", {})).get("south", false)), "connected wall lost south neighbor")
	for entry in floor_entries + wall_entries:
		_expect(DrawEntryContract.validate_entry(entry).is_empty(), "floor/wall component emitted invalid draw entry")
	report["floor_entries"] = floor_entries.size()
	report["wall_entries"] = wall_entries.size()
	report["wall_shape"] = str(topology.get("shape", ""))

func _check_wall_mount_and_door_ordering() -> void:
	var cell := Vector2i(1, 1)
	var depth := ProjectionService.get_depth_key(cell, Vector2.ZERO, Vector2(64.0, 35.5))
	var floor_entry := DrawEntryContract.make_entry(cell, "floor", "floor", depth, DrawEntryContract.SUB_ORDER_FLOOR, {})
	var cable_entry := DrawEntryContract.make_entry(cell, "cable", "cable", depth, DrawEntryContract.SUB_ORDER_CABLE, {}, DrawEntryContract.LAYER_BIAS_CABLE)
	var door_entry := ObjectRenderer.make_draw_entry(cell, "door", 0.0, {"profile_key": "door", "object_data": {}}, depth)
	var wall_entry := DrawEntryContract.make_entry(cell, "wall", "wall_body", depth, DrawEntryContract.SUB_ORDER_WALL_BODY, {}, DrawEntryContract.LAYER_BIAS_WALL)
	var mounted_entry := ObjectRenderer.make_draw_entry(cell, "wall_mounted", 0.0, {"profile_key": "terminal", "object_data": {"placement_mode": "wall_mounted"}}, depth, false)
	var overlay_entry := DrawEntryContract.make_entry(cell, "overlay", "overlay", depth, DrawEntryContract.SUB_ORDER_OVERLAY, {}, DrawEntryContract.LAYER_BIAS_OVERLAY)
	var entries: Array[Dictionary] = [mounted_entry, overlay_entry, wall_entry, door_entry, cable_entry, floor_entry]
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return DrawEntryContract.less(a, b, depth, depth))
	var kinds: Array[String] = []
	for entry in entries:
		kinds.append(str(entry.get("kind", "")))
	_expect(kinds == ["floor", "cable", "door", "wall_body", "wall_mounted", "overlay"], "representative floor/cable/door/wall/mount/fog order changed: %s" % str(kinds))
	report["queue_order"] = kinds

func _check_door_route_and_bridge_commands() -> void:
	var profile: Dictionary = DoorCanvasRenderer.build_visual_profile("digital_door", "locked")
	var threshold := PackedVector2Array([Vector2(-20.0, 0.0), Vector2(0.0, -10.0), Vector2(20.0, 0.0), Vector2(0.0, 10.0)])
	var context: Dictionary = {
		"profile": profile,
		"threshold_polygon": threshold,
		"door_frame_polygon": threshold,
		"valid_jamb_centers": [Vector2(-22.0, 0.0), Vector2(22.0, 0.0)],
		"door_insert_center": Vector2.ZERO,
		"orientation": "axis_x",
		"tile_half_size": Vector2(64.0, 35.5),
		"wall_height": 56.0,
		"door_texture_succeeded": false,
	}
	var threshold_commands: Array[Dictionary] = DoorCanvasRenderer.build_threshold_commands(context)
	var frame_commands: Array[Dictionary] = DoorCanvasRenderer.build_frame_commands(context)
	var body_commands: Array[Dictionary] = DoorCanvasRenderer.build_body_commands(context)
	var state_commands: Array[Dictionary] = DoorCanvasRenderer.build_state_overlay_commands(context)
	_expect(not threshold_commands.is_empty() and str(threshold_commands[0].get("kind", "")) == "polygon", "door threshold command phase changed")
	_expect(frame_commands.size() >= 7, "door frame/jamb command phase changed")
	_expect(not body_commands.is_empty(), "door body command phase became empty")
	_expect(not state_commands.is_empty() and str(state_commands[0].get("kind", "")) == "circle", "door state overlay command phase changed")

	var wall_segment: Dictionary = RouteRenderer.build_wall_route_segment(Vector2(100.0, 80.0), Vector2(64.0, 35.5), "east")
	var wall_commands: Array[Dictionary] = RouteRenderer.build_procedural_route_commands("air_duct", wall_segment, "outer")
	_expect(wall_commands.size() >= 4, "wall route command plan changed")
	var cable_commands: Array[Dictionary] = CableCanvasRenderer.build_floor_cable_commands({
		"center": Vector2(100.0, 80.0),
		"tile_half_size": Vector2(64.0, 35.5),
		"profile": {"base": Color(0.2, 0.2, 0.25), "accent": Color(0.8, 0.7, 0.3), "outline": Color(0.05, 0.05, 0.07)},
		"install_mode": "floor",
		"route_plan": {"shape": "straight_x", "active_dirs": ["east", "west"], "geometry_mode": "straight", "has_switch": false, "valid": true, "endpoint_cap": false, "junction_marker": false, "invalid_marker": false},
		"endpoints": {"east": Vector2(164.0, 48.0), "west": Vector2(36.0, 112.0)},
		"direction_vectors": {"east": Vector2(64.0, -32.0), "west": Vector2(-64.0, 32.0)},
		"object_link_rows": [],
		"health_state": "normal",
	})
	var bridge_commands: Array[Dictionary] = CableCanvasRenderer.build_bridge_commands({"object_center": Vector2(20.0, 40.0), "cable_center": Vector2(60.0, 80.0), "install_mode": "floor"})
	_expect(cable_commands.size() == 3, "floor cable straight command plan changed")
	_expect(bridge_commands.size() == 6, "object/cable bridge command plan changed")
	report["door_commands"] = threshold_commands.size() + frame_commands.size() + body_commands.size() + state_commands.size()
	report["route_commands"] = wall_commands.size() + cable_commands.size() + bridge_commands.size()

func _check_selection_constructor_debug_and_fog() -> void:
	var diamond := PackedVector2Array([Vector2(0.0, -20.0), Vector2(40.0, 0.0), Vector2(0.0, 20.0), Vector2(-40.0, 0.0)])
	var selection: Array[Dictionary] = OverlayRenderer.build_mouse_selection_commands({"selected_points": diamond, "route_point_sets": [diamond], "action_points": diamond})
	var constructor: Array[Dictionary] = MapConstructorOverlayRenderer.build_commands({
		"selected_points": diamond,
		"preview_points": diamond,
		"preview_mode": "blocked",
		"links": [{"start": Vector2.ZERO, "end": Vector2(20.0, 10.0), "broken": true}],
		"validation_markers": [{"center": Vector2(5.0, 5.0), "severity": "error"}],
	})
	var debug: Array[Dictionary] = RuntimeDebugOverlayRenderer.build_helper_preview_commands(diamond)
	var fog_color: Color = FogRenderer.get_fog_color({"visible": false, "explored": false, "unexplored_alpha": 0.42})
	var fog: Array[Dictionary] = FogRenderer.build_cell_overlay_commands({"fog_color": fog_color, "diamond_points": diamond, "draw_outlines": true})
	_expect(selection.size() >= 15, "selection overlay smoke plan changed")
	_expect(constructor.size() >= 8, "constructor overlay smoke plan changed")
	_expect(not debug.is_empty(), "runtime debug overlay smoke plan changed")
	_expect(fog.size() == 5 and str(fog[0].get("kind", "")) == "polygon", "fog final overlay smoke plan changed")
	report["overlay_commands"] = selection.size() + constructor.size() + debug.size() + fog.size()

func _check_asset_fallback_and_alignment() -> void:
	var attempts: Array[Dictionary] = ObjectTextureDispatchPolicy.build_attempt_plan({
		"profile_key": "terminal",
		"primary_asset_id": "object_terminal",
		"primary_is_png": false,
		"has_terminal_visual": true,
		"terminal_texture_asset_id": "object_terminal_powered",
	})
	_expect(attempts.size() == 3, "asset fallback attempt count changed")
	_expect(str(attempts[0].get("kind", "")) == "optional" and str(attempts[1].get("kind", "")) == "legacy", "asset primary fallback precedence changed")
	_expect(str(attempts[2].get("source", "")) == "terminal_state", "asset state fallback precedence changed")
	var rule: Dictionary = AlignmentPolicy.normalize_runtime_rule("object_terminal", AlignmentPolicy.get_alignment_rule("object_terminal"), Vector2(128.0, 71.0), Vector2(64.0, 35.5), Vector2(128.0, 64.0))
	_expect(Vector2(rule.get("expected_size", Vector2.ZERO)).x > 0.0, "asset alignment expected size missing")
	_expect(not str(rule.get("anchor", "")).is_empty(), "asset alignment anchor missing")
	report["asset_attempts"] = attempts.map(func(attempt: Dictionary) -> String: return str(attempt.get("kind", "")))
	report["alignment_anchor"] = str(rule.get("anchor", ""))

func _check_renderer_coordinator_order() -> void:
	var renderer: RoomVisualRenderer = RendererScript.new()
	var depth := 100.0
	var a := DrawEntryContract.make_entry(Vector2i(1, 1), "floor", "floor", depth, DrawEntryContract.SUB_ORDER_FLOOR, {})
	var b := DrawEntryContract.make_entry(Vector2i(1, 1), "wall", "wall_body", depth, DrawEntryContract.SUB_ORDER_WALL_BODY, {})
	_expect(renderer.sort_iso_draw_entries(a, b), "coordinator draw-entry comparator changed")
	_expect(renderer.get_iso_projection_mode() == ProjectionService.PROJECTION_STANDARD, "coordinator projection delegation changed")
	renderer.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

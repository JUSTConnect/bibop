extends RefCounted
class_name CoolingRoutingContourService

const ROUTING_KINDS: Array[String] = ["air_duct", "water_pipe"]
const VALID_SIDES: Array[String] = ["NE", "NW", "SE", "SW"]
const OPPOSITE_SIDE: Dictionary = {"NE":"SW", "SW":"NE", "NW":"SE", "SE":"NW"}

static func _routing_kind(object_data: Dictionary) -> String:
	var kind: String = str(object_data.get("routing_kind", "")).strip_edges().to_lower()
	return kind if kind in ROUTING_KINDS else ""

static func _route_mode(object_data: Dictionary) -> String:
	return "inner" if str(object_data.get("route_mode", object_data.get("wall_routing_mode", "inner"))).strip_edges().to_lower() == "inner" else "outer"

static func _normalize_side(value: Variant) -> String:
	var side: String = str(value).strip_edges().to_upper()
	return side if side in VALID_SIDES else ""

static func _route_sides(object_data: Dictionary) -> Array[String]:
	var sides: Array[String] = []
	for key in ["wall_side_1", "wall_side_2"]:
		var side: String = _normalize_side(object_data.get(key, ""))
		if not side.is_empty():
			sides.append(side)
	return sides

static func _side_delta(side: String) -> Vector2i:
	match _normalize_side(side):
		"NE": return Vector2i(0, -1)
		"NW": return Vector2i(-1, 0)
		"SE": return Vector2i(1, 0)
		"SW": return Vector2i(0, 1)
	return Vector2i.ZERO

static func _object_cell(object_data: Dictionary) -> Vector2i:
	var value: Variant = object_data.get("position", object_data.get("cell", Vector2i.ZERO))
	if value is Vector2i: return value
	if value is Vector2: return Vector2i(int(value.x), int(value.y))
	if value is Array and Array(value).size() >= 2: return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	if value is Dictionary:
		var dict: Dictionary = Dictionary(value)
		return Vector2i(int(dict.get("x", 0)), int(dict.get("y", 0)))
	return Vector2i.ZERO

static func _routing_objects(objects_by_id: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id_variant in objects_by_id.keys():
		var object_id: String = str(id_variant)
		var data: Dictionary = Dictionary(objects_by_id[id_variant])
		if not _routing_kind(data).is_empty():
			result[object_id] = data
	return result

static func _physically_connected(a: Dictionary, b: Dictionary) -> bool:
	if _routing_kind(a) != _routing_kind(b) or _route_mode(a) != _route_mode(b):
		return false
	var a_cell: Vector2i = _object_cell(a)
	var b_cell: Vector2i = _object_cell(b)
	if _route_mode(a) == "outer":
		# TODO: replace this preview-only fallback with shared wall-face exterior adjacency when visuals define wall-face spans.
		return a_cell.distance_squared_to(b_cell) == 1
	for side in _route_sides(a):
		if a_cell + _side_delta(side) == b_cell and _route_sides(b).has(str(OPPOSITE_SIDE.get(side, ""))):
			return true
	return false

static func _build_physical_components(objects_by_id: Dictionary) -> Array[Array]:
	var ids: Array = objects_by_id.keys()
	var links: Dictionary = {}
	for id in ids: links[id] = []
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a_id: String = str(ids[i]); var b_id: String = str(ids[j])
			if _physically_connected(Dictionary(objects_by_id[a_id]), Dictionary(objects_by_id[b_id])):
				links[a_id].append(b_id); links[b_id].append(a_id)
	var seen: Dictionary = {}
	var components: Array[Array] = []
	for id in ids:
		if seen.has(id): continue
		var queue: Array = [id]
		var members: Array = []
		seen[id] = true
		while not queue.is_empty():
			var current: String = str(queue.pop_front())
			members.append(current)
			for next in Array(links.get(current, [])):
				if not seen.has(next):
					seen[next] = true; queue.append(next)
		components.append(members)
	return components

static func build_contours(objects_by_id: Dictionary) -> Dictionary:
	var routing: Dictionary = _routing_objects(objects_by_id)
	var physical_components: Array[Array] = _build_physical_components(routing)
	var result: Dictionary = {"air_duct": {}, "water_pipe": {}}
	var counters: Dictionary = {"air_duct": 0, "water_pipe": 0}
	var assigned: Dictionary = {}
	var manual_groups: Dictionary = {}
	for object_id in routing.keys():
		var data: Dictionary = Dictionary(routing[object_id])
		if str(data.get("cooling_contour_mode", "auto")).strip_edges().to_lower() != "manual":
			continue
		var member_ids: Array = Array(data.get("cooling_contour_member_ids", []))
		if not member_ids.is_empty():
			var key: String = "%s|members:%s" % [_routing_kind(data), object_id]
			manual_groups[key] = []
			if not member_ids.has(object_id):
				member_ids.append(object_id)
			for member_variant in member_ids:
				var member_id: String = str(member_variant).strip_edges()
				if routing.has(member_id) and _routing_kind(Dictionary(routing[member_id])) == _routing_kind(data) and not Array(manual_groups[key]).has(member_id):
					manual_groups[key].append(member_id)
			continue
		if not str(data.get("cooling_contour_id", "")).strip_edges().is_empty():
			var key: String = "%s|%s" % [_routing_kind(data), str(data.get("cooling_contour_id", "")).strip_edges()]
			if not manual_groups.has(key): manual_groups[key] = []
			manual_groups[key].append(object_id)
	for key in manual_groups.keys():
		var parts: PackedStringArray = str(key).split("|", false, 1)
		var kind: String = parts[0]; var contour_id: String = parts[1]
		result[kind][contour_id] = {"routing_kind": kind, "members": Array(manual_groups[key]).duplicate(), "cells": []}
		for member in Array(manual_groups[key]):
			assigned[member] = true
			result[kind][contour_id]["cells"].append(_object_cell(Dictionary(routing[member])))
	for component in physical_components:
		var auto_members: Array = []
		var kind: String = ""
		for member in component:
			if assigned.has(member): continue
			auto_members.append(member); kind = _routing_kind(Dictionary(routing[member]))
		if auto_members.is_empty(): continue
		counters[kind] = int(counters[kind]) + 1
		var contour_id: String = "%s_contour_%03d" % [kind, int(counters[kind])]
		result[kind][contour_id] = {"routing_kind": kind, "members": auto_members, "cells": []}
		for member in auto_members:
			result[kind][contour_id]["cells"].append(_object_cell(Dictionary(routing[member])))
	return result

static func get_object_contour_id(object_data: Dictionary, object_id: String, auto_contours: Dictionary) -> String:
	if str(object_data.get("cooling_contour_mode", "auto")).strip_edges().to_lower() == "manual":
		for contour_id in Dictionary(auto_contours.get(_routing_kind(object_data), {})).keys():
			if Array(Dictionary(auto_contours[_routing_kind(object_data)][contour_id]).get("members", [])).has(object_id):
				return str(contour_id)
		return str(object_data.get("cooling_contour_id", "")).strip_edges()
	var kind: String = _routing_kind(object_data)
	for contour_id in Dictionary(auto_contours.get(kind, {})).keys():
		if Array(Dictionary(auto_contours[kind][contour_id]).get("members", [])).has(object_id):
			return str(contour_id)
	return ""

static func collect_contour_warnings(objects_by_id: Dictionary) -> Dictionary:
	var warnings: Dictionary = {}
	var routing: Dictionary = _routing_objects(objects_by_id)
	for object_id in routing.keys(): warnings[object_id] = []
	for a_id in routing.keys():
		var a: Dictionary = Dictionary(routing[a_id])
		var sides: Array[String] = _route_sides(a)
		if _route_mode(a) == "inner" and sides.size() >= 2 and sides[0] == sides[1]: warnings[a_id].append("Inner routing sides must be different.")
		for side in sides:
			if _route_mode(a) != "inner": continue
			var expected_cell: Vector2i = _object_cell(a) + _side_delta(side)
			var opposite: String = str(OPPOSITE_SIDE.get(side, ""))
			var found_any: bool = false
			for b_id in routing.keys():
				if a_id == b_id: continue
				var b: Dictionary = Dictionary(routing[b_id])
				if _object_cell(b) != expected_cell: continue
				found_any = true
				if _routing_kind(b) != _routing_kind(a): warnings[a_id].append("Neighbor routing kind mismatch: expected %s." % _routing_kind(a))
				elif _route_mode(b) != _route_mode(a): warnings[a_id].append("Neighbor routing mode mismatch: expected %s." % _route_mode(a))
				elif not _route_sides(b).has(opposite): warnings[a_id].append("No matching neighboring routing port on %s." % opposite)
				break
			if not found_any: warnings[a_id].append("No matching neighboring routing port on %s." % opposite)
	var by_manual_id: Dictionary = {}
	for object_id in routing.keys():
		var data: Dictionary = Dictionary(routing[object_id])
		if str(data.get("cooling_contour_mode", "auto")).strip_edges().to_lower() != "manual": continue
		var member_ids: Array = Array(data.get("cooling_contour_member_ids", []))
		if not member_ids.is_empty():
			var members_manual_id: String = "members:%s" % object_id
			by_manual_id[members_manual_id] = []
			if not member_ids.has(object_id): member_ids.append(object_id)
			for member_variant in member_ids:
				var member_id: String = str(member_variant).strip_edges()
				if routing.has(member_id): by_manual_id[members_manual_id].append(member_id)
			continue
		var explicit_manual_id: String = str(data.get("cooling_contour_id", "")).strip_edges()
		if explicit_manual_id.is_empty(): continue
		if not by_manual_id.has(explicit_manual_id): by_manual_id[explicit_manual_id] = []
		by_manual_id[explicit_manual_id].append(object_id)
	var components: Array[Array] = _build_physical_components(routing)
	for manual_id in by_manual_id.keys():
		var kinds: Dictionary = {}; var component_indexes: Dictionary = {}
		for object_id in Array(by_manual_id[manual_id]):
			kinds[_routing_kind(Dictionary(routing[object_id]))] = true
			for index in range(components.size()):
				if components[index].has(object_id): component_indexes[index] = true
				
		if kinds.size() > 1:
			for object_id in Array(by_manual_id[manual_id]): warnings[object_id].append("Manual contour id cannot mix air duct and water pipe.")
		if component_indexes.size() > 1:
			for object_id in Array(by_manual_id[manual_id]): warnings[object_id].append("Manual contour id contains disconnected segments.")
	return warnings

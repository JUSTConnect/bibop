from pathlib import Path

path = Path("scripts/game/map_constructor_validation_service.gd")
text = path.read_text()
start = text.index("\tvar contour_objects_by_id: Dictionary = {}")
end = text.index("\t_get_power_link_validation_rules().append_key_door_link_issues", start)
block = '''\tvar route_objects_by_id: Dictionary = {}
\tfor route_object_variant in manager.mission_world_objects:
\t\tvar route_object: Dictionary = manager._safe_dictionary(route_object_variant)
\t\tvar route_object_id: String = _safe_string(route_object.get("id", "")).strip_edges()
\t\tif not route_object_id.is_empty():
\t\t\troute_objects_by_id[route_object_id] = route_object
\tvar route_issues: Dictionary = CoolingRoutingContourServiceRef.collect_route_issues(route_objects_by_id)
\tfor route_object_id_value in route_issues.keys():
\t\tvar route_object_id: String = str(route_object_id_value)
\t\tvar route_object_data: Dictionary = Dictionary(route_objects_by_id.get(route_object_id, {}))
\t\tvar route_cell: Vector2i = manager._deserialize_cell_variant(route_object_data.get("position", Vector2i(-1, -1)))
\t\tvar issue_index: int = 0
\t\tfor route_issue_value in Array(route_issues[route_object_id_value]):
\t\t\tvar route_issue: Dictionary = Dictionary(route_issue_value)
\t\t\tvar issue_code: String = str(route_issue.get("code", "passive_route_invalid"))
\t\t\tvar issue_message: String = issue_code
\t\t\tvar route_side: String = str(route_issue.get("side", ""))
\t\t\tif not route_side.is_empty():
\t\t\t\tissue_message += " on %s" % route_side
\t\t\tissues.append(_make_map_constructor_issue("passive_route_%s_%s_%d" % [route_object_id, issue_code, issue_index], "warning", issue_message, route_cell, source_name, "world_object", route_object_id, "Adjust mount side or route ports to match a physical neighbor."))
\t\t\tissue_index += 1
'''
path.write_text(text[:start] + block + text[end:])

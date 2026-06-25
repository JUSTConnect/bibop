#!/usr/bin/env python3
from pathlib import Path

cable_path = Path("tools/check_cable_canvas_renderer_boundary.py")
cable_source = cable_path.read_text(encoding="utf-8")
cable_old = '''for name, delegate in thin_delegates.items():
    body = function_body(renderer, name)
    if delegate not in body or "_draw_canvas_commands" not in body:
        errors.append(f"RoomVisualRenderer {name} must be a thin CableCanvasRenderer/canonical-executor delegate")
    for forbidden in ("draw_line(", "draw_circle(", "draw_arc(", "draw_polyline(", "while cursor", "match color_id"):
        if forbidden in body:
            errors.append(f"RoomVisualRenderer {name} retained migrated cable policy: {forbidden}")
'''
cable_new = '''draw_delegates = {
    "draw_iso_cable_hidden_segment",
    "draw_iso_cable_wall_segment",
    "draw_object_cable_bridge",
    "draw_iso_cable_damage_marker",
    "draw_iso_cable_object_links",
    "_draw_iso_cable_polyline",
    "draw_iso_cable_endpoint_cap",
    "draw_iso_cable_invalid_marker",
}
for name, delegate in thin_delegates.items():
    body = function_body(renderer, name)
    if delegate not in body:
        errors.append(f"RoomVisualRenderer {name} must delegate to CableCanvasRenderer")
    if name in draw_delegates and "_draw_canvas_commands" not in body:
        errors.append(f"RoomVisualRenderer {name} must execute commands through the canonical Canvas executor")
    for forbidden in ("draw_line(", "draw_circle(", "draw_arc(", "draw_polyline(", "while cursor", "match color_id"):
        if forbidden in body:
            errors.append(f"RoomVisualRenderer {name} retained migrated cable policy: {forbidden}")
'''
if cable_old not in cable_source:
    raise SystemExit("expected cable boundary block not found")
cable_path.write_text(cable_source.replace(cable_old, cable_new), encoding="utf-8")
print("corrected cable Canvas boundary policy")

alignment_path = Path("tools/check_iso_asset_alignment_policy_boundary.py")
alignment_source = alignment_path.read_text(encoding="utf-8")
legacy_requirement = '    "VisualAssetCatalogScript.get_all_asset_paths",\n'
if legacy_requirement not in alignment_source:
    raise SystemExit("expected legacy alignment/catalog requirement not found")
alignment_path.write_text(
    alignment_source.replace(legacy_requirement, ""),
    encoding="utf-8",
)
print("removed obsolete direct catalog requirement from alignment boundary")

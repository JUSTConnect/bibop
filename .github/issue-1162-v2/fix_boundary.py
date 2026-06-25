#!/usr/bin/env python3
from pathlib import Path

path = Path("tools/check_cable_canvas_renderer_boundary.py")
source = path.read_text(encoding="utf-8")
old = '''for name, delegate in thin_delegates.items():
    body = function_body(renderer, name)
    if delegate not in body or "_draw_canvas_commands" not in body:
        errors.append(f"RoomVisualRenderer {name} must be a thin CableCanvasRenderer/canonical-executor delegate")
    for forbidden in ("draw_line(", "draw_circle(", "draw_arc(", "draw_polyline(", "while cursor", "match color_id"):
        if forbidden in body:
            errors.append(f"RoomVisualRenderer {name} retained migrated cable policy: {forbidden}")
'''
new = '''draw_delegates = {
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
if old not in source:
    raise SystemExit("expected cable boundary block not found")
path.write_text(source.replace(old, new), encoding="utf-8")
print("corrected cable Canvas boundary policy")

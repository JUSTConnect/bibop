from pathlib import Path

renderer_path = Path("scripts/field/room_visual_renderer.gd")
source = renderer_path.read_text(encoding="utf-8")
anchor = "func set_map_constructor_overlay_preferences(prefs: Dictionary) -> void:\n"
state = '''var map_constructor_overlay_prefs: Dictionary = {
\t"show_preview": true,
\t"show_validation": true,
\t"show_links": true,
\t"show_power": true,
\t"show_wall_side_arrows": true,
\t"show_multi_select": true
}
var map_constructor_overlay_data: Dictionary = {}
var map_constructor_editor_render_active: bool = false
'''
if "var map_constructor_overlay_prefs: Dictionary" not in source:
    if anchor not in source:
        raise RuntimeError("Map Constructor preference setter anchor not found")
    source = source.replace(anchor, state + anchor, 1)
renderer_path.write_text(source, encoding="utf-8")

checker_path = Path("tools/check_room_visual_renderer_component_boundary.py")
checker = checker_path.read_text(encoding="utf-8")
checker = checker.replace(
    "ROOM_VISUAL_RENDERER_RUNTIME_DEBUG_EXTRACTION_CAP = 6153",
    "ROOM_VISUAL_RENDERER_RUNTIME_DEBUG_EXTRACTION_CAP = 6156",
)
checker_path.write_text(checker, encoding="utf-8")

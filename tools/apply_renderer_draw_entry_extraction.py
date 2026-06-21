from pathlib import Path
import re

path = Path(__file__).resolve().parents[1] / "scripts/field/room_visual_renderer.gd"
source = path.read_text(encoding="utf-8")

old_constants = '''const ISO_LAYER_BIAS_FLOOR: float = 0.0
const ISO_LAYER_BIAS_CABLE: float = 0.05
const ISO_LAYER_BIAS_ITEM: float = 0.1
const ISO_LAYER_BIAS_DOOR: float = 0.2
const ISO_LAYER_BIAS_WALL: float = 0.4
const ISO_LAYER_BIAS_WALL_MOUNTED: float = 0.55
const ISO_LAYER_BIAS_TERMINAL: float = 0.6
const ISO_LAYER_BIAS_ACTOR: float = 0.8
const ISO_LAYER_BIAS_OVERLAY: float = 1.0

const ISO_DRAW_SUB_ORDER_FLOOR: float = 0.0
const ISO_DRAW_SUB_ORDER_GROUND: float = 0.02
const ISO_DRAW_SUB_ORDER_PLATFORM_SURFACE: float = 0.05
const ISO_DRAW_SUB_ORDER_CABLE: float = 0.08
const ISO_DRAW_SUB_ORDER_ITEM: float = 0.14
const ISO_DRAW_SUB_ORDER_DOOR: float = 0.22
const ISO_DRAW_SUB_ORDER_WALL_BODY: float = 0.40
const ISO_DRAW_SUB_ORDER_WALL_TOP: float = 0.46
const ISO_DRAW_SUB_ORDER_WALL_MOUNTED: float = 0.56
const ISO_DRAW_SUB_ORDER_TERMINAL: float = 0.62
const ISO_DRAW_SUB_ORDER_OVERLAY: float = 1.0
'''
new_constants = '''const ISO_LAYER_BIAS_FLOOR: float = IsoDrawEntryContractRef.LAYER_BIAS_FLOOR
const ISO_LAYER_BIAS_CABLE: float = IsoDrawEntryContractRef.LAYER_BIAS_CABLE
const ISO_LAYER_BIAS_ITEM: float = IsoDrawEntryContractRef.LAYER_BIAS_ITEM
const ISO_LAYER_BIAS_DOOR: float = IsoDrawEntryContractRef.LAYER_BIAS_DOOR
const ISO_LAYER_BIAS_WALL: float = IsoDrawEntryContractRef.LAYER_BIAS_WALL
const ISO_LAYER_BIAS_WALL_MOUNTED: float = IsoDrawEntryContractRef.LAYER_BIAS_WALL_MOUNTED
const ISO_LAYER_BIAS_TERMINAL: float = IsoDrawEntryContractRef.LAYER_BIAS_TERMINAL
const ISO_LAYER_BIAS_ACTOR: float = IsoDrawEntryContractRef.LAYER_BIAS_ACTOR
const ISO_LAYER_BIAS_OVERLAY: float = IsoDrawEntryContractRef.LAYER_BIAS_OVERLAY

const ISO_DRAW_SUB_ORDER_FLOOR: float = IsoDrawEntryContractRef.SUB_ORDER_FLOOR
const ISO_DRAW_SUB_ORDER_GROUND: float = IsoDrawEntryContractRef.SUB_ORDER_GROUND
const ISO_DRAW_SUB_ORDER_PLATFORM_SURFACE: float = IsoDrawEntryContractRef.SUB_ORDER_PLATFORM_SURFACE
const ISO_DRAW_SUB_ORDER_CABLE: float = IsoDrawEntryContractRef.SUB_ORDER_CABLE
const ISO_DRAW_SUB_ORDER_ITEM: float = IsoDrawEntryContractRef.SUB_ORDER_ITEM
const ISO_DRAW_SUB_ORDER_DOOR: float = IsoDrawEntryContractRef.SUB_ORDER_DOOR
const ISO_DRAW_SUB_ORDER_WALL_BODY: float = IsoDrawEntryContractRef.SUB_ORDER_WALL_BODY
const ISO_DRAW_SUB_ORDER_WALL_TOP: float = IsoDrawEntryContractRef.SUB_ORDER_WALL_TOP
const ISO_DRAW_SUB_ORDER_WALL_MOUNTED: float = IsoDrawEntryContractRef.SUB_ORDER_WALL_MOUNTED
const ISO_DRAW_SUB_ORDER_TERMINAL: float = IsoDrawEntryContractRef.SUB_ORDER_TERMINAL
const ISO_DRAW_SUB_ORDER_OVERLAY: float = IsoDrawEntryContractRef.SUB_ORDER_OVERLAY
'''
assert old_constants in source
source = source.replace(old_constants, new_constants, 1)

def replace_function(text: str, name: str, replacement: str) -> str:
    start = re.search(rf"(?m)^func {re.escape(name)}\s*\(", text)
    assert start, name
    next_function = re.search(r"(?m)^func [A-Za-z0-9_]+\s*\(", text[start.end():])
    end = start.end() + next_function.start() if next_function else len(text)
    return text[:start.start()] + replacement.rstrip() + "\n\n" + text[end:]

source = replace_function(source, "sort_iso_draw_entries", '''func sort_iso_draw_entries(a: Dictionary, b: Dictionary) -> bool:
\tvar fallback_a: float = get_iso_depth_key(Vector2i(a.get("cell", Vector2i.ZERO)))
\tvar fallback_b: float = get_iso_depth_key(Vector2i(b.get("cell", Vector2i.ZERO)))
\treturn IsoDrawEntryContractRef.less(a, b, fallback_a, fallback_b)''')

source = replace_function(source, "make_iso_object_draw_entry", '''func make_iso_object_draw_entry(cell: Vector2i, layer_name: String, layer_bias: float, object_index: float, payload: Dictionary) -> Dictionary:
\tvar profile_key: String = str(payload.get("profile_key", ""))
\tvar stable_order_step: float = 0.00001 if layer_name == "wall_mounted" else 0.01
\tvar sub_order: float = get_iso_object_sub_order(layer_name, profile_key) + object_index * stable_order_step
\tif layer_name == "wall_mounted":
\t\tsub_order += float(get_wall_mounted_render_layer(Dictionary(payload.get("object_data", {})))) * 0.001
\tvar kind: String = "wall_mounted" if layer_name == "wall_mounted" else ("cable" if layer_name == "cable" else ("door" if profile_key.contains("door") or profile_key.contains("gate") else "object"))
\treturn IsoDrawEntryContractRef.make_entry(
\t\tcell,
\t\tlayer_name,
\t\tkind,
\t\tget_iso_object_depth_key_for_payload(payload),
\t\tsub_order,
\t\tpayload,
\t\tlayer_bias + object_index * 0.01
\t)''')

replacements = [
('''\t\t\tfloor_entries.append({
\t\t\t\t"cell": cell,
\t\t\t\t"kind": "ground" if not ground_asset_key.is_empty() else "floor",
\t\t\t\t"layer": "floor",
\t\t\t\t"depth_key": get_iso_floor_depth_key(cell),
\t\t\t\t"sub_order": ISO_DRAW_SUB_ORDER_GROUND if not ground_asset_key.is_empty() else ISO_DRAW_SUB_ORDER_FLOOR,
\t\t\t\t"payload": {"tile_type": tile_type}
\t\t\t})''', '''\t\t\tfloor_entries.append(IsoDrawEntryContractRef.make_entry(
\t\t\t\tcell,
\t\t\t\t"floor",
\t\t\t\t"ground" if not ground_asset_key.is_empty() else "floor",
\t\t\t\tget_iso_floor_depth_key(cell),
\t\t\t\tISO_DRAW_SUB_ORDER_GROUND if not ground_asset_key.is_empty() else ISO_DRAW_SUB_ORDER_FLOOR,
\t\t\t\t{"tile_type": tile_type}
\t\t\t))'''),
('''\t\t\twall_entries.append({
\t\t\t\t"cell": cell,
\t\t\t\t"layer": "wall",
\t\t\t\t"layer_bias": ISO_LAYER_BIAS_WALL,
\t\t\t\t"kind": "wall_body",
\t\t\t\t"depth_key": get_iso_wall_depth_key_for_cell(cell),
\t\t\t\t"sub_order": ISO_DRAW_SUB_ORDER_WALL_BODY,
\t\t\t\t"payload": {"tile_type": tile_type}
\t\t\t})''', '''\t\t\twall_entries.append(IsoDrawEntryContractRef.make_entry(
\t\t\t\tcell,
\t\t\t\t"wall",
\t\t\t\t"wall_body",
\t\t\t\tget_iso_wall_depth_key_for_cell(cell),
\t\t\t\tISO_DRAW_SUB_ORDER_WALL_BODY,
\t\t\t\t{"tile_type": tile_type},
\t\t\t\tISO_LAYER_BIAS_WALL
\t\t\t))'''),
('''\t\t\tplatform_entries.append({
\t\t\t\t"cell": cell,
\t\t\t\t"layer": "platform_surface",
\t\t\t\t"kind": "platform_surface",
\t\t\t\t"depth_key": get_iso_floor_depth_key(cell),
\t\t\t\t"sub_order": ISO_DRAW_SUB_ORDER_PLATFORM_SURFACE,
\t\t\t\t"payload": {"platform_data": platform_data}
\t\t\t})''', '''\t\t\tplatform_entries.append(IsoDrawEntryContractRef.make_entry(
\t\t\t\tcell,
\t\t\t\t"platform_surface",
\t\t\t\t"platform_surface",
\t\t\t\tget_iso_floor_depth_key(cell),
\t\t\t\tISO_DRAW_SUB_ORDER_PLATFORM_SURFACE,
\t\t\t\t{"platform_data": platform_data}
\t\t\t))'''),
('''\t\t\tdraw_entries.append({
\t\t\t\t"cell": cable_cell,
\t\t\t\t"layer": "cable",
\t\t\t\t"layer_bias": ISO_LAYER_BIAS_CABLE - 0.02,
\t\t\t\t"kind": "cable_bridge",
\t\t\t\t"depth_key": minf(get_iso_floor_depth_key(object_cell), get_iso_floor_depth_key(cable_cell)),
\t\t\t\t"sub_order": -0.5,
\t\t\t\t"payload": payload
\t\t\t})''', '''\t\t\tdraw_entries.append(IsoDrawEntryContractRef.make_entry(
\t\t\t\tcable_cell,
\t\t\t\t"cable",
\t\t\t\t"cable_bridge",
\t\t\t\tminf(get_iso_floor_depth_key(object_cell), get_iso_floor_depth_key(cable_cell)),
\t\t\t\t-0.5,
\t\t\t\tpayload,
\t\t\t\tISO_LAYER_BIAS_CABLE - 0.02
\t\t\t))'''),
]
for old, new in replacements:
    assert old in source
    source = source.replace(old, new, 1)

path.write_text(source, encoding="utf-8")
print("Applied RoomVisualRenderer draw-entry extraction")

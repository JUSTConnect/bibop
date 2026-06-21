#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OBJECT = ROOT / "scripts/visual/renderer/object_renderer.gd"
COORD = ROOT / "scripts/field/room_visual_renderer.gd"
TEST = ROOT / "tools/ci/check_object_renderer_contract.gd"
BOUNDARY = ROOT / "tools/check_room_visual_renderer_component_boundary.py"

object_src = OBJECT.read_text(encoding="utf-8")
if 'iso_draw_entry_contract.gd' not in object_src:
    object_src = object_src.replace(
        'const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")\n',
        'const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")\nconst IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")\n',
    )
entry_block = '''\n\nstatic func get_sub_order(layer_name: String, profile_key: String) -> float:\n\tif layer_name == "wall_mounted":\n\t\treturn IsoDrawEntryContractRef.SUB_ORDER_WALL_MOUNTED\n\tif layer_name == "cable":\n\t\treturn IsoDrawEntryContractRef.SUB_ORDER_CABLE\n\tif layer_name == "terminal":\n\t\treturn IsoDrawEntryContractRef.SUB_ORDER_TERMINAL\n\tif profile_key.contains("door") or profile_key.contains("gate"):\n\t\treturn IsoDrawEntryContractRef.SUB_ORDER_DOOR\n\treturn IsoDrawEntryContractRef.SUB_ORDER_ITEM\n\nstatic func get_wall_mounted_render_layer(object_data: Dictionary, is_routing_utility: bool = false) -> int:\n\tif object_data.has("wall_render_layer"):\n\t\treturn int(object_data.get("wall_render_layer", 20))\n\tvar object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()\n\tvar prefab_id: String = str(object_data.get("map_constructor_prefab_id", object_data.get("prefab_id", ""))).strip_edges().to_lower()\n\tvar visual_family: String = str(object_data.get("visual_family", object_data.get("visual_asset_family", ""))).strip_edges().to_lower()\n\tvar routing_kind: String = str(object_data.get("routing_kind", "")).strip_edges().to_lower()\n\tif object_type.contains("cable") or prefab_id.contains("cable") or visual_family.contains("cable") or routing_kind.contains("cable"):\n\t\treturn 10\n\tif prefab_id in ["external_air_duct", "external_water_pipe"] or object_type in ["external_air_duct", "external_water_pipe"]:\n\t\treturn 10\n\tif is_routing_utility:\n\t\treturn 10\n\treturn 20\n\nstatic func get_entry_kind(layer_name: String, profile_key: String) -> String:\n\tif layer_name == "wall_mounted":\n\t\treturn "wall_mounted"\n\tif layer_name == "cable":\n\t\treturn "cable"\n\tif profile_key.contains("door") or profile_key.contains("gate"):\n\t\treturn "door"\n\treturn "object"\n\nstatic func get_layer_bias(layer_name: String) -> float:\n\tif layer_name == "wall_mounted":\n\t\treturn IsoDrawEntryContractRef.LAYER_BIAS_WALL_MOUNTED\n\tif layer_name == "cable":\n\t\treturn IsoDrawEntryContractRef.LAYER_BIAS_CABLE\n\tif layer_name == "terminal":\n\t\treturn IsoDrawEntryContractRef.LAYER_BIAS_TERMINAL\n\treturn IsoDrawEntryContractRef.LAYER_BIAS_ITEM\n\nstatic func make_draw_entry(cell: Vector2i, layer_name: String, object_index: float, payload: Dictionary, depth_key: float, is_routing_utility: bool = false) -> Dictionary:\n\tvar profile_key: String = str(payload.get("profile_key", ""))\n\tvar stable_order_step: float = 0.00001 if layer_name == "wall_mounted" else 0.01\n\tvar sub_order: float = get_sub_order(layer_name, profile_key) + object_index * stable_order_step\n\tif layer_name == "wall_mounted":\n\t\tsub_order += float(get_wall_mounted_render_layer(Dictionary(payload.get("object_data", {})), is_routing_utility)) * 0.001\n\treturn IsoDrawEntryContractRef.make_entry(\n\t\tcell,\n\t\tlayer_name,\n\t\tget_entry_kind(layer_name, profile_key),\n\t\tdepth_key,\n\t\tsub_order,\n\t\tpayload,\n\t\tget_layer_bias(layer_name) + object_index * 0.01\n\t)\n'''
if 'static func make_draw_entry(' not in object_src:
    object_src = object_src.rstrip() + entry_block + '\n'
OBJECT.write_text(object_src, encoding="utf-8")

coord = COORD.read_text(encoding="utf-8")

def replace_func(name: str, body: str) -> None:
    global coord
    pattern = re.compile(rf'(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)')
    match = pattern.search(coord)
    if not match:
        raise RuntimeError(f"missing coordinator function {name}")
    coord = coord[:match.start()] + body.rstrip() + '\n\n' + coord[match.end():]

replace_func('get_iso_object_sub_order', '''func get_iso_object_sub_order(layer_name: String, profile_key: String) -> float:\n\treturn ObjectRendererRef.get_sub_order(layer_name, profile_key)''')
replace_func('get_wall_mounted_render_layer', '''func get_wall_mounted_render_layer(object_data: Dictionary) -> int:\n\treturn ObjectRendererRef.get_wall_mounted_render_layer(object_data, is_wall_routing_utility_object(object_data))''')
replace_func('make_iso_object_draw_entry', '''func make_iso_object_draw_entry(cell: Vector2i, layer_name: String, _layer_bias: float, object_index: float, payload: Dictionary) -> Dictionary:\n\treturn ObjectRendererRef.make_draw_entry(\n\t\tcell,\n\t\tlayer_name,\n\t\tobject_index,\n\t\tpayload,\n\t\tget_iso_object_depth_key_for_payload(payload),\n\t\tis_wall_routing_utility_object(Dictionary(payload.get("object_data", {})))\n\t)''')
COORD.write_text(coord, encoding="utf-8")

test = TEST.read_text(encoding="utf-8")
if '_check_entry_policy()' not in test:
    test = test.replace('\t_check_asset_policy()\n', '\t_check_asset_policy()\n\t_check_entry_policy()\n')
    insertion = '''\nfunc _check_entry_policy() -> void:\n\t_expect(ObjectRendererRef.get_sub_order("wall_mounted", "terminal") > ObjectRendererRef.get_sub_order("item", "generic_object"), "wall-mounted sub-order changed")\n\t_expect(ObjectRendererRef.get_wall_mounted_render_layer({"object_type": "external_air_duct"}) == 10, "routing utility wall layer changed")\n\t_expect(ObjectRendererRef.get_entry_kind("item", "door") == "door", "door entry kind changed")\n\tvar payload: Dictionary = {"profile_key": "terminal", "object_data": {"object_type": "terminal"}}\n\tvar entry: Dictionary = ObjectRendererRef.make_draw_entry(Vector2i(2, 3), "terminal", 0.0, payload, 42.0)\n\t_expect(str(entry.get("layer", "")) == "terminal", "object entry layer changed")\n\t_expect(str(entry.get("kind", "")) == "object", "terminal entry kind changed")\n\t_expect(is_equal_approx(float(entry.get("depth_key", 0.0)), 42.0), "object entry depth changed")\n'''
    test = test.replace('\nfunc _expect(condition: bool, message: String) -> void:', insertion + '\nfunc _expect(condition: bool, message: String) -> void:')
TEST.write_text(test, encoding="utf-8")

boundary = BOUNDARY.read_text(encoding="utf-8")
for name, delegate in {
    'get_iso_object_sub_order': 'ObjectRendererRef.get_sub_order',
    'get_wall_mounted_render_layer': 'ObjectRendererRef.get_wall_mounted_render_layer',
    'make_iso_object_draw_entry': 'ObjectRendererRef.make_draw_entry',
}.items():
    marker = 'for name, delegate in wall_delegates.items():'
    if delegate not in boundary:
        addition = f'\nif "{delegate}" not in function_body(renderer, "{name}"):\n    errors.append("RoomVisualRenderer {name} must delegate to ObjectRenderer")\n'
        boundary = boundary.replace(marker, addition + '\n' + marker)
if 'static func make_draw_entry' not in boundary:
    token_marker = '    "static func get_asset_key_for_object_data",\n'
    boundary = boundary.replace(token_marker, token_marker + '    "static func make_draw_entry",\n')
BOUNDARY.write_text(boundary, encoding="utf-8")
print("Object entry policy extraction applied")

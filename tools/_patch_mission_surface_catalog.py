from pathlib import Path
import re
p=Path(__file__).resolve().parents[1] / 'scripts/game/mission_manager.gd'
s=p.read_text()

needle='const WorldStateStoreRef = preload("res://scripts/world/world_state_store.gd")\n'
add='''const SurfaceMaterialCatalogRef = preload("res://scripts/world/surface_material_catalog.gd")
const WallHeightCatalogRef = preload("res://scripts/world/wall_height_catalog.gd")
const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
'''
assert needle in s
s=s.replace(needle,needle+add,1)
a=s.index('const ISO_PLACEHOLDER_ASSET_PATHS: Dictionary = {')
b=s.index('var world_state_store:',a)
s=s[:a]+s[b:]

def replace_func(src,name,new):
    m=re.search(rf'(?m)^func {re.escape(name)}\s*\(',src)
    if not m: raise RuntimeError('missing '+name)
    n=re.search(r'(?m)^func [A-Za-z0-9_]+\s*\(',src[m.end():])
    end=m.end()+n.start() if n else len(src)
    return src[:m.start()]+new.rstrip()+"\n\n"+src[end:]

repls={
'normalize_map_constructor_wall_material_id':'''func normalize_map_constructor_wall_material_id(material_id: String) -> String:
\treturn SurfaceMaterialCatalogRef.normalize_wall_material_id(material_id)''',
'_is_known_map_constructor_wall_material_id':'''func _is_known_map_constructor_wall_material_id(material_id: String) -> bool:
\treturn SurfaceMaterialCatalogRef.is_known_wall_material_id(material_id)''',
'get_map_constructor_floor_material_catalog':'''func get_map_constructor_floor_material_catalog() -> Dictionary:
\treturn VisualAssetCatalogRef.decorate_surface_material_catalog(SurfaceMaterialCatalogRef.get_floor_catalog(), "floor")''',
'_is_known_map_constructor_floor_material_id':'''func _is_known_map_constructor_floor_material_id(material_id: String) -> bool:
\treturn SurfaceMaterialCatalogRef.is_known_floor_material_id(material_id)''',
'get_map_constructor_wall_height_catalog':'''func get_map_constructor_wall_height_catalog() -> Dictionary:
\treturn WallHeightCatalogRef.get_wall_catalog()''',
'normalize_map_constructor_wall_height':'''func normalize_map_constructor_wall_height(value: String) -> String:
\treturn WallHeightCatalogRef.normalize_wall_height(value, "")''',
'normalize_floor_height_level':'''func normalize_floor_height_level(value: String) -> String:
\treturn WallHeightCatalogRef.normalize_floor_height(value, "default")''',
'get_map_constructor_floor_height_catalog':'''func get_map_constructor_floor_height_catalog() -> Dictionary:
\treturn WallHeightCatalogRef.get_floor_catalog()''',
'get_map_constructor_wall_material_catalog':'''func get_map_constructor_wall_material_catalog() -> Dictionary:
\treturn VisualAssetCatalogRef.decorate_surface_material_catalog(SurfaceMaterialCatalogRef.get_wall_catalog(), "wall")''',
'normalize_visual_texture_asset_id':'''func normalize_visual_texture_asset_id(asset_id: String) -> String:
\treturn VisualAssetCatalogRef.resolve_legacy_mission_asset_id(asset_id)''',
'normalize_visual_texture_asset_id_for_context':'''func normalize_visual_texture_asset_id_for_context(asset_id: String, asset_context: String) -> String:
\treturn VisualAssetCatalogRef.resolve_legacy_mission_asset_id(asset_id, asset_context)''',
}
for name,new in repls.items(): s=replace_func(s,name,new)
s=s.replace('var alias_ids: Array = VISUAL_TEXTURE_ASSET_ALIASES.keys()', 'var alias_ids: Array = VisualAssetCatalogRef.get_legacy_mission_visual_texture_aliases().keys()')

new_floor_state='''func _get_map_constructor_floor_visual_state_for_material_id(material_id: String) -> Dictionary:
\tvar material := SurfaceMaterialCatalogRef.normalize_floor_material_id(material_id, "concrete")
\tvar family: String = GridManager.FLOOR_FAMILY_METAL if material in ["steel", "titan"] else GridManager.FLOOR_FAMILY_CONCRETE
\treturn {"family": family, "wear": GridManager.FLOOR_WEAR_NONE, "base_variant": -1, "overlay_variant": -1, "mirror_h": false, "mirror_v": false}'''
s=replace_func(s,'_get_map_constructor_floor_visual_state_for_material_id',new_floor_state)
s=s.replace('var normalized_material_id: String = material_id.to_lower().strip_edges()\n\tif not _is_known_map_constructor_floor_material_id(normalized_material_id):', 'var normalized_material_id: String = SurfaceMaterialCatalogRef.normalize_floor_material_id(material_id, "")\n\tif normalized_material_id.is_empty() or not _is_known_map_constructor_floor_material_id(material_id):',1)
s=s.replace('normalized_material_id in ["breachable_concrete", "breachable_brick"]', 'SurfaceMaterialCatalogRef.is_breachable_wall_material(normalized_material_id)')
s=s.replace('existing_material_id in ["breachable_concrete", "breachable_brick"]', 'SurfaceMaterialCatalogRef.is_breachable_wall_material(existing_material_id)')
s=s.replace('not (material_id in ["breachable_concrete", "breachable_brick"])', 'not SurfaceMaterialCatalogRef.is_breachable_wall_material(material_id)')
s=s.replace('material_id in ["breachable_concrete", "breachable_brick"]', 'SurfaceMaterialCatalogRef.is_breachable_wall_material(material_id)')

insert_before='func get_map_constructor_wall_material_overrides() -> Dictionary:\n'
helper='''func normalize_map_constructor_surface_override_snapshot(snapshot: Dictionary) -> Dictionary:
\tvar result := snapshot.duplicate(true)
\tvar wall_rows := Dictionary(result.get("wall_material_overrides", {})).duplicate(true)
\tfor key_variant in wall_rows.keys():
\t\tvar key := str(key_variant)
\t\tvar row := Dictionary(wall_rows.get(key, {})).duplicate(true)
\t\tvar raw_material := str(row.get("material_id", ""))
\t\tif not raw_material.is_empty():
\t\t\tvar canonical_wall := SurfaceMaterialCatalogRef.normalize_wall_material_id(raw_material)
\t\t\tif SurfaceMaterialCatalogRef.is_known_wall_material_id(canonical_wall):
\t\t\t\trow["material_id"] = canonical_wall
\t\tvar raw_height := str(row.get("wall_height", row.get("wall_visual_height", "")))
\t\tif WallHeightCatalogRef.is_known_wall_height(raw_height):
\t\t\tvar canonical_height := WallHeightCatalogRef.normalize_wall_height(raw_height, "")
\t\t\tif canonical_height.is_empty():
\t\t\t\trow.erase("wall_height")
\t\t\t\trow.erase("wall_visual_height")
\t\t\telse:
\t\t\t\trow["wall_height"] = canonical_height
\t\t\t\trow.erase("wall_visual_height")
\t\twall_rows[key] = row
\tresult["wall_material_overrides"] = wall_rows
\tvar floor_rows := Dictionary(result.get("floor_material_overrides", {})).duplicate(true)
\tfor key_variant in floor_rows.keys():
\t\tvar key := str(key_variant)
\t\tvar row := Dictionary(floor_rows.get(key, {})).duplicate(true)
\t\tvar canonical_floor := SurfaceMaterialCatalogRef.normalize_floor_material_id(str(row.get("material_id", "")), "")
\t\tif not canonical_floor.is_empty():
\t\t\trow["material_id"] = canonical_floor
\t\trow["floor_height"] = WallHeightCatalogRef.normalize_floor_height(str(row.get("floor_height", row.get("floor_visual_height", row.get("ground_height", "default")))), "default")
\t\trow.erase("floor_visual_height")
\t\trow.erase("ground_height")
\t\tfloor_rows[key] = row
\tresult["floor_material_overrides"] = floor_rows
\treturn result

'''
assert insert_before in s
s=s.replace(insert_before,helper+insert_before,1)
for forbidden in ['const ISO_PLACEHOLDER_ASSET_PATHS','const FLOOR_TEXTURE_ASSET_ALIASES','const WALL_TEXTURE_ASSET_ALIASES','const OBJECT_TEXTURE_ASSET_ALIASES','const VISUAL_TEXTURE_ASSET_ALIASES']:
    assert forbidden not in s, forbidden
p.write_text(s)
print('patched mission',len(s.splitlines()))

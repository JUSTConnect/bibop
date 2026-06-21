from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]

# Renderer delegates canonical domain normalization and renderer-only asset mapping.
p=root/'scripts/field/room_visual_renderer.gd'; s=p.read_text()
needle='const VisualAssetCatalogScript = preload("res://scripts/visual/visual_asset_catalog.gd")\n'
add='''const SurfaceMaterialCatalogRef = preload("res://scripts/world/surface_material_catalog.gd")
const WallHeightCatalogRef = preload("res://scripts/world/wall_height_catalog.gd")
'''
assert needle in s; s=s.replace(needle,needle+add,1)
s=s.replace('const ISO_WALL_HEIGHT_LEVELS: Array[String] = ["low", "halflow", "mid", "halfmid", "tall"]','const ISO_WALL_HEIGHT_LEVELS: Array[String] = WallHeightCatalogRef.WALL_HEIGHT_LEVELS')

def repl(src,name,new):
 m=re.search(rf'(?m)^func {re.escape(name)}\s*\(',src); assert m,name
 n=re.search(r'(?m)^func [A-Za-z0-9_]+\s*\(',src[m.end():]); end=m.end()+n.start() if n else len(src)
 return src[:m.start()]+new.rstrip()+"\n\n"+src[end:]

for name,new in {
'normalize_floor_material_key':'''func normalize_floor_material_key(material_key: String) -> String:
\treturn SurfaceMaterialCatalogRef.normalize_floor_material_id(material_key, "concrete")''',
'normalize_floor_height_level':'''func normalize_floor_height_level(value: String) -> String:
\treturn WallHeightCatalogRef.normalize_floor_height(value, "")''',
'normalize_wall_material_asset_base_key':'''func normalize_wall_material_asset_base_key(profile_key: String) -> String:
\treturn VisualAssetCatalogScript.resolve_wall_material_base_asset_key(profile_key)''',
'normalize_wall_height_level':'''func normalize_wall_height_level(value: String) -> String:
\treturn WallHeightCatalogRef.normalize_wall_height(value, "")''',
'normalize_wall_height_level_for_material':'''func normalize_wall_height_level_for_material(base_key: String, height_level: String) -> String:
\tvar normalized_height := WallHeightCatalogRef.normalize_wall_height(height_level, "")
\treturn VisualAssetCatalogScript.normalize_wall_height_for_asset_base(base_key, normalized_height)''',
'get_wall_asset_key_for_material_and_height':'''func get_wall_asset_key_for_material_and_height(material_asset_key: String, height_level: String) -> String:
\tvar normalized_height := WallHeightCatalogRef.normalize_wall_height(height_level, "")
\treturn VisualAssetCatalogScript.resolve_wall_asset_key_for_material_and_height(material_asset_key, normalized_height)''',
}.items(): s=repl(s,name,new)
p.write_text(s)
print('renderer',len(s.splitlines()))

# MapConstructorService restores normalized authoring state.
p=root/'scripts/game/map_constructor_service.gd'; s=p.read_text()
old='manager._map_constructor_wall_material_overrides = Dictionary(snapshot.get("wall_material_overrides", {})).duplicate(true)'
new='''var normalized_surface_snapshot: Dictionary = manager.normalize_map_constructor_surface_override_snapshot({"wall_material_overrides": snapshot.get("wall_material_overrides", {})})
\tmanager._map_constructor_wall_material_overrides = Dictionary(normalized_surface_snapshot.get("wall_material_overrides", {})).duplicate(true)'''
assert old in s;s=s.replace(old,new,1);p.write_text(s)

# Preset application normalizes legacy surface ids at load boundary.
p=root/'scripts/game/map_constructor_preset_service.gd'; s=p.read_text()
old='''\tvar applied_fields: Array[String] = []
\tfor field_name in SNAPSHOT_FIELDS:
\t\tif not snapshot.has(field_name):
\t\t\tcontinue
\t\towner.set(field_name, _duplicate_if_possible(snapshot.get(field_name)))
\t\tapplied_fields.append(field_name)'''
new='''\tvar effective_snapshot: Dictionary = snapshot.duplicate(true)
\tif owner.has_method("normalize_map_constructor_surface_override_snapshot"):
\t\tvar normalized_surface: Dictionary = owner.call("normalize_map_constructor_surface_override_snapshot", {
\t\t\t"wall_material_overrides": effective_snapshot.get("_map_constructor_wall_material_overrides", {}),
\t\t\t"floor_material_overrides": effective_snapshot.get("_map_constructor_floor_material_overrides", {})
\t\t})
\t\teffective_snapshot["_map_constructor_wall_material_overrides"] = Dictionary(normalized_surface.get("wall_material_overrides", {})).duplicate(true)
\t\teffective_snapshot["_map_constructor_floor_material_overrides"] = Dictionary(normalized_surface.get("floor_material_overrides", {})).duplicate(true)
\tvar applied_fields: Array[String] = []
\tfor field_name in SNAPSHOT_FIELDS:
\t\tif not effective_snapshot.has(field_name):
\t\t\tcontinue
\t\towner.set(field_name, _duplicate_if_possible(effective_snapshot.get(field_name)))
\t\tapplied_fields.append(field_name)'''
assert old in s;s=s.replace(old,new,1);p.write_text(s)
print('services patched')

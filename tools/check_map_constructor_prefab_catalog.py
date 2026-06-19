#!/usr/bin/env python3
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
mission = (root / 'scripts/game/mission_manager.gd').read_text()
catalog_path = root / 'scripts/game/map_constructor_prefab_catalog.gd'
world_path = root / 'scripts/world/world_object_catalog.gd'
if not catalog_path.exists():
    raise SystemExit('missing scripts/game/map_constructor_prefab_catalog.gd')
catalog = catalog_path.read_text()
world = world_path.read_text()
checks = []
checks.append(('MissionManager preloads presentation catalog', 'MapConstructorPrefabCatalogRef' in mission))
checks.append(('MissionManager metadata delegates to catalog', 'MapConstructorPrefabCatalogRef.get_prefab_presentation' in mission and 'MapConstructorPrefabCatalogRef.normalize_presentation_row' in mission))
legacy_body = re.search(r'func _get_map_constructor_prefab_metadata_catalog\(\).*?(?=\nfunc )', mission, re.S)
checks.append(('MissionManager does not own large presentation dictionary', legacy_body is not None and legacy_body.group(0).count('"display_name"') == 0))
checks.append(('MissionManager does not call private catalog implementation', 'MapConstructorPrefabCatalogRef._get_' not in mission and 'MapConstructorPrefabCatalogRef._' not in legacy_body.group(0)))
checks.append(('presentation catalog owns prefab order', 'const PREFAB_ORDER' in catalog and 'get_prefab_order' in catalog))
checks.append(('presentation catalog owns category order', 'const CATEGORY_ORDER' in catalog and 'get_category_order' in catalog and 'const CATEGORY_BY_PREFAB' in catalog))
forbidden_world_tokens = ['CONSTRUCTOR_PALETTE_PREFAB_ORDER', 'CONSTRUCTOR_PALETTE_GROUP_ORDER', 'CONSTRUCTOR_PALETTE_GROUP_BY_PREFAB', 'get_constructor_palette_rows', 'get_constructor_palette_group_for_prefab']
checks.append(('WorldObjectCatalog no longer owns constructor presentation inventories', not any(token in world for token in forbidden_world_tokens)))
forbidden_inventory = ['WALL_MOUNTED_PREFABS', 'FLOOR_PREFABS', 'FLOOR_AND_WALL_PREFABS', 'PLACEMENT_DEFAULTS']
checks.append(('presentation catalog has no placement inventory tables', not any(token in catalog for token in forbidden_inventory)))
presentation_body = re.search(r'static func _get_presentation_catalog\(\).*?\n\treturn metadata', catalog, re.S)
forbidden_keys = ['"placement_mode"', '"placement_surfaces"', '"default_placement_surface"', '"supports_floor"', '"supports_wall"', '"floor_only"', '"wall_only"', '"requires_floor"', '"requires_wall"', '"requires_floor_anchor"', '"requires_floor_anchor_when_wall_mounted"', '"changes_passability"', '"blocks_movement"']
checks.append(('presentation rows do not hardcode placement contract keys', presentation_body is not None and not any(key in presentation_body.group(0) for key in forbidden_keys)))
checks.append(('presentation rows do not hardcode gameplay default_state', presentation_body is not None and not re.search(r'"default_state"\s*:\s*\{\s*[^}]', presentation_body.group(0))))
lookup_body = re.search(r'static func get_prefab_presentation\(.*?\nstatic func normalize_presentation_row', catalog, re.S)
checks.append(('catalog includes canonical alias fallback logic', lookup_body is not None and 'canonical_id' in lookup_body.group(0) and 'catalog.has(canonical_id)' in lookup_body.group(0)))
checks.append(('catalog preserves requested alias identifiers', lookup_body is not None and 'requested_prefab_id' in lookup_body.group(0) and 'base_row["prefab_id"] = requested_id' in lookup_body.group(0)))
failed = [name for name, ok in checks if not ok]
if failed:
    for name in failed:
        print('FAIL:', name)
    raise SystemExit(1)
for name, _ in checks:
    print('OK:', name)

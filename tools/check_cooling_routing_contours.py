#!/usr/bin/env python3
"""Static smoke checks for cooling routing contour metadata and editor hooks."""
from pathlib import Path
import re, sys
issues=[]
catalog=Path('scripts/world/world_object_catalog.gd').read_text()
ui=Path('scripts/ui/map_constructor/map_constructor_property_controls.gd').read_text()+Path('scripts/ui/map_constructor/map_constructor_inspector.gd').read_text()
service=Path('scripts/game/cooling/cooling_routing_contour_service.gd').read_text()
validation=Path('scripts/game/map_constructor_validation_service.gd').read_text()
for oid, kind in [('external_air_duct','air_duct'),('external_water_pipe','water_pipe')]:
    m=re.search(rf'"{oid}"\s*:\s*\{{(?P<body>.*?)\n\t"(?:external_air_duct|module_external)"', catalog, re.S)
    if oid == 'external_air_duct':
        m=re.search(rf'"{oid}"\s*:\s*\{{(?P<body>.*?)\n\t"module_external"', catalog, re.S)
    if not m:
        issues.append(f'missing {oid}'); continue
    body=m.group('body')
    for token in [f'"routing_kind":"{kind}"', f'"cooling_system_type":"{kind}"', '"cooling_contour_id":""', '"cooling_contour_mode":"auto"', '"cooling_system_tab":true']:
        if token not in body: issues.append(f'{oid} missing {token}')
    schema=re.search(r'"property_schema"\s*:\s*\[(.*?)\]', body, re.S)
    if not schema or not schema.group(1).lstrip().startswith('{"field":"route_mode"'):
        issues.append(f'{oid} route_mode not first')
    for field in ['route_mode','cooling_contour_mode','cooling_contour_id','wall_side_1','wall_side_2']:
        if f'"field":"{field}"' not in body or '"tab":"Cooling System"' not in body:
            issues.append(f'{oid} missing Cooling System field {field}')
    if '"visible_if":{"field":"route_mode","equals":"inner"}' not in body:
        issues.append(f'{oid} missing wall_side visible_if')
for token in ['add_archetype_schema_properties_for_tab', 'row_tab', 'TabContainer', 'Cooling System', 'rendered_cooling_schema']:
    if token not in ui: issues.append(f'missing inspector tab hook {token}')
inspector = Path('scripts/ui/map_constructor/map_constructor_inspector.gd').read_text()
for token in [
    'static func _is_cooling_routing_object',
    'routing_kind", data.get("cooling_system_type"',
    'object_type in ["external_air_duct", "external_water_pipe"]',
    'if is_cooling_routing_object:',
    'elif rendered_cooling_schema:',
    '_render_cooling_system_controls',
    '"Route mode"',
    '"route_mode": "inner", "wall_routing_mode": "inner"',
    '"route_mode": "outer", "wall_routing_mode": "outer"',
    '"Wall side 1"',
    '"Wall side 2"',
    '"Contour mode"',
    '"Manual contour id"',
    '"Computed contour id"',
    '"Contour members"',
    '"Contour warnings"',
    'CoolingRoutingContourServiceRef.build_contours',
    'CoolingRoutingContourServiceRef.get_object_contour_id',
    'CoolingRoutingContourServiceRef.collect_contour_warnings',
    'and not is_cooling_routing_object',
]:
    if token not in inspector:
        issues.append(f'missing robust cooling inspector token {token}')
if inspector.find('"Route mode"') > inspector.find('"Wall side 1"'):
    issues.append('route mode is not rendered before wall_side_1')
if 'data.get("route_mode", data.get("wall_routing_mode", data.get("routing_mode", data.get("routing_style", "outer"))))' not in inspector:
    issues.append('route mode normalization does not read route_mode/wall_routing_mode/routing_mode/routing_style')
if '"Manual contour id"' not in inspector or 'if _normalize_cooling_contour_mode(data) == "manual":' not in inspector:
    issues.append('manual contour id is not conditional on manual mode')
if '"Wall side 1"' not in inspector or 'if _normalize_wall_routing_mode_value(data) == "inner":' not in inspector:
    issues.append('wall_side rows are not conditional on inner mode')
for token in ['class_name CoolingRoutingContourService', 'build_contours', 'collect_contour_warnings', 'get_object_contour_id', 'Manual contour id contains disconnected segments.', 'Manual contour id cannot mix air duct and water pipe.', '_physically_connected']:
    if token not in service: issues.append(f'missing service token {token}')
if 'CoolingRoutingContourServiceRef.collect_contour_warnings' not in validation:
    issues.append('validation does not collect contour warnings')

# Top-level Cooling System constructor category and selected-cell routing checks.
game_ui = Path('scripts/ui/game_ui.gd').read_text()
map_service = Path('scripts/game/map_constructor_service.gd').read_text()
mission = Path('scripts/game/mission_manager.gd').read_text()
object_palette = Path('scripts/ui/map_constructor/map_constructor_object_palette.gd').read_text()
for text, source_name in [(game_ui, 'GameUI categories'), (map_service, 'inspection model')]:
    if 'Cooling System' not in text:
        issues.append(f'{source_name} missing top-level Cooling System tab/category')
for oid in ['external_air_duct', 'external_water_pipe']:
    idx = mission.find(f'"{oid}": {{"display_name":')
    if idx < 0:
        issues.append(f'missing {oid} constructor metadata')
        continue
    body = mission[idx:idx + 1800]
    for token in ['"category":"Cooling System"', '"constructor_group":"cooling_system"', '"constructor_tab":"cooling_system"', '"placement_mode":"wall_mounted"', '"route_mode":"inner"', '"wall_routing_mode":"inner"']:
        if token not in body:
            issues.append(f'{oid} constructor metadata missing {token}')
for token in ['object_type in ["external_air_duct", "external_water_pipe"]', 'routing_kind in ["air_duct", "water_pipe"]', 'cooling_system_type in ["air_duct", "water_pipe"]', 'return "cooling_system"']:
    if token not in inspector or token not in map_service:
        issues.append(f'missing cooling selected-cell routing token {token}')
if 'parent.add_child(cooling_configurable)' not in inspector or 'elif rendered_cooling_schema:' not in inspector:
    issues.append('cooling routing objects still appear to use the nested Object/Cooling System TabContainer path')
if 'return "Cooling System"' not in object_palette:
    issues.append('palette grouping does not expose Cooling System group')

if issues:
    print('Cooling routing contour checks failed:')
    for issue in issues: print(' -', issue)
    sys.exit(1)
print('Cooling routing contour checks passed.')

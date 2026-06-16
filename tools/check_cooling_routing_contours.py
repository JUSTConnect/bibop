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
for token in ['class_name CoolingRoutingContourService', 'build_contours', 'collect_contour_warnings', 'get_object_contour_id', 'Manual contour id contains disconnected segments.', 'Manual contour id cannot mix air duct and water pipe.', '_physically_connected']:
    if token not in service: issues.append(f'missing service token {token}')
if 'CoolingRoutingContourServiceRef.collect_contour_warnings' not in validation:
    issues.append('validation does not collect contour warnings')
if issues:
    print('Cooling routing contour checks failed:')
    for issue in issues: print(' -', issue)
    sys.exit(1)
print('Cooling routing contour checks passed.')

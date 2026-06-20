#!/usr/bin/env python3
from pathlib import Path
import re, sys
errors=[]
service=Path('scripts/game/runtime_readiness_service.gd')
bridge=Path('scripts/ui/map_constructor/map_constructor_ui_bridge.gd')
game=Path('scripts/ui/game_ui.gd')
controller=Path('scripts/bipob/bipob_controller.gd')
workflow=Path('.github/workflows/godot-parser-gate.yml')
if not service.exists(): errors.append('RuntimeReadinessService is missing')
text=service.read_text() if service.exists() else ''
for forbidden in ['Control','Label','CanvasItem','get_node','$','Node2D','CanvasLayer','PanelContainer','Timer']:
    if re.search(r'\b'+re.escape(forbidden)+r'\b', text) or forbidden in ['get_node','$'] and forbidden in text:
        errors.append(f'service contains UI/scene reference {forbidden}')
for code in ['missing_virtual_power','missing_internal_data','missing_external_data_bridge','missing_air_intake','thermal_warning','thermal_critical','damage_warning','damage_critical','constructor_consistency_invalid','overlay_preview_active']:
    if code not in text: errors.append(f'missing service code {code}')
for cat in ['power','data','external','cooling','thermal','damage','consistency','overlay']:
    if f'"{cat}"' not in text: errors.append(f'missing service category {cat}')
b=bridge.read_text()
for forbidden in ['infer_warning_category_from_text','infer_warning_severity_from_text','is_virtual_power_available','is_internal_data_network_available','is_external_data_network_available','has_external_air_intake','get_highest_internal_preview_heat','get_constructor_warning_lines']:
    if forbidden in b: errors.append(f'bridge still contains domain fallback {forbidden}')
g=game.read_text()
m=re.search(r'func _get_constructor_status_badges\(\).*?\nfunc ', g, re.S)
if not m: errors.append('GameUI badges function missing')
else:
    badges=m.group(0)
    for raw in ['is_virtual_power_available','is_internal_data_network_available','is_external_data_network_available','has_external_air_intake','get_highest_internal_preview_heat','get_warning_count']:
        if raw in badges: errors.append(f'GameUI badges recompute {raw}')
if 'func _infer_warning_category_from_text' in g or 'func _infer_warning_severity_from_text' in g:
    errors.append('GameUI text inference wrappers remain')
c=controller.read_text()
for name in ['get_warning_count','get_constructor_readiness_summary_text','get_constructor_readiness_compact_text','get_constructor_warning_summary_text','get_constructor_warning_lines']:
    mm=re.search(r'func '+name+r'\(\).*?(?=\nfunc |\Z)', c, re.S)
    if not mm: continue
    body=mm.group(0)
    if 'RuntimeReadinessServiceRef.evaluate_constructor' not in body and name not in ['get_constructor_warning_summary_text']:
        errors.append(f'{name} does not delegate to RuntimeReadinessService')
if re.search(r'\b_process\s*\(', text) or re.search(r'\bTimer\b', text):
    errors.append('RuntimeReadinessService must not use polling/Timer')
for path in [bridge, game, controller]:
    t=path.read_text()
    for marker in ['RuntimeReadinessServiceRef.evaluate_constructor']:
        for m in re.finditer(marker, t):
            window=t[max(0,m.start()-300):m.end()+300]
            if re.search(r'\b_process\s*\(', window) or re.search(r'\bTimer\b', window):
                errors.append(f'readiness evaluation appears near polling/Timer in {path}')
w=workflow.read_text()
for needed in ['python tools/check_runtime_readiness_service.py','check_runtime_readiness_service.gd']:
    if needed not in w: errors.append(f'workflow missing {needed}')
if errors:
    for e in errors: print('ERROR:', e)
    sys.exit(1)
print('RuntimeReadinessService static audit: OK')

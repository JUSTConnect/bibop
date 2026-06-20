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
    if re.search(r'\b'+re.escape(forbidden)+r'\b', text) or (forbidden in ['get_node','$'] and forbidden in text):
        errors.append(f'service contains UI/scene reference {forbidden}')
for forbidden in ['_text', '_summary_text', '_compact_text', 'contains(', 'split(', 'begins_with(']:
    if forbidden in text:
        errors.append(f'service contains text-derived domain logic marker {forbidden}')
if re.search(r'default_value\s*:\s*bool[^\n=]*=\s*true', text) or '_bool_query' in text:
    errors.append('service appears to use permissive default=true for readiness checks')
for code in ['readiness_source_unavailable','source_contract_incomplete','missing_virtual_power','missing_internal_data','missing_external_data_bridge','missing_air_intake','thermal_warning','thermal_critical','damage_warning','damage_critical','constructor_consistency_invalid','overlay_preview_active']:
    if code not in text: errors.append(f'missing service code {code}')
for cat in ['runtime','power','data','external','cooling','thermal','damage','consistency','overlay']:
    if f'"{cat}"' not in text: errors.append(f'missing service category {cat}')
for status in ['STATUS_NOT_READY', 'STATUS_BLOCKED', 'STATUS_READY_WITH_WARNINGS']:
    if status not in text: errors.append(f'missing status {status}')

b=bridge.read_text()
if 'RuntimeReadinessService' in b or 'evaluate_constructor' in b:
    errors.append('bridge must not directly evaluate RuntimeReadinessService')
for forbidden in ['infer_warning_category_from_text','infer_warning_severity_from_text','is_virtual_power_available','is_internal_data_network_available','is_external_data_network_available','has_external_air_intake','get_highest_internal_preview_heat','get_constructor_warning_lines']:
    if forbidden in b: errors.append(f'bridge still contains domain fallback {forbidden}')
for expected in ['get_constructor_warning_items(readiness_result: Dictionary)','get_constructor_readiness_state(readiness_result: Dictionary)','build_warning_panel(readiness_result: Dictionary)']:
    if expected not in b: errors.append(f'bridge snapshot API missing {expected}')

g=game.read_text()
m=re.search(r'func _get_constructor_status_badges\(\).*?\nfunc ', g, re.S)
if not m: errors.append('GameUI badges function missing')
else:
    badges=m.group(0)
    for raw in ['is_virtual_power_available','is_internal_data_network_available','is_external_data_network_available','has_external_air_intake','get_highest_internal_preview_heat','get_warning_count']:
        if raw in badges: errors.append(f'GameUI badges recompute {raw}')
if 'func _infer_warning_category_from_text' in g or 'func _infer_warning_severity_from_text' in g:
    errors.append('GameUI text inference wrappers remain')
if 'latest_constructor_readiness_result = RuntimeReadinessServiceRef.evaluate_constructor(bipob).duplicate(true)' not in g:
    errors.append('GameUI does not store duplicated readiness snapshot')
for hook in ['func _on_runtime_bipob_status_changed', 'func _ensure_gameplay_runtime_created', 'func _load_bipob_profile', 'func _destroy_gameplay_runtime', 'func _toggle_map_constructor_mode', 'func _refresh_map_constructor_browser']:
    hm=re.search(r'%s\(.*?(?=\nfunc |\Z)' % re.escape(hook), g, re.S)
    if not hm:
        errors.append(f'missing invalidation hook {hook}')
    elif hook == 'func _destroy_gameplay_runtime':
        if 'latest_constructor_readiness_result = {}' not in hm.group(0): errors.append('destroy runtime does not clear readiness cache')
    elif '_refresh_constructor_readiness_result()' not in hm.group(0):
        errors.append(f'{hook} does not refresh readiness cache')

c=controller.read_text()
required_adapters=[
    'get_virtual_power_affected_module_ids','get_internal_data_affected_module_ids','get_external_data_affected_module_ids',
    'get_air_cooling_affected_module_ids','get_thermal_preview_affected_module_ids','get_damage_preview_affected_module_ids',
    'has_overlay_preview_changes','get_overlay_preview_affected_module_ids','get_constructor_consistency_affected_module_ids'
]
for name in required_adapters:
    if f'func {name}(' not in c: errors.append(f'missing production affected-ID adapter {name}')
for name in ['get_warning_count','get_constructor_readiness_summary_text','get_constructor_readiness_compact_text','get_constructor_warning_lines']:
    mm=re.search(r'func '+name+r'\(\).*?(?=\nfunc |\Z)', c, re.S)
    if not mm:
        errors.append(f'{name} missing')
        continue
    body=mm.group(0)
    count=body.count('RuntimeReadinessServiceRef.evaluate_constructor')
    if count != 1:
        errors.append(f'{name} must evaluate service exactly once, found {count}')
if 'func get_constructor_consistency_issue_count() -> int:\n\treturn get_constructor_consistency_issue_lines().size()' not in c:
    errors.append('consistency count must directly count issue lines')

if re.search(r'\b_process\s*\(', text) or re.search(r'\bTimer\b', text):
    errors.append('RuntimeReadinessService must not use polling/Timer')
for path in [bridge, game, controller]:
    t=path.read_text()
    for marker in ['RuntimeReadinessServiceRef.evaluate_constructor']:
        for found in re.finditer(marker, t):
            window=t[max(0,found.start()-300):found.end()+300]
            if re.search(r'\b_process\s*\(', window) or re.search(r'\bTimer\b', window):
                errors.append(f'readiness evaluation appears near polling/Timer in {path}')
w=workflow.read_text()
for needed in ['python tools/check_runtime_readiness_service.py','check_runtime_readiness_service.gd']:
    if needed not in w: errors.append(f'workflow missing {needed}')
if errors:
    for e in errors: print('ERROR:', e)
    sys.exit(1)
print('RuntimeReadinessService static audit: OK')

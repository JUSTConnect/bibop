#!/usr/bin/env python3
from pathlib import Path
import re, sys
ROOT = Path(__file__).resolve().parents[1]
errors=[]
def text(p):
    return (ROOT/p).read_text(encoding='utf-8')
def expect(cond,msg):
    if not cond: errors.append(msg)
project=text('project.godot')
expect('RuntimeHudRepair' not in project,'RuntimeHudRepair autoload remains')
deleted_repair_path = Path('scripts/ui/runtime') / 'runtime_hud_repair_service.gd'
expect(not (ROOT/deleted_repair_path).exists(), str(deleted_repair_path) + ' still exists')
expect('MapConstructorInspectorStructure=' not in project,'MapConstructorInspectorStructure autoload remains')
inspector=text('scripts/ui/map_constructor/map_constructor_inspector_structure_layer.gd')
for token in ['func _process','CHECK_INTERVAL','get_tree(','current_scene']:
    expect(token not in inspector, f'inspector structure contains forbidden {token}')
expect('static func apply_structure' in inspector and 'static func apply_from_ui' in inspector,'inspector structure lacks explicit API')
bridge=text('scripts/ui/runtime/runtime_action_panel_bridge.gd')
pm=re.search(r'func process_feedback[\s\S]*?(?=\nfunc )', bridge)
expect(pm is not None,'RuntimeActionPanelBridge.process_feedback missing')
if pm:
    body=pm.group(0)
    for token in ['refresh_controls(','RuntimeInteractionPresenterRef.refresh','get_target_data(','get_action_view_model(','is_manipulator_blocked(']:
        expect(token not in body, f'process_feedback still performs correctness work: {token}')
expect('RuntimeNotificationsRef.process_runtime_notification_timer(ui, delta)' not in bridge,'notification correctness still depends on bridge frame processing')
game=text('scripts/ui/game_ui.gd')
for cls in ['class InternalIsoPreviewControl','class SelectedModuleMiniPreviewControl','class ConstructorValidationOverlayControl']:
    idx=game.find(cls); nxt=game.find('\nclass ', idx+1)
    if nxt == -1:
        nxt = game.find('\nvar bipob:', idx+1)
    block=game[idx:nxt if nxt!=-1 else len(game)]
    expect('func _process' not in block, f'{cls} still has _process')
    expect('func request_refresh()' in block, f'{cls} lacks request_refresh')
expect('func _initialize_runtime_hud' in game and 'func _teardown_runtime_hud' in game and 'func request_runtime_hud_refresh' in game,'explicit runtime HUD lifecycle hooks missing')
for hook in ['status_changed','world_action_panel_requested','interaction_mode_entered','interaction_mode_exited','profile_changed']:
    expect(hook in game, f'missing explicit invalidation hook {hook}')
processes=re.finditer(r'func _process[^\n]*:\n(?P<body>(?:\t.*\n|\n)*)', game+"\nfunc ")
for m in processes:
    body=m.group('body')
    for token in ['get_target_data','get_action_view_model','RuntimeReadinessService','_apply_runtime_hud_layout','_initialize_runtime_hud','_ensure_runtime_world_actions_panel']:
        expect(token not in body, f'_process invokes forbidden correctness token {token}')
presenter=text('scripts/ui/runtime/runtime_interaction_presenter.gd')
wm=re.search(r'static func refresh_world_actions_panel[\s\S]*?(?=\n\nstatic func )', presenter)
expect(wm is not None,'refresh_world_actions_panel missing')
if wm:
    body=wm.group(0)
    for token in ['_ensure_runtime_world_actions_panel','_build_runtime_world_actions_panel']:
        expect(token not in body, f'world action refresh still rebuilds panel via {token}')
for root,_,files in __import__('os').walk(ROOT):
    for f in files:
        if f.endswith(('.gd','.py','.godot','.yml','.yaml')):
            s=Path(root,f).read_text(encoding='utf-8', errors='ignore')
            
            rel=Path(root,f).relative_to(ROOT)
            if rel != Path('tools/check_event_driven_runtime_hud.py'):
                deleted_name = 'runtime_hud_' + 'repair_service.gd'
                expect(deleted_name not in s, f'deleted repair path referenced in {rel}')
for token in ['REPAIR_INTERVAL','REBUILD_COOLDOWN','CHECK_INTERVAL := 0.35','CHECK_INTERVAL := 0.25']:
    expect(token not in game+bridge+inspector, f'periodic repair/cooldown token introduced: {token}')
workflow=text('.github/workflows/godot-parser-gate.yml')
expect('python tools/check_runtime_readiness_service.py' in workflow,'RuntimeReadinessService static audit not active')
expect('python tools/check_event_driven_runtime_hud.py' in workflow,'event-driven HUD static audit not wired')
expect('check_event_driven_runtime_hud.gd' in workflow,'event-driven HUD behavior gate not wired')
if errors:
    print('Event-driven runtime HUD audit FAILED:')
    for e in errors: print(' -', e)
    sys.exit(1)
print('Event-driven runtime HUD audit OK')

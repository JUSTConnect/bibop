#!/usr/bin/env python3
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / 'scripts/field/grid_manager.gd'
text = path.read_text(encoding='utf-8')

def strip_comments(src: str) -> str:
    out=[]
    for line in src.splitlines():
        in_str=False; quote=''; esc=False; cut=len(line)
        for i,ch in enumerate(line):
            if in_str:
                if esc: esc=False
                elif ch=='\\': esc=True
                elif ch==quote: in_str=False
            elif ch in ('"', "'"):
                in_str=True; quote=ch
            elif ch=='#':
                cut=i; break
        out.append(line[:cut])
    return '\n'.join(out)

code = strip_comments(text)
checks = {
    'legacy _draw': r'(?m)^\s*func\s+_draw\s*\(',
    'draw_rect': r'\bdraw_rect\s*\(',
    'draw_polygon': r'\bdraw_(?:colored_)?polygon\s*\(',
    'draw_circle': r'\bdraw_circle\s*\(',
    'draw_line': r'\bdraw_line\s*\(',
    'draw_texture': r'\bdraw_texture\w*\s*\(',
    'queue_redraw': r'\bqueue_redraw\s*\(',
    'debug_draw_legacy_grid': r'\bdebug_draw_legacy_grid\b',
    'RoomVisualRenderer dependency': r'\b(?:preload|load)\s*\([^\)]*RoomVisualRenderer|\bRoomVisualRenderer\b',
    'Texture2D rendering type': r'\bTexture2D\b',
    'visual asset reference': r'res://assets/visual',
    'TASK TEST fallback function': r'\bget_mission10_layout\s*\(',
    'TASK TEST reset branch': r'(?:if|elif)\s+mission_index\s*==\s*10\b',
}
fail=[]
for name,pat in checks.items():
    if re.search(pat, code):
        fail.append(name)

catalog_path = ROOT / 'scripts/game/mission_content_catalog.gd'
if not catalog_path.exists():
    fail.append('MissionContentCatalog missing')
else:
    catalog = catalog_path.read_text(encoding='utf-8')
    if '"layout_source": "mission_content_catalog"' not in catalog:
        fail.append('TASK TEST catalog layout source missing')
    if 'MissionIdsRef.resolve_task_test_alias' not in catalog:
        fail.append('TASK TEST compatibility alias missing')

manager_path = ROOT / 'scripts/game/mission_manager.gd'
if not manager_path.exists():
    fail.append('MissionManager missing')
else:
    manager = manager_path.read_text(encoding='utf-8')
    if 'func apply_catalog_mission_layout_to_grid' not in manager:
        fail.append('catalog-first layout apply missing')
    if 'grid_manager.call("apply_mission_layout"' not in manager:
        fail.append('catalog layout is not applied through GridManager public API')
    if 'reset_mission_layout(10' in manager or 'get_mission10_layout(' in manager:
        fail.append('MissionManager still calls retired TASK TEST GridManager fallback')

if fail:
    print('GridManager boundary violations:')
    for f in fail: print(f'- {f}')
    sys.exit(1)
print('GridManager rendering and TASK TEST layout boundary OK')

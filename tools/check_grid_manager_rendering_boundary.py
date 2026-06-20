#!/usr/bin/env python3
from pathlib import Path
import re, sys

path = Path('scripts/field/grid_manager.gd')
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
}
fail=[]
for name,pat in checks.items():
    if re.search(pat, code):
        fail.append(name)
if fail:
    print('GridManager rendering boundary violations:')
    for f in fail: print(f'- {f}')
    sys.exit(1)
print('GridManager rendering boundary OK')

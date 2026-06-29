#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
errors=[]
binding=(root/'scripts/world/binding_store.gd')
if not binding.exists(): errors.append('scripts/world/binding_store.gd is missing')
else:
 t=binding.read_text()
 for token in ['class_name BindingStore','func add_binding','func remove_binding','func get_bindings_for_source','func get_snapshot']:
  if token not in t: errors.append(f'missing {token}')
if 'BindingStore' not in (root/'docs/ROADMAP.md').read_text(): errors.append('BindingStore roadmap reference missing')
if errors:
 print('BindingStore gate failed:')
 for e in errors: print('-',e)
 raise SystemExit(1)
print('OK: BindingStore contract holds')

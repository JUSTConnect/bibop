# Local review checklist

These lightweight review aids use only the Python standard library. They run from the repository root, do not invoke Godot CLI, and do not require network access or external packages.

## Run the checks

```bash
python tools/check_map_constructor_sections.py
python tools/check_gdscript_safety_patterns.py
python tools/check_gdscript_safety_patterns.py --check-allowed-files
git diff --check
```

## What the tools check

- `tools/check_map_constructor_sections.py` reads the Map Constructor inspector source and its floor/wall coverage helper. It fails if the expected inspector sections are missing or no longer appear in the expected order from **1. Object Identity** through **8. Wall Coverage**.
- `tools/check_gdscript_safety_patterns.py` scans selected GDScript paths for a small set of known unsafe or generated patterns: `PackedString_safe_ui_array`, appending to a temporary `_safe_ui_array(...)`, and narrowly matched unsafe UI casts such as `Dictionary(row_variant)` or `Array(value)`. It also emits heuristic warnings for likely `mission_manager_runtime.call(...)` calls in inline UI callbacks without a nearby null check and matching `has_method(...)` guard.
- `tools/check_gdscript_safety_patterns.py --check-allowed-files` additionally fails if the current Git changes include files outside the focused PR 19 tooling/documentation allowlist. This optional mode is useful while reviewing this PR, but the base safety scan remains reusable after the PR is merged.

These scripts are review aids, not a replacement for manual code review or runtime testing in Godot when gameplay behavior changes.

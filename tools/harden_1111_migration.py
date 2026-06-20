#!/usr/bin/env python3
from pathlib import Path

path = Path("tools/apply_1111_screen_router.py")
source = path.read_text(encoding="utf-8")

source = source.replace(
    'app_screen_mode = mode_value as AppScreenMode',
    'app_screen_mode = mode_value',
)
source = source.replace(
    '\tif bool(payload.get("start_mission", false)):\n\t\t_on_start_mission_button_pressed()\n\tcall_deferred("_attach_runtime_gameplay_view")',
    '\tif bool(payload.get("start_mission", false)):\n\t\t_on_start_mission_button_pressed()\n\tif screen_router != null:\n\t\tscreen_router.set_active_payload({"start_mission": false, "preserve_profile": true})\n\tcall_deferred("_attach_runtime_gameplay_view")',
)
source = source.replace(
    '\tright_button_panel = null\n\n\nfunc _screen_cleanup_charging',
    '\tright_button_panel = null\n\tmain_box_row = null\n\tleft_panel = null\n\tbox_content_scroll = null\n\tbox_tab_row = null\n\tmission_tab_button = null\n\tmodules_tab_button = null\n\texternal_tab_button = null\n\tinternal_tab_button = null\n\tbox_restart_button = null\n\tbox_return_button = null\n\tbipob_alpha_button = null\n\tbipob_beta_button = null\n\tbipob_juggernaut_button = null\n\tbox_back_button = null\n\tprev_installed_button = null\n\tnext_installed_button = null\n\tprev_box_button = null\n\tnext_box_button = null\n\n\nfunc _screen_cleanup_charging',
)

anchor = "# Top-level back buttons use router history.\ngame = game.replace('Callable(self, \"show_center_screen\")', 'Callable(self, \"_navigate_back_or_center\")')\n"
if anchor not in source:
    raise RuntimeError("main handler insertion anchor missing")
source = source.replace(
    anchor,
    anchor + '''game = replace_once(
    game,
    'func _on_main_settings_pressed() -> void:\n\tshow_placeholder_screen("Settings")\nfunc _on_main_about_pressed() -> void:\n\tshow_placeholder_screen("About")\n',
    'func _on_main_settings_pressed() -> void:\n\tnavigate_to_screen(AppScreenMode.SETTINGS_PLACEHOLDER)\nfunc _on_main_about_pressed() -> void:\n\tnavigate_to_screen(AppScreenMode.ABOUT_PLACEHOLDER)\n',
    "main placeholder modes",
)
''',
    1,
)

source = source.replace(
    'func _on_enter(screen_id: StringName, _screen: Control, _payload: Dictionary, _repeated: bool) -> void:',
    'func _on_enter(_screen: Control, _payload: Dictionary, _repeated: bool, screen_id: StringName) -> void:',
)
source = source.replace(
    'func _on_cleanup(screen_id: StringName, _screen: Control) -> void:',
    'func _on_cleanup(_screen: Control, screen_id: StringName) -> void:',
)

helper_anchor = '''def function_at(source: str, position: int) -> str:
    matches = list(re.finditer(r"^func ([A-Za-z0-9_]+)\\(", source[:position], re.M))
    return matches[-1].group(1) if matches else ""
'''
if helper_anchor not in source:
    raise RuntimeError("static audit helper anchor missing")
source = source.replace(
    helper_anchor,
    helper_anchor + '''

def function_block(source: str, name: str) -> str:
    start = re.search(rf"^func {re.escape(name)}\\(", source, re.M)
    if start is None:
        return ""
    end = source.find("\\nfunc ", start.end())
    return source[start.start(): end if end != -1 else len(source)]
''',
    1,
)

old_public_audit = '''    block_match = re.search(rf"func {public_name}\\([^\\n]*\\)(?: -> [^:\\n]+)?:\\n([\\s\\S]*?)(?=\\nfunc |\\Z)", game)
    expect(block_match is not None, f"missing public navigation wrapper: {public_name}")
    if block_match:
        block = block_match.group(0)
        for forbidden in ["_build_fullscreen_root", "add_child(", "queue_free()", ".visible = true", ".visible = false"]:
            expect(forbidden not in block, f"navigation wrapper {public_name} still mutates screen tree via {forbidden}")
'''
new_public_audit = '''    block = function_block(game, public_name)
    expect(bool(block), f"missing public navigation wrapper: {public_name}")
    if block:
        for forbidden in ["_build_fullscreen_root", "add_child(", "queue_free()", ".visible = true", ".visible = false"]:
            expect(forbidden not in block, f"navigation wrapper {public_name} still mutates screen tree via {forbidden}")
'''
if old_public_audit not in source:
    raise RuntimeError("public wrapper audit block missing")
source = source.replace(old_public_audit, new_public_audit, 1)
source = source.replace(
    'for token in ["register_screen", "func reset", "func replace", "func push", "func back", "resolve_focus_target", "_cleanup_instance"]:',
    'for token in ["register_screen", "func reset", "func replace", "func push", "func back", "set_active_payload", "resolve_focus_target", "_cleanup_instance"]:',
)

path.write_text(source, encoding="utf-8")
print("harden_1111_migration: OK")

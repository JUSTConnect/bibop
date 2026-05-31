# UI split architecture

## Current responsibility map

`scripts/ui/game_ui.gd` is the root UI orchestrator. It creates and connects the HUD root, passes dependencies to helper classes, and coordinates high-level visibility and refresh behavior. Keep section-specific builders and behavior in the focused helper scripts instead of growing `game_ui.gd` again.

The UI is split into two groups:

- `scripts/ui/map_constructor/` contains Map Constructor/editor UI helpers.
- `scripts/ui/runtime/` contains gameplay HUD helpers.

## Map Constructor UI ownership

| Helper | Primary responsibility |
| --- | --- |
| `scripts/ui/map_constructor/map_constructor_ui_safe.gd` | Guarded UI conversion helpers for Variant values, dictionaries, arrays, and strings. |
| `scripts/ui/map_constructor/map_constructor_property_controls.gd` | Property editor controls and property-update wiring. |
| `scripts/ui/map_constructor/map_constructor_link_controls.gd` | Entity-link controls, link candidates, and link-update wiring. |
| `scripts/ui/map_constructor/map_constructor_validation_view.gd` | Validation issues, warnings, readiness, and audit presentation. |
| `scripts/ui/map_constructor/map_constructor_floor_wall_controls.gd` | Floor and wall coverage controls, material/coating choices, and wall-side helpers. |
| `scripts/ui/map_constructor/map_constructor_inspector.gd` | Selected-cell/entity inspector composition. |
| `scripts/ui/map_constructor/map_constructor_actions.gd` | Shared UI actions after placement, move, duplicate, delete, property, floor, or wall mutations. |
| `scripts/ui/map_constructor/map_constructor_object_palette.gd` | Object prefab palette and placement choices. |
| `scripts/ui/map_constructor/map_constructor_tabs.gd` | Map Constructor tab composition and switching. |
| `scripts/ui/map_constructor/map_constructor_panel.gd` | Top-level Map Constructor panel composition and orchestration. |

## Runtime UI ownership

| Helper | Primary responsibility |
| --- | --- |
| `scripts/ui/runtime/runtime_hud.gd` | Runtime HUD composition and refresh behavior. |
| `scripts/ui/runtime/runtime_object_hud.gd` | Runtime object status and object-specific HUD presentation. |
| `scripts/ui/runtime/runtime_interaction_panel.gd` | Runtime interaction/action panel presentation and wiring. |
| `scripts/ui/runtime/runtime_notifications.gd` | Runtime notifications, hints, and transient messages. |

## Where to make common changes

| Change | Start in |
| --- | --- |
| Map Constructor inspector layout or selection presentation | `scripts/ui/map_constructor/map_constructor_inspector.gd` |
| Map Constructor property controls | `scripts/ui/map_constructor/map_constructor_property_controls.gd` |
| Map Constructor link controls | `scripts/ui/map_constructor/map_constructor_link_controls.gd` |
| Validation, warning, readiness, or audit view | `scripts/ui/map_constructor/map_constructor_validation_view.gd` |
| Floor/wall coverage controls or material choices | `scripts/ui/map_constructor/map_constructor_floor_wall_controls.gd` |
| Object prefab palette behavior | `scripts/ui/map_constructor/map_constructor_object_palette.gd` |
| Tab composition or panel-level orchestration | `scripts/ui/map_constructor/map_constructor_tabs.gd` and `scripts/ui/map_constructor/map_constructor_panel.gd` |
| Runtime object HUD | `scripts/ui/runtime/runtime_object_hud.gd` |
| Runtime interaction panel | `scripts/ui/runtime/runtime_interaction_panel.gd` |
| Runtime notifications or hints | `scripts/ui/runtime/runtime_notifications.gd` |
| Cross-section root wiring only | `scripts/ui/game_ui.gd` |

When a Map Constructor UI mutation is needed, prefer the shared methods in `map_constructor_actions.gd`. UI helpers should call the `MissionManager` facade rather than reaching into Map Constructor services directly. See [Map Constructor architecture](map_constructor.md).

## UI-only PR guardrails

- Keep UI-only PRs inside the relevant UI helper files and any explicitly allowed root-orchestrator file.
- Do not touch runtime systems from a UI-only PR unless the task explicitly requests a runtime change.
- Do not move business logic into UI helpers.
- Do not modify `project.godot`, scenes, save/load schemas, or Map Constructor services unless explicitly requested.
- Preserve existing runtime behavior while changing presentation or UI wiring.

## Local review checks

Run the lightweight checks before review:

```bash
python tools/check_map_constructor_sections.py
python tools/check_gdscript_safety_patterns.py
git diff --check
```

Godot CLI validation may be added when Godot is installed, but these local documentation and static checks do not require Godot.

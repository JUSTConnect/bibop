# Bipob — Codex instructions

This is a Godot 4.6 project using GDScript.

## Workflow

- Prefer editing `.gd` scripts.
- Do not modify `.tscn` scene files unless explicitly requested.
- If a scene/node/UI change is needed, explain what should be created manually in Godot Editor.
- Keep changes small and task-focused.
- Do not introduce large architecture changes without asking.
- Preserve current MVP scope.

## Current controls

- W / Up — Move forward
- S / Down — Move backward
- A / Left — Turn left
- D / Right — Turn right
- E — Interact / Action
- Space — End turn

## Project structure

- `scenes/` — Godot scenes
- `scripts/` — GDScript code
- `assets/` — art/audio placeholders
- `data/` — future data-driven configs
- `docs/` — design notes

## Current milestone

M1 completed:
- Grid field
- Bipob movement and direction
- Energy and action points
- Physical key
- Locked door
- Mission complete exit
- Command UI
- Status UI
- Hint UI
- Fog of war
- Directional visor vision

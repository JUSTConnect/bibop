# NewBIP PR-11–PR-20 implementation

## Scope

This iteration turns the first object-system prototype into an editor/runtime foundation while preserving the existing Power Source → Terminal → Door slice.

## PR-11 — Controller split

The active composition root is `scripts/app/editor_app_controller.gd`.

Responsibilities are separated into:

- `palette_controller.gd` — definitions and palette preview data.
- `map_editor_controller.gd` — editor state and world mutations.
- `map_editor_history_controller.gd` — undoable clear operation.
- `object_inspector_controller.gd` — inspector view model and edits.
- `play_safe_inspector_controller.gd` — blocks edits in Play mode.
- `world_runtime_controller.gd` — derived systems and runtime patches.
- `app_layout_builder.gd` — UI construction only.

`app_root.gd` is a thin scene shell. Legacy controller paths remain compatibility aliases.

## PR-12 — Smoke tests

Headless tests cover:

- definition validation;
- test-room generation;
- power propagation and interactions;
- document roundtrip and migration;
- visual catalog resolution;
- command history;
- passability;
- Edit/Play boundary;
- agent pathfinding;
- contextual actions;
- 350-line file limits.

Runner:

```text
godot --headless --path . --script res://tests/smoke/smoke_test_runner.gd
```

## PR-13 — World repository

`WorldObjectRepository` is the source of truth for placed objects and cell occupancy.

`EditorState` owns only:

- selection;
- active tool;
- app mode;
- next instance index.

Gameplay systems receive object snapshots or repository references instead of scanning the scene tree.

## PR-14 — Commands and history

Undoable operations:

- place object;
- erase object;
- edit config/identity;
- edit links;
- clear map.

Derived runtime patches do not enter command history.

## PR-15 — Map document v3

Version 3 stores:

- `map_id`;
- grid configuration;
- object instances;
- editor state;
- metadata.

Migration path:

```text
v1 snapshot → v2 document → v3 document
```

Derived `power_state` is excluded from saves and recalculated after loading.

## PR-16 — Passability

Current rules:

- empty cell: passable;
- open door: passable;
- closed door: blocked;
- power cable: passable;
- non-occupying object: passable;
- solid object: blocked.

## PR-17 — Edit and Play modes

Edit mode permits placement, removal, configuration, links, undo/redo and saving.

Play mode permits selection, contextual actions, interactions and agent movement. Entering Play captures a reset snapshot. Returning to Edit restores the editor world.

## PR-18 — Test agent

The debug agent uses BFS pathfinding and a restricted test-room corridor. A closed door blocks the route. Opening the door allows the agent to reach its goal.

## PR-19 — Contextual actions

Actions are provided from runtime state instead of hardcoded UI rules.

Examples:

- Power Source: Turn on / Turn off.
- Door: Open / Close / Lock / Unlock.
- Terminal: Activate.

The inspector displays the action panel, but execution rules live in domain/system files.

## PR-20 — Cable power graph

Power nodes are connected by four-directional cell adjacency.

Nodes include:

- power sources;
- power cables;
- external-power consumers.

A connected component is powered when it contains an active source. Direct `power_source` links remain a migration fallback for older maps.

## Active test room

The test room contains:

```text
Power Source (1,1) → Cable (2,1) → Terminal (3,1)
                                      ↓
                                  Door (3,2)
```

The test agent moves from `(0,2)` to `(5,2)`. The door at `(3,2)` blocks its route until opened.

## File-size policy

- preferred: 100–250 lines;
- split warning: 300 lines;
- hard maximum: 350 lines.

The smoke suite checks the primary controllers and systems against the hard maximum.

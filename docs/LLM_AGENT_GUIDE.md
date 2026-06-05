# BIPOB LLM Agent Guide

This guide is for Codex, ChatGPT, and any other LLM agent working on the BIPOB repository.

> RU note: этот файл нужен, чтобы подключать новых агентов без ручного переноса всего контекста.

---

## 1. Read First

Before making changes, read:

1. `README.md`
2. `docs/PROJECT_RULES.md`
3. `docs/ARCHITECTURE.md`
4. `docs/MECHANICS_ARCHITECTURE.md`
5. task-specific docs, if provided

If instructions conflict, follow the most specific task instructions, unless they violate `PROJECT_RULES.md`.

---

## 2. Project Summary

BIPOB is a Godot 4.x prototype of an isometric engineering puzzle / tactics game about modular robots.

The current goal is not to add large amounts of content. The current goal is to stabilize:

- architecture;
- base mechanics;
- final `128x71` isometric room presentation;
- TASK TEST sandbox;
- module management;
- vertical slice preparation.

---

## 3. Agent Role Split

### Codex / implementation agent

Codex should:

- implement scoped code changes;
- keep PRs small;
- follow target files;
- run or describe smoke checks;
- avoid docs/audits unless explicitly asked.

Codex should not:

- perform broad architecture audits;
- rewrite documentation unless the task says so;
- invent new roadmap priorities;
- expand overloaded files when a service extraction is appropriate;
- change `project.godot` without explicit instruction.

### ChatGPT planning/audit agent

ChatGPT may:

- audit architecture;
- define tasks for Codex;
- update docs if explicitly requested;
- prepare roadmap and milestone plans;
- ask clarifying questions.

---

## 4. Mandatory Development Pattern

When adding a new mechanic, first decide its home.

Do not default to adding logic into existing large files.

Preferred homes:

```text
scripts/game/<feature>_service.gd
scripts/game/<feature>_runtime.gd
scripts/game/<feature>_validation.gd
scripts/world/<feature>_system.gd
scripts/bipob/<feature>_controller.gd
scripts/ui/<area>/<area>_controller.gd
scripts/visual/<feature>_catalog.gd
```

Large files may keep wrappers for compatibility, but not full new systems.

---

## 5. Known Overloaded Files

Treat these files carefully:

- `scripts/game/mission_manager.gd`
- `scripts/ui/game_ui.gd`
- `scripts/bipob/bipob_controller.gd`
- `scripts/field/room_visual_renderer.gd`
- `scripts/field/grid_manager.gd`

Do not add large new systems to them.

---

## 6. Architecture Boundaries

- `GridManager`: gameplay grid truth.
- `RoomVisualRenderer`: visual-only isometric projection and draw order.
- `MissionManager`: mission runtime coordinator, currently overloaded, reduce over time.
- `GameUI`: UI shell/coordinator, should delegate to smaller UI controllers.
- `BipobController`: robot runtime state and command bridge, should delegate mechanics.
- `WorldObjectCatalog`: canonical object/prefab definitions and legacy alias normalization.
- `MissionContentCatalog`: mission definitions, currently only TASK TEST is well-catalogued.

---

## 7. Current Decisions

- Godot 4.6 opens the project.
- Final projection: `128x71`.
- TASK TEST is a dev sandbox for validating mechanics.
- TASK TEST may later help create 2–3 tutorial vertical slice missions.
- Early legacy missions may be removed after their mechanics are extracted or rewritten.
- Power Block manages module ports, not energy storage.
- Battery stores energy.
- Advanced encounter systems are planned later, after base mechanics.
- README is English-first with Russian notes.

---

## 8. Task Template for Codex

Use this format when asking Codex to implement something:

```text
BIP-XXX — Title

Goal:
...

Scope:
...

Target files:
- ...

Do not touch:
- project.godot
- unrelated mission resources
- documentation unless explicitly requested

Rules:
- follow docs/PROJECT_RULES.md
- keep new logic in dedicated files where possible
- no gameplay mutation in visual-only work

Acceptance criteria:
[ ] ...
[ ] ...

Manual smoke checklist:
[ ] Open project in Godot 4.6
[ ] Run TASK TEST
[ ] Verify ...
```

---

## 9. Review Priorities

When reviewing changes, check:

1. Did the task add logic to an overloaded file unnecessarily?
2. Did visual work change gameplay?
3. Did validation mutate active mission state?
4. Did the change duplicate constants or asset maps?
5. Did it preserve TASK TEST?
6. Did it avoid unrelated docs/project settings changes?
7. Is the new system reusable outside one mission?

---

## 10. Common Mistakes to Avoid

- Adding new mechanics directly into `MissionManager`.
- Adding new UI systems directly into `GameUI`.
- Adding renderer logic that changes gameplay state.
- Treating wall/floor visual geometry as gameplay truth.
- Adding new mission content when the task is TASK TEST-only.
- Writing normal mission resources from validation tools.
- Mixing documentation/audit work into implementation PRs.
- Reintroducing `128x64` as the final projection standard.

---

## 11. Completion Reporting

Implementation agents should report:

```text
Changed files:
- ...

What changed:
- ...

Smoke checks:
- pass/fail/not run

Risks:
- ...
```

Do not update roadmap percentages unless explicitly asked.

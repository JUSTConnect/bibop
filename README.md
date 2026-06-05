# BIPOB

**BIPOB** is a Godot 4.x prototype of an isometric engineering puzzle / tactics game about modular robots called Bipobs.

The player controls a small robot on a grid-based map, explores rooms, scans devices, restores power, connects cables, opens doors, uses terminals, manages inventory, and configures Bipob from internal and external modules.

> RU note: проект пока находится в стадии прототипа. Основная цель сейчас — стабилизировать архитектуру, базовые механики, изометрический визуал и TASK TEST sandbox перед полноценным вертикальным срезом.

---

## Current Status

- Engine: Godot 4.x. The current project opens in Godot 4.6.
- Projection target: isometric / axonometric 2D, final floor diamond standard `128x71`.
- Status: active prototype, not production-ready.
- Main development focus: core mechanics, TASK TEST sandbox, Map Constructor, module management, connected floor/wall rendering, and first vertical slice missions.

Some art in the repository is production-style work-in-progress, while some assets are placeholder/dev assets used to validate scale, pivots, projection and gameplay readability.

---

## Core Game Idea

Bipob is not just a character. Bipob is a configurable device.

Modules define what the robot can do:

- batteries provide energy storage;
- Power Blocks distribute module ports;
- processors and connectors enable advanced interactions;
- sensors enable scan, radar, thermal vision and X-Ray;
- manipulators allow physical interaction;
- tools enable repair, cutting or engineering actions;
- cooling and defensive systems control survivability and limitations;
- future combat systems will be added after the base mechanics are stable.

The long-term design goal is that the player cannot simply install every available module. The player must choose the best configuration for the mission. Later, when one Bipob reaches practical limits, additional Bipobs can be introduced to expand tactical and engineering possibilities.

---

## Key Documentation

Read these documents before changing the project:

- [`docs/PROJECT_RULES.md`](docs/PROJECT_RULES.md) — mandatory project rules and contribution boundaries.
- [`docs/LLM_AGENT_GUIDE.md`](docs/LLM_AGENT_GUIDE.md) — universal instructions for Codex and other LLM agents.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — target architecture and ownership boundaries.
- [`docs/MECHANICS_ARCHITECTURE.md`](docs/MECHANICS_ARCHITECTURE.md) — planned mechanics and where they should live.
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — global roadmap to release with completion tracking.

> RU note: если новая механика или логика появляется в проекте, её нельзя просто добавлять в уже перегруженные файлы. Максимально выносить новые системы в отдельные сервисы/контроллеры/каталоги.

---

## Core Architecture Rules

- `GridManager` is the gameplay truth for map cells, visibility and walkability.
- `RoomVisualRenderer` is visual-only and must not own gameplay rules.
- `MissionManager` should be reduced over time and must not keep absorbing new systems.
- `GameUI` should act as a UI shell/coordinator, not as the owner of all runtime, box and constructor logic.
- TASK TEST is the main mechanics sandbox.
- New mechanics must be implemented as separate files/services where possible.
- Visual PRs must not change pathfinding, passability or mission logic.
- Validation must be read-only or use snapshot/restore.
- Codex implementation tasks should not do audits or documentation maintenance unless explicitly requested.

---

## TASK TEST

TASK TEST / `mission_10` / `task_test` is currently a development sandbox.

Purpose:

- validate all required mechanics;
- test Map Constructor behavior;
- test visual scale, pivots and isometric placement;
- prepare 2–3 vertical slice tutorial missions through sandbox-proven systems.

It is not yet decided whether TASK TEST will become an in-game editor/constructor for players.

---

## Near-Term Priorities

1. Stop growth of overloaded files by extracting new mechanics into dedicated services.
2. Extract shared visual asset catalog and remove asset mapping duplication.
3. Stabilize final `128x71` floor/wall visual architecture.
4. Keep TASK TEST validation safe and non-mutating.
5. Finish base mechanics before starting full combat/enemy implementation.
6. Implement module port management: Power Block, Internal Interface, External Interface, Processor and Connector requirements.
7. Build 2–3 tutorial vertical slice missions from sandbox-proven mechanics.

---

## Running the Project

Open the project in Godot 4.x. The current repository is known to open in Godot 4.6.

Avoid editing `project.godot` unless the task explicitly requires it.

---

## Repository

Main repository: `JUSTConnect/bibop`

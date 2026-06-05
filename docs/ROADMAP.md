# BIPOB Roadmap

This roadmap tracks the global development direction from prototype to release.

> RU note: проценты здесь примерные. Они нужны не для точной бухгалтерии, а чтобы понимать стадию проекта. Codex не должен обновлять этот файл без явного запроса.

---

## 1. Current Overall Progress

Estimated full project completion: **8%**

Current phase: **Prototype architecture and mechanics foundation**

Main blockers:

- overloaded core files;
- visual floor/wall stability;
- module port system not implemented yet;
- TASK TEST validation safety;
- first vertical slice missions not built yet.

---

## 2. Milestone Update Rule

After completing a milestone, update this file manually:

```text
[ ] milestone status
[ ] completion percentage
[ ] what changed
[ ] what remains
[ ] next milestone
[ ] blockers
```

Do not require Codex to update this file unless explicitly requested.

---

## 3. Global Release Phases

| Phase | Name | Status | Estimated completion |
|---|---|---:|---:|
| 0 | Prototype base | In progress | 35% |
| 1 | Architecture stabilization | In progress | 20% |
| 2 | Visual room foundation | In progress | 30% |
| 3 | Core mechanics foundation | In progress | 25% |
| 4 | Module management foundation | Not started / partial data only | 10% |
| 5 | TASK TEST complete sandbox | In progress | 40% |
| 6 | First vertical slice | Not started | 0% |
| 7 | Extended gameplay systems | Not started | 0% |
| 8 | Content production | Not started | 0% |
| 9 | UX / save / progression | Not started / partial | 5% |
| 10 | Release polish | Not started | 0% |

---

## 4. Phase 0 — Prototype Base

Estimated completion: **35%**

Goal:

Establish a playable prototype with grid movement, room rendering, interaction flow, and sandbox testing.

Done / partial:

- Godot project opens in 4.6.
- GridManager exists.
- RoomVisualRenderer exists.
- BipobController exists.
- MissionManager exists.
- TASK TEST exists.
- Some mechanics are already represented in code.

Remaining:

- reduce overloaded files;
- finish first stable gameplay loop;
- remove or migrate old legacy mission dependencies.

---

## 5. Phase 1 — Architecture Stabilization

Estimated completion: **20%**

Goal:

Stop growth of overloaded files and make future mechanics easy to place.

Milestones:

```text
[ ] Extract VisualAssetCatalog
[ ] Extract MissionIds constants
[ ] Extract MapConstructorPresetService
[ ] Extract MissionInventoryRuntimeService
[ ] Split GameUI into smaller UI controllers
[ ] Add file-size / architecture review rule to PR workflow
```

Success criteria:

- New mechanics have clear target files.
- MissionManager stops absorbing new systems.
- GameUI becomes a shell/coordinator.
- Visual asset paths are defined once.

---

## 6. Phase 2 — Visual Room Foundation

Estimated completion: **30%**

Goal:

Make the isometric room look coherent and stable using final `128x71` projection.

Milestones:

```text
[ ] Seamless floor surfaces
[ ] Connected wall runs
[ ] Reduced wall spill into floor cells
[ ] Door openings preserved inside wall runs
[ ] Wall-mounted anchor zones preserved
[ ] Object grounding polish
[ ] Cable visual pass
[ ] Platform visual states
[ ] Fog/visibility production pass
```

Success criteria:

- Floor reads as one connected surface.
- Walls read as architecture, not isolated blocks.
- Doors are inserted into walls, not floating floor objects.
- Visual layer does not change gameplay truth.

---

## 7. Phase 3 — Core Mechanics Foundation

Estimated completion: **25%**

Goal:

Stabilize the base engineering puzzle systems.

Milestones:

```text
[ ] Movement and action economy stable
[ ] Door access stable
[ ] Terminal action flow stable
[ ] Power graph scoped apply stable
[ ] Cable/socket/reel stable
[ ] Cooling stable enough for puzzle use
[ ] Scan/diagnostic/X-Ray stable
[ ] Inventory pickup/use/drop stable
[ ] Platforms stable enough for puzzle use
[ ] TASK TEST smoke checklist covers core mechanics
```

Success criteria:

- Failed actions do not mutate state.
- Preview functions do not mutate state.
- Power/cooling/cable changes are scoped.
- Systems work outside one-off mission hacks.

---

## 8. Phase 4 — Module Management Foundation

Estimated completion: **10%**

Goal:

Make module configuration a real gameplay system.

Milestones:

```text
[ ] Internal module space rules
[ ] External module slot rules
[ ] Power Block port distribution
[ ] Internal Interface ports
[ ] External Interface ports
[ ] Processor requirement checks
[ ] Connector requirement checks
[ ] Installed but inactive modules
[ ] Inactive reason reporting
[ ] Box UI for module port usage
[ ] Module configuration smoke tests
```

Success criteria:

- Player cannot install/activate everything at once.
- Module choices matter before each mission.
- Power Block is port management, not battery storage.
- Battery remains energy storage.

---

## 9. Phase 5 — TASK TEST Complete Sandbox

Estimated completion: **40%**

Goal:

Use TASK TEST to validate all important mechanics before vertical slice missions.

Milestones:

```text
[ ] Read-only or snapshot/restore validation
[ ] Constructor palette validation stable
[ ] Object overlap validation stable
[ ] Power/cable/cooling scenario validation
[ ] Module configuration scenario validation
[ ] Visual diagnostics stable
[ ] Sandbox smoke checklist complete
```

Success criteria:

- TASK TEST can validate mechanics safely.
- Sandbox data does not pollute normal missions.
- New systems are proven here before story/tutorial use.

---

## 10. Phase 6 — First Vertical Slice

Estimated completion: **0%**

Goal:

Build 2–3 tutorial missions from sandbox-proven mechanics.

Milestones:

```text
[ ] Mission 1: movement, scan, door, terminal
[ ] Mission 2: power, cable, socket, item use
[ ] Mission 3: modules, sensors, route choice
[ ] Tutorial UI text
[ ] Mission complete/fail flow
[ ] Basic progression loop
```

Success criteria:

- A new player understands the core loop.
- Missions use reusable systems, not one-off hacks.
- TASK TEST remains the development sandbox.

---

## 11. Phase 7 — Extended Gameplay Systems

Estimated completion: **0%**

Goal:

Add later tactical and systemic gameplay after base mechanics are stable.

Milestones:

```text
[ ] Runtime state framework
[ ] Equipment behavior framework
[ ] Automated object framework
[ ] Interaction availability framework
[ ] Recovery framework
[ ] Balance rules
[ ] TASK TEST scenarios
```

Success criteria:

- Extended systems are modular.
- They do not live inside MissionManager or BipobController.
- They are validated in TASK TEST before content production.

---

## 12. Phase 8 — Content Production

Estimated completion: **0%**

Goal:

Create real mission content and progression after systems are stable.

Milestones:

```text
[ ] Mission structure
[ ] Puzzle progression
[ ] Asset replacement plan
[ ] Final room visual pass
[ ] Module unlock pacing
[ ] Multi-Bipob progression design
```

---

## 13. Phase 9 — UX / Save / Progression

Estimated completion: **5%**

Goal:

Make the game usable as a full product experience.

Milestones:

```text
[ ] Save/load runtime state
[ ] Box screen polish
[ ] Module installation UX
[ ] Mission selection UX
[ ] Inventory/storage UX
[ ] Settings
[ ] Feedback and diagnostics for players
```

---

## 14. Phase 10 — Release Polish

Estimated completion: **0%**

Goal:

Prepare the project for a public playable release.

Milestones:

```text
[ ] Performance pass
[ ] Bug fixing
[ ] Art consistency pass
[ ] Audio pass
[ ] Tutorial polish
[ ] Packaging/export
[ ] Demo materials
```

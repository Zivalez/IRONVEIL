# IRONVEIL

2.5D isometric survival/engineering RPG prototype built with Godot 4.x.

> **Current repository phase:** Phase 1 — Prototype / First Playable implementation.  
> Phase 2+ is intentionally not implemented until the Phase 1 runtime acceptance checklist passes, per `IRONVEIL_MASTER_PROMPT.md`.

## First Playable Loop

```text
Spawn in forest
→ find/eat food
→ discover abandoned workshop
→ collect scrap
→ repair water wheel
→ craft + install crude gear
→ load logs into mechanical saw
→ wheel torque flows through gear/belt
→ saw automatically produces planks
```

The mechanical chain is simulation-backed. The saw does not use a repeated manual craft action: it only processes while its graph node receives enough RPM and torque.

## Controls

| Input | Action |
|---|---|
| WASD | Move |
| Shift | Sprint |
| F | Interact |
| Q / E | Rotate isometric camera 90° |
| Mouse wheel | Zoom |
| 1 | Eat Wild Berries |
| C | Craft Crude Gear |
| Space | Basic melee attack |
| J | Field Journal |
| Esc | Settings |
| H | Help |
| F5 | Save |
| F9 | Load |

## Requirements

- Godot **4.7.1** with export templates for local/native/Web exports.
- Python 3 for repository validation and the optional UI-SFX fetch helper.
- Docker for the Web container build.

The project uses Godot's **GL Compatibility** renderer because Web is the public deployment target.

## Run in Godot

```bash
godot --path .
```

Or open `project.godot` in the Godot editor and run the main scene.

## Validate Source

```bash
python3 tools/validate_project.py
```

Run the same Godot gate used by Docker when Godot is installed:

```bash
godot --headless --path . --import
godot --headless --path . res://scenes/tests/ci_runner.tscn
```

The CI runner is a **normal project scene**, not a `godot --script` entry point. That distinction is intentional: project autoloads (`TickManager`, `GameState`, `SettingsManager`, `DataRegistry`, etc.) are initialized before normal scenes, matching the lifecycle used by the actual game. The runner then loads every runtime script, validates all catalogs, tests the mechanical solver, and instantiates `boot.tscn` end-to-end. Any failure exits Godot with code 1, so Docker/Dokploy stops before Web export.

## UI SFX

The UI audio integration targets the CC0 audio files from the `mechanical` pack in `romainsimon/uisfx`.
Binary audio is intentionally not vendored by the generated source package in environments where the upstream binaries cannot be fetched.

With internet access:

```bash
python3 tools/fetch_ui_sfx.py
```

Expected destination:

```text
audio/ui/mechanical/
```

The game safely runs without these optional UI cue files; `AudioManager` simply skips a missing cue.

## Native Exports

Presets are provided for Windows and Linux.

```bash
godot --headless --path . --export-release "Windows Desktop" build/IRONVEIL.exe
godot --headless --path . --export-release "Linux" build/IRONVEIL.x86_64
```

## Web Export

```bash
godot --headless --path . --export-release "Web" build/index.html
```

Web threading is disabled for Phase 1 to avoid SharedArrayBuffer / COOP / COEP requirements until profiling proves it is necessary.

## Docker / Dokploy

A multi-stage Docker build exports the Web build in the builder stage and serves it through nginx.

```bash
docker build -t ironveil:phase1 .
docker run --rm -p 8080:80 ironveil:phase1
```

Open `http://localhost:8080`.

For **Phase 1**, create a Dokploy **Application**, point it at this repository, select the root `Dockerfile`, and expose container port 80. Do not use Compose yet: the room server/lobby services required for a real multi-service topology do not exist in this phase.

When Phase 2 implements the dedicated room server and lobby, deployment becomes multi-service and may move to Dokploy Compose or separately managed Applications. Public co-op additionally must satisfy the security/scalability gate below.

## Multiplayer Security / Public Release Gate

The revised master prompt makes public co-op conditional on explicit capacity and abuse controls. See:

- `docs/PHASE2_NETWORK_ARCHITECTURE.md`
- `docs/PHASE2_SECURITY_SCALABILITY.md`

Key future requirements are server-enforced max 4 players/room, configurable room capacity, per-room CPU/RAM limits, rate limiting, server-side input sanitization, WSS through Dokploy/Traefik, crash restart + checkpoint recovery, and operational logging. These are **not claimed as implemented in Phase 1**.

## Architecture at a Glance

```text
Input / UI / Rendering
        │
        ▼
Gameplay adapters (Player, Workshop, Machines)
        │
        ▼
GameState ───── SaveManager
   │
   ├── TickManager
   ├── MechanicalNetwork graph solver
   ├── DataRegistry → JSON definitions
   └── ChunkManager → FULL / SIMPLIFIED / STATISTICAL tiers
```

Simulation state is kept separate from visual nodes so Phase 2 can move authoritative simulation to a dedicated server rather than rewriting gameplay from scratch.

## Repository Layout

```text
scenes/                 Entry scenes
scripts/core/            Simulation, state, save, settings, tick/LOD systems
scripts/data/            Data catalog loader
scripts/game/            Player/world/machine adapters
scripts/ui/              HUD/settings/journal UI
scripts/tests/           Headless logic checks
data/                    Data-driven item/recipe/machine/etc definitions
audio/ui/mechanical/     Optional UI SFX assets
docs/                    Architecture and test documentation
tools/                   Validation and asset helper scripts
build/                   Generated exports (gitignored except .gitkeep)
```

## Source-of-Truth Documents

- `IRONVEIL_GAME_BLUEPRINT.md` — game design.
- `IRONVEIL_MASTER_PROMPT.md` — process, locked technical decisions, roadmap and acceptance rules.
- `PROJECT_STATE.md` — factual current state.
- `DECISIONS.md` — technical/design decisions made while implementing.
- `CHANGELOG.md` — work log.
- `docs/PHASE2_SECURITY_SCALABILITY.md` — mandatory capacity/anti-abuse/WSS/resilience contract for future public co-op.

## Important Scope Rule

Do **not** start Phase 2 implementation until every Phase 1 runtime acceptance item in `PROJECT_STATE.md` has been verified in a real Godot/native/Web runtime. Static source validation is not a substitute for playing the First Playable end-to-end.

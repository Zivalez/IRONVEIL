# IRONVEIL

**IRONVEIL** is a 2.5D isometric survival/engineering RPG built with Godot 4.x. Progression is knowledge-driven: observe systems, understand them, build working infrastructure, then automate it.

> **Current repository phase:** **Phase 3 — MVP implementation candidate**.  
> Phase 1 Web First Playable has been reported running by the project owner. Phase 3 was explicitly requested by the owner before every Phase-2 multiplayer acceptance item was proven; unresolved runtime/co-op debt remains tracked in `PROJECT_STATE.md` and is not marked passed.

## Phase 2 Vertical Slice

```text
Green Hollow forest
→ survive + collect field resources
→ abandoned workshop
→ repair water wheel
→ install gear/belt transmission
→ automate plank production
→ repair Ashwick east bridge
→ enter Ashwick
→ speak with Archivist Mara
→ use mechanical press for 2 plates
→ repair/open Foundry Vault
→ open both thermal relief valves
→ thermal-shock Furnace Saint armor
→ defeat Furnace Saint during the vulnerability window
```

The boss is intentionally systemic: sealed armor reduces direct attacks to negligible damage. The Foundry pressure system creates the real combat opening.


## Phase 3 MVP extension

```text
Green Hollow / Ashwick / Foundry
→ Ashlands wind-powered industry
→ workshop metallurgy
→ powered industrial shaping
→ Flooded Basin irrigation
→ multi-factor farming
→ settlement barter loop
```

The three MVP regions are **Green Hollow**, **Ashlands**, and **Flooded Basin**. Survival now includes temperature, fatigue, stamina, stress, morale, body-part injury state and infection risk. Crafting is enforced across handcraft/workshop/industrial tiers, and industrial output requires live mechanical power.

Phase-3 source does **not** claim the blueprint's 15–25 hours of authored content yet; this is a systems/content implementation candidate awaiting real Godot/Web/co-op acceptance.

## Visual Direction

Phase 2 establishes the **Modern Pixel Art / Hi-Bit / HD-2D-inspired** rendering direction:

- authored pixel sprites for player, enemies, NPC, vegetation and pickups;
- nearest-neighbor pixel filtering;
- pixel textures on 3D terrain/buildings/machinery;
- real 3D machinery so gears/wheels/belts remain mechanically readable;
- dynamic lights and real-time shadows;
- pixel dust/steam fields;
- Web-safe screen shader with restrained quantization, dithering, vignette and colorblind transforms.

The included art is a representative development set, **not final production-quality art**. The visual contract is in `docs/ART_DIRECTION_MODERN_PIXEL.md`.

## Controls

All keyboard controls can be rebound from Settings → Controls. Defaults:

| Input | Action |
|---|---|
| WASD | Move |
| Shift | Sprint |
| F | Interact |
| Space | Melee attack |
| Q / E | Rotate isometric camera 90° |
| Mouse wheel | Zoom |
| 1 | Quick consume |
| C | Craft Crude Gear |
| J | Field Journal |
| N | Co-op room terminal |
| Esc | Settings |
| H | Help |
| F5 / F9 | Save / Load |

## Settings

Phase 2 exposes all master-prompt categories:

- **Graphics:** resolution/window mode persistence, VSync, quality/shadow fields, modern-pixel post-processing toggles, camera zoom, UI scale.
- **Audio:** separate master/music/SFX/ambient volumes and mutes.
- **Controls:** remappable keybinds and mouse sensitivity.
- **Gameplay:** HUD, camera rotation and current world modifiers.
- **Accessibility:** text/UI scale, colorblind transform and subtitles toggle.
- **Network:** display name, lobby API URL and region field.

## Architecture

```text
                    ┌──────────────────────────┐
                    │  Godot Web/Native Client │
                    │ input + rendering + HUD  │
                    └─────────────┬────────────┘
                                  │ HTTPS lobby / WebSocket room
                    ┌─────────────┴────────────┐
                    │                          │
          ┌─────────▼─────────┐      ┌────────▼──────────┐
          │ Lobby Service     │      │ Godot Room Server │
          │ create/list/join  │      │ WebSocket peer    │
          │ password/rate cap │      │ room state/checkpt│
          └───────────────────┘      └───────────────────┘

Single-player simulation remains:
Input/UI → gameplay adapters → GameState → TickManager / MechanicalNetwork / DataRegistry / ChunkManager
```

The Phase 2 networking implementation currently provides authenticated room membership, server-clamped movement replication, roster replication and shared vertical-slice progression flags. **Inventory, survival, general enemy simulation and the full machine simulation have not yet all been migrated to server authority; Furnace Saint health/vulnerability is server-owned in co-op**, so public competitive/anti-cheat claims are explicitly out of scope until that authority migration and desync testing are finished.

## Requirements

- Godot **4.7.1** + matching export templates.
- Python 3.11+ for repository/lobby validation.
- Docker / Docker Compose for container tests and Phase 2 service topology.

The public Web client uses Godot **GL Compatibility** rendering.

## Validate Source

Static/data/deployment contract:

```bash
python3 tools/validate_project.py
```

Lobby HTTP/security contract:

```bash
python3 tools/test_lobby_contract.py
```

Godot project-aware CI gate:

```bash
godot --headless --path . --import
godot --headless --path . res://scenes/tests/ci_runner.tscn
```

The Godot gate runs as a normal project scene so all autoloads are initialized exactly as they are for the exported game. It checks autoloads, runtime scripts/scenes, data catalogs, the mechanical solver and the actual `boot.tscn` path.

## Run Single Player

```bash
godot --path .
```

Or open `project.godot` and run the project.

## Build Web Client

```bash
docker build --no-cache -t ironveil:phase2-client .
docker run --rm -p 8080:80 ironveil:phase2-client
```

This root `Dockerfile` intentionally remains usable as a normal **Dokploy Application** for the single-player/Web client.

## Run Phase 2 Co-op Stack Locally

Create environment file:

```bash
cp .env.phase3.example .env.phase3
```

Replace `ROOM_TOKEN_SECRET` with a long random value, then:

```bash
docker compose --env-file .env.phase3 -f docker-compose.phase3.yml up --build
```

Default local endpoints:

```text
Web client  http://127.0.0.1:8080
Lobby API   http://127.0.0.1:8081
Room WS     ws://127.0.0.1:9081
```

Open Settings → Network and ensure Lobby API URL is `http://127.0.0.1:8081`. Press **N** for the room terminal.

### Public Dokploy topology

For public HTTPS co-op, deploy three endpoints/services:

```text
client  → https://<game-domain>
lobby   → https://<lobby-domain>
room    → wss://<room-domain>
```

Configure:

```text
ROOM_TOKEN_SECRET=<strong random secret shared by lobby + room server>
PUBLIC_WS_URL=wss://<room-domain>
ALLOWED_ORIGIN=https://<game-domain>
MAX_ACTIVE_ROOMS=<profiled VPS capacity>
```

The lobby can be exposed as a separate Dokploy Application or as the `lobby` service in Dokploy Compose. The room server must have WebSocket upgrade support and long-lived proxy timeouts. CPU/RAM limits are present in `docker-compose.phase2.yml` as initial testing ceilings, not final production sizing.

**Do not expose co-op publicly yet just because containers start.** Complete `docs/PHASE2_SECURITY_SCALABILITY.md` and the 2–4 client runtime checklist first.

## Native Exports

```bash
godot --headless --path . --export-release "Windows Desktop" build/IRONVEIL.exe
godot --headless --path . --export-release "Linux" build/IRONVEIL.x86_64
```

## UI SFX

The project targets the CC0 `mechanical` pack from `romainsimon/uisfx` for interface cues. If assets are not vendored:

```bash
python3 tools/fetch_ui_sfx.py
```

Missing optional UI cue files do not block gameplay.

## Repository Layout

```text
assets/pixel/             Phase-2 representative pixel-art set
data/                     Data-driven catalogs
scenes/                   boot/main/test/server scenes
scripts/core/             state, ticks, networking, save, settings, solvers
scripts/game/             world gameplay adapters and vertical-slice systems
scripts/server/           headless room server
scripts/ui/               HUD/settings/journal/co-op terminal
services/lobby/           Python lobby/matchmaking service
shaders/                  Web-compatible modern-pixel post processing
docs/                     architecture, visual, security and test contracts
tools/                    validators and local contract tests
```

## Source of Truth

- `IRONVEIL_GAME_BLUEPRINT.md`
- `IRONVEIL_MASTER_PROMPT.md`
- `PROJECT_STATE.md`
- `DECISIONS.md`
- `CHANGELOG.md`

Do not begin Phase 3 until Phase 2 is verified end-to-end in solo and 2–4 player co-op and the vertical slice can be completed through Furnace Saint without a crash or major desync.

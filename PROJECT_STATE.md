# PROJECT STATE — IRONVEIL

**Last updated:** 2026-08-16  
**Current phase:** Phase 1 — Prototype / First Playable  
**Current status:** Implementation assembled; static validation targeted. Runtime acceptance still requires Godot + Docker execution.

## Current Milestone

Milestone 1 — First Playable:

```text
Player spawn di hutan
→ mencari makanan
→ menemukan workshop rusak
→ memperbaiki water wheel
→ menghubungkan gear
→ menyalakan mechanical saw
→ memproduksi plank otomatis
```

## Functional in Source Implementation

The following systems are connected in code and are part of the current playable path:

- 3D isometric player movement, sprint, 90° camera rotation and zoom.
- World interaction targeting and resource pickups.
- Data-driven item, recipe, material, machine, enemy, biome and technology catalogs.
- Inventory and crude-gear crafting.
- Basic survival state: hunger, thirst, health and starvation/dehydration damage.
- Basic melee combat and one hostile prototype enemy.
- Field Journal implementing Observation → Hypothesis → Confirmation notes.
- Mechanical graph solver separated from rendering.
- Water wheel source: 32 RPM / 120 Nm once repaired.
- Gear transformer: 3:1 speed ratio with efficiency loss.
- Belt transmission with efficiency loss.
- Mechanical saw consumer with real RPM/torque thresholds and automatic processing.
- Secondary mechanical press consumer as a small automation proof.
- Save/load for player position, inventory, survival, journal, objectives, flags and mechanical graph state.
- Minimal persistent graphics/audio settings for Phase 1.
- Chunk/LOD architecture scaffold with FULL / SIMPLIFIED / STATISTICAL tiers.
- Docker Web-export pipeline and nginx runtime configuration.
- Native/Web export presets.
- Headless mechanical solver test and static repository validator.

## Intentionally Not Built Yet

Per the roadmap and guardrails:

- Room/lobby UI and actual multiplayer transport — Phase 2.
- Dedicated room server and matchmaking/lobby API — Phase 2.
- Multiplayer capacity controls (server-enforced max 4 players, active-room cap, per-room resource limits) — Phase 2.
- Public multiplayer anti-abuse/WSS/recovery gate — must be complete before public room release, fully required by Phase 3.
- Full settings categories (controls/accessibility/network) — Phase 2.
- Full farming/NPC/three-region content — Phase 3.
- Electrical simulation, factions, Veil technology/endgame — Phase 4.
- Large procedural world, complex vehicles, weather engineering, 100+ enemies — explicitly deferred.

## Phase 1 Acceptance Checklist

### Source/architecture

- [x] Godot project and main scene exist.
- [x] Data-driven catalogs are wired through `DataRegistry`.
- [x] Simulation/game state is separated from player input/rendering.
- [x] Tiered `TickManager` exists.
- [x] Mechanical graph solver exists independently of machine visuals.
- [x] Chunk/LOD scaffold exists for future simulation simplification / multiplayer interest management.
- [x] Settings persistence is implemented.
- [x] Save/load includes mechanical and player gameplay state.
- [x] README explains run/test/export controls.
- [x] Dockerfile + nginx Web serving setup exists at repository root.

### Runtime verification — MUST be checked on a machine with Godot/Docker

- [ ] Godot project imports with zero parser/runtime errors.
- [ ] Start → final plank loop can be played without a crash.
- [ ] Hunger/thirst visibly tick and cause health loss at zero.
- [ ] Water wheel repair actually enables graph power.
- [ ] Gear output reports transformed RPM/torque.
- [ ] Saw processes logs automatically only while powered.
- [ ] F5/F9 restore the complete First Playable machine state correctly.
- [ ] Graphics/audio settings survive a restart.
- [ ] Windows export launches without editor.
- [ ] Linux export launches without editor.
- [ ] `docker build` succeeds from root.
- [ ] Web build loads and is playable in browser from the nginx container.

**Phase 2 is blocked until every runtime item above is green.**

## Future Multiplayer Security Gate (new master prompt §4.5)

The revised master prompt adds a mandatory security/scalability contract. It is intentionally **not implemented in Phase 1**, because room/lobby services do not exist yet. The requirements are now captured in `docs/PHASE2_SECURITY_SCALABILITY.md` and linked from the Phase 2 network design.

Mandatory future controls include:

- hard server-side maximum of 4 players per room;
- configurable active-room capacity;
- CPU/RAM limits per room server;
- create-room and password-attempt rate limiting;
- server-side room/player-name sanitization;
- WSS for public HTTPS deployments and verified reverse-proxy WebSocket behavior;
- room-server restart policy plus periodic checkpoint/recovery;
- basic lifecycle/error/disconnect logging without plaintext passwords.

These are release gates for public co-op, not decorative TODOs.

## Known Incomplete Asset Work

The UI SFX mapping is implemented, but binary `.ogg` files from the `uisfx` mechanical pack are not included in this generated package because the construction environment could not retrieve the upstream audio binaries. `tools/fetch_ui_sfx.py` downloads the expected cues when run with network access. The game remains functional without them.

## Concrete Next Steps

1. Run `python3 tools/validate_project.py` and resolve every static issue.
2. Open with Godot 4.7.1, run the headless test, then manually complete the entire First Playable loop.
3. Export Windows/Linux/Web and verify the Docker/browser path. Only after those checks pass, mark Milestone 1 complete and begin Phase 2.
4. When Phase 2 begins, implement the capacity/resource-limit foundation from `docs/PHASE2_SECURITY_SCALABILITY.md`; before any public room release, complete its full anti-abuse/WSS/resilience checklist.

## Web runtime incident — 2026-08-16

The first Dokploy Web deployment reached the Godot splash screen but then displayed a black canvas. This proves the public HTML/WebAssembly boot path is reachable, but does **not** satisfy Phase 1 runtime acceptance.

Corrective source changes are now staged:

- Web export explicitly includes all JSON runtime catalogs.
- Docker performs Godot import + headless script tests before Web export.
- A dedicated boot scene reports gameplay load/player/camera startup failure on-canvas.
- Web artifacts with stable `index.*` names are no longer cached as immutable.

**Current gate:** redeploy this revision, hard-refresh/clear the previous site cache once, then verify the forest scene + HUD appears and complete the First Playable loop. Phase 1 remains in progress until that runtime test passes.

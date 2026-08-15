# CHANGELOG — IRONVEIL

## 2026-08-16 — Phase 0 + Phase 1 implementation session

### Added

- Godot 4.x GL Compatibility project and handcrafted forest/workshop main scene.
- Data-driven JSON catalogs for items, recipes, machines, materials, enemy, biome and technologies.
- Separate tick scheduler for simulation, machines, farming and economy.
- Central gameplay state with inventory, survival, objective, journal and flags.
- Mechanical graph solver supporting source → gear/belt transformer → consumer propagation.
- Water wheel repair flow, 3:1 transmission assembly and automatic saw processing.
- Optional powered mechanical press.
- Player movement, interaction, resource collection, sprint and basic melee combat.
- Prototype enemy.
- Isometric camera with 90° rotation, zoom and occluder fading.
- Field Journal with Observation / Hypothesis / Confirmation stages.
- HUD, help screen and persistent Phase 1 graphics/audio settings.
- Save/load for player + simulation/machine state.
- Chunk/LOD architecture scaffold for simulation tiers and future multiplayer interest management.
- Web, Windows and Linux export presets.
- Multi-stage Godot Web-export + nginx Dockerfile.
- nginx WebAssembly/PCK MIME, gzip and static-cache configuration.
- Static repository validator and Godot headless mechanical-network test.
- Optional helper to fetch CC0 UI SFX cues from the upstream mechanical pack.
- README, architecture documentation, test plan and living project documents.

### Not claimed as complete

Runtime execution, native exports and Docker/Web acceptance were not performed in the source-generation environment because Godot and Docker runtimes were unavailable there. Phase 1 remains acceptance-blocked until those checks are run successfully.

## 2026-08-16 — Revised master prompt alignment

### Changed

- Replaced `IRONVEIL_MASTER_PROMPT.md` with the newly supplied revision.
- Added the mandatory §4.5 security/scalability contract for future co-op deployment.
- Expanded Phase 2 network architecture with server-enforced four-player capacity, active-room caps, WSS, resource isolation, checkpoint recovery, and logging requirements.
- Added `docs/PHASE2_SECURITY_SCALABILITY.md` with explicit Phase 2/Phase 3 ownership and a public multiplayer release checklist.
- Updated `PROJECT_STATE.md`, `DECISIONS.md`, README and static validation so future work cannot silently ignore the new public-room gate.

### Scope preserved

No room server, lobby, rate limiter, or public multiplayer transport was falsely added to Phase 1. Those systems remain blocked until the First Playable runtime acceptance gate passes, exactly as required by the revised roadmap.


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


## 2026-08-16 — Web black-screen hardening

- Fixed Web export preset so runtime JSON catalogs under `res://data/*.json` are included in the exported PCK.
- Replaced immediate editor quit in Docker with the official headless `--import` flow before export.
- Added Godot headless runtime-script parsing/tests as a mandatory Docker build gate.
- Added a minimal boot diagnostics scene that only hands control to gameplay after a player and active Camera3D exist; startup failures now display an on-canvas diagnostic instead of leaving an unexplained black canvas.
- Removed `immutable` caching for fixed-name Godot `index.pck`, `index.wasm`, and JS assets so redeploys cannot mix new HTML with stale engine/project payloads.

## 2026-08-16 — Dokploy compile fix + visual-direction lock
- Fixed Godot 4.7 `inference_on_variant` compile failure in `MechanicalNetwork.solve()` by explicitly converting the typed queue pop result to `String`.
- Strongly typed `GameState.mechanical_network` so downstream RPM/torque calls keep static return types.
- Builder now installs `fontconfig`, removing the headless `libfontconfig.so.1` warnings seen in Dokploy.
- Locked modern pixel art / HD-2D-inspired 2.5D as the final visual direction and documented the Web/Compatibility-safe rendering contract.
- Explicitly classified current primitive geometry as gameplay blockout rather than final art.

## 2026-08-16 — HUD hardening
- Reworked `scripts/ui/hud.gd` to use conservative explicit typing and named callbacks.
- Corrected an earlier audit mistake: GDScript does allow `:=` in default parameter declarations; the false validator rule was removed.
- Confirmed prior mechanical-network Variant-inference fix and fontconfig Docker fix are present.

## 2026-08-16 — Full Phase 1 source audit
- Added `scripts/tests/compile_all.gd`, which independently loads every runtime script and both entry scenes before runtime tests.
- Reworked the headless test runner to avoid compile-time preload chains and added a real boot-to-gameplay smoke test (player, active camera, water-wheel source and saw consumer).
- Audited GDScript Variant boundaries across GameState, save/load, JSON catalogs, player/enemy input, camera raycasts, settings and audio loading; risky values now use explicit `Variant` checks/casts or concrete types.
- Made SettingsManager skip window-only DisplayServer operations under Godot `--headless`, while still applying non-window settings for CI smoke tests.
- Extended static validation with runtime-script compile-gate coverage, project/scene resource-reference checks, machine/enemy/biome item-reference checks and Milestone-1 resource-economy sanity checks.
- Docker now requires import → all-script compile gate → runtime smoke tests → Web export → non-empty `index.html/js/wasm/pck`, in that order.
- Added a full code-audit report and updated deployment troubleshooting documentation.

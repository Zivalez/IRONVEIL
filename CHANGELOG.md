# CHANGELOG

## 1.0.1-source — Dokploy authentication hotfix

- Replaced email identity with case-insensitive nickname + password registration and login.
- Added migration for legacy account records; email fields are removed from persisted account metadata.
- Replaced the Web client's localhost API default with `https://ironveil.zvlz.dev/api` and migrate stale browser settings automatically.
- Added same-origin nginx proxy routes for `/api/*` and `/room-ws`, so Dokploy only needs one public domain on the client service.
- Added a domain-specific production environment template and nickname authentication contract coverage.

## 1.0.0-source — Phase 4 full-route production candidate

- Added product entry, account/session flow, personal/shared world selection, invites, and cross-browser continuation.
- Added atomic server metadata, checksummed rolling world snapshots, local save migration/backups, and autosave.
- Added stable membership-gated shared-world rooms, crop/world-object replication, transactional containers, and recoverable room checkpoints.
- Added Iron Mountains, Frostline, The Deep, Veil Nexus, steam, electricity, purification, rail, late fabrication, and three Veil endings.
- Added smooth follow/look-ahead camera, expanded field console, accessibility preferences, and player/enemy motion feedback.
- Added Phase-4 static contract and persistence end-to-end tests.

## 2026-08-16 — Phase 2 Vertical Slice candidate

- Expanded the First Playable into Green Hollow → Workshop → Ashwick → Foundry Vault → Furnace Saint.
- Added bridge repair, Archivist Mara, Foundry gate, thermal valves and systemic boss encounter.
- Added representative Modern Pixel/Hi-Bit sprite and texture set, pixel-aware materials, dust/steam and Web-compatible post-processing shader.
- Added full Phase 2 settings categories and remappable keybinds; interaction prompts now reflect remapped controls.
- Added `NetworkManager`, co-op room terminal, remote player rendering and server-routed shared progression flags.
- Added Python lobby service with public/private rooms, password hashing/validation, sanitization, rate limiting, active-room cap and signed join tickets.
- Added headless Godot room server, periodic checkpointing, structured logs and Phase 2 Compose topology with resource ceilings/restart policies.
- Added private-room join by room ID/invite code.
- Added `tools/test_lobby_contract.py`; local HTTP contract test passes.
- Extended static/Godot CI contracts to include Phase 2 data, scripts, scenes, resources and world invariants.
- Documented Phase 2 vertical-slice, network authority boundary and runtime acceptance debt.


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

## 2026-08-16 — Autoload lifecycle / CI architecture correction
- Confirmed all required manager autoloads were already present in `project.godot`; the repeated unresolved-identifier errors came from the CI execution model, not missing project configuration.
- Removed `compile_all.gd` / `run_headless_tests.gd` as `godot --script` entry points.
- Added `scenes/tests/ci_runner.tscn` + `scripts/tests/ci_runner.gd`, executed through a normal project scene so autoloads exist before project-aware compile/runtime checks.
- CI now explicitly asserts seven autoload nodes, loads all production scripts and scenes, validates disk JSON and live `DataRegistry`, tests mechanical math, and reproduces the real `boot.tscn` startup path.
- CI PASS markers are now conditioned on an empty failure list; failures exit with code 1.
- Docker and Makefile now use the same normal-scene CI lifecycle.
- Native Windows/Linux export presets now include `*.json` catalogs too, preventing the Web-only JSON export fix from becoming a native-build regression later.

## 2026-08-16 — Phase 2 Godot 4.7 String API hardening

- Fixed the Phase 2 HUD compile failure at `scripts/ui/hud.gd:598`: `String.upper()` was replaced with Godot 4.7 `String.to_upper()`.
- Audited all GDScript files for common Python/JavaScript-style String API leakage (`upper`, `lower`, `startswith`, `endswith`, `strip`, `splitlines`).
- Added a static Godot String API guard to `tools/validate_project.py` so these high-confidence invalid calls fail before Dokploy.
- Re-ran static project validation, lobby contract tests, and Python bytecode compilation successfully.
- Godot/Docker runtime validation remains authoritative and must still pass on Dokploy before this Phase 2 candidate is marked runtime-accepted.

## 2026-08-16 — Phase 3 MVP implementation candidate

- Added Green Hollow/Ashlands/Flooded Basin region model.
- Expanded survival with temperature, fatigue, stamina, stress, morale, body-part injury and infection risk.
- Added handcraft/workshop/industrial crafting tiers.
- Added Ashland wind industry, industrial hammer, powered precision station and basin irrigation pump.
- Added persistent multi-factor farming and settlement barter NPCs.
- Added Phase-3 public-mode security gates, general HTTP rate limiting and Phase-3 Compose profile.
- Extended Godot CI/static validation contracts for Phase-3 scripts/data/world content.

# DECISIONS — IRONVEIL

This file records choices made where the blueprint/master prompt did not fix an exact implementation value.

## 2026-08-16

### D-001 — Project toolchain pin

**Decision:** Pin generated export/deployment configuration to Godot 4.7.1 and `barichello/godot-ci:4.7.1`.

**Reason:** Keep the project, export templates and Docker builder on one exact version instead of mixing minor releases.

---

### D-002 — Phase 1 mechanical baseline

**Decision:** Use these prototype values:

- Water wheel: 32 RPM, 120 Nm.
- Gearbox: 3:1 output speed ratio, 90% efficiency.
- Belt: 1:1, 95% efficiency.
- Mechanical saw: requires 70 RPM and 22 Nm.
- Saw cycle: 2.5 seconds per log, 3 planks per log.

**Reason:** The 3:1 gear makes a low-speed/high-torque wheel reach saw speed while preserving enough torque after predictable transmission losses. Values are prototype tuning, not lore constants.

---

### D-003 — Phase 1 interaction scheme

**Decision:** Use direct keyboard/mouse prototype inputs instead of a full rebind layer in Phase 1.

**Reason:** The master prompt only requires minimal graphics + audio settings in Phase 1. Full key remapping belongs to the complete Phase 2 settings system.

---

### D-004 — Hand-authored prototype region

**Decision:** Use one handcrafted 54×54-unit forest/workshop region built from primitive meshes.

**Reason:** It tests exploration → workshop → machine loop without violating the procedural-world guardrail or making the prototype depend on external art production.

---

### D-005 — Knowledge delivery

**Decision:** Journal discoveries are automatically recorded as Observation / Hypothesis / Confirmation entries triggered by relevant actions.

**Reason:** This directly implements the blueprint's Knowledge Rule and avoids external-wiki dependency.

---

### D-006 — Mechanical simulation ownership

**Decision:** `GameState` owns the `MechanicalNetwork`; world machine nodes are adapters that present/interact with authoritative simulation state.

**Reason:** Keeps simulation independent from visuals and prepares Phase 2 server authority.

---

### D-007 — Chunk system scope

**Decision:** Phase 1 includes tier calculation only (FULL / SIMPLIFIED / STATISTICAL), not actual streaming/unloading.

**Reason:** Provides the architectural seam required by the master prompt while avoiding premature world-streaming complexity.

---

### D-008 — UI SFX delivery

**Decision:** Integrate semantic cue paths for the `mechanical` UI SFX pack and include a deterministic fetch helper; missing cue files are non-fatal.

**Reason:** The implementation environment could not fetch the binary OGG assets, and the game should never fail to boot merely because optional interface audio is absent.

---

### D-009 — Multiplayer boundary

**Decision:** Do not implement room/lobby/network transport in Phase 1. Build simulation state, ticks, chunk interest model and entity adapters so authoritative networking can attach in Phase 2.

**Reason:** This follows the explicit Phase 1/Phase 2 split in the master prompt and protects the First Playable milestone from scope creep.

---

### D-010 — Secondary machine

**Decision:** Include a simple mechanical press as a secondary powered consumer, but keep it outside the required Milestone 1 objective chain.

**Reason:** The Phase 1 system list explicitly mentions a mechanical press; keeping it optional proves graph reuse without expanding the mandatory First Playable loop.

---

### D-011 — Revised multiplayer security boundary

**Decision:** Treat the new master-prompt §4.5 security/scalability requirements as hard future phase gates, but do not create fake lobby/rate-limit/room-server implementations in Phase 1. Document and validate the contract now; implement basic room/player/resource limits in Phase 2 and require the full rate-limit/WSS/checkpoint/logging gate before public room release.

**Reason:** The revised source of truth explicitly places these controls with the multiplayer stack and public-deployment gate. Adding runtime security code before the services exist would violate the no-big-bang/phase-order rules and produce untestable dead infrastructure.


## 2026-08-16 — Web deployment reliability

- The project main scene is now `scenes/boot.tscn`; the actual First Playable remains `scenes/main.tscn`. The boot scene is intentionally tiny and has no gameplay preloads so it can surface parser/startup failures visibly.
- Runtime JSON catalogs remain data-driven JSON for Phase 1, but the Web preset must explicitly include `*.json` because Godot does not treat arbitrary JSON as an automatically exported resource.
- Fixed-name Web artifacts (`index.pck`, `index.wasm`, `index.js`) use revalidation rather than immutable caching. Content-hashed immutable caching can be reconsidered only if the export/deployment pipeline introduces hashed filenames.
- A successful Docker build must run `scripts/tests/run_headless_tests.gd` before Web export so gameplay script parser failures are rejected during Dokploy build rather than discovered only in a browser.

## 2026-08-16 — Modern pixel art is the locked visual target
- Final world presentation is modern pixel art / HD-2D-inspired 2.5D, not raw low-poly blockout.
- Orthographic camera and real 3D mechanical motion remain because they serve readability of automation systems.
- Pixel-authored sprites/textures provide the visual identity; dynamic lighting, real-time shadows, particles and Web-compatible post-processing enhance them.
- Public Web/Compatibility renderer remains the baseline; Forward+-only effects cannot become required visual features.
- Current primitive meshes are explicitly classified as Phase 1 blockout, not final graphics. See `docs/ART_DIRECTION_MODERN_PIXEL.md`.

## 2026-08-16 — Treat Godot parser errors as deployment blockers
- Do not guess GDScript syntax rules in the Python validator. `:=` is valid in default parameter declarations; the previous rule that rejected it was removed.
- The authoritative compile check is Godot itself: Docker first runs `compile_all.gd`, which loads every runtime script independently, then runs the runtime smoke tests, and only exports Web if both gates pass.
- Python validation only catches high-confidence structural/data/deployment regressions and known dangerous Variant-inference patterns.

### D-012 — Dependency-first compile gate

**Decision:** Compile/load runtime scripts dependency-first and load `main.gd` last; do not use a test runner made entirely of compile-time `preload()` constants.

**Reason:** A bad dependency previously made the test runner report only `Could not preload hud.gd`, masking the underlying parser/type error. Independent loading makes the Docker log identify the failing resource directly.

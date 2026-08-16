# IRONVEIL Phase 4 — Production Candidate Contract

**Version:** 1.1.0 source candidate  
**Blueprint:** `IRONVEIL_FINAL_GAME_BLUEPRINT_v2.md`

This source advances the prior three-region MVP into a complete beginning-to-ending Web-game route. “Production candidate” is deliberate: source and service contracts pass in the artifact environment, while the Godot 4.7.1/Web runtime and deployed 2–4-client acceptance gates still require a runtime that is not installed in this environment.

## Player journey implemented

```text
Account / Guest
→ Personal or Shared World
→ Green Hollow survival and first automation
→ Ashwick / Foundry / Furnace Saint
→ Ashlands industry
→ Flooded Basin irrigation and farming
→ Iron Mountains structural engineering
→ Frostline steam, electricity, and purification
→ The Deep relay recovery and rail logistics
→ Veil Nexus
→ Restore / Destroy / Rewrite ending
```

The objective chain contains 33 states and ends only after a Veil decision.

## Phase 4 workstreams

### Presentation

- Product entry screen with IRONVEIL’s industrial editorial language.
- Smooth player-follow isometric camera, velocity look-ahead, rotation smoothing, bounds, zoom, reset, and occlusion.
- Contextual HUD plus full Character, Inventory, Crafting, and Infrastructure console.
- Player and enemy movement/attack/hit motion, regional lighting, particles, machine motion, and distinct regional palettes.
- Accessibility adds reduced motion, high contrast preference, camera-shake preference, text/UI scale, subtitles, and colorblind transforms.

### Persistent account worlds

- Nickname + password registration, sign in, sign out, session restoration, personal worlds, shared worlds, invite codes, member limits, and world list. No email is collected.
- Server-side world and per-player snapshot split.
- Cross-browser continuation through authenticated world loading.
- Atomic metadata writes and checksummed rolling world checkpoints.
- Versioned save envelopes with local backup fallback and legacy Phase-3 migration.
- Autosave every 120 seconds plus manual F5/F9 local checkpoint controls.

### Shared-world authority

- One stable room identity per persistent shared world.
- Membership required before a persistent room ticket is issued.
- Four-player server cap, WSS/public-origin fail-closed configuration, rate limiting, and signed short-lived tickets.
- Server-routed progression, boss damage, player position validation, crop world objects, and transactional shared containers.
- Room snapshots retain flags, boss, crops/world objects, and containers after all players disconnect.
- Atomic room checkpoint plus checksum and previous-checkpoint recovery.

### Full route systems

- Seven traversable main areas: the six blueprint regions plus Veil Nexus endgame space.
- Technology ladder: Primitive → Mechanical → Industrial → Steam → Electrical → Logistics → Veil.
- Electrical generation, prioritized consumers, storage, load shedding, steam pressure, and pollution/purification state.
- Region-specific enemies, resources, specialists, landmarks, hazards, machines, and revisit dependencies.
- Late industrial fabricator recipes for pressure vessels, coils, relays, rail, and gateway interface.
- Restore, Destroy, and Rewrite endings recorded in the internal journal and persistent state.

## Verification commands

```bash
python3 tools/validate_project.py
python3 tools/test_lobby_contract.py
python3 tools/test_public_security_contract.py
python3 tools/test_persistence_contract.py
```

The Docker client build remains the authoritative Godot compile, headless test, and Web export gate:

```bash
docker build --no-cache -t ironveil:1.1.0 .
docker compose --env-file .env.phase3 -f docker-compose.phase3.yml up --build
```

## Runtime acceptance still required before public release

- Godot 4.7.1 imports and compiles every production script.
- Headless CI scene passes all autoload, scene, data, mechanical, and boot assertions.
- Exported Web client loads and the full 33-step route is playable.
- Fresh-account Browser A → save → Browser B → continue test passes against the deployed endpoint.
- Two and four browsers complete shared interactions without divergence; a fifth player is rejected.
- Shared crop/container/machine changes persist across room restart.
- WSS survives a long session through Dokploy/Traefik.
- Forced lobby/room restart recovers the latest valid checkpoint.
- CPU/RAM ceilings and Web frame pacing pass on the target VPS/device profile.

These are deployment/runtime facts and must not be marked passed from static source inspection alone.

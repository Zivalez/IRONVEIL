# PROJECT STATE — IRONVEIL

**Last updated:** 2026-08-16  
**Current phase:** **Phase 4 — full-route production candidate**  
**Scope:** A complete source route now spans account/world selection through all six core regions and the Veil ending. Runtime and deployment acceptance debt remains explicit and is not treated as passed.

## Phase 4 source completed

- Product entry flow: guest, account creation/login/logout, personal/shared world creation, world list, invites, and continue.
- Server-side cross-browser persistence with atomic metadata, checksummed rolling snapshots, membership, and per-player state.
- Stable persistent shared-world room identity, server membership gate, crop/object authority, transactional containers, reconnect state, and crash-safe room checkpoints.
- Final camera model, expanded industrial field console, reduced-motion/high-contrast preferences, and animated character/enemy feedback.
- Iron Mountains, Frostline, The Deep, and Veil Nexus added to the Phase-3 regions.
- Steam, electrical generation/load/storage, pollution purification, rail logistics, Veil gateway, and three endings added.
- Full objective route now contains 33 states from first food to final Veil consequence.

## Implemented in source

### Three-region MVP

- **Green Hollow**: original survival/workshop/Ashwick/Foundry route retained.
- **Ashlands**: distinct climate context, industrial ruins, ore/charcoal, Harker barter, wind mechanical source, workshop metallurgy, powered industrial hammer and precision bench.
- **Flooded Basin**: distinct climate context, water field, irrigation pump, three persistent crop plots, Grower Nia barter and basin enemies/resources.

### Survival / health

- Hunger and thirst retained.
- Body temperature responds to region ambient temperature.
- Fatigue affects movement/stamina recovery.
- Stamina gates sprinting and attacks.
- Stress and morale are persistent survival values.
- Body-part injuries are tracked for head/torso/arms/legs.
- Arm injuries reduce combat output; leg injuries reduce movement.
- Untreated injuries increase infection risk; bandage/salve reduce medical risk.

### Crafting / automation

- Explicit craft-tier enforcement: handcraft → workshop → industrial.
- Workshop recipes: filtration, irrigation hardware and steel bloom.
- Industrial recipes require powered industrial machinery.
- Ashland wind source feeds industrial consumers.
- Industrial hammer automatically processes loaded steel bloom while power requirements are met.
- Precision bench requires live mechanical power.
- Basin irrigation pump requires installed hardware plus mechanical power.

### Farming

Crop growth evaluates water, fertility, sunlight, local region temperature and pests. Irrigation online status automatically offsets water drain, following the design rule that infrastructure should reduce chores rather than create more of them.

### NPC settlement basics

Data-driven NPC definitions include specialization, stated need, barter cost and production offer for Mara/Harker/Nia-level settlement interactions. Full factions/reputation remain Phase 4 scope.

### Security / deployment hardening

- Hard room cap remains 4 players.
- Active-room cap remains configurable.
- Create-room, password-attempt and general HTTP request rate limits exist.
- Names remain sanitized/bounded.
- Public mode enforces WSS browser endpoint, HTTPS exact origin and strong room-token secret.
- CPU/RAM ceilings and restart policies are present in Phase-3 Compose.
- Headless room checkpointing/logging retained.

## Not yet accepted / runtime debt

1. This Phase-3 source has not been executed by a local Godot 4.7.1 binary in the artifact environment; Dokploy Godot CI remains the authoritative compile/runtime gate.
2. Full three-region route has not yet been end-to-end played in the deployed Web build.
3. 2–4-player Phase-2/Phase-3 co-op acceptance remains pending.
4. General inventory, farming, most machine inventory and ordinary enemy state are not yet fully room-server authoritative. Shared progression/boss authority is stronger than general simulation authority.
5. Public WSS/Traefik long-session behavior needs real deployment verification.
6. Forced crash/checkpoint restore and resource-limit stress need real tests.
7. Authored content implements the complete critical route, but the blueprint's 60–100-hour ambition is not claimed without playtime telemetry and a production art/content campaign.
8. Pixel assets remain a coherent development set; the screenshot-level final Hi-Bit art gate requires visual review of an actual export.

## Phase 3 acceptance checklist

- [ ] `IRONVEIL ALL-SCRIPT COMPILE GATE: PASS` on Godot 4.7.1.
- [ ] `IRONVEIL HEADLESS TESTS: PASS`.
- [ ] Web export loads without parser/runtime errors.
- [ ] Phase-2 route still completes without regression.
- [ ] Ashlands region entry/climate/resources function.
- [ ] Harker barter and windmill repair are completable legitimately.
- [ ] Workshop Steel Bloom and powered Steel Beam production work.
- [ ] Precision Component production requires powered industrial station.
- [ ] Flooded Basin region and irrigation header work.
- [ ] Farming responds to all five factors and can reach harvest.
- [ ] Save/load restores injuries, region and crop state.
- [ ] 2 clients complete route without major divergence.
- [ ] 4 clients complete route; fifth is rejected.
- [ ] Public lobby fails closed on non-WSS/weak-secret/wildcard-origin config.
- [ ] Public WSS survives long session through Dokploy/Traefik.
- [ ] Forced room crash restarts and restores checkpoint.
- [ ] CPU/RAM ceilings verified under stress.

## Next

1. Run the Docker/Godot 4.7.1 build gate and capture its PASS markers.
2. Play the full 33-step solo route in the exported Web client.
3. Run Browser A/B persistence, then 2→4-client shared-world and restart recovery acceptance.

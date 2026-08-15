# PROJECT STATE — IRONVEIL

**Last updated:** 2026-08-16  
**Current phase:** **Phase 3 — MVP implementation candidate**  
**Owner override:** Phase 3 implementation was explicitly requested even though the previous Phase-2 multiplayer runtime checklist was not fully proven. That debt remains visible below; it is not treated as passed.

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
7. Phase-3 content is an MVP systems/content candidate; it does **not** honestly provide 15–25 hours of authored content yet.
8. Pixel assets remain representative development art, not final production-quality Hi-Bit art.

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

1. Push candidate to GitHub and let Dokploy run the Godot 4.7.1 CI gate.
2. Fix any engine-level parser/runtime issue before adding further Phase-3 content.
3. Run solo three-region progression, then 2→4 client co-op/security acceptance.

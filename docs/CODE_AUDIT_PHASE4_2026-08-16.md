# IRONVEIL Phase 4 Source Audit

**Date:** 2026-08-16  
**Scope:** final blueprint v2 against the supplied Phase-3 clean candidate.

## Baseline verified before changes

- Archive checksum manifest: all 106 tracked source entries matched.
- Static project validator: passed.
- Lobby contract: passed.
- Public security contract: passed.
- Baseline accurately described itself as a Phase-3 candidate and did not falsely claim runtime acceptance.

## Gap found

The supplied source implemented Green Hollow, Ashlands, Flooded Basin, survival, early/industrial mechanical crafting, farming, NPC barter, a co-op foundation, and hardened public configuration. It did not implement the Phase-4 gates for product entry, authenticated persistent worlds, cross-browser continuation, stable shared-world ownership, shared containers, final regions, steam/electric/rail progression, Veil endgame, or endings.

## Corrections implemented

### Identity and persistence

- Added PBKDF2 password accounts, opaque expiring sessions, personal/shared world records, membership, invite codes, and per-account world limits.
- Added server-side world snapshots split into shared world state and per-player state.
- Added atomic writes, SHA-256 verification, rolling checkpoints, corrupt-checkpoint fallback, local backup, and legacy local-save migration.

### Shared-world integrity

- Persistent worlds receive stable room identities and cannot issue tickets to non-members.
- Empty rooms retain shared state instead of erasing it on the last disconnect.
- Added bounded crop/object replication and idempotent shared-container transactions.
- Extended authoritative progression through the Veil ending and included crops/containers in room checkpoints.

### Game completeness path

- Added Iron Mountains, Frostline, The Deep, and Veil Nexus to the existing three-region route.
- Added structural lift, pressure alloy/vessel, steam pressure, electrical generation/storage/load shedding, purification/pollution, Deep Rail, Veil gateway, and three endings.
- Expanded the objective chain from the Phase-3 ending to a 33-state beginning-to-ending route.
- Added final product menu, persistent world browser, field console, follow/look-ahead camera, animation feedback, and accessibility preferences.

## Security observations

- Persistent room IDs are not sufficient authorization; membership is rechecked before ticket issuance.
- Public mode still fails closed unless the secret is strong, the browser origin is exact HTTPS, and the room endpoint is WSS.
- Shared container operations are transaction-idempotent and quantities are bounded.
- Crop replication accepts only known object prefixes and clamps every numeric field.
- Account and checkpoint request sizes are bounded; world checkpoint payloads cap at 1 MiB.

## Test evidence in this environment

- `IRONVEIL STATIC VALIDATION: PASS`
- `IRONVEIL LOBBY CONTRACT: PASS`
- `IRONVEIL PUBLIC SECURITY CONTRACT: PASS`
- `IRONVEIL PERSISTENCE CONTRACT: PASS`
- Python bytecode compilation: passed.
- All JSON catalogs: parsed successfully.

## Hard acceptance boundary

No Godot or container runtime is installed in the artifact environment. Therefore this audit does not claim that Godot parsed the new GDScript, produced the Web export, or passed real browser/WSS/multi-client/performance/visual acceptance. The Dockerfile contains those authoritative gates and must be run in Dokploy or another Docker-capable environment before public release.

The blueprint's 60–100-hour content target also remains an ambition, not a defensible measured claim. The source now has the complete critical path and systems architecture; authored breadth, final art, balancing, and measured playtime remain production work validated through playtesting rather than source inspection.

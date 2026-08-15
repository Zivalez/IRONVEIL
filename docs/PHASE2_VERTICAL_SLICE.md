# PHASE 2 — Vertical Slice Contract

## Purpose

Phase 2 must prove that IRONVEIL works as a coherent game rather than a collection of prototype systems. The route therefore reuses Phase 1 engineering in meaningful world progression instead of adding unrelated mechanics.

## Route

### 1. Green Hollow

Player starts with survival pressure and field resources. Pixel vegetation/terrain establish the Modern Pixel Art direction while the journal introduces the knowledge-first loop.

### 2. Abandoned Workshop

The player restores:

```text
Water Wheel → Gearbox → Belt → Mechanical Saw
                         └────→ Mechanical Press
```

The saw automatically produces Planks while power thresholds are met. The press converts Scrap into Pressed Plates.

### 3. Ashwick East Bridge

The bridge costs **6 Planks**. This is deliberately not a new crafting menu: the existing automation system solves an exploration problem.

### 4. Ashwick

Archivist Mara explains enough about Foundry machinery to turn an unknown obstacle into a hypothesis. This is a small Phase 2 NPC interaction, not the full faction/NPC simulation reserved for later phases.

### 5. Foundry Gate

Requires:

- 2 Pressed Plates;
- 4 Planks;
- Mara knowledge flag.

This links mechanical automation, exploration and discovery.

### 6. Foundry Vault

One compact dungeon arena with industrial walls, steam, warm machinery lights and two thermal relief valves.

### 7. Furnace Saint

Normal attacks against sealed armor are intentionally ineffective. Opening both relief valves causes rapid thermal contraction and creates a short vulnerability window.

```text
Observe armor resistance
→ infer Foundry pressure is relevant
→ open Valve A + Valve B
→ thermal shock
→ attack exposed joints
→ repeat if window closes
```

This boss tests the blueprint rule that combat can be a systems puzzle rather than a damage sponge.

## Economy sanity

The source validator checks that the placed/log-output economy can cover the critical path:

- enough Scrap for water wheel, crude gear and required plates;
- enough Logs / automatic Plank output to cover bridge + Foundry gate;
- no debug grant required by the intended route.

## Visual acceptance

A Phase 2 screenshot should read as a deliberate Modern Pixel / Hi-Bit hybrid:

- player/NPC/enemies/foliage/pickups use pixel artwork;
- nearest-neighbor filtering remains crisp;
- machines stay readable in 3D;
- lighting/shadows materially affect mood;
- particles and post-processing enhance rather than create the pixel identity.

Current assets are representative development art. Final production art is not a Phase 2 source-generation claim.

## Completion condition

Phase 2 solo content is considered runtime-complete only when a player can reach and defeat Furnace Saint through normal resource acquisition and intended mechanics without external explanation, crash, debug commands or save corruption.

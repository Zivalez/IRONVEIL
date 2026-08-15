# IRONVEIL Phase 3 — MVP Contract

Phase 3 expands the accepted Phase-1/Phase-2 foundation into a three-region MVP while preserving the master-prompt guardrails. The owner explicitly requested Phase 3 implementation before every Phase-2 multiplayer runtime acceptance item was proven; that unresolved acceptance debt remains tracked in `PROJECT_STATE.md` and is not silently waived.

## Regions

1. **Green Hollow** — temperate survival, field resources, workshop, Ashwick settlement and the existing Foundry route.
2. **Ashlands** — heat load, ore/charcoal economy, Machinist Harker, wind-driven mechanical industry, industrial shaping.
3. **Flooded Basin** — cool/wet survival pressure, irrigation infrastructure, crop beds, Grower Nia.

Ashwick/Foundry are subareas/hub content, not counted as extra regions.

## Phase-3 systems

- Survival: hunger, thirst, body temperature, fatigue, stamina, stress, morale, body-part injury state and infection risk.
- Combat: attacks cost stamina; arm injuries reduce damage/handling, leg injuries reduce travel speed.
- Crafting tiers:
  - handcraft: field gear and medicine;
  - workshop: filtration, irrigation hardware, basic metallurgy;
  - industrial: precision parts/structural output requiring powered mechanical infrastructure.
- Mechanical automation: original water-wheel chain plus Ashland wind source, industrial hammer, powered precision bench and irrigation pump.
- Farming: water, fertility, sunlight, temperature and pest pressure. Powered irrigation reduces repeated watering work.
- NPC settlement basics: specialization, need, barter cost and production offer. No full faction/reputation system yet.
- Save state includes survival, injuries, region context and persistent farm/world-object state.

## MVP progression extension

```text
Phase-2 Furnace Saint clear
→ Ashlands survey
→ barter for metallurgy stock
→ repair wind source
→ workshop steel bloom
→ powered industrial shaping
→ Flooded Basin survey
→ connect irrigation hardware
→ powered irrigation
→ plant/grow/harvest crop
→ settlement barter
→ Phase-3 MVP loop complete
```

## Explicitly still deferred

- full electrical simulation;
- weather engineering;
- vehicles;
- large-scale procedural world;
- faction/reputation system;
- Veil endgame;
- 100+ enemy roster.

## Acceptance boundary

Source presence is not completion. Phase 3 is only accepted after Godot CI, browser runtime, save/load, the full three-region route, farming, industrial automation, 2–4-player co-op and the public-security checklist pass on the actual deployment topology.

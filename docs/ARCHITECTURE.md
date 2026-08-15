# IRONVEIL — Phase 1 Architecture

## 1. Authority Boundary

The prototype is deliberately structured as if the simulation could be moved to a dedicated server later.

```text
┌────────────────────────────────────────────────────────────┐
│ Client-facing / presentation                              │
│ Player input · HUD · camera · meshes · animation          │
└────────────────────────────┬───────────────────────────────┘
                             │ intents / interactions
                             ▼
┌────────────────────────────────────────────────────────────┐
│ Gameplay adapters                                          │
│ Player · WaterWheel · GearAssembly · Saw · Press · Pickup │
└────────────────────────────┬───────────────────────────────┘
                             │ mutate/query
                             ▼
┌────────────────────────────────────────────────────────────┐
│ Authoritative-ready simulation                             │
│ GameState · MechanicalNetwork · TickManager · ChunkManager│
└────────────────────────────┬───────────────────────────────┘
                             │ persistence
                             ▼
                    SaveManager / JSON
```

Phase 1 runs all layers in one Godot process, but the simulation does not depend on camera/HUD/render state.

## 2. Data-driven Definitions

`DataRegistry` loads JSON arrays and indexes them by `id`.

Current catalogs:

- `items.json`
- `recipes.json`
- `machines.json`
- `materials.json`
- `enemies.json`
- `biomes.json`
- `technologies.json`

Gameplay scripts query these definitions rather than embedding display names and recipe inputs into every object.

## 3. Tick Tiers

`TickManager` provides independent signals:

```text
simulation_tick  → physics cadence (movement/combat)
machine_tick     → 0.1 sec / 10 Hz
farming_tick     → 1 sec / 1 Hz
economy_tick     → 10 sec / 0.1 Hz
```

The architecture avoids running every simulation system in every object's `_process()`.

## 4. Mechanical Graph

`MechanicalNetwork` is independent from rendering.

```text
water_wheel
  32 RPM / 120 Nm
      │
      ▼
gearbox_3_to_1
  ratio 3.0
  efficiency 0.90
      │
      ▼
belt
  ratio 1.0
  efficiency 0.95
      ├──────────────► mechanical_saw
      └──────────────► mechanical_press
```

Transformer rule:

```text
output_rpm    = input_rpm × ratio
output_torque = (input_torque / ratio) × efficiency
```

Consumer power is true only when received RPM and torque both meet its thresholds.

This gives predictable failure: a disconnected wheel, missing gear or insufficient torque makes the consumer stop for a traceable reason.

## 5. Chunk / LOD Scaffold

`ChunkManager` maps X/Z positions to 24-unit chunks and assigns:

- `FULL` within 1 chunk of a player;
- `SIMPLIFIED` within 3 chunks;
- `STATISTICAL` beyond that.

Phase 1 does not stream world nodes. This scaffold exists so later simulation can choose different update models and Phase 2 networking can broadcast only relevant chunks.

## 6. Save Boundary

`SaveManager` persists:

- player position;
- inventory;
- survival values;
- objective step;
- journal;
- gameplay flags;
- mechanical network nodes/edges;
- machine queues/output via gameplay flags.

Visual transform/state is reconstructed from simulation state after load where applicable.

## 7. Settings

Phase 1 settings include:

- VSync;
- quality preset storage;
- camera zoom;
- UI scale;
- master/music/SFX/ambient volume values.

They are stored in `user://settings.cfg` and reapplied at launch. The full controls/accessibility/network settings set remains a Phase 2 deliverable.

## 8. Web Deployment

```text
Source repository
      │
      ▼
barichello/godot-ci builder
      │ Godot headless Web export
      ▼
/app/build
      │
      ▼
nginx:alpine runtime
      │
      ▼
Dokploy reverse proxy / TLS
```

Web threading is disabled in the Phase 1 export preset. nginx explicitly serves WASM and PCK MIME types and enables compression/caching appropriate for static game assets.

## 9. Phase 2 Networking Seam

Phase 2 should preserve `GameState`/tick/mechanical ownership on the room server and turn client gameplay adapters into input-command/RPC producers.

`ChunkManager` player-interest calculations become the basis for replication interest. Do not make HUD/camera/player-local effects authoritative server state.

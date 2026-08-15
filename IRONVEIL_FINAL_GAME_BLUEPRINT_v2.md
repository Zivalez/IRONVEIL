# IRONVEIL — FINAL GAME BLUEPRINT
**Version:** 2.0 Final Consolidated Blueprint  
**Status:** Source of Truth  
**Genre:** 2.5D Isometric Survival / Engineering RPG / Automation / Knowledge-Based Immersive Simulation  
**Primary Target:** Web (Godot HTML5/Web export via Docker + Dokploy)  
**Secondary Target:** Windows/Linux native builds for development and performance validation  
**Engine:** Godot 4.x  
**Core Principle:** **Mastery through Understanding**

---

# 0. Executive Summary

**IRONVEIL** adalah game 2.5D isometric survival-engineering RPG yang memadukan:

- survival sistemik;
- combat berbasis positioning dan stamina;
- eksplorasi dan discovery;
- crafting bertingkat;
- mechanical automation;
- environmental puzzle;
- knowledge progression;
- persistent shared-world co-op;
- serta visual **Modern Pixel Art / Hi-Bit** dengan teknologi rendering modern.

Progression sejati bukan:

> Level 1 → Level 2 → Level 3

tetapi:

> Tidak tahu → Mengerti → Bisa membuat → Bisa mengoptimalkan → Bisa mengautomasi → Bisa menciptakan sistem baru.

Pemain berkembang karena memahami dunia.

---

# 1. One-Sentence Pitch

> **A modern pixel-art 2.5D survival engineering RPG where players survive, explore, fight, experiment, and build increasingly complex machines in a persistent world whose systems must be understood before they can be mastered.**

---

# 2. Core Fantasy

Pemain memulai sebagai survivor dengan perlengkapan terbatas di dunia pasca-runtuh yang dipenuhi:

- reruntuhan industri;
- mesin lama;
- settlement manusia;
- biome berbahaya;
- creature dengan perilaku sistemik;
- teknologi kuno yang tidak sepenuhnya dipahami;
- dan jaringan misterius bernama **The Veil**.

Pada awal game, pemain:

- mencari air;
- mencari makanan;
- menggunakan alat sederhana;
- menghindari ancaman.

Pada pertengahan game, pemain:

- membangun workshop;
- memperbaiki mesin;
- memproduksi material;
- membuat pertanian;
- membuat jaringan logistik;
- membuka jalur antar-region.

Pada akhir game, pemain:

- mengoperasikan fasilitas industri;
- mengendalikan sistem energi;
- membangun mega-project;
- memahami The Veil;
- dan menentukan masa depan dunia.

---

# 3. Five Core Pillars

Setiap feature baru harus memperkuat minimal satu pillar.

## 3.1 Survival
Dunia berbahaya dan membutuhkan perencanaan.

## 3.2 Discovery
Eksplorasi menghasilkan pengetahuan, bukan hanya loot.

## 3.3 Engineering
Masalah dapat diselesaikan dengan sistem dan infrastructure.

## 3.4 Mastery
Skill utama pemain adalah pemahaman.

## 3.5 World Interaction
Dunia harus bereaksi terhadap tindakan pemain.

---

# 4. Core Design Rules

## 4.1 Interesting Decision Rule

Setiap feature harus menjawab:

> Apakah ini menciptakan keputusan menarik?

Jika hanya menambah chore tanpa keputusan:

**hapus atau sederhanakan.**

---

## 4.2 Complexity Rule

Kompleksitas muncul dari hubungan sistem.

Contoh baik:

```text
Water Pressure
+
Pipe Network
+
Pump Power
+
Storage
```

Contoh buruk:

```text
20 menu upgrade pump
```

---

## 4.3 Knowledge Rule

Informasi menggunakan tiga tingkat:

```text
Observation
↓
Hypothesis
↓
Confirmation
```

Pemain tidak boleh dipaksa menebak tanpa clue.

---

## 4.4 Failure Rule

Kegagalan:

- harus dapat dijelaskan;
- predictable;
- memberikan pengetahuan;
- dicatat oleh journal.

Contoh:

```text
Boiler exploded
↓
Pressure exceeded safe limit
↓
Journal updated
```

---

## 4.5 No-Wiki Dependency

Informasi yang dibutuhkan untuk menyelesaikan game harus tersedia di dalam game.

Wiki eksternal boleh membantu komunitas, tetapi tidak boleh menjadi requirement.

---

# 5. Final Visual Identity

## 5.1 Official Style

Visual resmi IRONVEIL adalah:

> **Modern Pixel Art / Hi-Bit 2.5D with modern rendering**

Inspirasi filosofis dapat berasal dari game pixel-art modern seperti *Sea of Stars*, tetapi IRONVEIL harus memiliki identitas industri sendiri.

Bukan:

> Low-poly game + pixelation filter.

Tetapi:

> Pixel-authored art + pixel-aware 3D machinery + modern light/shadow/VFX.

---

# 6. Pixel Art Rules

Pixel art harus:

- mempunyai intentional pixel clusters;
- menggunakan nearest-neighbor filtering;
- memiliki consistent pixel density;
- memiliki silhouette yang jelas;
- menggunakan palette terkontrol;
- tidak blur ketika camera zoom;
- tidak terlihat seperti AI-generated smooth art yang kemudian dipixelate.

---

# 7. Character Art

Player, NPC, dan enemy utama menggunakan pixel-authored sprites.

Target:

```text
Idle
Walk
Run
Attack
Hit
Death
Interact
Tool Use
```

Minimum directional coverage:

```text
4-direction
```

Preferred:

```text
8-direction
```

Karakter harus terasa hidup walaupun pemain diam.

---

# 8. Machine Art

Machine tetap berupa object 3D.

Alasannya:

- gear harus benar-benar berputar;
- belt harus bergerak;
- shaft harus mempunyai arah;
- machine layout harus terbaca secara fisik;
- player harus bisa melihat hubungan sistem.

Machine menggunakan:

- low-to-medium complexity geometry;
- pixel-authored textures;
- nearest texture filtering;
- limited material palette;
- stylized metallic roughness;
- animated moving components.

---

# 9. World Art

Environment menggunakan kombinasi:

- 3D terrain;
- pixel-textured surfaces;
- Sprite3D foliage;
- pixel props;
- 3D industrial structures;
- animated environmental objects.

Dunia tidak boleh terlihat sebagai:

```text
flat rectangle
+
random props
```

Setiap region harus mempunyai:

- visual hierarchy;
- landmark;
- environmental storytelling;
- foreground;
- midground;
- background;
- ambient motion.

---

# 10. Official Palette Direction

## Green Hollow

- moss green;
- deep forest green;
- muted teal;
- soil brown;
- fog gray.

## Ashlands

- charcoal;
- rust;
- oxidized red;
- dark steel;
- soot gray.

## Flooded Basin

- desaturated cyan;
- swamp green;
- oxidized blue;
- wet concrete;
- pale algae.

## Industrial Technology

- steel;
- brass;
- warm amber;
- furnace orange.

## The Veil

- cold cyan;
- near-white;
- pale blue;
- impossible-clean highlights.

The Veil harus langsung terlihat asing dibanding teknologi manusia.

---

# 11. Lighting

Lighting adalah bagian gameplay dan art direction.

Wajib:

- dynamic directional light;
- realtime shadow;
- dynamic lamps;
- furnace lighting;
- player-local light jika relevan;
- machine indicator lights.

Lighting juga dapat memengaruhi:

- stealth;
- enemy attraction;
- visibility;
- mood.

---

# 12. VFX

Wajib tersedia secara bertahap:

- sparks;
- steam;
- dust;
- smoke;
- embers;
- sawdust;
- water splash;
- hit impact;
- heat distortion ringan;
- environmental particles.

VFX harus pixel-aware dan tidak terlalu smooth sehingga bentrok dengan art.

---

# 13. Post Processing

Compatibility/Web-safe effects:

- subtle color quantization;
- dithering;
- vignette;
- color grading;
- controlled bloom substitute jika kompatibel;
- palette transforms;
- light fog approximation;
- colorblind transforms.

Post-processing tidak boleh menghancurkan readability UI.

---

# 14. Camera — Final Behavior

Camera tidak boleh fixed di tengah map.

Official camera model:

```text
Player-Follow Isometric Camera
```

Fitur wajib:

- smooth follow;
- player-centric framing;
- look-ahead berdasarkan velocity;
- configurable damping;
- zoom;
- rotate 90°;
- bounds;
- obstruction fade/transparency;
- camera reset;
- no sudden snap kecuali scripted event.

Player harus selalu menjadi anchor visual utama.

---

# 15. Camera Feel

Camera follow harus:

- cukup responsif untuk combat;
- cukup lembut untuk eksplorasi;
- tidak membuat motion sickness;
- tidak membuat player hilang di sudut screen.

Boss arena boleh menggunakan temporary framing khusus.

---

# 16. UI/UX Design Direction

UI lama yang bersifat generic prototype **tidak menjadi standard final**.

Official UI direction:

> **Industrial editorial interface with modern spacing, hierarchy, motion, and pixel-aware details.**

Prinsip:

- kuat secara hierarchy;
- minim generic card;
- tidak penuh rounded rectangle;
- tidak memakai gradient random;
- tidak terasa seperti dashboard SaaS;
- tidak memakai excessive border;
- tidak semua informasi ditampilkan bersamaan.

---

# 17. UI Taste Rules

Setiap screen harus melalui:

## Layout
Apakah hierarchy jelas?

## Density
Apakah terlalu padat/kosong?

## Typography
Apakah title/body/status terbaca berbeda?

## Motion
Apakah perubahan state terasa?

## Feedback
Apakah action menghasilkan response?

## Identity
Apakah masih terasa IRONVEIL jika logo dihapus?

Jika jawabannya tidak:

redesign.

---

# 18. HUD

HUD default harus minimal.

Tampilkan hanya informasi penting:

- health;
- stamina;
- hunger/thirst summary;
- interaction prompt;
- contextual objective;
- quick item/tool state;
- machine status hanya ketika relevant.

Detail survival lebih dalam masuk ke Character/Status screen.

---

# 19. Inventory UI

Inventory harus mendukung:

- weight;
- volume;
- equipment;
- item category;
- quick compare;
- context action;
- tooltip yang informatif.

Item visual menggunakan icon pixel-art.

Tidak boleh terasa seperti spreadsheet polos.

---

# 20. Crafting UI

Crafting dibagi:

```text
Handcraft
Workshop
Industrial
```

UI harus menjelaskan:

- requirement;
- machine requirement;
- missing material;
- knowledge requirement;
- production state.

Industrial crafting harus terasa seperti operator panel, bukan menu craft biasa.

---

# 21. Machine UI

Machine mempunyai:

```text
RPM
Torque
Load
Temperature
Efficiency
Condition
```

Tetapi semua tidak harus selalu ditampilkan.

Default:

- status ringkas;
- warning;
- throughput.

Advanced diagnostics dibuka saat inspect.

---

# 22. Animation Standard

Tidak boleh ada major entity yang statis total.

Player:

- idle;
- walk;
- run;
- attack;
- hit;
- interact;
- tool use;
- death.

Enemy:

- idle;
- patrol;
- aggro;
- attack;
- stagger;
- death.

NPC:

- idle variation;
- walk;
- work action;
- talk reaction.

World:

- foliage sway;
- water movement;
- smoke;
- gears;
- belt;
- valves;
- furnaces;
- doors;
- bridges;
- lights.

UI:

- reveal;
- hover;
- focus;
- panel transition;
- objective update;
- success/failure feedback.

---

# 23. World Density Rule

Dunia tidak boleh terasa seperti kotak besar dengan beberapa object.

Setiap playable area harus mempunyai:

```text
Primary Landmark
Secondary Landmark
Traversal Feature
Resource Cluster
Ambient Props
Environmental Story
Threat
Optional Discovery
```

---

# 24. Ambient Life

Untuk menghindari dunia terasa mati:

- small wildlife;
- insects;
- birds;
- moving foliage;
- ambient machine movement;
- smoke columns;
- NPC routines;
- occasional distant events;
- environmental audio layers.

Tidak semuanya harus interactable.

---

# 25. World Structure

Final full game target:

```text
6–8 interconnected regions
```

Region tidak boleh sekadar skin.

Setiap region mempunyai mechanic emphasis sendiri.

---

# 26. Region 1 — Green Hollow

Tema:

> Survival, food, natural resources, first engineering.

Fokus:

- wood;
- herbs;
- farming;
- basic hunting;
- water;
- first workshop.

Key technology:

- water wheel;
- mechanical saw;
- early gearbox.

---

# 27. Region 2 — Ashlands

Tema:

> Industry, metallurgy, scarcity, pollution.

Fokus:

- ore;
- coal/charcoal;
- scrap;
- abandoned industry;
- high temperature.

Technology:

- industrial mechanical processing;
- heavy hammer;
- precision components.

---

# 28. Region 3 — Flooded Basin

Tema:

> Water management, salvage, irrigation.

Fokus:

- pump;
- pipes;
- flooded structures;
- water contamination;
- farming infrastructure.

Technology:

- fluid handling;
- irrigation;
- hydraulic concepts.

---

# 29. Region 4 — Iron Mountains

Tema:

> Mining, verticality, structural engineering.

Fokus:

- deep mines;
- elevators;
- mine carts;
- rare ore;
- structural hazards.

Technology:

- advanced metallurgy;
- rail foundations.

---

# 30. Region 5 — Frostline / High Plateau

Tema:

> Temperature and energy management.

Fokus:

- severe cold;
- insulation;
- fuel;
- thermal systems.

Technology:

- advanced steam;
- thermal engineering.

---

# 31. Region 6 — The Deep

Tema:

> Ancient systems and forbidden infrastructure.

Fokus:

- underground ecosystem;
- geothermal energy;
- Veil technology;
- dangerous machine ruins.

---

# 32. Optional Additional Regions

Possible:

- coastal ruins;
- toxic marsh;
- shattered city;
- Veil anomaly zone.

Only add if they strengthen pillar and do not dilute content quality.

---

# 33. Core Gameplay Loop

```text
Explore
↓
Observe
↓
Collect
↓
Experiment
↓
Understand
↓
Craft
↓
Build
↓
Automate
↓
Expand
↓
Encounter New Problem
↓
Explore Again
```

---

# 34. Survival System

Player state:

- hunger;
- thirst;
- temperature;
- fatigue;
- stamina;
- stress;
- morale;
- wounds;
- infection.

Survival progression should transform:

```text
manual chore
↓
infrastructure problem
↓
automated solution
```

---

# 35. Health System

Body zones:

- head;
- torso;
- left arm;
- right arm;
- left leg;
- right leg.

Injuries:

- cut;
- puncture;
- burn;
- fracture;
- infection;
- poison.

Injury effects must be understandable.

---

# 36. Combat

Combat philosophy:

- positioning;
- stamina;
- spacing;
- timing;
- environment;
- weapon reach;
- enemy pattern recognition.

No button-mashing design.

---

# 37. Enemy Ecology

Enemy has:

- perception;
- behavior;
- habitat;
- weakness;
- relation with environment.

Example:

**Hollow Stalker**

- weak vision;
- high vibration sensitivity;
- can be distracted with noise;
- punishes careless machine use.

---

# 38. Boss Philosophy

Bosses test system understanding.

Example:

**Furnace Saint**

- armor resists normal attacks;
- player manipulates thermal valves;
- thermal shock opens vulnerability;
- environment becomes part of boss fight.

---

# 39. Knowledge Progression

Knowledge categories:

- mechanics;
- metallurgy;
- chemistry;
- agriculture;
- medicine;
- electricity;
- architecture;
- biology;
- Veil studies.

Knowledge is gained through:

- observation;
- books;
- dismantling;
- experimentation;
- NPC;
- environmental clues.

---

# 40. Journal

Journal acts as internal wiki.

Example:

```text
HOLLOW STALKER

Observation:
Reacts to floor vibration.

Hypothesis:
Movement speed may affect detection.

Confirmation:
High-frequency vibration disrupts its tracking.
```

---

# 41. Crafting

Three layers:

## Handcraft

- rope;
- improvised weapon;
- basic tool.

## Workshop

- gear;
- machine component;
- weapon component;
- processed material.

## Industrial

- precision parts;
- advanced alloy;
- large machine components;
- rail components.

---

# 42. Mechanical Automation

Sources:

- hand crank;
- water wheel;
- windmill;
- steam engine;
- later combustion/electric motor.

Network values:

```text
RPM
Torque
Load
Direction
Efficiency
```

---

# 43. Gear System

Gear ratio matters.

Example:

```text
40T → 10T

RPM increases
Torque decreases
```

Player must understand tradeoffs.

---

# 44. Logistics

Transport methods:

- chute;
- belt;
- pipe;
- cart;
- elevator;
- rail.

Late game:

- automated production lines;
- remote resource routes;
- regional logistics.

---

# 45. Fluid System

Fluid properties:

- flow;
- pressure;
- temperature;
- type.

Fluid types:

- water;
- oil;
- fuel;
- steam;
- chemical fluid.

---

# 46. Farming

Factors:

- soil fertility;
- water;
- temperature;
- sunlight;
- pest;
- fertilizer.

Automation:

- irrigation;
- greenhouse;
- pump;
- later automatic harvesting.

---

# 47. Food

Food properties:

- calories;
- hydration;
- nutrition;
- freshness.

Preservation:

- drying;
- salting;
- smoking;
- cold storage.

---

# 48. NPC

NPCs must have:

- profession;
- routine;
- need;
- production;
- trade;
- relationship.

Early NPC system remains simple.

Full faction simulation belongs later.

---

# 49. Settlement

Settlement can evolve due to:

- resources supplied;
- infrastructure repaired;
- threats cleared;
- trade routes opened.

Player can influence settlement development.

---

# 50. Economy

Not all settlements use one universal money.

Supported:

- barter;
- local currency;
- resource contracts.

Trade should reinforce regional dependency.

---

# 51. Quest Philosophy

Quest is a problem, not always a checklist.

Example:

```text
Village water stopped.
```

Possible solutions:

- repair pump;
- construct new route;
- divert water;
- trade/import water.

---

# 52. Persistent World

World state persists.

Save includes:

- world progression;
- structures;
- machines;
- crops;
- bosses;
- bridges;
- gates;
- resource nodes;
- major environmental state;
- NPC settlement state.

---

# 53. Final Co-op Model

Official model:

> **One room = one persistent shared world instance**

Players in the same room do not each own separate copies of the world.

All participants share:

- world structures;
- machine state;
- crop state;
- objective state;
- boss state;
- unlocked traversal;
- settlement state.

---

# 54. Solo World

Solo world is:

- owned by one account;
- persistent server-side;
- can be continued later;
- optionally convertible into shared world if design allows.

---

# 55. Shared Co-op World

Shared world contains:

```text
World ID
Owner
Members
Permissions
World Snapshot
Player Characters
Checkpoint History
```

The owner can:

- continue world;
- invite players;
- manage permissions;
- optionally transfer ownership later.

---

# 56. Player-Specific State

Each player maintains:

- character inventory;
- equipment;
- health;
- status;
- personal position;
- personal journal;
- personal accessibility/settings;
- selected quick slots.

Shared progression and personal progression must be explicitly separated.

---

# 57. Server Authority

Authoritative state must live on server for:

- player position validation;
- world progression;
- machine state;
- boss state;
- shared inventory/container state;
- crop state;
- construction state;
- damage state;
- persistent changes.

Client never becomes source of truth for shared persistent data.

---

# 58. Save Architecture

Primary save:

> **Server-side**

Not browser-local.

Recommended split:

## Relational metadata

PostgreSQL:

- accounts;
- worlds;
- memberships;
- permissions;
- player profiles;
- save metadata;
- room records.

## World snapshot

Serialized versioned world state:

- JSON/binary compressed snapshot;
- persistent volume/object storage;
- checkpoint rotation.

---

# 59. Autosave

World must:

- checkpoint periodically;
- checkpoint on major milestone;
- checkpoint on graceful shutdown;
- retain several previous checkpoints.

Crash recovery loads latest valid checkpoint.

---

# 60. Browser Persistence

Browser storage is only for:

- local settings;
- login/session token;
- cached preferences;
- last selected world.

Never depend on browser storage as the only copy of meaningful progression.

---

# 61. Cross-Browser / Cross-Device Continue

Account-authenticated player must be able to:

```text
Browser A
↓
Play
↓
Logout

Browser B / New PC
↓
Login
↓
World list appears
↓
Continue
```

This is mandatory for production persistence.

---

# 62. Guest Mode

Optional Guest mode:

- instant play;
- local temporary identity;
- not guaranteed cross-device.

Player should be encouraged to upgrade Guest → Account without losing progress.

---

# 63. Authentication

Keep auth simple.

Minimum viable:

- account name/email;
- password or magic-link style login;
- secure session/token;
- logout;
- session refresh.

Do not over-build social features.

---

# 64. World Selection UX

Main menu:

```text
Continue
New World
Shared Worlds
Join World
Settings
Credits
```

Continue should show:

- world name;
- playtime;
- last played;
- region;
- solo/co-op;
- members.

---

# 65. Co-op Continue Flow

Owner:

```text
Shared Worlds
↓
Choose World
↓
Start Session
↓
Room server loads snapshot
↓
Invite members join
```

Members:

```text
Shared Worlds
↓
Available World
↓
Join Session
```

If world session inactive:

display status instead of deleting progress.

---

# 66. Multiplayer Transport

Web client:

```text
HTTPS → Lobby/API
WSS → Room Server
```

Never rely on raw ENet UDP from browser.

---

# 67. Security

Public co-op requires:

- max 4 player/room;
- room capacity limit;
- rate limiting;
- password attempt lockout;
- WSS;
- HTTPS origin validation;
- server-side sanitization;
- resource ceilings;
- restart policy;
- world checkpoint;
- structured logging.

---

# 68. Multiplayer Scaling

Initial:

```text
1 VPS
↓
Lobby
↓
N Room Servers
```

Later:

```text
Lobby
↓
Scheduler
↓
Multiple room hosts
```

Horizontal scaling is not required until actual load demands it.

---

# 69. Main Menu & UX Productization

Phase 4 requires a product-quality entry flow:

```text
Boot
↓
Account / Guest
↓
World Select
↓
Solo / Shared World
↓
Load
↓
Gameplay
```

No direct spawn into world as production default.

---

# 70. Settings Final

## Graphics

- resolution/window mode native;
- quality preset;
- shadows;
- post process;
- UI scale;
- camera zoom;
- VSync native.

## Audio

- master;
- music;
- SFX;
- ambient;
- mute categories.

## Controls

- remappable keys;
- mouse sensitivity;
- controller optional.

## Gameplay

- HUD;
- camera;
- difficulty modifiers;
- interaction preferences.

## Accessibility

- text scale;
- colorblind palettes;
- subtitle;
- reduced motion;
- high contrast;
- camera shake toggle.

## Network

- display name;
- server region if applicable;
- networking diagnostics.

---

# 71. Audio Identity

UI:

- mechanical switches;
- relays;
- subtle interface clicks.

World:

- gear grinding;
- steam release;
- motor hum;
- metal impact;
- forest ambience;
- water;
- distant industrial ambience.

Sound must reinforce world activity.

---

# 72. Music

Music is adaptive.

States:

- exploration;
- danger;
- boss;
- discovery;
- settlement;
- Veil.

Silence is also a tool.

---

# 73. Save Versioning

Every save snapshot requires:

```text
save_version
game_version
world_schema_version
```

Migration system must support older saves when feasible.

Never silently corrupt incompatible save.

---

# 74. Death

Death consequences:

- respawn at safe point;
- dropped/recoverable resources depending mode;
- world state persists;
- knowledge remains.

Avoid excessive grind punishment.

---

# 75. Difficulty

Use world modifiers rather than only Easy/Normal/Hard.

Examples:

- resource scarcity;
- harsh climate;
- enemy aggression;
- injury severity;
- machine wear.

---

# 76. Time

Target day:

```text
30–45 real minutes
```

Subject to playtest.

---

# 77. Seasons

Possible:

- spring;
- summer;
- autumn;
- winter.

Must meaningfully affect systems.

If production cost becomes too high, seasons may ship post-1.0.

---

# 78. Pollution

Industry creates:

- air contamination;
- soil degradation;
- water contamination.

Counter-systems:

- filters;
- scrubbers;
- waste processing.

Pollution must create decisions rather than punishment only.

---

# 79. Main Mystery — The Veil

The Veil is an ancient infrastructure network tied to:

- energy;
- climate;
- communication;
- logistics;
- unknown technologies.

Its collapse contributed to the world's ruin.

---

# 80. Endgame Choice

Possible endings:

## Restore
Bring back the original Veil system.

## Destroy
Prevent centralized infrastructure from returning.

## Rewrite
Alter its rules.

Endings depend on player understanding and infrastructure built across the world.

---

# 81. Mega Projects

Examples:

- continental power grid;
- Deep Rail;
- atmospheric engine;
- Veil Gateway;
- regional purification network.

Mega projects require production chains from multiple regions.

---

# 82. Technology Progression

```text
Primitive
↓
Mechanical
↓
Steam
↓
Electrical
↓
Industrial
↓
Veil Technology
```

---

# 83. Electrical System

Full electrical simulation belongs in late game / Phase 4.

Core:

- generation;
- distribution;
- load;
- storage;
- switch;
- relay;
- motor.

Keep complexity readable.

---

# 84. Logic Automation

Late game:

```text
Sensor
+
Relay
+
Timer
+
Switch
```

Example:

```text
IF Tank < 20%
THEN Pump ON
```

Use visual logic, not coding requirement.

---

# 85. Transportation

Progression:

```text
Walk
↓
Cart
↓
Bicycle / simple vehicle
↓
Motor vehicle
↓
Rail
```

Complex vehicles should not overwhelm core gameplay.

---

# 86. Rail

Rail becomes late-game logistics backbone.

Supports:

- ore;
- fuel;
- bulk components;
- regional supply.

---

# 87. World Streaming

Chunk-based world:

## Near player
Full simulation.

## Far
Simplified.

## Very far
Statistical.

Same system supports multiplayer interest management.

---

# 88. Simulation Tick

Recommended:

```text
Movement / combat: 60 Hz

Machine simulation:
10–20 Hz

Farming:
1 Hz

World economy:
0.1 Hz
```

Never simulate everything every frame.

---

# 89. Data-Driven Architecture

Definitions:

- ItemDefinition
- MaterialDefinition
- RecipeDefinition
- MachineDefinition
- EnemyDefinition
- BiomeDefinition
- TechnologyDefinition
- NPCDefinition
- CropDefinition

Do not hardcode balancing values inside behavior scripts.

---

# 90. Server Architecture

Full production architecture:

```text
Browser Client
     │
     ├── HTTPS ──> API / Lobby / Account
     │
     └── WSS ────> Room Server
                     │
                     ├── World Simulation
                     ├── Player Simulation
                     ├── Save Checkpoint
                     └── Multiplayer Authority
```

Storage:

```text
PostgreSQL
+
Persistent World Snapshot Storage
```

---

# 91. Final Development Phases

## Phase 0 — Setup

- Godot project;
- data-driven foundation;
- docs;
- export setup.

**Status:** complete.

---

## Phase 1 — Prototype

Target:

```text
Forest
↓
Food
↓
Workshop
↓
Water Wheel
↓
Gear
↓
Mechanical Saw
↓
Automatic Plank
```

Purpose:

prove core mechanical loop.

**Status:** completed/runtime proven.

---

## Phase 2 — Vertical Slice

Target:

- forest;
- Ashwick town;
- abandoned workshop;
- Foundry;
- Furnace Saint;
- 2–4 player networking foundation;
- modern pixel visual pipeline.

Purpose:

prove beginning-to-boss vertical slice.

**Status:** implemented; runtime debt must remain documented if not fully multiplayer-accepted.

---

## Phase 3 — MVP

Target:

- Green Hollow;
- Ashlands;
- Flooded Basin;
- extended survival;
- 3-tier crafting;
- farming;
- basic NPC;
- stronger automation;
- co-op security hardening.

Purpose:

prove medium-term gameplay structure.

**Status:** implemented/runtime candidate.

---

## Phase 4 — Full Game / Productionization

Phase 4 is not merely "more content".

It contains:

### Presentation Overhaul
- final follow camera;
- UI redesign;
- animations;
- VFX;
- world density.

### Persistence
- account system;
- server-side saves;
- cross-browser continuation;
- shared persistent worlds.

### Co-op Productization
- authoritative persistent world;
- shared containers/machines;
- member management;
- reliable reconnect.

### Full Content
- 6–8 regions;
- steam;
- electricity;
- factions;
- rail;
- advanced automation;
- The Deep;
- The Veil;
- mega projects;
- endings.

### Polish
- audio;
- accessibility;
- balancing;
- save migration;
- performance.

---

# 92. Phase 4 — Mandatory Presentation Gate

Phase 4 cannot be considered complete if:

- camera still feels fixed;
- UI looks generic;
- world is sparse;
- player/enemy lacks animation;
- primary region still looks like blockout;
- major machines lack visual feedback;
- lighting/VFX feel placeholder.

---

# 93. Phase 4 — Mandatory Persistence Gate

Must support:

```text
Create Account
↓
Create World
↓
Play
↓
Logout
↓
New Browser
↓
Login
↓
Continue Same World
```

Without losing:

- world;
- inventory;
- machines;
- crops;
- progression.

---

# 94. Phase 4 — Mandatory Co-op Gate

Test:

```text
Player A creates shared world
Player B joins
↓
both see same machine
↓
A changes machine
↓
B sees authoritative result
↓
both leave
↓
server stops
↓
world checkpoint persists
↓
next day A starts world again
↓
B rejoins
↓
same world state restored
```

Required.

---

# 95. Phase 4 — Mandatory Visual Gate

A screenshot without HUD must immediately read as:

> intentional modern pixel-art game

Not:

> Godot prototype with pixel filter.

---

# 96. Phase 4 — Mandatory UI Gate

UI must:

- have a recognizable design language;
- maintain spacing scale;
- use meaningful motion;
- avoid default Godot look;
- avoid generic AI dashboard appearance;
- support keyboard/mouse cleanly;
- remain readable at Web resolutions.

---

# 97. Phase 4 — Mandatory World Gate

Each main region requires:

- major landmark;
- safe hub or recovery location;
- traversal identity;
- resource identity;
- at least one environmental mechanic;
- enemy ecosystem;
- ambient life;
- optional discovery;
- meaningful reason to revisit.

---

# 98. Phase 4 — Multiplayer Save Ownership

World types:

## Personal World

Owner:

single account.

Members:

optional guests if conversion allowed.

## Shared World

Owner:

one account or team ownership record.

Members:

multiple accounts.

World progress:

shared.

Character progress:

per-player.

---

# 99. Reconnect Handling

If a player disconnects:

- world remains authoritative;
- character enters safe disconnect state;
- reconnect token/session is allowed;
- client resynchronizes state;
- no duplicate inventory transaction.

---

# 100. Conflict Resolution

Never accept client state wholesale.

Use:

```text
Client Intent
↓
Server Validate
↓
Server Apply
↓
Server Broadcast Result
```

Examples:

- pickup;
- attack;
- machine interaction;
- container transfer;
- crop harvest.

---

# 101. Shared Containers

Shared container operations must be server transactional.

Avoid:

```text
A takes item
B takes same item
```

Result must resolve once.

---

# 102. Save Safety

Use:

- atomic snapshot writes;
- rolling backups;
- schema version;
- checksum;
- graceful migration.

Corrupt save should fall back to previous valid checkpoint.

---

# 103. Anti-Cheat Philosophy

Primary purpose:

protect shared-world integrity.

Do not build invasive anti-cheat.

Server authority is the main defense.

---

# 104. Web Performance

Because Web/WASM is public target:

- limit overdraw;
- use pooled particles;
- use chunk LOD;
- avoid expensive shaders;
- batch sprite/prop use where possible;
- profile machine networks;
- simplify far simulation.

Native build remains performance benchmark.

---

# 105. Modding

Potential post-core feature.

Architecture should remain data-driven to permit future modding.

Do not delay 1.0 for full mod support.

---

# 106. Content Target

Full-game target:

```text
Main progression:
60–100 hours

Deep mastery:
150–200+ hours
```

This is a design ambition, not a release claim until content actually exists.

---

# 107. Replayability

Sources:

- world modifiers;
- different engineering solutions;
- factions;
- resource distribution;
- player specialization;
- different ending choices;
- shared worlds.

---

# 108. Unique Selling Points

## 1. Knowledge-Based Progression

Understanding is power.

## 2. Deep Physical Automation

Machines are visible systems, not menu abstractions.

## 3. Modern Pixel Industrial World

Hi-Bit pixel art with modern light/VFX and physical machinery.

## 4. Systemic Problems

Combat, survival, exploration, and infrastructure interconnect.

## 5. Persistent Shared Worlds

Co-op world can be continued across sessions and browsers.

---

# 109. What IRONVEIL Must Never Become

Do not allow IRONVEIL to become:

- generic survival crafting clone;
- grind simulator;
- empty open world;
- low-poly prototype with pixel filter;
- generic AI UI;
- machine menu simulator;
- MMO-like quest checklist game;
- co-op where each client disagrees about world state;
- browser-only local-save game.

---

# 110. Final Quality Bar

Before calling IRONVEIL "Full Game", these statements must all be true:

### Gameplay
Core loop remains interesting for extended play.

### Engineering
Machines create genuine system interaction.

### Combat
Responsive and readable.

### World
Dense, alive, distinctive.

### Art
Immediately reads as Modern Pixel Art / Hi-Bit.

### Animation
Characters and world visibly move and react.

### UI
Polished, intentional, non-generic.

### Multiplayer
2–4 player shared world is stable.

### Save
Progress survives server restart and browser/device changes.

### Performance
Web build remains playable at intended quality preset.

### Content
Full progression reaches The Veil ending path.

---

# 111. Final Vision

At the beginning:

> The player worries about whether they have enough clean water to survive tonight.

Later:

> The player repairs a water wheel and watches their first mechanical production chain come alive.

Mid-game:

> The player runs farms, workshops, regional production lines, and settlement infrastructure.

Late game:

> Multiple regions are connected through rail, energy, automated production, and shared co-op infrastructure.

Endgame:

> The player stands in front of The Veil—a system once considered incomprehensible—and realizes they finally understand enough to decide what the world should become.

The emotional progression is:

```text
Fear
↓
Curiosity
↓
Understanding
↓
Control
↓
Responsibility
```

That is IRONVEIL.

---

# Appendix A — Final Art Checklist

Before accepting a major area:

- [ ] Consistent pixel density
- [ ] No blurry sprite filtering
- [ ] Player has animation
- [ ] Enemy has animation
- [ ] Ambient motion exists
- [ ] Lighting has purpose
- [ ] Shadows are readable
- [ ] VFX support gameplay
- [ ] Area has landmark
- [ ] Area has environmental storytelling
- [ ] Screenshot looks authored
- [ ] No obvious prototype primitive remains on critical path

---

# Appendix B — Final UI Checklist

- [ ] No generic Godot default panels
- [ ] No arbitrary rounded-card dashboard layout
- [ ] Typography hierarchy is clear
- [ ] Spacing uses consistent scale
- [ ] State changes have motion/feedback
- [ ] Interaction prompt is contextual
- [ ] HUD is not overloaded
- [ ] Machine diagnostics are progressive
- [ ] Inventory is readable
- [ ] Crafting is readable
- [ ] Settings are complete
- [ ] Colorblind mode works
- [ ] Reduced-motion mode works
- [ ] UI scale works in Web

---

# Appendix C — Final Co-op Checklist

- [ ] One room = one shared world
- [ ] Max 4 players enforced server-side
- [ ] Server authoritative world state
- [ ] Shared machine state
- [ ] Shared boss state
- [ ] Shared crop state
- [ ] Shared container state
- [ ] Per-player inventory
- [ ] Reconnect works
- [ ] World restart persists
- [ ] Account continuity works
- [ ] Cross-browser continuation works
- [ ] WSS only for public deployment
- [ ] Rate limit
- [ ] Room capacity
- [ ] Checkpoint
- [ ] Logs
- [ ] Crash recovery

---

# Appendix D — Final Phase 4 Workstreams

## Workstream 1 — Camera & Movement Feel
Player-follow camera, look-ahead, smoothness, occlusion.

## Workstream 2 — UI/UX Redesign
HUD, inventory, crafting, settings, world selection, machine UI.

## Workstream 3 — Modern Pixel Art Pass
Character, NPC, enemy, environment, machine texturing.

## Workstream 4 — Animation & VFX
Characters, machines, world, UI, particles.

## Workstream 5 — World Density
Landmarks, props, life, environmental stories, traversal.

## Workstream 6 — Account & Persistence
Accounts, world list, world save, player save, cross-browser.

## Workstream 7 — Multiplayer Authority
Shared machine/container/world simulation, reconnect, ownership.

## Workstream 8 — Full Regions
Iron Mountains, Frostline, The Deep, additional region if justified.

## Workstream 9 — Late Technology
Steam, electricity, logic, rail, industrial automation.

## Workstream 10 — Factions & Endgame
Faction relationships, The Veil, mega projects, endings.

## Workstream 11 — Audio & Accessibility
World audio, UI SFX, adaptive music, accessibility.

## Workstream 12 — Performance & Release
Profiling, Web optimization, save migration, regression testing.

---

# Appendix E — Scope Control

Feature baru hanya masuk jika:

1. memperkuat core pillar;
2. tidak merusak Web target;
3. bisa dijelaskan secara sistemik;
4. punya gameplay consequence;
5. tidak hanya menambah chore;
6. tidak mengurangi readability;
7. tidak merusak persistent co-op architecture.

---

# Final Statement

**IRONVEIL bukan game tentang mempunyai karakter dengan statistik terbesar.**

IRONVEIL adalah game tentang:

> **memahami sistem yang awalnya terasa mustahil, lalu perlahan menguasainya—sendiri atau bersama pemain lain—hingga dunia yang rusak dapat dibangun kembali berdasarkan keputusan mereka sendiri.**

**Mastery through Understanding.**

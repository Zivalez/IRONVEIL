# GAME BLUEPRINT — Project Codename: **IRONVEIL**

> **Genre:** 2.5D Isometric Survival / Automation / Knowledge RPG / Immersive Simulation  
> **Core Pillars:** Survival, Discovery, Automation, Systems Thinking, Combat Mastery, Environmental Puzzles  
> **Primary Inspiration:** Project Zomboid, Minecraft Create, Soulslike design philosophy, immersive sims, engineering sandbox  
> **Target Experience:** Mudah dipahami di permukaan, sangat sulit dikuasai; progression panjang yang bertumpu pada pengetahuan pemain, bukan hanya level karakter.

---

# 0. High-Level Concept

**IRONVEIL** adalah game 2.5D isometric tentang bertahan hidup dan membangun kembali peradaban di dunia yang telah kehilangan sistem industrinya.

Pemain tidak diberi daftar resep lengkap, objective marker permanen, atau tutorial yang menjelaskan setiap sistem.

Sebaliknya, pemain harus:

- mengamati dunia;
- membaca catatan;
- membongkar mesin;
- menguji material;
- memahami hubungan mekanik;
- menciptakan sistem produksi;
- memecahkan struktur kuno;
- melawan makhluk dan kelompok manusia;
- mempelajari pola dunia;
- dan secara perlahan menemukan cara kerja teknologi yang sudah hilang.

Progression utama bukan:

> Level 1 → Level 2 → Level 3.

Tetapi:

> Tidak tahu → Mengerti → Bisa membuat → Bisa mengoptimalkan → Bisa mengautomasi → Bisa menciptakan sistem baru.

Dengan kata lain:

**pengetahuan pemain adalah level sebenarnya.**

---

# 1. Design Vision

Game harus terasa seperti dunia yang tidak peduli apakah pemain sudah memahami aturannya atau belum.

Tidak ada sistem yang berdiri sendiri.

Contoh:

- air memengaruhi pertanian;
- pertanian memengaruhi makanan;
- makanan memengaruhi stamina;
- stamina memengaruhi combat;
- combat memengaruhi kemampuan eksplorasi;
- eksplorasi membuka material;
- material membuka mesin;
- mesin membuka automation;
- automation membuka produksi massal;
- produksi massal memungkinkan ekspedisi lebih jauh;
- ekspedisi membuka teknologi baru.

Semua sistem membentuk rantai sebab-akibat.

Tujuan desainnya adalah membuat pemain merasa:

> "Aku tidak menang karena karakterku memiliki angka lebih besar. Aku menang karena akhirnya aku memahami dunia ini."

---

# 2. Player Fantasy

Pemain memulai sebagai seseorang yang hampir tidak mengetahui apa pun.

Pada late game, pemain dapat menjadi:

- survivor;
- engineer;
- machinist;
- explorer;
- hunter;
- alchemist;
- logistician;
- tactician;
- architect;
- archaeologist;
- dan system designer.

Bukan melalui pemilihan kelas kaku.

Identitas pemain muncul dari sistem yang mereka pilih untuk kuasai.

---

# 3. Core Gameplay Loop

Loop utama:

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
Encounter New Problems
  ↓
Explore Again
```

Versi lebih detail:

```text
Eksplorasi
→ menemukan lokasi / teknologi / ancaman
→ mengumpulkan resource
→ membawa pulang sampel / komponen
→ melakukan eksperimen
→ menemukan fungsi sebenarnya
→ membangun prototipe
→ mengintegrasikan ke base
→ meningkatkan efisiensi
→ automasi
→ membuka area yang sebelumnya mustahil
→ menemukan masalah lebih besar
```

Loop ini harus terus relevan sampai late game.

---

# 4. World Structure

Dunia menggunakan struktur **semi-open world interconnected regions**.

Bukan satu map kosong raksasa.

Setiap region memiliki:

- kondisi lingkungan;
- material spesifik;
- hazard;
- fauna;
- musuh;
- teknologi;
- lore;
- puzzle;
- dan sistem survival yang berbeda.

Contoh biome:

## 4.1 Ashlands

Wilayah bekas kota industri.

Karakteristik:

- gedung runtuh;
- scrap metal sangat banyak;
- udara berdebu;
- mesin lama;
- jaringan underground;
- monster mekanis.

Resource utama:

- iron scrap;
- copper;
- bearings;
- motors;
- machine parts.

---

## 4.2 Green Hollow

Wilayah hutan lebat.

Fokus:

- kayu;
- tanaman;
- herbal medicine;
- fauna;
- food chain;
- natural chemistry.

Ancaman:

- predator;
- poison plants;
- territorial creatures.

---

## 4.3 Flooded Basin

Daerah perkotaan yang terendam.

Gameplay:

- perahu;
- diving;
- underwater salvage;
- listrik berbahaya;
- water pressure.

Technology reward:

- pumps;
- hydraulic systems;
- water turbines.

---

## 4.4 Iron Mountains

Wilayah pegunungan.

Gameplay:

- mining;
- elevator shafts;
- mine carts;
- rock stability;
- temperature.

Resource:

- high-grade ore;
- rare alloys.

---

## 4.5 The Deep

Zona bawah tanah massive.

Ini bukan sekadar dungeon.

The Deep adalah sebuah dunia kedua.

Memiliki:

- ecosystem sendiri;
- ancient infrastructure;
- geothermal systems;
- unknown machines.

Late-game exploration dimulai dari sini.

---

# 5. World Simulation

Dunia harus terasa seperti sistem aktif.

Contoh simulasi:

### Cuaca

- hujan;
- badai;
- panas;
- kabut;
- salju;
- acid rain pada area tertentu.

Cuaca memengaruhi:

- visibility;
- farming;
- machines;
- travel;
- enemy behavior.

---

### Temperatur

Temperatur tidak hanya memengaruhi karakter.

Juga memengaruhi:

- food preservation;
- engine cooling;
- metallurgy;
- chemical reactions;
- water state.

---

### Electricity

Listrik bukan resource abstrak.

Pemain harus memahami:

```text
Generation
→ Voltage
→ Distribution
→ Load
→ Storage
```

Kesalahan sistem dapat menyebabkan:

- fuse putus;
- motor mati;
- kabel terbakar;
- battery rusak.

---

# 6. Survival System

Survival harus kompleks tetapi tidak menjengkelkan.

Sistem:

- hunger;
- thirst;
- temperature;
- fatigue;
- wounds;
- infection;
- stress;
- morale.

Namun setiap kebutuhan mempunyai solusi sistemik.

Contoh progression air:

```text
Minum sungai
↓
merebus air
↓
filter manual
↓
rain collector
↓
pump
↓
filtration plant
↓
automated water system
```

Progression membuat survival perlahan berubah dari masalah menjadi infrastructure.

---

# 7. Health System

Tidak menggunakan HP sederhana saja.

Tubuh dibagi menjadi:

- head;
- torso;
- left arm;
- right arm;
- left leg;
- right leg.

Cedera memiliki tipe:

- cut;
- fracture;
- burn;
- puncture;
- infection;
- poison.

Efek realistis namun tetap game-friendly.

Contoh:

Fractured arm:

- attack speed turun;
- weapon handling buruk;
- crafting tertentu tidak bisa dilakukan.

---

# 8. Combat Philosophy

Combat menggunakan filosofi soulslike tetapi dari perspektif 2.5D.

Fokus:

- positioning;
- stamina;
- timing;
- weapon reach;
- enemy patterns;
- terrain.

Tidak ada combat button-mashing.

---

# 9. Weapon Categories

Weapon system dibagi berdasarkan fungsi.

## Melee

- knife;
- axe;
- spear;
- sword;
- hammer;
- improvised weapon.

## Ranged

- bows;
- crossbows;
- firearms;
- pneumatic weapons.

## Mechanical

Late game memungkinkan pemain membuat:

- bolt launchers;
- rail-powered devices;
- traps;
- automated turrets.

---

# 10. Weapon Condition

Senjata memiliki:

- material;
- edge;
- durability;
- balance;
- weight.

Contoh:

Dua sword tidak selalu sama.

Satu bisa:

```text
Steel quality: High
Edge: Sharp
Balance: Front-heavy
Durability: 84%
```

Yang lain:

```text
Steel quality: Medium
Edge: Excellent
Balance: Balanced
Durability: 91%
```

---

# 11. Enemy Design

Musuh tidak hanya lebih kuat secara statistik.

Mereka memiliki:

- behavior;
- ecology;
- weaknesses;
- sensory systems;
- combat patterns.

Contoh monster:

## Hollow Stalker

Mendeteksi:

- suara;
- getaran.

Tidak memiliki penglihatan bagus.

Cara mengalahkan:

- berjalan pelan;
- membuat noise distraction;
- jebakan vibration.

Pengetahuan tentang musuh jauh lebih penting daripada damage.

---

# 12. Boss Philosophy

Boss bukan sekadar damage sponge.

Boss adalah ujian terhadap pemahaman sistem.

Contoh:

## The Furnace Saint

Arena adalah pabrik tua.

Boss mempunyai armor hampir tidak bisa ditembus.

Namun arena memiliki:

- valves;
- furnaces;
- conveyor;
- steam pipes.

Pemain dapat:

1. mengaktifkan furnace;
2. memancing boss ke jalur tertentu;
3. meningkatkan pressure;
4. membuka valve;
5. menghancurkan armor boss dengan thermal shock.

Boss fight menjadi puzzle + combat.

---

# 13. Knowledge Progression

Tidak ada skill tree tradisional penuh.

Sebaliknya ada **Knowledge Web**.

Kategori:

- mechanics;
- metallurgy;
- chemistry;
- agriculture;
- medicine;
- electricity;
- architecture;
- biology.

Knowledge diperoleh melalui:

- experimentation;
- books;
- blueprints;
- NPC;
- dismantling;
- observation.

---

# 14. Discovery System

Crafting recipe tidak otomatis tersedia.

Pemain dapat menemukan recipe melalui:

### Reverse Engineering

Membongkar item.

Contoh:

```text
Broken Water Pump
↓
Dismantle
↓
Discover:
- Impeller
- Shaft
- Seal
- Housing
```

Setelah beberapa kali eksperimen:

```text
Knowledge unlocked:
Centrifugal Pump
```

---

# 15. Experimentation System

Pemain memiliki workstation eksperimen.

Input:

- materials;
- components;
- energy;
- tools.

Contoh:

Pemain mencoba:

```text
Copper
+
Zinc
+
Heat
```

Hasil:

```text
Brass discovered
```

Namun game tidak memberi kombinasi sejak awal.

Pemain menemukan melalui clue.

---

# 16. Crafting Philosophy

Crafting dibagi menjadi tiga level.

## Handcraft

Item sederhana.

Contoh:

- rope;
- spear;
- basic tools.

## Workshop

Butuh workstation.

Contoh:

- gears;
- mechanical parts;
- firearm components.

## Industrial

Butuh machine network.

Contoh:

- steel;
- motors;
- precision components.

---

# 17. Mechanical Automation

Sistem ini adalah salah satu core terbesar game.

Terinspirasi Create Mod namun dibuat lebih industrial.

Power awal:

- hand crank;
- water wheel;
- windmill.

Kemudian:

- steam;
- combustion;
- electricity;
- geothermal.

---

# 18. Mechanical Power

Mechanical machines menggunakan:

```text
Torque
RPM
Load
```

Contoh:

Water wheel:

```text
Torque: High
RPM: Low
```

Untuk menggerakkan saw:

```text
Gearbox
→ RPM meningkat
→ Torque menurun
```

Jika load terlalu besar:

```text
Machine stalls
```

---

# 19. Gear System

Gear mempunyai rasio.

Contoh:

```text
Large Gear 40 teeth
Small Gear 10 teeth
```

Ratio:

```text
4:1
```

Pemain harus memahami bagaimana gearbox bekerja.

Namun UI membantu visualisasi.

---

# 20. Conveyor & Logistics

Item dapat dipindahkan melalui:

- belts;
- chutes;
- carts;
- pipes;
- elevators;
- rail systems.

Late game base dapat terlihat seperti factory.

---

# 21. Fluid System

Fluids merupakan sistem fisik.

Jenis:

- water;
- fuel;
- oil;
- steam;
- chemicals.

Memiliki:

- pressure;
- temperature;
- flow rate.

Pipe system bisa mengalami:

- leak;
- pressure loss;
- rupture.

---

# 22. Steam Engineering

Steam menjadi technology tier penting.

Loop:

```text
Fuel
→ Boiler
→ Steam
→ Engine
→ Mechanical Power
```

Namun boiler berbahaya.

Jika:

```text
Pressure > Limit
```

Maka boiler dapat meledak.

---

# 23. Electricity System

Electricity membuka automation tingkat tinggi.

Komponen:

- generators;
- wires;
- switches;
- relays;
- batteries;
- transformers;
- motors.

Pemain dapat membuat logic network sederhana.

---

# 24. Logic Automation

Late game:

```text
Sensors
+
Switches
+
Relays
+
Timers
```

Pemain dapat membuat automation logic.

Contoh:

```text
IF WaterTank < 20%
THEN Pump ON
```

Tidak perlu coding.

Visual logic system.

---

# 25. Farming

Pertanian bukan hanya:

> tanam → tunggu → panen.

Faktor:

- soil;
- water;
- temperature;
- sunlight;
- fertilizer;
- pests.

Automation memungkinkan:

- irrigation;
- greenhouse;
- automated harvesting.

---

# 26. Food System

Food mempunyai:

- calories;
- nutrition;
- freshness.

Preservation:

- drying;
- salting;
- smoking;
- refrigeration.

Late game:

cold storage.

---

# 27. Base Building

Building bukan grid block sederhana.

Pemain dapat membuat:

- foundations;
- walls;
- floors;
- beams;
- roofs.

Structural system ringan digunakan.

Jika struktur terlalu lemah:

```text
collapse
```

---

# 28. Base Evolution

Base berkembang secara visual.

### Tier 0

Campfire + tent.

### Tier 1

Wood shelter.

### Tier 2

Workshop.

### Tier 3

Mechanical factory.

### Tier 4

Electric settlement.

### Tier 5

Industrial complex.

---

# 29. Exploration

Eksplorasi harus menghasilkan pengetahuan.

Reward tidak selalu loot.

Reward bisa:

- map information;
- blueprint;
- clue;
- machine schematic;
- enemy weakness.

---

# 30. Environmental Puzzle

Puzzle harus terintegrasi dunia.

Tidak ada puzzle seperti:

> geser kotak tanpa alasan.

Contoh:

Pemain menemukan lift mati.

Untuk mengaktifkan:

1. mencari generator;
2. memperbaiki belt;
3. mengisi fuel;
4. memperbaiki switchboard;
5. mengatur gear ratio.

Puzzle sebenarnya adalah sistem.

---

# 31. Ancient Machines

Dunia memiliki teknologi pra-collapse.

Pemain sering menemukan mesin tanpa tahu fungsinya.

Contoh:

```
Unknown Device
```

Setelah eksperimen:

```
Device seems to alter magnetic fields.
```

Kemudian:

```
Electromagnetic Stabilizer discovered.
```

---

# 32. Mapping System

Map tidak langsung lengkap.

Pemain harus:

- explore;
- survey;
- menemukan landmark.

Map dapat diberi marker manual.

Late game:

cartography station.

---

# 33. Navigation

Tidak selalu ada GPS marker.

Pemain menggunakan:

- compass;
- landmarks;
- map;
- signs.

---

# 34. Inventory

Inventory menggunakan kombinasi:

- weight;
- volume.

Bukan slot sederhana.

Contoh:

Sebuah anvil kecil tetapi berat.

Cotton besar tetapi ringan.

---

# 35. Transportation

Progression:

```text
Walking
↓
Cart
↓
Bicycle
↓
Animal Cart
↓
Motor Vehicle
↓
Rail System
```

Vehicle memerlukan maintenance.

---

# 36. Rail Network

Late game automation.

Pemain bisa membuat:

- tracks;
- carts;
- signals;
- stations.

Digunakan untuk memindahkan:

- ores;
- materials;
- fuel.

---

# 37. Economy

Tidak semua NPC memakai currency.

Beberapa settlement menggunakan barter.

Contoh:

```
Food Settlement
menginginkan tools
```

```
Mining Settlement
menginginkan food
```

Mendorong trade network.

---

# 38. NPC Settlement

NPC memiliki:

- kebutuhan;
- spesialisasi;
- hubungan;
- produksi.

Pemain dapat:

- membantu;
- berdagang;
- merekrut;
- mengambil alih.

---

# 39. Factions

Contoh:

### The Foundry

Engineer industrialist.

Percaya teknologi adalah solusi.

### Green Choir

Menolak industri berat.

Fokus ecological survival.

### Ashborn

Kelompok raider.

### Archivists

Mengumpulkan knowledge lama.

---

# 40. Reputation

Faction bereaksi terhadap tindakan pemain.

Misalnya:

membangun large industrial factory dapat meningkatkan hubungan dengan Foundry tetapi menurunkan hubungan dengan Green Choir.

---

# 41. Quest Design

Tidak menggunakan banyak quest marker.

Quest berupa masalah.

Contoh:

```
Village water supply stopped.
```

Pemain bebas menyelesaikan:

- repair pump;
- build new well;
- reroute river;
- trade water.

---

# 42. Emergent Gameplay

Sistem harus memungkinkan solusi tidak direncanakan.

Contoh:

Musuh terlalu kuat.

Pemain bisa:

- bertarung;
- membuat trap;
- menjatuhkan struktur;
- membakar area;
- memancing predator lain.

---

# 43. Death System

Death harus mempunyai konsekuensi tetapi tidak terlalu menghukum.

Saat mati:

- karakter kembali ke safe location;
- sebagian equipment tertinggal;
- kondisi dunia tetap.

Knowledge tidak hilang.

Ini penting.

Karena:

**knowledge adalah progression utama.**

---

# 44. Difficulty Philosophy

Tidak menggunakan:

```text
Easy
Normal
Hard
```

Sebagai sistem utama.

Sebaliknya gunakan world modifiers.

Contoh:

- scarce resources;
- harsh climate;
- aggressive enemies;
- permanent injuries;
- machine failures.

---

# 45. Time

Satu hari game kira-kira:

```text
30–45 menit real time
```

Cukup cepat untuk perubahan dunia terasa.

Namun tidak terlalu cepat sehingga survival menjadi chore.

---

# 46. Seasons

Season system:

- spring;
- summer;
- autumn;
- winter.

Mempengaruhi:

- crops;
- animals;
- temperature;
- travel.

---

# 47. Long-Term Progression

Early game:

> survive.

Mid game:

> build systems.

Late game:

> control infrastructure.

End game:

> understand the world.

---

# 48. Main Mystery

Dunia hancur bukan karena perang biasa.

Ada sebuah jaringan teknologi kuno yang disebut:

# **The Veil**

The Veil adalah sistem massive yang dahulu mengatur:

- energy;
- climate;
- logistics;
- communication.

Collapse dimulai ketika jaringan ini gagal.

---

# 49. Main Objective

Game tidak langsung mengatakan:

> Save the world.

Pemain perlahan menemukan bahwa The Veil mungkin dapat diaktifkan kembali.

Namun keputusan akhir:

### Restore The Veil

Mengembalikan sistem lama.

### Destroy The Veil

Membiarkan manusia berkembang secara independen.

### Rewrite The Veil

Mengubah fungsi sistem.

---

# 50. Endgame

Endgame bukan final boss saja.

Untuk mencapai pusat The Veil pemain membutuhkan:

- energy infrastructure;
- transportation network;
- advanced materials;
- faction cooperation;
- knowledge.

Artinya base yang pemain bangun sejak awal relevan sampai akhir.

---

# 51. Endgame Mega Projects

Contoh mega project:

## Continental Power Grid

Menghubungkan beberapa region.

## Deep Rail

Rail network ke The Deep.

## Atmospheric Engine

Mengubah cuaca region.

## Veil Gateway

Membuka area final.

Mega project membutuhkan ratusan komponen.

---

# 52. Replayability

Replay didukung oleh:

- procedural resource distribution;
- faction relationships;
- technology discovery order;
- world events;
- different starting regions.

---

# 53. World Events

Contoh:

- migration;
- storm;
- faction war;
- machine awakening;
- plague;
- resource depletion.

---

# 54. Dynamic Resource Economy

Resource tidak infinite secara sederhana.

Beberapa resource:

- renewable;
- finite;
- recyclable.

Pemain harus belajar recycling.

---

# 55. Pollution

Industry menghasilkan pollution.

Efek:

- soil degradation;
- water contamination;
- creature mutation.

Pemain dapat membangun:

- scrubber;
- filters;
- waste processing.

---

# 56. Sound System

Suara memiliki gameplay.

Noise dari machine dapat:

- menarik musuh;
- mengganggu settlement;
- menutupi suara langkah.

---

# 57. Light

Light juga mekanik.

Beberapa makhluk:

- takut cahaya;
- tertarik cahaya.

Industrial lighting membutuhkan electricity.

---

# 58. Stealth

Stealth dipengaruhi:

- light;
- noise;
- movement;
- environment.

---

# 59. Weather Engineering

Late game technology memungkinkan:

- cloud seeding;
- greenhouse climate;
- atmospheric control.

Tidak langsung mengontrol seluruh cuaca dunia.

---

# 60. Research Philosophy

Tidak ada menu:

```text
Spend 5 Research Points
```

Research membutuhkan:

- samples;
- machine;
- experimentation;
- observations.

---

# 61. Journal

Game otomatis mencatat knowledge.

Contoh:

```
Hollow Stalker

Observed:
- reacts strongly to vibration
- poor visual response
```

Setelah lebih banyak observasi:

```
Weakness:
High-frequency vibration
```

---

# 62. No Wiki Dependency Philosophy

Game harus menyediakan informasi cukup di dalam game.

Namun pemain tetap harus berpikir.

Journal menjadi internal wiki.

---

# 63. UI Philosophy

UI:

- minimal;
- industrial;
- diegetic-inspired;
- tidak penuh icon arcade.

Gunakan:

- diagrams;
- schematics;
- gauges.

---

# 64. Machine UI

Machine tidak hanya memiliki tombol:

```text
ON / OFF
```

Tampilkan:

```text
RPM
Torque
Temperature
Load
Efficiency
```

Namun visual harus jelas.

---

# 65. Camera

2.5D isometric.

Camera:

- rotate 90°;
- zoom;
- floor visibility system.

Bangunan transparan ketika menghalangi pemain.

---

# 66. Art Style

Gaya:

**stylized industrial pixel / low-poly hybrid**

Pilihan bagus:

- environment low-poly;
- pixelated textures;
- baked lighting;
- limited palette.

Hasil:

retro namun modern.

---

# 67. Visual Identity

Dominan:

- charcoal;
- rust;
- steel;
- muted green;
- amber machine lights.

Ancient technology:

- cold cyan;
- white light.

---

# 68. Animation

Tidak perlu animation ultra-realistis.

Fokus:

- readable;
- responsive;
- mechanical.

Machine animation harus memuaskan.

Gear harus benar-benar berputar sesuai hubungan mekanis.

---

# 69. Audio Identity

Gunakan banyak audio mekanik:

- gear grinding;
- steam release;
- motor hum;
- metal impact.

Machine system harus terasa hidup.

---

# 70. Player Progression Summary

Progression:

```text
SURVIVOR
↓
CRAFTSMAN
↓
ENGINEER
↓
INDUSTRIALIST
↓
SYSTEM ARCHITECT
↓
VEIL ENGINEER
```

Namun tidak ditampilkan sebagai class.

---

# 71. Approximate Playtime

Target:

Main progression:

```text
60–100 jam
```

Deep mastery:

```text
200+ jam
```

Sandbox:

praktis unlimited.

---

# 72. Multiplayer Potential

Game sebaiknya didesain single-player first.

Kemudian dapat ditambahkan:

```text
2–4 player cooperative
```

Karena automation akan sangat menarik untuk cooperative.

Contoh pembagian role:

- explorer;
- engineer;
- farmer;
- fighter.

Namun role tidak dikunci.

---

# 73. Modding

Jika memungkinkan, architecture sebaiknya mendukung mod.

Data-driven:

- items;
- recipes;
- machines;
- enemies;
- world generation.

Modding dapat memperpanjang umur game drastis.

---

# 74. Development Scope Strategy

Jangan membuat seluruh sistem sekaligus.

Gunakan vertical slice.

---

# 75. Prototype Phase

Prototype hanya membutuhkan:

### Map

Satu region kecil.

### Systems

- movement;
- inventory;
- basic crafting;
- hunger;
- combat;
- one machine system.

### Automation

- hand crank;
- gear;
- belt;
- mechanical press.

---

# 76. Vertical Slice

Target vertical slice:

```
1–2 jam gameplay
```

Isi:

- small town;
- forest;
- abandoned workshop;
- one dungeon;
- one boss.

Technology progression:

```text
Hand tools
↓
Water wheel
↓
Gear system
↓
Mechanical press
```

Jika loop ini menyenangkan, seluruh game layak dilanjutkan.

---

# 77. MVP

MVP pertama:

World:

```text
3 regions
```

Systems:

- survival;
- combat;
- crafting;
- mechanical automation;
- farming;
- basic NPC.

Playtime:

```text
15–25 hours
```

---

# 78. Full Game

Full game:

```text
6–8 regions
```

Technology tiers:

```text
Primitive
Mechanical
Steam
Electrical
Industrial
Veil Technology
```

---

# 79. Technology Tree

```text
Primitive
│
├── Woodworking
├── Stoneworking
└── Basic Tools
     │
     ▼
Mechanical
│
├── Gears
├── Shafts
├── Belts
└── Water Power
     │
     ▼
Steam
│
├── Boilers
├── Pistons
├── Pressure Systems
└── Steam Engines
     │
     ▼
Electrical
│
├── Generators
├── Batteries
├── Motors
└── Sensors
     │
     ▼
Industrial
│
├── Automation
├── Rail
├── Chemical Processing
└── Advanced Metallurgy
     │
     ▼
Veil Technology
```

---

# 80. Core Design Rule

Semua feature baru harus menjawab:

> Apakah feature ini menciptakan keputusan menarik?

Jika hanya menambah pekerjaan pemain tanpa keputusan:

**hapus atau sederhanakan.**

---

# 81. Complexity Rule

Complexity harus muncul dari hubungan sistem.

Bukan dari menu rumit.

Contoh bagus:

```text
Water pressure
+
pipe network
+
pump power
```

Contoh buruk:

```
20 jenis menu upgrade pump
```

---

# 82. Knowledge Rule

Game tidak boleh menjelaskan semua hal.

Tetapi juga tidak boleh membuat pemain menebak tanpa clue.

Gunakan tiga tingkat informasi:

### Observation

Apa yang pemain lihat.

### Hypothesis

Apa yang mungkin terjadi.

### Confirmation

Knowledge yang sudah terbukti.

---

# 83. Failure Philosophy

Failure adalah bagian progression.

Contoh:

boiler meledak.

Pemain belajar:

```
Pressure terlalu tinggi.
```

Game kemudian menambahkan journal entry.

Failure menjadi pengalaman.

---

# 84. Machine Failure

Machine dapat rusak karena:

- overheating;
- overload;
- poor lubrication;
- bad materials.

Namun failure harus predictable.

Pemain selalu dapat mengetahui penyebabnya.

---

# 85. Maintenance

Late game automation tidak boleh berubah menjadi maintenance simulator.

Solusi:

pemain dapat membuat:

- lubrication systems;
- monitoring sensors;
- maintenance drones / machines.

Dengan demikian complexity meningkat tetapi chores menurun.

---

# 86. Endgame Automation

Late-game player dapat membuat factory yang hampir autonomous.

Input:

```text
Ore
```

Output:

```text
Precision Machine Components
```

Seluruh chain berjalan otomatis.

---

# 87. Why This Game Can Last Long

Longevity tidak berasal dari grind.

Tetapi dari:

- system mastery;
- optimization;
- exploration;
- experimentation;
- emergent solutions;
- mega projects.

Pemain selalu memiliki sesuatu untuk diperbaiki.

---

# 88. Player Stories

Game idealnya menghasilkan cerita seperti:

> "Aku mencoba membuat steam generator tetapi pressure terlalu tinggi dan seluruh workshop meledak."

Atau:

> "Aku membuat jalur kereta sepanjang map hanya untuk membawa iron ore otomatis."

Atau:

> "Boss yang sulit ternyata bisa dikalahkan dengan membuat trap menggunakan mesin pabrik."

Inilah tipe cerita pemain yang membuat game memorable.

---

# 89. Primary Unique Selling Points

## 1. Knowledge-Based Progression

Pengetahuan pemain adalah progression utama.

## 2. Deep Mechanical Automation

Automation menggunakan konsep mekanik yang logis.

## 3. Systems-Driven Survival

Survival dapat diselesaikan melalui engineering.

## 4. Environmental Combat

Dunia dapat digunakan sebagai senjata.

## 5. Integrated Puzzles

Puzzle berasal dari sistem dunia.

---

# 90. One-Sentence Pitch

> **A 2.5D survival engineering RPG where every machine, enemy, environment, and mystery follows systems the player must learn, exploit, and eventually automate.**

---

# 91. Recommended Development Priority

Urutan pengembangan paling aman:

```text
Movement
↓
World Interaction
↓
Inventory
↓
Basic Survival
↓
Crafting
↓
Combat
↓
Mechanical Power
↓
Machine Automation
↓
Exploration
↓
Knowledge System
↓
Enemy Ecology
↓
NPC
↓
Electricity
↓
World Simulation
↓
Late Game Systems
```

Jangan memulai dari:

- faction;
- story besar;
- procedural world;
- multiplayer.

Core mechanical loop harus menyenangkan terlebih dahulu.

---

# 92. Technical Architecture Recommendation

Untuk implementasi teknis, dunia sebaiknya dibuat berbasis **data-driven systems**.

Contoh data:

```text
ItemDefinition
MachineDefinition
MaterialDefinition
RecipeDefinition
EnemyDefinition
BiomeDefinition
TechnologyDefinition
```

Runtime object membaca definisi tersebut.

Keuntungannya:

- mudah balancing;
- mudah modding;
- mudah menambah item;
- tidak hardcoded.

---

# 93. Simulation Update Strategy

Jangan melakukan simulation full setiap frame.

Gunakan beberapa frequency tier.

Contoh:

```text
Combat / movement:
60 ticks/sec

Machine simulation:
10–20 ticks/sec

Farming:
1 tick/sec

World economy:
1 tick/10 sec
```

Ini penting agar factory besar tetap performant.

---

# 94. Machine Network Architecture

Mechanical network dapat dianggap sebagai graph.

```text
Power Source
     │
     ▼
Shaft ─ Gear ─ Gearbox
             │
             ▼
          Machine
```

Setiap node memiliki:

```text
RPM
Torque
Load
Direction
```

Network solver menghitung distribusi power.

---

# 95. Electrical Network Architecture

Mirip mechanical network.

Node:

- generators;
- batteries;
- switches;
- loads.

Network menghitung:

```text
Power Production
Power Demand
Storage
```

---

# 96. Save System

World harus persistent.

Simpan:

- player state;
- base;
- machines;
- items;
- NPC;
- world events.

Machine simulation yang jauh dari player dapat menggunakan simplified simulation.

---

# 97. Performance Strategy

World dibagi menjadi chunks.

Chunk dekat pemain:

```
Full simulation
```

Chunk jauh:

```
Simplified simulation
```

Chunk sangat jauh:

```
Statistical simulation
```

---

# 98. Suggested Engine

Pilihan realistis:

### Godot

Sangat cocok jika:

- indie;
- 2.5D;
- open source;
- sistem custom berat.

### Unity

Cocok jika:

- membutuhkan ecosystem besar;
- asset store;
- tooling mature.

Untuk game sistemik seperti ini, **Godot sangat menarik**, terutama jika ingin kontrol penuh dan scope indie.

---

# 99. First Playable Goal

First playable tidak perlu besar.

Target:

```text
Player bangun di hutan.
↓
Mencari makanan.
↓
Menemukan workshop rusak.
↓
Memperbaiki water wheel.
↓
Menghubungkan gear.
↓
Menyalakan mechanical saw.
↓
Memproduksi plank otomatis.
```

Jika momen:

> "mesin pertamaku akhirnya hidup"

terasa memuaskan, fondasi game sudah benar.

---

# 100. Final Vision

Pada awal permainan:

Pemain takut malam karena tidak mempunyai makanan.

Pada pertengahan permainan:

Pemain membangun factory untuk memproduksi equipment.

Pada late game:

Pemain membuat jaringan:

- rail;
- electricity;
- logistics;
- automation.

Pada akhir permainan:

Pemain berdiri di depan mesin terbesar yang pernah dibuat manusia dan akhirnya memahami:

**apa sebenarnya The Veil.**

Dunia yang awalnya terasa mustahil perlahan berubah menjadi sistem yang dapat dipahami.

Dan itulah inti permainan ini:

> **Mastery through understanding.**

---

# Appendix A — Recommended Working Title Alternatives

Nama **IRONVEIL** hanya codename sementara. Alternatif:

- Ironveil
- Veilworks
- Hollow Engine
- Ash & Gear
- Deepframe
- Relic Forge
- Rustbound
- Last Mechanism
- Greyfoundry
- The Engine Below

---

# Appendix B — Core Pillar Checklist

Feature baru sebaiknya masuk jika memperkuat minimal satu dari lima pillar berikut:

1. **Survival**
2. **Discovery**
3. **Engineering**
4. **Mastery**
5. **World Interaction**

Jika sebuah feature tidak memperkuat salah satu pillar tersebut, pertimbangkan untuk membuangnya.

---

# Appendix C — Scope Guardrails

Agar proyek tidak berubah menjadi terlalu besar sejak awal:

**Jangan implementasikan pada prototype:**

- multiplayer;
- procedural world skala besar;
- puluhan faction;
- kendaraan kompleks;
- full electrical simulation;
- weather engineering;
- The Veil endgame;
- 100+ enemy.

Prototype cukup membuktikan tiga hal:

1. eksplorasi menarik;
2. combat cukup responsif;
3. membangun mesin terasa sangat memuaskan.

Jika tiga hal tersebut berhasil, sistem lain dapat dibangun di atas fondasinya.

#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "project.godot",
    "export_presets.cfg",
    "scenes/boot.tscn",
    "scenes/main.tscn",
    "scenes/tests/ci_runner.tscn",
    "scripts/tests/ci_runner.gd",
    "scripts/game/main.gd",
    "scripts/core/game_state.gd",
    "scripts/core/mechanical_network.gd",
    "scripts/core/settings_manager.gd",
    "Dockerfile",
    "nginx.conf",
    "IRONVEIL_MASTER_PROMPT.md",
    "IRONVEIL_GAME_BLUEPRINT.md",
    "IRONVEIL_FINAL_GAME_BLUEPRINT_v2.md",
    "PROJECT_STATE.md",
    "DECISIONS.md",
    "CHANGELOG.md",
    "docs/PHASE2_NETWORK_ARCHITECTURE.md",
    "docs/PHASE2_SECURITY_SCALABILITY.md",
    "docs/PHASE2_VERTICAL_SLICE.md",
    "docs/DOKPLOY_PHASE2.md",
    "docker-compose.phase2.yml",
    "Dockerfile.room",
    "services/lobby/lobby.py",
    "services/lobby/Dockerfile",
    "tools/test_lobby_contract.py",
    "scenes/server/room_server.tscn",
    "scripts/core/network_manager.gd",
    "scripts/game/boss_furnace_saint.gd",
    "scripts/game/bridge_repair.gd",
    "scripts/game/dungeon_gate.gd",
    "scripts/game/thermal_valve.gd",
    "scripts/game/town_npc.gd",
    "shaders/modern_pixel_post.gdshader",
    "docker-compose.phase3.yml",
    ".env.phase3.example",
    "docs/PHASE3_MVP.md",
    "docs/DOKPLOY_PHASE3.md",
    "scripts/game/region_zone.gd",
    "scripts/game/farm_plot.gd",
    "scripts/game/settlement_npc.gd",
    "scripts/game/workshop_bench.gd",
    "scripts/game/windmill_source.gd",
    "scripts/game/industrial_hammer.gd",
    "scripts/game/industrial_station.gd",
    "scripts/game/irrigation_pump.gd",
    "scripts/core/account_manager.gd",
    "scripts/core/infrastructure_network.gd",
    "scripts/game/engineering_node.gd",
    "scripts/game/late_fabricator.gd",
    "scripts/game/veil_terminal.gd",
    "scripts/ui/title_screen.gd",
    "scripts/ui/mobile_controls.gd",
    "scripts/ui/virtual_joystick.gd",
    "scripts/core/input_profile.gd",
    "assets/branding/ironveil_boot_splash.png",
    "assets/branding/ironveil_icon.png",
    "services/lobby/persistence.py",
    "tools/test_persistence_contract.py",
    "docs/PHASE4_PRODUCTION_CANDIDATE.md",
]

CATALOGS = [
    "items.json",
    "recipes.json",
    "machines.json",
    "materials.json",
    "enemies.json",
    "biomes.json",
    "technologies.json",
    "crops.json",
    "npcs.json",
]

def fail(message: str) -> None:
    print(f"[FAIL] {message}")
    raise SystemExit(1)

def check_required() -> None:
    missing = [p for p in REQUIRED if not (ROOT / p).exists()]
    if missing:
        fail("Missing required files: " + ", ".join(missing))

    # Runtime UI uses the engine default font. Keep player-facing source text
    # ASCII-only so unsupported punctuation cannot render as missing glyphs.
    for script_path in (ROOT / "scripts").rglob("*.gd"):
        text = script_path.read_text(encoding="utf-8")
        if any(ord(character) > 127 for character in text):
            fail(f"Runtime script contains non-ASCII UI text: {script_path.relative_to(ROOT)}")

def load_catalog(name: str) -> dict[str, dict]:
    path = ROOT / "data" / name
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"{name}: invalid JSON: {exc}")
    if not isinstance(value, list):
        fail(f"{name}: root must be an array")
    out = {}
    for record in value:
        if not isinstance(record, dict) or not record.get("id"):
            fail(f"{name}: every record needs an id")
        if record["id"] in out:
            fail(f"{name}: duplicate id {record['id']}")
        out[record["id"]] = record
    return out

def check_data() -> None:
    loaded = {name: load_catalog(name) for name in CATALOGS}
    items = loaded["items.json"]
    for recipe_id, recipe in loaded["recipes.json"].items():
        for side in ("inputs", "outputs"):
            for item_id in recipe.get(side, {}):
                if item_id not in items:
                    fail(f"Recipe {recipe_id} references missing item {item_id}")

    for machine_id, machine in loaded["machines.json"].items():
        for key in ("input_item", "output_item"):
            item_id = machine.get(key)
            if item_id and item_id not in items:
                fail(f"Machine {machine_id} references missing item {item_id}")

    for enemy_id, enemy in loaded["enemies.json"].items():
        for item_id in enemy.get("drops", {}):
            if item_id not in items:
                fail(f"Enemy {enemy_id} drops missing item {item_id}")

    for biome_id, biome in loaded["biomes.json"].items():
        for item_id in biome.get("resources", []):
            if item_id not in items:
                fail(f"Biome {biome_id} references missing resource item {item_id}")

    for crop_id, crop in loaded["crops.json"].items():
        for key in ("seed_item", "harvest_item"):
            item_id = crop.get(key)
            if item_id and item_id not in items:
                fail(f"Crop {crop_id} references missing item {item_id}")

    for npc_id, npc in loaded["npcs.json"].items():
        for side in ("cost", "offer"):
            for item_id in npc.get(side, {}):
                if item_id not in items:
                    fail(f"NPC {npc_id} {side} references missing item {item_id}")

    # Milestone-1 economy sanity: enough fixed resources exist in main.gd to
    # repair the wheel (2 Scrap), craft the gear (2 Scrap), and load the saw.
    main = (ROOT / "scripts/game/main.gd").read_text(encoding="utf-8")
    scrap_spawned = sum(int(q) for q in re.findall(r'_spawn_pickup\("scrap",\s*(\d+)', main))
    log_spawned = sum(int(q) for q in re.findall(r'_spawn_pickup\("log",\s*(\d+)', main))
    berry_spawned = sum(int(q) for q in re.findall(r'_spawn_pickup\("wild_berries",\s*(\d+)', main))
    if scrap_spawned < 4:
        fail("Milestone 1 requires at least 4 Scrap in the region")
    if log_spawned < 1:
        fail("Milestone 1 requires at least 1 Log in the region")
    if berry_spawned < 1:
        fail("Milestone 1 requires at least 1 edible berry in the region")

    # Phase-2 economy: four Logs at 3 Planks each = 12. The bridge and gate
    # consume 10 total, leaving margin. Scrap pays wheel(2)+gear(2)+plates(2).
    if log_spawned * int(loaded["machines.json"]["mechanical_saw"].get("output_count", 0)) < 10:
        fail("Phase 2 requires enough Logs to produce at least 10 Planks")
    if scrap_spawned < 6:
        fail("Phase 2 requires at least 6 Scrap for wheel, gear, and 2 press plates")
    for enemy_id in ("hollow_stalker", "furnace_saint"):
        if enemy_id not in loaded["enemies.json"]:
            fail(f"Phase 2 missing enemy definition: {enemy_id}")
    for biome_id in ("ashwick_town", "foundry_vault"):
        if biome_id not in loaded["biomes.json"]:
            fail(f"Phase 2 missing biome definition: {biome_id}")

def check_mechanical_math() -> None:
    # Mirror the deterministic Phase 1 chain:
    # wheel 32 RPM / 120 Nm -> 3:1 gear @90% -> belt @95% -> saw @92%
    gear_rpm = 32.0 * 3.0
    gear_torque = (120.0 / 3.0) * 0.90
    belt_torque = gear_torque * 0.95
    saw_torque = belt_torque * 0.92
    if not math.isclose(gear_rpm, 96.0):
        fail("Mechanical reference math RPM regression")
    if not math.isclose(gear_torque, 36.0):
        fail("Mechanical reference math torque regression")
    if saw_torque < 22.0:
        fail("Prototype chain no longer supplies the saw minimum torque")

def check_master_prompt_contract() -> None:
    master = (ROOT / "IRONVEIL_MASTER_PROMPT.md").read_text(encoding="utf-8")
    required_terms = [
        "### 4.5 Keamanan & Skalabilitas",
        "Max pemain per room: **4**",
        "Rate limit endpoint create room",
        "Wajib **WSS**",
        "state persistence/checkpoint",
        "Checklist keamanan & skalabilitas §4.5",
    ]
    missing = [term for term in required_terms if term not in master]
    if missing:
        fail("Revised master-prompt security contract missing: " + ", ".join(missing))

    security_doc = (ROOT / "docs/PHASE2_SECURITY_SCALABILITY.md").read_text(encoding="utf-8")
    for term in (
        "Hard maximum: **4 players**",
        "Create-room endpoint",
        "Password attempts",
        "WSS",
        "Checkpoints",
        "Public Multiplayer Release Checklist",
    ):
        if term not in security_doc:
            fail(f"Phase 2 security/scalability contract missing section: {term}")

def check_deploy_contract() -> None:
    presets = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    if 'name="Web"' not in presets or 'variant/thread_support=false' not in presets:
        fail("Web preset must exist with thread support disabled")
    if 'include_filter="*.json"' not in presets:
        fail("Web preset must explicitly include JSON runtime catalogs")
    if 'html/experimental_virtual_keyboard=true' not in presets:
        fail("Web mobile sign-in requires the virtual keyboard bridge")
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    for branding_setting in (
        'config/icon="res://assets/branding/ironveil_icon.png"',
        'boot_splash/image="res://assets/branding/ironveil_boot_splash.png"',
        'boot_splash/show_image=true',
    ):
        if branding_setting not in project:
            fail("Custom IRONVEIL startup branding is incomplete: " + branding_setting)
    dockerfile = (ROOT / "Dockerfile").read_text(encoding="utf-8")
    if "barichello/godot-ci:4.7.1" not in dockerfile:
        fail("Docker builder is not pinned to Godot CI 4.7.1")
    if 'InputProfile="*res://scripts/core/input_profile.gd"' not in project:
        fail("Mobile/desktop input profile autoload is missing")
    mobile = (ROOT / "scripts/ui/mobile_controls.gd").read_text(encoding="utf-8")
    for mobile_term in ("VirtualJoystickScript", "InputEventScreenTouch", "InputEventScreenDrag", "adjust_zoom", "rotate_step"):
        if mobile_term not in mobile:
            fail("Mobile control contract missing: " + mobile_term)
    nginx = (ROOT / "nginx.conf").read_text(encoding="utf-8")
    if "application/wasm wasm;" not in nginx:
        fail("nginx does not explicitly map .wasm")
    if "application/octet-stream pck;" not in nginx:
        fail("nginx does not explicitly map .pck")
    if "immutable" in nginx:
        fail("nginx must not immutable-cache fixed-name Godot index.pck/index.wasm assets")
    if 'run/main_scene="res://scenes/boot.tscn"' not in (ROOT / "project.godot").read_text(encoding="utf-8"):
        fail("Boot diagnostics scene must be the project main scene")
    if "res://scenes/tests/ci_runner.tscn" not in dockerfile:
        fail("Docker build must run the scene-based CI runner before Web export")
    if "--script res://scripts/tests" in dockerfile:
        fail("Docker must not run project tests via --script; autoload lifecycle would be bypassed")
    if dockerfile.index("ci_runner.tscn") > dockerfile.index("--export-release"):
        fail("Scene-based CI gate must run before Web export")

    camera = (ROOT / "scripts/game/camera_rig.gd").read_text(encoding="utf-8")
    if "camera.look_at(Vector3.ZERO" in camera or "look_ahead_seconds: float = 0.0" not in camera:
        fail("Camera must stay centered on the player rig")
    player = (ROOT / "scripts/game/player.gd").read_text(encoding="utf-8")
    if "_outside_playable_world" not in player or "_recover_from_void" not in player:
        fail("Player void/out-of-bounds recovery is missing")

def strip_strings_and_comments(text: str) -> str:
    out = []
    i = 0
    quote = None
    while i < len(text):
        c = text[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
            i += 1
            continue
        if c in ("'", '"'):
            quote = c
            i += 1
            continue
        if c == "#":
            while i < len(text) and text[i] != "\n":
                i += 1
            out.append("\n")
            continue
        out.append(c)
        i += 1
    return "".join(out)

def check_gdscript_structure() -> None:
    stack_pairs = {")": "(", "]": "[", "}": "{"}
    preload_re = re.compile(r'preload\("res://([^"]+)"\)')
    for path in ROOT.rglob("*.gd"):
        text = path.read_text(encoding="utf-8")
        cleaned = strip_strings_and_comments(text)
        stack = []
        for char in cleaned:
            if char in "([{":
                stack.append(char)
            elif char in ")]}":
                if not stack or stack.pop() != stack_pairs[char]:
                    fail(f"{path.relative_to(ROOT)}: unbalanced delimiter")
        if stack:
            fail(f"{path.relative_to(ROOT)}: unbalanced delimiter at EOF")
        for rel in preload_re.findall(text):
            if not (ROOT / rel).exists():
                fail(f"{path.relative_to(ROOT)} preloads missing res://{rel}")

def check_compile_gate_coverage() -> None:
    ci_runner = (ROOT / "scripts/tests/ci_runner.gd").read_text(encoding="utf-8")
    listed = set(re.findall(r'"res://(scripts/[^"\n]+\.gd)"', ci_runner))
    runtime_scripts = {
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / "scripts").rglob("*.gd")
        if "/tests/" not in "/" + path.relative_to(ROOT).as_posix()
    }
    missing = sorted(runtime_scripts - listed)
    if missing:
        fail("ci_runner.gd does not compile-check runtime scripts: " + ", ".join(missing))

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    required_autoloads = {
        "DataRegistry", "TickManager", "ChunkManager", "SettingsManager",
        "NetworkManager", "GameState", "SaveManager", "AudioManager",
    }
    configured = set(re.findall(r'^([A-Za-z_][A-Za-z0-9_]*)="\*res://', project, flags=re.MULTILINE))
    missing_autoloads = sorted(required_autoloads - configured)
    if missing_autoloads:
        fail("project.godot is missing required autoloads: " + ", ".join(missing_autoloads))

    for singleton in required_autoloads:
        if f'"{singleton}"' not in ci_runner:
            fail(f"ci_runner.gd does not assert autoload availability: {singleton}")

    # Dependency order matters for _ready() connections even though all names are
    # globally registered. Keep foundational services before consumers.
    autoload_order = re.findall(r'^([A-Za-z_][A-Za-z0-9_]*)="\*res://', project, flags=re.MULTILINE)
    required_order = [
        "DataRegistry", "TickManager", "ChunkManager", "SettingsManager",
        "NetworkManager", "GameState", "SaveManager", "AudioManager",
    ]
    positions = {name: autoload_order.index(name) for name in required_order if name in autoload_order}
    if positions.get("TickManager", 999) > positions.get("ChunkManager", -1):
        fail("TickManager must autoload before ChunkManager")
    if positions.get("TickManager", 999) > positions.get("GameState", -1):
        fail("TickManager must autoload before GameState")
    if positions.get("DataRegistry", 999) > positions.get("GameState", -1):
        fail("DataRegistry must autoload before GameState")
    if positions.get("GameState", 999) > positions.get("SaveManager", -1):
        fail("GameState must autoload before SaveManager")

def check_project_references() -> None:
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    for rel in re.findall(r'"\*?res://([^"\n]+)"', project):
        if not (ROOT / rel).exists():
            fail(f"project.godot references missing res://{rel}")
    for scene in (ROOT / "scenes").rglob("*.tscn"):
        text = scene.read_text(encoding="utf-8")
        for rel in re.findall(r'path="res://([^"\n]+)"', text):
            if not (ROOT / rel).exists():
                fail(f"{scene.relative_to(ROOT)} references missing res://{rel}")

def check_no_known_variant_inference_hazards() -> None:
    # Godot 4.7 treats inference from Variant as an error by default. This is not
    # a GDScript parser; the Docker compile gate remains authoritative. Catch only
    # high-confidence patterns that caused this project to fail before.
    patterns = [
        re.compile(r'\bvar\s+\w+\s*:=\s*[^\n]*\.pop_(?:front|back)\s*\('),
        re.compile(r'\bvar\s+\w+\s*:=\s*[^\n]*\.get\s*\('),
        re.compile(r'\bvar\s+\w+\s*:=\s*ResourceLoader\.load\s*\('),
        re.compile(r'\bvar\s+\w+\s*:=\s*JSON\.parse_string\s*\('),
    ]
    for path in (ROOT / "scripts").rglob("*.gd"):
        text = strip_strings_and_comments(path.read_text(encoding="utf-8"))
        for pattern in patterns:
            match = pattern.search(text)
            if match:
                line = text.count("\n", 0, match.start()) + 1
                fail(f"{path.relative_to(ROOT)}:{line}: risky Variant inference with :=")


def check_no_foreign_string_api_calls() -> None:
    # Catch common Python/JS string methods that do not exist on Godot String.
    # Godot 4 uses methods such as to_upper(), to_lower(), begins_with(),
    # ends_with(), and strip_edges(). The Godot runtime compile gate remains
    # authoritative; this guard exists to stop obvious API slips earlier.
    invalid_methods = {
        "upper": "to_upper",
        "lower": "to_lower",
        "startswith": "begins_with",
        "endswith": "ends_with",
        "strip": "strip_edges",
        "splitlines": "split with a newline delimiter",
    }
    pattern = re.compile(r"\.([A-Za-z_][A-Za-z0-9_]*)\s*\(")
    for path in (ROOT / "scripts").rglob("*.gd"):
        text = strip_strings_and_comments(path.read_text(encoding="utf-8"))
        for match in pattern.finditer(text):
            method = match.group(1)
            if method not in invalid_methods:
                continue
            line = text.count("\n", 0, match.start()) + 1
            fail(
                f"{path.relative_to(ROOT)}:{line}: unsupported Godot String-style call .{method}(); "
                f"use {invalid_methods[method]} instead"
            )

def check_phase2_contract() -> None:
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    if 'NetworkManager="*res://scripts/core/network_manager.gd"' not in project:
        fail("Phase 2 requires NetworkManager autoload")

    game_state = (ROOT / "scripts/core/game_state.gd").read_text(encoding="utf-8")
    if "VERTICAL SLICE COMPLETE" not in game_state or "Furnace Saint" not in game_state:
        fail("Phase-2 objective chain is incomplete")
    if game_state.count('"') < 10:
        fail("GameState appears unexpectedly truncated")

    main_gd = (ROOT / "scripts/game/main.gd").read_text(encoding="utf-8")
    for term in ("BridgeRepairScript", "TownNPCScript", "DungeonGateScript", "ThermalValveScript", "BossScript", "PostProcessScript"):
        if term not in main_gd:
            fail(f"Phase-2 world is missing {term}")

    pixel_dir = ROOT / "assets/pixel"
    pixel_assets = list(pixel_dir.glob("*.png"))
    if len(pixel_assets) < 20:
        fail("Modern-pixel vertical slice requires at least 20 authored pixel assets")
    for asset in ("player.png", "tree.png", "furnace_saint.png", "rust_metal.png", "town_stone.png", "spark.png", "steam.png"):
        if not (pixel_dir / asset).exists():
            fail(f"Missing Phase-2 pixel asset: {asset}")

    network = (ROOT / "scripts/core/network_manager.gd").read_text(encoding="utf-8")
    for term in ("MAX_PLAYERS_PER_ROOM := 4", "WebSocketMultiplayerPeer", "auth_callback", "ROOM_TOKEN_SECRET", "constant_time_compare", "_request_boss_damage", "_peer_is_near", "BOSS_DAMAGE_MIN_INTERVAL_MS"):
        if term not in network:
            fail(f"NetworkManager missing required multiplayer/security primitive: {term}")

    lobby = (ROOT / "services/lobby/lobby.py").read_text(encoding="utf-8")
    for term in ("MAX_PLAYERS_PER_ROOM = 4", "CREATE_ROOM_LIMIT_PER_MINUTE", "PASSWORD_ATTEMPTS_PER_MINUTE", "pbkdf2_hmac", "issue_ticket"):
        if term not in lobby:
            fail(f"Lobby service missing security control: {term}")

    compose = (ROOT / "docker-compose.phase2.yml").read_text(encoding="utf-8")
    for term in ("room-server:", "lobby:", "mem_limit:", "cpus:", "restart: unless-stopped", "ROOM_TOKEN_SECRET:?Set ROOM_TOKEN_SECRET"):
        if term not in compose:
            fail(f"Phase-2 compose missing infrastructure control: {term}")

    gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
    dockerignore = (ROOT / ".dockerignore").read_text(encoding="utf-8")
    if ".env.*" not in gitignore or "!.env.phase2.example" not in gitignore:
        fail("Phase-2 secret env files must be ignored while preserving the example file")
    if ".env.*" not in dockerignore:
        fail("Phase-2 secret env files must not enter Docker build context")

    hud = (ROOT / "scripts/ui/hud.gd").read_text(encoding="utf-8")
    for term in ("CO-OP ROOM TERMINAL", "Room ID / invite code", "Colorblind palette", "_begin_rebind", "boss_health_bar"):
        if term not in hud:
            fail(f"Phase-2 HUD/settings missing capability: {term}")


def check_phase3_contract() -> None:
    biomes = load_catalog("biomes.json")
    regions = [rid for rid, record in biomes.items() if record.get("region") is True]
    for required in ("green_hollow", "ashlands", "flooded_basin"):
        if required not in regions:
            fail(f"Phase 3 missing required region: {required}")

    recipes = load_catalog("recipes.json")
    tiers = {str(record.get("tier", "")) for record in recipes.values()}
    if not {"handcraft", "workshop", "industrial"}.issubset(tiers):
        fail("Phase 3 requires handcraft/workshop/industrial recipe tiers")

    game_state = (ROOT / "scripts/core/game_state.gd").read_text(encoding="utf-8")
    for term in ("body_temperature", "fatigue", "stress", "morale", "infection_risk", "injuries", "CRAFT_TIER_RANK"):
        if term not in game_state:
            fail(f"Phase 3 survival/crafting state missing: {term}")

    farm = (ROOT / "scripts/game/farm_plot.gd").read_text(encoding="utf-8")
    for term in ("water", "fertility", "sunlight", "pests", "preferred_temperature"):
        if term not in farm:
            fail(f"Phase 3 farming factor missing: {term}")

    main_gd = (ROOT / "scripts/game/main.gd").read_text(encoding="utf-8")
    for term in ("_build_ashlands_region", "_build_flooded_basin_region", "WindmillSourceScript", "IndustrialHammerScript", "IrrigationPumpScript", "FarmPlotScript"):
        if term not in main_gd:
            fail(f"Phase 3 world/system missing: {term}")

    lobby = (ROOT / "services/lobby/lobby.py").read_text(encoding="utf-8")
    for term in ("PUBLIC_MODE", "GENERAL_REQUEST_LIMIT_PER_MINUTE", 'PUBLIC_WS_URL.startswith("wss://")', 'ALLOWED_ORIGIN.startswith("https://")'):
        if term not in lobby:
            fail(f"Phase 3 public security gate missing: {term}")

    compose = (ROOT / "docker-compose.phase3.yml").read_text(encoding="utf-8")
    for term in ("PUBLIC_MODE", "mem_limit:", "cpus:", "restart: unless-stopped", "GENERAL_REQUEST_LIMIT_PER_MINUTE"):
        if term not in compose:
            fail(f"Phase 3 compose missing deployment control: {term}")

    gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
    dockerignore = (ROOT / ".dockerignore").read_text(encoding="utf-8")
    if "!.env.phase3.example" not in gitignore or "!.env.phase3.example" not in dockerignore:
        fail("Phase 3 example env must remain available while real env files stay ignored")


def check_phase4_contract() -> None:
    biomes = load_catalog("biomes.json")
    regions = {rid for rid, record in biomes.items() if record.get("region") is True}
    required_regions = {"green_hollow", "ashlands", "flooded_basin", "iron_mountains", "frostline", "the_deep", "veil_nexus"}
    if not required_regions.issubset(regions):
        fail("Phase 4 missing final regions: " + ", ".join(sorted(required_regions - regions)))

    technologies = load_catalog("technologies.json")
    for technology in ("primitive", "mechanical", "industrial", "steam", "electrical", "logistics", "veil"):
        if technology not in technologies:
            fail(f"Phase 4 technology progression missing: {technology}")

    game_state = (ROOT / "scripts/core/game_state.gd").read_text(encoding="utf-8")
    for term in ("mine_lift_online", "regional_purifier_online", "deep_rail_online", "veil_gateway_online", "veil_ending", "game_complete"):
        if term not in game_state:
            fail(f"Phase 4 progression state missing: {term}")

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    for autoload in ("AccountManager", "InfrastructureNetwork"):
        if autoload not in project:
            fail(f"Phase 4 autoload missing: {autoload}")

    lobby = (ROOT / "services/lobby/lobby.py").read_text(encoding="utf-8")
    persistence = (ROOT / "services/lobby/persistence.py").read_text(encoding="utf-8")
    for route in ('/auth/register', '/auth/login', '/worlds', '/checkpoint', '/invite'):
        if route not in lobby:
            fail(f"Phase 4 API route missing: {route}")
    for term in ("pbkdf2_hmac", "_atomic_json", "checksum", "MAX_CHECKPOINTS", "join_invite"):
        if term not in persistence:
            fail(f"Phase 4 persistence safety missing: {term}")

    network = (ROOT / "scripts/core/network_manager.gd").read_text(encoding="utf-8")
    for term in ("_request_world_object", "_request_container_transfer", "_room_world_objects", "_room_containers"):
        if term not in network:
            fail(f"Phase 4 authoritative shared state missing: {term}")

    title = (ROOT / "scripts/ui/title_screen.gd").read_text(encoding="utf-8")
    for term in ("ACCOUNT GATEWAY", "WORLD ARCHIVE", "MY WORLDS", "CREATE WORLD", "JOIN BY CODE"):
        if term not in title:
            fail(f"Phase 4 product entry flow missing: {term}")


def main() -> None:
    check_required()
    check_data()
    check_mechanical_math()
    check_master_prompt_contract()
    check_deploy_contract()
    check_gdscript_structure()
    check_compile_gate_coverage()
    check_project_references()
    check_no_known_variant_inference_hazards()
    check_no_foreign_string_api_calls()
    check_phase2_contract()
    check_phase3_contract()
    check_phase4_contract()
    print("IRONVEIL STATIC VALIDATION: PASS")
    print("Note: static validation does not replace running Godot or docker build.")

if __name__ == "__main__":
    main()

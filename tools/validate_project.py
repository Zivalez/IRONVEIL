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
    "scenes/main.tscn",
    "scripts/game/main.gd",
    "scripts/core/game_state.gd",
    "scripts/core/mechanical_network.gd",
    "scripts/core/settings_manager.gd",
    "Dockerfile",
    "nginx.conf",
    "IRONVEIL_MASTER_PROMPT.md",
    "IRONVEIL_GAME_BLUEPRINT.md",
    "PROJECT_STATE.md",
    "DECISIONS.md",
    "CHANGELOG.md",
    "docs/PHASE2_NETWORK_ARCHITECTURE.md",
    "docs/PHASE2_SECURITY_SCALABILITY.md",
]

CATALOGS = [
    "items.json",
    "recipes.json",
    "machines.json",
    "materials.json",
    "enemies.json",
    "biomes.json",
    "technologies.json",
]

def fail(message: str) -> None:
    print(f"[FAIL] {message}")
    raise SystemExit(1)

def check_required() -> None:
    missing = [p for p in REQUIRED if not (ROOT / p).exists()]
    if missing:
        fail("Missing required files: " + ", ".join(missing))

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
    dockerfile = (ROOT / "Dockerfile").read_text(encoding="utf-8")
    if "barichello/godot-ci:4.7.1" not in dockerfile:
        fail("Docker builder is not pinned to Godot CI 4.7.1")
    nginx = (ROOT / "nginx.conf").read_text(encoding="utf-8")
    if "application/wasm wasm;" not in nginx:
        fail("nginx does not explicitly map .wasm")
    if "application/octet-stream pck;" not in nginx:
        fail("nginx does not explicitly map .pck")

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

def main() -> None:
    check_required()
    check_data()
    check_mechanical_math()
    check_master_prompt_contract()
    check_deploy_contract()
    check_gdscript_structure()
    print("IRONVEIL STATIC VALIDATION: PASS")
    print("Note: static validation does not replace running Godot or docker build.")

if __name__ == "__main__":
    main()

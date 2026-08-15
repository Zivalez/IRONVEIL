#!/usr/bin/env python3
"""Fetch the exact CC0 UI SFX mechanical Ogg cues used by IRONVEIL."""
from pathlib import Path
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "audio" / "ui" / "mechanical"
BASE = "https://raw.githubusercontent.com/romainsimon/uisfx/main/packages/uisfx/sounds/mechanical"
FILES = [
    "hover.ogg",
    "press.ogg",
    "complete.ogg",
    "error.ogg",
    "toggle-on.ogg",
    "toggle-off.ogg",
    "open.ogg",
    "close.ogg",
]

DEST.mkdir(parents=True, exist_ok=True)
for name in FILES:
    url = f"{BASE}/{name}"
    print(f"Fetching {url}")
    with urlopen(url, timeout=30) as response:
        (DEST / name).write_bytes(response.read())

print("UI SFX mechanical cues installed.")

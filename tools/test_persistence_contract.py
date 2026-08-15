#!/usr/bin/env python3
"""End-to-end account, cross-browser world, invite, and checkpoint test."""
from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def request(url: str, method: str = "GET", payload: dict | None = None, token: str = "") -> tuple[int, dict]:
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, method=method)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=3) as response:
            return response.status, json.loads(response.read())
    except urllib.error.HTTPError as exc:
        return exc.code, json.loads(exc.read())


def main() -> int:
    port = free_port()
    with tempfile.TemporaryDirectory(prefix="ironveil-persistence-") as temp:
        temp_path = Path(temp)
        env = os.environ | {
            "LOBBY_HOST": "127.0.0.1",
            "LOBBY_PORT": str(port),
            "LOBBY_DATA_PATH": str(temp_path / "rooms.json"),
            "WORLD_STORE_PATH": str(temp_path / "persistence.json"),
            "WORLD_SNAPSHOT_PATH": str(temp_path / "worlds"),
            "ROOM_TOKEN_SECRET": "persistence-contract-secret",
            "PUBLIC_WS_URL": "ws://127.0.0.1:9081",
            "ALLOWED_ORIGIN": "http://127.0.0.1:8080",
        }
        process = subprocess.Popen([sys.executable, str(ROOT / "services/lobby/lobby.py")], cwd=ROOT, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        base = f"http://127.0.0.1:{port}"
        try:
            for _ in range(60):
                try:
                    if request(base + "/health")[0] == 200:
                        break
                except OSError:
                    time.sleep(0.1)
            else:
                raise AssertionError("server did not become ready")

            status, registered = request(base + "/auth/register", "POST", {"nickname": "OwnerEngineer", "password": "correct-horse-ironveil"})
            assert status == 201, registered
            assert registered["account"]["nickname"] == "OwnerEngineer" and "email" not in registered["account"]
            owner_token = registered["session_token"]
            assert request(base + "/auth/me", token=owner_token)[0] == 200
            status, refreshed = request(base + "/auth/refresh", "POST", {}, owner_token)
            assert status == 200 and refreshed["session_token"] != owner_token
            owner_token = refreshed["session_token"]
            assert request(base + "/auth/register", "POST", {"nickname": "ownerengineer", "password": "correct-horse-ironveil"})[0] == 400

            status, world = request(base + "/worlds", "POST", {"name": "Copper Meridian", "kind": "shared", "modifiers": {"harsh_climate": True}}, owner_token)
            assert status == 201, world
            world_id = world["id"]
            snapshot = {"world": {"flags": {"mine_lift_online": True}}, "player": {"inventory": {"steel_beam": 2}, "position": [210, 1, 0]}}
            status, _ = request(base + f"/worlds/{world_id}/checkpoint", "POST", {"snapshot": snapshot, "region": "iron_mountains", "playtime_delta": 900}, owner_token)
            assert status == 200

            # A fresh login represents a second browser and must see the same server world.
            status, login = request(base + "/auth/login", "POST", {"nickname": "OWNERENGINEER", "password": "correct-horse-ironveil"})
            assert status == 200
            browser_b_token = login["session_token"]
            status, listing = request(base + "/worlds", token=browser_b_token)
            assert status == 200 and listing["worlds"][0]["region"] == "iron_mountains"
            status, loaded = request(base + f"/worlds/{world_id}", token=browser_b_token)
            assert status == 200
            assert loaded["snapshot"]["world"]["flags"]["mine_lift_online"] is True
            assert loaded["snapshot"]["players"]

            status, invite = request(base + f"/worlds/{world_id}/invite", "POST", {}, owner_token)
            assert status == 201
            status, member = request(base + "/auth/register", "POST", {"nickname": "BasinMechanic", "password": "another-strong-password"})
            assert status == 201
            status, joined = request(base + "/worlds/join", "POST", {"invite_code": invite["invite_code"]}, member["session_token"])
            assert status == 200 and joined["members"] == 2

            status, owner_room = request(base + "/rooms", "POST", {"name": "ignored", "password": "", "public": True, "player_name": "Owner", "world_id": world_id}, owner_token)
            assert status == 201 and owner_room["room_id"] == "w-" + world_id
            status, _ = request(base + f"/rooms/{owner_room['room_id']}/join", "POST", {"password": "", "player_name": "Intruder"})
            assert status == 401
            status, member_room = request(base + "/rooms", "POST", {"name": "ignored", "password": "", "public": True, "player_name": "Member", "world_id": world_id}, member["session_token"])
            assert status == 200 and member_room["room_id"] == owner_room["room_id"]

            # Tamper newest checkpoint; loader must roll back to the previous valid one.
            checkpoint_dir = temp_path / "worlds" / world_id
            newest = sorted(checkpoint_dir.glob("checkpoint-*.json"))[-1]
            newest.write_text('{"checksum":"bad","snapshot":{"world":{"corrupt":true}}}', encoding="utf-8")
            status, recovered = request(base + f"/worlds/{world_id}", token=owner_token)
            assert status == 200 and "corrupt" not in recovered["snapshot"].get("world", {})

            print("IRONVEIL PERSISTENCE CONTRACT: PASS")
            return 0
        except (AssertionError, OSError, ValueError) as exc:
            print("IRONVEIL PERSISTENCE CONTRACT: FAIL", repr(exc))
            return 1
        finally:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Local contract test for the Phase-2 lobby service (standard library only)."""
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


def request(url: str, method: str = "GET", payload: dict | None = None) -> tuple[int, dict]:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=2.0) as response:
            return response.status, json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        return exc.code, json.loads(exc.read().decode("utf-8"))


def main() -> int:
    port = free_port()
    with tempfile.TemporaryDirectory(prefix="ironveil-lobby-") as tmp:
        env = os.environ.copy()
        env.update({
            "LOBBY_HOST": "127.0.0.1",
            "LOBBY_PORT": str(port),
            "MAX_ACTIVE_ROOMS": "2",
            "CREATE_ROOM_LIMIT_PER_MINUTE": "10",
            "PASSWORD_ATTEMPTS_PER_MINUTE": "2",
            "ROOM_TOKEN_SECRET": "phase2-contract-test-secret",
            "PUBLIC_WS_URL": "ws://127.0.0.1:19081",
            "ALLOWED_ORIGIN": "http://127.0.0.1:18080",
            "LOBBY_DATA_PATH": str(Path(tmp) / "rooms.json"),
        })
        proc = subprocess.Popen(
            [sys.executable, str(ROOT / "services/lobby/lobby.py")],
            cwd=ROOT,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        base = f"http://127.0.0.1:{port}"
        try:
            deadline = time.time() + 6.0
            while time.time() < deadline:
                try:
                    status, health = request(base + "/health")
                    if status == 200 and health.get("ok") is True:
                        break
                except OSError:
                    pass
                time.sleep(0.1)
            else:
                print("LOBBY CONTRACT: server did not become healthy")
                return 1

            status, created = request(base + "/rooms", "POST", {
                "name": "Ashwick <> Test",
                "password": "gear123",
                "public": True,
                "player_name": "Scout<script>",
            })
            assert status == 201, (status, created)
            room_id = str(created.get("room_id", ""))
            assert room_id and created.get("join_token") and created.get("websocket_url")

            status, listed = request(base + "/rooms")
            assert status == 200
            rooms = listed.get("rooms", [])
            assert len(rooms) == 1
            assert rooms[0]["name"] == "Ashwick Test"
            assert rooms[0]["requires_password"] is True
            assert "password" not in rooms[0]
            assert rooms[0]["max_players"] == 4

            for expected in (403, 403, 429):
                status, _ = request(base + f"/rooms/{room_id}/join", "POST", {
                    "password": "wrong",
                    "player_name": "Peer",
                })
                assert status == expected, status

            status, joined = request(base + f"/rooms/{room_id}/join", "POST", {
                "password": "gear123",
                "player_name": "Peer",
            })
            assert status == 200, (status, joined)
            assert joined.get("room_id") == room_id and joined.get("join_token")

            # Creator reservation + three joins fills the hard four-player room cap.
            for player_name in ("Peer2", "Peer3"):
                status, _ = request(base + f"/rooms/{room_id}/join", "POST", {
                    "password": "gear123",
                    "player_name": player_name,
                })
                assert status == 200, status
            status, room_full = request(base + f"/rooms/{room_id}/join", "POST", {
                "password": "gear123",
                "player_name": "Peer5",
            })
            assert status == 409 and room_full.get("reason") == "room_full", (status, room_full)

            # Private rooms must not be listed but remain joinable by room ID.
            status, private = request(base + "/rooms", "POST", {
                "name": "Private Foundry",
                "password": "",
                "public": False,
                "player_name": "Host",
            })
            assert status == 201, (status, private)
            private_id = private["room_id"]
            status, listed = request(base + "/rooms")
            assert all(room.get("id") != private_id for room in listed.get("rooms", []))
            status, _ = request(base + f"/rooms/{private_id}/join", "POST", {
                "password": "",
                "player_name": "Invitee",
            })
            assert status == 200

            # Capacity is already 2 rooms; a third create is rejected.
            status, full = request(base + "/rooms", "POST", {
                "name": "Overflow",
                "password": "",
                "public": True,
                "player_name": "Host",
            })
            assert status == 503 and full.get("reason") == "server_capacity_reached", (status, full)

            print("IRONVEIL LOBBY CONTRACT: PASS")
            return 0
        except (AssertionError, OSError, ValueError) as exc:
            print("IRONVEIL LOBBY CONTRACT: FAIL", repr(exc))
            return 1
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=2.0)
            except subprocess.TimeoutExpired:
                proc.kill()


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""IRONVEIL Phase-2 lobby/matchmaking service.

Standard-library only on purpose: small attack surface, no framework dependency,
and easy to run in Dokploy/Docker. It creates short-lived HMAC join tickets that
are validated independently by the authoritative Godot room server.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import re
import secrets
import threading
import time
import uuid
from collections import defaultdict, deque
from dataclasses import dataclass, asdict
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

HOST = os.getenv("LOBBY_HOST", "0.0.0.0")
PORT = int(os.getenv("LOBBY_PORT", "8080"))
MAX_ACTIVE_ROOMS = max(1, int(os.getenv("MAX_ACTIVE_ROOMS", "16")))
MAX_PLAYERS_PER_ROOM = 4
CREATE_ROOM_LIMIT_PER_MINUTE = max(1, int(os.getenv("CREATE_ROOM_LIMIT_PER_MINUTE", "6")))
PASSWORD_ATTEMPTS_PER_MINUTE = max(1, int(os.getenv("PASSWORD_ATTEMPTS_PER_MINUTE", "5")))
PUBLIC_WS_URL = os.getenv("PUBLIC_WS_URL", "ws://127.0.0.1:9081")
TOKEN_SECRET = os.getenv("ROOM_TOKEN_SECRET", "development-only-change-me")
ALLOWED_ORIGIN = os.getenv("ALLOWED_ORIGIN", "*")
ROOM_TTL_SECONDS = max(300, int(os.getenv("ROOM_TTL_SECONDS", "21600")))
RESERVATION_TTL_SECONDS = max(15, int(os.getenv("RESERVATION_TTL_SECONDS", "120")))
DATA_PATH = Path(os.getenv("LOBBY_DATA_PATH", "/data/rooms.json"))

SAFE_NAME_RE = re.compile(r"[^A-Za-z0-9 _\-\.]")


def now() -> int:
    return int(time.time())


def clean_name(value: Any, fallback: str, max_len: int = 32) -> str:
    text = str(value or "").strip()
    text = SAFE_NAME_RE.sub("", text)
    text = re.sub(r"\s+", " ", text)[:max_len].strip()
    return text or fallback


def password_hash(password: str, salt: bytes | None = None) -> tuple[str, str]:
    if salt is None:
        salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 120_000)
    return base64.urlsafe_b64encode(salt).decode().rstrip("="), base64.urlsafe_b64encode(digest).decode().rstrip("=")


def verify_password(password: str, salt_b64: str, digest_b64: str) -> bool:
    if not digest_b64:
        return password == ""
    salt = base64.urlsafe_b64decode(salt_b64 + "=" * (-len(salt_b64) % 4))
    _, candidate = password_hash(password, salt)
    return hmac.compare_digest(candidate, digest_b64)


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def issue_ticket(room_id: str, player_name: str, ttl: int = 180) -> str:
    payload = {
        "room_id": room_id,
        "player_name": clean_name(player_name, "Survivor", 24),
        "exp": now() + ttl,
        "nonce": secrets.token_hex(8),
    }
    payload_b64 = b64url(json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8"))
    signature = hmac.new(TOKEN_SECRET.encode("utf-8"), payload_b64.encode("ascii"), hashlib.sha256).digest()
    return payload_b64 + "." + b64url(signature)


@dataclass
class Room:
    id: str
    name: str
    public: bool
    password_salt: str
    password_digest: str
    created_at: int
    last_activity: int
    reservations: dict[str, int]

    @property
    def requires_password(self) -> bool:
        return bool(self.password_digest)

    def active_reservations(self) -> int:
        cutoff = now() - RESERVATION_TTL_SECONDS
        self.reservations = {key: ts for key, ts in self.reservations.items() if ts >= cutoff}
        return len(self.reservations)

    def public_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "public": self.public,
            "requires_password": self.requires_password,
            "players": min(self.active_reservations(), MAX_PLAYERS_PER_ROOM),
            "max_players": MAX_PLAYERS_PER_ROOM,
        }


class LobbyState:
    def __init__(self) -> None:
        self.lock = threading.RLock()
        self.rooms: dict[str, Room] = {}
        self.create_attempts: dict[str, deque[int]] = defaultdict(deque)
        self.password_attempts: dict[tuple[str, str], deque[int]] = defaultdict(deque)
        self.load()

    def cleanup(self) -> None:
        with self.lock:
            cutoff = now() - ROOM_TTL_SECONDS
            stale = [rid for rid, room in self.rooms.items() if room.last_activity < cutoff]
            for rid in stale:
                self.rooms.pop(rid, None)
            for room in self.rooms.values():
                room.active_reservations()
            if stale:
                self.save()

    def allow_rate(self, bucket: deque[int], limit: int, window: int = 60) -> bool:
        cutoff = now() - window
        while bucket and bucket[0] <= cutoff:
            bucket.popleft()
        if len(bucket) >= limit:
            return False
        bucket.append(now())
        return True

    def save(self) -> None:
        try:
            DATA_PATH.parent.mkdir(parents=True, exist_ok=True)
            data = [asdict(room) for room in self.rooms.values()]
            DATA_PATH.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
        except OSError as exc:
            print(json.dumps({"event": "lobby_persist_error", "error": str(exc)}), flush=True)

    def load(self) -> None:
        if not DATA_PATH.exists():
            return
        try:
            raw = json.loads(DATA_PATH.read_text(encoding="utf-8"))
            for item in raw if isinstance(raw, list) else []:
                room = Room(**item)
                self.rooms[room.id] = room
        except Exception as exc:  # corrupted state must not prevent boot
            print(json.dumps({"event": "lobby_restore_error", "error": str(exc)}), flush=True)


STATE = LobbyState()


class Handler(BaseHTTPRequestHandler):
    server_version = "IRONVEILLobby/0.2"

    def log_message(self, fmt: str, *args: Any) -> None:
        # Avoid BaseHTTPRequestHandler's verbose free-form log. Structured logs below
        # never include plaintext room passwords.
        print(json.dumps({"event": "http", "remote": self.client_address[0], "message": fmt % args}), flush=True)

    def end_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", ALLOWED_ORIGIN)
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_OPTIONS(self) -> None:
        self.send_response(HTTPStatus.NO_CONTENT)
        self.end_headers()

    def do_GET(self) -> None:
        STATE.cleanup()
        path = urlparse(self.path).path
        if path == "/health":
            self.json_response(HTTPStatus.OK, {"ok": True, "rooms": len(STATE.rooms), "max_rooms": MAX_ACTIVE_ROOMS})
            return
        if path == "/rooms":
            with STATE.lock:
                rooms = [room.public_dict() for room in STATE.rooms.values() if room.public]
            rooms.sort(key=lambda room: room["name"].lower())
            self.json_response(HTTPStatus.OK, {"rooms": rooms})
            return
        self.json_response(HTTPStatus.NOT_FOUND, {"message": "not_found"})

    def do_POST(self) -> None:
        STATE.cleanup()
        path = urlparse(self.path).path
        if path == "/rooms":
            self.create_room()
            return
        match = re.fullmatch(r"/rooms/([A-Za-z0-9\-]+)/join", path)
        if match:
            self.join_room(match.group(1))
            return
        self.json_response(HTTPStatus.NOT_FOUND, {"message": "not_found"})

    def create_room(self) -> None:
        ip = self.client_address[0]
        with STATE.lock:
            if not STATE.allow_rate(STATE.create_attempts[ip], CREATE_ROOM_LIMIT_PER_MINUTE):
                self.json_response(HTTPStatus.TOO_MANY_REQUESTS, {"message": "Too many room creation attempts. Try again later."})
                return
            if len(STATE.rooms) >= MAX_ACTIVE_ROOMS:
                self.json_response(HTTPStatus.SERVICE_UNAVAILABLE, {"message": "Server full, try again later.", "reason": "server_capacity_reached"})
                return
            body = self.read_json()
            if body is None:
                return
            room_name = clean_name(body.get("name"), "Field Room", 32)
            player_name = clean_name(body.get("player_name"), "Survivor", 24)
            password = str(body.get("password") or "")[:64]
            is_public = bool(body.get("public", True))
            salt, digest = ("", "") if not password else password_hash(password)
            room_id = uuid.uuid4().hex[:12]
            reservation_id = secrets.token_hex(8)
            room = Room(
                id=room_id,
                name=room_name,
                public=is_public,
                password_salt=salt,
                password_digest=digest,
                created_at=now(),
                last_activity=now(),
                reservations={reservation_id: now()},
            )
            STATE.rooms[room_id] = room
            STATE.save()
        self.structured("room_created", {"room_id": room_id, "public": is_public})
        self.ticket_response(room_id, player_name, HTTPStatus.CREATED)

    def join_room(self, room_id: str) -> None:
        ip = self.client_address[0]
        body = self.read_json()
        if body is None:
            return
        password = str(body.get("password") or "")[:64]
        player_name = clean_name(body.get("player_name"), "Survivor", 24)
        with STATE.lock:
            room = STATE.rooms.get(room_id)
            if room is None:
                self.json_response(HTTPStatus.NOT_FOUND, {"message": "Room not found."})
                return
            if room.active_reservations() >= MAX_PLAYERS_PER_ROOM:
                self.json_response(HTTPStatus.CONFLICT, {"message": "Room is full.", "reason": "room_full"})
                return
            if room.requires_password and not verify_password(password, room.password_salt, room.password_digest):
                bucket = STATE.password_attempts[(ip, room_id)]
                if not STATE.allow_rate(bucket, PASSWORD_ATTEMPTS_PER_MINUTE):
                    self.structured("password_lockout", {"room_id": room_id, "remote": ip})
                    self.json_response(HTTPStatus.TOO_MANY_REQUESTS, {"message": "Too many incorrect password attempts. Try again later."})
                    return
                self.structured("password_failed", {"room_id": room_id, "remote": ip})
                self.json_response(HTTPStatus.FORBIDDEN, {"message": "Incorrect room password."})
                return
            reservation_id = secrets.token_hex(8)
            room.reservations[reservation_id] = now()
            room.last_activity = now()
            STATE.save()
        self.ticket_response(room_id, player_name, HTTPStatus.OK)

    def ticket_response(self, room_id: str, player_name: str, status: HTTPStatus) -> None:
        self.json_response(status, {
            "room_id": room_id,
            "join_token": issue_ticket(room_id, player_name),
            "websocket_url": PUBLIC_WS_URL,
        })

    def read_json(self) -> dict[str, Any] | None:
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length <= 0 or length > 8192:
            self.json_response(HTTPStatus.BAD_REQUEST, {"message": "Invalid request body."})
            return None
        try:
            parsed = json.loads(self.rfile.read(length).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            self.json_response(HTTPStatus.BAD_REQUEST, {"message": "Invalid JSON."})
            return None
        if not isinstance(parsed, dict):
            self.json_response(HTTPStatus.BAD_REQUEST, {"message": "JSON object required."})
            return None
        return parsed

    def json_response(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def structured(self, event: str, data: dict[str, Any]) -> None:
        print(json.dumps({"event": event, "unix": now(), "data": data}, separators=(",", ":")), flush=True)


def main() -> None:
    print(json.dumps({
        "event": "lobby_started",
        "host": HOST,
        "port": PORT,
        "max_rooms": MAX_ACTIVE_ROOMS,
        "max_players_per_room": MAX_PLAYERS_PER_ROOM,
        "public_ws_url": PUBLIC_WS_URL,
        "warning": "ROOM_TOKEN_SECRET is using development default" if TOKEN_SECRET == "development-only-change-me" else "",
    }), flush=True)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()

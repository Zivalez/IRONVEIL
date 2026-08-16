"""Server-side accounts and versioned world snapshots for IRONVEIL.

The implementation intentionally uses only Python's standard library so the
same small container can serve accounts, lobby discovery, and durable worlds.
State is protected by a process lock, written atomically, checksummed, and
rotated.  A later PostgreSQL adapter can preserve this public API unchanged.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import os
import re
import secrets
import threading
import time
import uuid
from pathlib import Path
from typing import Any


NICKNAME_RE = re.compile(r"^[A-Za-z0-9_.-]{3,24}$")
WORLD_NAME_RE = re.compile(r"[^A-Za-z0-9 _\-\.]", re.ASCII)
SESSION_TTL_SECONDS = max(3600, int(os.getenv("SESSION_TTL_SECONDS", "2592000")))
MAX_WORLDS_PER_ACCOUNT = max(1, int(os.getenv("MAX_WORLDS_PER_ACCOUNT", "12")))
MAX_CHECKPOINTS = max(2, int(os.getenv("MAX_WORLD_CHECKPOINTS", "5")))
STORE_PATH = Path(os.getenv("WORLD_STORE_PATH", "/data/persistence.json"))
SNAPSHOT_ROOT = Path(os.getenv("WORLD_SNAPSHOT_PATH", "/data/worlds"))


class StoreError(ValueError):
    """A safe error that may be returned to the client."""


def _now() -> int:
    return int(time.time())


def _password_hash(password: str, salt: bytes | None = None) -> tuple[str, str]:
    salt = salt or secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 210_000)
    return salt.hex(), digest.hex()


def _clean_world_name(value: Any) -> str:
    name = WORLD_NAME_RE.sub("", str(value or "").strip())
    name = re.sub(r"\s+", " ", name)[:48].strip()
    return name or "Unnamed World"


def _atomic_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(data, separators=(",", ":"), sort_keys=True), encoding="utf-8")
    os.replace(temporary, path)


class PersistenceStore:
    def __init__(self) -> None:
        self.lock = threading.RLock()
        self.accounts: dict[str, dict[str, Any]] = {}
        self.sessions: dict[str, dict[str, Any]] = {}
        self.worlds: dict[str, dict[str, Any]] = {}
        self.invites: dict[str, dict[str, Any]] = {}
        self._load()

    def _load(self) -> None:
        if not STORE_PATH.exists():
            return
        try:
            raw = json.loads(STORE_PATH.read_text(encoding="utf-8"))
            if isinstance(raw, dict):
                self.accounts = dict(raw.get("accounts", {}))
                self.sessions = dict(raw.get("sessions", {}))
                self.worlds = dict(raw.get("worlds", {}))
                self.invites = dict(raw.get("invites", {}))
                # Phase 4.1 removes email identity. Preserve existing accounts by
                # deriving a unique nickname from their old display name.
                used: set[str] = set()
                migrated = False
                for account in self.accounts.values():
                    nickname = str(account.get("nickname", "")).strip()
                    if not NICKNAME_RE.fullmatch(nickname):
                        seed = re.sub(r"[^A-Za-z0-9_.-]", "", str(account.get("display_name", "Survivor")))[:20]
                        seed = seed if len(seed) >= 3 else "Survivor"
                        nickname = seed
                        suffix = 2
                        while nickname.lower() in used:
                            nickname = "%s%d" % (seed[:20], suffix)
                            suffix += 1
                        migrated = True
                    account["nickname"] = nickname
                    account["display_name"] = nickname
                    if "email" in account:
                        account.pop("email", None)
                        migrated = True
                    used.add(nickname.lower())
                if migrated:
                    self._save()
        except Exception as exc:
            print(json.dumps({"event": "persistence_restore_error", "error": str(exc)}), flush=True)

    def _save(self) -> None:
        _atomic_json(STORE_PATH, {
            "schema_version": 2,
            "accounts": self.accounts,
            "sessions": self.sessions,
            "worlds": self.worlds,
            "invites": self.invites,
        })

    def _public_account(self, account: dict[str, Any]) -> dict[str, Any]:
        nickname = str(account["nickname"])
        return {"id": account["id"], "nickname": nickname, "display_name": nickname}

    def _issue_session(self, account_id: str) -> tuple[str, int]:
        token = secrets.token_urlsafe(32)
        expires_at = _now() + SESSION_TTL_SECONDS
        self.sessions[hashlib.sha256(token.encode()).hexdigest()] = {
            "account_id": account_id,
            "expires_at": expires_at,
        }
        return token, expires_at

    def register(self, nickname: Any, password: Any) -> dict[str, Any]:
        display_nickname = str(nickname or "").strip()
        normalized = display_nickname.lower()
        raw_password = str(password or "")
        if not NICKNAME_RE.fullmatch(display_nickname):
            raise StoreError("Nickname must be 3-24 characters using letters, numbers, dot, dash, or underscore.")
        if len(raw_password) < 10 or len(raw_password) > 128:
            raise StoreError("Password must contain 10-128 characters.")
        with self.lock:
            if any(str(item.get("nickname", "")).lower() == normalized for item in self.accounts.values()):
                raise StoreError("That nickname is already in use.")
            salt, digest = _password_hash(raw_password)
            account_id = uuid.uuid4().hex
            account = {
                "id": account_id,
                "nickname": display_nickname,
                "display_name": display_nickname,
                "password_salt": salt,
                "password_digest": digest,
                "created_at": _now(),
            }
            self.accounts[account_id] = account
            token, expires_at = self._issue_session(account_id)
            self._save()
            return {"account": self._public_account(account), "session_token": token, "expires_at": expires_at}

    def login(self, nickname: Any, password: Any) -> dict[str, Any]:
        normalized = str(nickname or "").strip().lower()
        raw_password = str(password or "")
        with self.lock:
            account = next((a for a in self.accounts.values() if str(a.get("nickname", "")).lower() == normalized), None)
            salt = bytes.fromhex(str(account.get("password_salt", ""))) if account is not None else bytes(16)
            _, candidate = _password_hash(raw_password, salt)
            expected = str(account.get("password_digest", "")) if account is not None else "0" * 64
            valid = hmac.compare_digest(candidate, expected)
            if not valid or account is None:
                raise StoreError("Nickname or password is incorrect.")
            token, expires_at = self._issue_session(account["id"])
            self._save()
            return {"account": self._public_account(account), "session_token": token, "expires_at": expires_at}

    def authenticate(self, token: str) -> dict[str, Any] | None:
        if not token:
            return None
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        with self.lock:
            session = self.sessions.get(token_hash)
            if not session or int(session.get("expires_at", 0)) <= _now():
                self.sessions.pop(token_hash, None)
                return None
            return self.accounts.get(str(session.get("account_id")))

    def logout(self, token: str) -> None:
        with self.lock:
            self.sessions.pop(hashlib.sha256(token.encode()).hexdigest(), None)
            self._save()

    def refresh_session(self, token: str) -> dict[str, Any]:
        # Session rotation limits the useful lifetime of a copied browser token.
        with self.lock:
            account = self.authenticate(token)
            if account is None:
                raise StoreError("Session is invalid or expired.")
            self.sessions.pop(hashlib.sha256(token.encode()).hexdigest(), None)
            next_token, expires_at = self._issue_session(account["id"])
            self._save()
            return {"account": self._public_account(account), "session_token": next_token, "expires_at": expires_at}

    def create_world(self, account_id: str, name: Any, kind: Any, modifiers: Any) -> dict[str, Any]:
        world_kind = str(kind or "personal")
        if world_kind not in {"personal", "shared"}:
            raise StoreError("World type must be personal or shared.")
        with self.lock:
            owned = sum(1 for world in self.worlds.values() if world.get("owner_id") == account_id)
            if owned >= MAX_WORLDS_PER_ACCOUNT:
                raise StoreError("World limit reached.")
            world_id = uuid.uuid4().hex[:16]
            timestamp = _now()
            safe_modifiers = modifiers if isinstance(modifiers, dict) else {}
            world = {
                "id": world_id,
                "name": _clean_world_name(name),
                "kind": world_kind,
                "owner_id": account_id,
                "members": {account_id: "owner"},
                "created_at": timestamp,
                "last_played": timestamp,
                "playtime_seconds": 0,
                "region": "green_hollow",
                "game_version": "1.0.0",
                "world_schema_version": 1,
                "checkpoint_index": 0,
                "modifiers": {str(k)[:32]: bool(v) for k, v in safe_modifiers.items()},
            }
            self.worlds[world_id] = world
            self._write_checkpoint(world, {"world": {}, "players": {}})
            self._save()
            return self.public_world(world, account_id)

    def public_world(self, world: dict[str, Any], account_id: str) -> dict[str, Any]:
        return {
            "id": world["id"],
            "name": world["name"],
            "kind": world["kind"],
            "role": world.get("members", {}).get(account_id, "member"),
            "members": len(world.get("members", {})),
            "last_played": world.get("last_played", 0),
            "playtime_seconds": world.get("playtime_seconds", 0),
            "region": world.get("region", "green_hollow"),
            "game_version": world.get("game_version", "1.0.0"),
            "world_schema_version": world.get("world_schema_version", 1),
            "modifiers": world.get("modifiers", {}),
        }

    def list_worlds(self, account_id: str) -> list[dict[str, Any]]:
        with self.lock:
            result = [self.public_world(w, account_id) for w in self.worlds.values() if account_id in w.get("members", {})]
            return sorted(result, key=lambda item: int(item["last_played"]), reverse=True)

    def _member_world(self, account_id: str, world_id: str) -> dict[str, Any]:
        world = self.worlds.get(world_id)
        if world is None or account_id not in world.get("members", {}):
            raise StoreError("World not found or access denied.")
        return world

    def load_world(self, account_id: str, world_id: str) -> dict[str, Any]:
        with self.lock:
            world = self._member_world(account_id, world_id)
            envelope = self._read_latest_checkpoint(world)
            return {"world": self.public_world(world, account_id), "snapshot": envelope.get("snapshot", {})}

    def save_world(self, account_id: str, world_id: str, snapshot: Any, region: Any, playtime_delta: Any) -> dict[str, Any]:
        if not isinstance(snapshot, dict):
            raise StoreError("Snapshot must be a JSON object.")
        with self.lock:
            world = self._member_world(account_id, world_id)
            previous = self._read_latest_checkpoint(world).get("snapshot", {})
            merged = dict(previous) if isinstance(previous, dict) else {}
            merged["world"] = snapshot.get("world", merged.get("world", {}))
            players = dict(merged.get("players", {})) if isinstance(merged.get("players", {}), dict) else {}
            if isinstance(snapshot.get("player"), dict):
                players[account_id] = snapshot["player"]
            merged["players"] = players
            world["region"] = _clean_world_name(region)[:32].lower().replace(" ", "_")
            world["playtime_seconds"] = int(world.get("playtime_seconds", 0)) + max(0, min(int(playtime_delta or 0), 86400))
            world["last_played"] = _now()
            self._write_checkpoint(world, merged)
            self._save()
            return self.public_world(world, account_id)

    def create_invite(self, account_id: str, world_id: str) -> str:
        with self.lock:
            world = self._member_world(account_id, world_id)
            if world.get("owner_id") != account_id or world.get("kind") != "shared":
                raise StoreError("Only a shared-world owner can create invites.")
            code = secrets.token_hex(4).upper()
            self.invites[code] = {"world_id": world_id, "expires_at": _now() + 86400}
            self._save()
            return code

    def join_invite(self, account_id: str, invite_code: Any) -> dict[str, Any]:
        code = str(invite_code or "").strip().upper()[:32]
        with self.lock:
            invite = self.invites.get(code)
            if not invite or int(invite.get("expires_at", 0)) <= _now():
                raise StoreError("Invite is invalid or expired.")
            world = self.worlds.get(str(invite.get("world_id")))
            if world is None:
                raise StoreError("Shared world no longer exists.")
            if len(world.get("members", {})) >= 4 and account_id not in world.get("members", {}):
                raise StoreError("Shared world already has four members.")
            world.setdefault("members", {})[account_id] = "member"
            self._save()
            return self.public_world(world, account_id)

    def _checkpoint_path(self, world_id: str, index: int) -> Path:
        return SNAPSHOT_ROOT / world_id / f"checkpoint-{index:04d}.json"

    def _write_checkpoint(self, world: dict[str, Any], snapshot: dict[str, Any]) -> None:
        index = int(world.get("checkpoint_index", 0)) + 1
        payload = json.dumps(snapshot, separators=(",", ":"), sort_keys=True)
        envelope = {
            "save_version": 1,
            "game_version": world.get("game_version", "1.0.0"),
            "world_schema_version": world.get("world_schema_version", 1),
            "created_at": _now(),
            "checksum": hashlib.sha256(payload.encode()).hexdigest(),
            "snapshot": snapshot,
        }
        _atomic_json(self._checkpoint_path(world["id"], index), envelope)
        world["checkpoint_index"] = index
        stale = index - MAX_CHECKPOINTS
        if stale > 0:
            self._checkpoint_path(world["id"], stale).unlink(missing_ok=True)

    def _read_latest_checkpoint(self, world: dict[str, Any]) -> dict[str, Any]:
        index = int(world.get("checkpoint_index", 0))
        for candidate in range(index, max(0, index - MAX_CHECKPOINTS), -1):
            path = self._checkpoint_path(world["id"], candidate)
            if not path.exists():
                continue
            try:
                envelope = json.loads(path.read_text(encoding="utf-8"))
                snapshot = envelope.get("snapshot", {})
                payload = json.dumps(snapshot, separators=(",", ":"), sort_keys=True)
                if hmac.compare_digest(hashlib.sha256(payload.encode()).hexdigest(), str(envelope.get("checksum", ""))):
                    return envelope
            except Exception:
                continue
        return {"snapshot": {"world": {}, "players": {}}}

# PROJECT STATE — IRONVEIL

**Last updated:** 2026-08-16  
**Current phase:** **Phase 2 — Vertical Slice**  
**Status:** Phase 2 implementation candidate. Phase 1 Web build is reported running by the owner. The expanded solo vertical-slice source, modern-pixel rendering foundation, full settings UI, lobby service and room-server foundation are implemented and statically validated. Godot/Dokploy Phase 2 runtime and 2–4 client co-op acceptance are still pending. The reported Godot 4.7 HUD `String.upper()` compile failure has been fixed to `String.to_upper()` and guarded by static lint.

## Current Milestone

```text
Green Hollow
→ Workshop automation
→ Ashwick bridge
→ Archivist Mara
→ Mechanical press
→ Foundry Vault
→ dual thermal valves
→ Furnace Saint
→ VERTICAL SLICE COMPLETE
```

## Functional in Source

### Vertical-slice content

- Continuous Phase 2 route containing forest, abandoned workshop, Ashwick town and Foundry Vault dungeon.
- Phase 1 survival/inventory/combat/mechanical automation retained.
- Bridge repair uses automatically produced Planks as an exploration gate.
- Archivist Mara provides world/knowledge progression before Foundry access.
- Mechanical press creates the required Pressed Plates.
- Foundry gate consumes 2 Pressed Plates + 4 Planks.
- Two thermal relief valves create a timed Furnace Saint vulnerability window.
- Furnace Saint sealed armor heavily resists brute-force damage.
- Objective chain extended through vertical-slice completion.
- Journal continues Observation → Hypothesis → Confirmation design.

### Modern Pixel / Hi-Bit presentation foundation

- Representative authored pixel sprites for player, remote player, NPC, three enemy types, vegetation, pickups and effects.
- Pixel textures for forest/town/workshop/dungeon/wood/rust/stone/water surfaces.
- Nearest filtering contract in project and material helpers.
- 3D machinery retained for physically readable rotation/transmission.
- Dynamic DirectionalLight/OmniLight and real-time shadows.
- Pixel dust/steam atmosphere.
- Web-safe screen shader for quantization, dithering, vignette and accessibility transforms.
- Art is development-quality representative content, not final production art.

### Settings

- Graphics, Audio, Controls, Gameplay, Accessibility and Network categories exist.
- Keybinds are remappable and world prompts read the current interaction/crafting binds.
- Settings persist through ConfigFile.

### Phase 2 networking foundation

- `NetworkManager` autoload using `WebSocketMultiplayerPeer`.
- WebSocket room server scene/process.
- HMAC-signed short-lived lobby join tickets.
- SceneMultiplayer authentication path.
- Hard 4-player room limit on room server and lobby.
- Configurable active-room cap.
- Public/private rooms; private rooms joinable via invite room ID.
- Server-side room password checking; plaintext password is not listed/logged.
- Room/player name sanitization and bounds in lobby.
- Create-room and incorrect-password rate limiting in lobby.
- Server-clamped movement replication and remote-player presentation.
- Shared Phase 2 world flags replicated through room server.
- Periodic room-state checkpoint file and restart policy in Compose.
- Structured lobby/room logs.
- Initial Compose resource ceilings for lobby/room server.

### Deployment/test tooling

- Root Web-client `Dockerfile` remains compatible with Dokploy Application deployment.
- `Dockerfile.room` builds the headless room server.
- `services/lobby/Dockerfile` builds the lobby.
- `docker-compose.phase2.yml` defines the Phase 2 topology.
- Static validator passes.
- Python lobby integration/contract test passes locally.
- Godot scene-based CI includes all Phase 2 runtime scripts and checks the real boot path.

## Important Incomplete Work

These items prevent calling Phase 2 complete:

1. **Godot Phase 2 runtime has not been executed in this build environment.** It must pass Dokploy/Godot CI and actual browser play.
2. **2–4 Web clients have not yet been runtime-tested together.** Movement/flags need desync and disconnect/reconnect tests.
3. **Full server authority is incomplete.** Inventory, survival, general enemy AI and machine simulation are still primarily client-local; Furnace Saint health/vulnerability is server-owned; the room server currently authorizes membership, clamps movement and owns shared progression flags. These systems must migrate to authority before claiming the complete server-authoritative architecture from the master prompt.
4. Public WSS/Traefik long-lived connection behavior is not yet verified.
5. Checkpoint recovery is implemented for current room shared state but has not been force-crash tested, and it does not yet include the complete future authoritative factory/inventory simulation.
6. Lobby player counts currently use short-lived reservations rather than authoritative live presence; this is acceptable for the implementation candidate but must be reconciled before final Phase 2 acceptance.
7. Representative Phase 2 pixel art establishes direction but does not meet final production-art quality.

## Phase 2 Acceptance Checklist

### Solo vertical slice

- [ ] Client Docker build passes the Phase 2 Godot CI gate.
- [ ] Web build loads from splash into gameplay without parser/runtime errors.
- [ ] Forest → workshop → Ashwick → Foundry → Furnace Saint can be completed end-to-end.
- [ ] Bridge resource economy is completable without debug grants.
- [ ] Mechanical press can produce 2 required plates.
- [ ] Foundry gate opens from legitimate resources.
- [ ] Both thermal valves produce a timed boss vulnerability window.
- [ ] Furnace Saint cannot be efficiently brute-forced and can be defeated in the intended window.
- [ ] Save/load does not corrupt the Phase 2 objective/world flags.
- [ ] Modern-pixel post-processing and representative assets render correctly in Web Compatibility.

### Settings

- [ ] All six settings categories open without UI overlap at 1280×720.
- [ ] Remapped keys immediately change gameplay and prompts.
- [ ] Settings persist after browser reload/native restart.
- [ ] Colorblind/post-processing toggles update the rendered result.

### Lobby / room server

- [x] Python lobby create/list/join contract test passes locally.
- [x] Public room listing hides private rooms/passwords.
- [x] Private room can be addressed by room ID/invite code in UI/source contract.
- [x] Lobby rejects room creation at configured room capacity.
- [x] Wrong password attempts are rate limited.
- [ ] `Dockerfile.room` builds and room server reaches `IRONVEIL_ROOM_SERVER_READY`.
- [ ] Two Web clients can join one room.
- [ ] Four Web clients can join one room.
- [ ] Fifth player is rejected server-side.
- [ ] Remote movement is stable and a disconnect removes the remote player.
- [ ] Bridge/gate/valve/boss shared flags stay consistent between clients.
- [ ] Rejoining client receives existing shared flags.
- [ ] No major desync through the complete vertical-slice route.

### Authority / security / resilience

- [ ] Inventory/survival/machine/combat/enemy state needed for co-op is migrated to authoritative server ownership or otherwise validated so clients cannot arbitrarily commit authoritative world outcomes.
- [ ] Public client uses HTTPS lobby + WSS room endpoint.
- [ ] Dokploy/Traefik WebSocket upgrade and long-lived timeout verified.
- [ ] CPU/RAM ceilings validated under deliberate stress.
- [ ] Forced room-server crash triggers restart.
- [ ] Forced crash restores the latest valid checkpoint.
- [ ] Logs are sufficient to diagnose room lifecycle/errors/disconnects.

## Phase 3 Gate

**Do not start Phase 3** until every Phase 2 gameplay/co-op requirement above that is part of the master prompt has passed in real runtime. Public co-op additionally remains blocked by the complete `docs/PHASE2_SECURITY_SCALABILITY.md` release checklist.

## Next Concrete Steps

1. Push this Phase 2 candidate to GitHub and run the Web client Docker/Dokploy build; fix any Godot 4.7 parser/runtime gate failure before further features.
2. Deploy lobby + room server privately, configure HTTPS/WSS endpoints, then test 2 → 4 clients.
3. Move co-op-sensitive inventory/machine/combat/world mutation to server authority and run the full vertical slice with multiple clients before marking Phase 2 complete.

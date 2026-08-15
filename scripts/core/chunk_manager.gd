extends Node

# Phase 1 architecture scaffold for both simulation LOD and future multiplayer
# interest management. It deliberately does not stream/unload scene content yet.
enum SimulationTier { FULL, SIMPLIFIED, STATISTICAL }

const CHUNK_SIZE := 24.0
const FULL_RADIUS_CHUNKS := 1
const SIMPLIFIED_RADIUS_CHUNKS := 3

var active_player_positions: Array[Vector3] = []
var explicit_tiers: Dictionary = {}

func _ready() -> void:
	TickManager.economy_tick.connect(_refresh_from_scene_players)

func world_to_chunk(position: Vector3) -> Vector2i:
	return Vector2i(
		floori(position.x / CHUNK_SIZE),
		floori(position.z / CHUNK_SIZE)
	)

func tier_for_world_position(position: Vector3) -> int:
	var coord := world_to_chunk(position)
	if explicit_tiers.has(coord):
		return int(explicit_tiers[coord])
	return _tier_from_interest(coord)

func tier_for_chunk(coord: Vector2i) -> int:
	if explicit_tiers.has(coord):
		return int(explicit_tiers[coord])
	return _tier_from_interest(coord)

func set_explicit_tier(coord: Vector2i, tier: int) -> void:
	explicit_tiers[coord] = tier

func clear_explicit_tier(coord: Vector2i) -> void:
	explicit_tiers.erase(coord)

func update_interest(player_positions: Array[Vector3]) -> void:
	active_player_positions = player_positions.duplicate()

func _tier_from_interest(coord: Vector2i) -> int:
	if active_player_positions.is_empty():
		return SimulationTier.STATISTICAL

	var best_distance := 999999
	for position in active_player_positions:
		var player_chunk := world_to_chunk(position)
		var distance := maxi(abs(coord.x - player_chunk.x), abs(coord.y - player_chunk.y))
		best_distance = mini(best_distance, distance)

	if best_distance <= FULL_RADIUS_CHUNKS:
		return SimulationTier.FULL
	if best_distance <= SIMPLIFIED_RADIUS_CHUNKS:
		return SimulationTier.SIMPLIFIED
	return SimulationTier.STATISTICAL

func _refresh_from_scene_players(_delta: float) -> void:
	var positions: Array[Vector3] = []
	for player in get_tree().get_nodes_in_group("players"):
		if player is Node3D:
			positions.append((player as Node3D).global_position)
	update_interest(positions)

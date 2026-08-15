extends Area3D

var region_id: String = "green_hollow"
var zone_size: Vector3 = Vector3(30.0, 4.0, 30.0)
var _label: Label3D

func configure(id: String, size_value: Vector3) -> void:
	region_id = id
	zone_size = size_value

func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = zone_size
	collision.shape = shape
	collision.position.y = zone_size.y * 0.5
	add_child(collision)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		GameState.set_region_context(region_id)
		if region_id == "ashlands" and GameState.objective_step == 12:
			GameState.advance_objective(13)
		elif region_id == "flooded_basin" and GameState.objective_step == 17:
			GameState.advance_objective(18)

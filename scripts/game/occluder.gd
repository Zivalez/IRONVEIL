extends StaticBody3D

var mesh_instance: MeshInstance3D

func configure(size: Vector3, color: Color) -> void:
	collision_layer = 2
	collision_mask = 0

	mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	mesh_instance.material_override = material
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)

func set_faded(faded: bool) -> void:
	if mesh_instance != null:
		mesh_instance.transparency = 0.72 if faded else 0.0

extends Node3D
class_name ArenaWalls

const WALL_X: float = 6.0
const LANE_HALF_LEN: float = 28.0
const PILLAR_STEP: float = 4.0

func _ready() -> void:
	_build_parapets()
	_build_colliders()

func _build_parapets() -> void:
	# Materials
	var slate_mat = StandardMaterial3D.new()
	slate_mat.albedo_color = Color(0.12, 0.15, 0.20)
	slate_mat.roughness = 0.75

	var cyan_mat = StandardMaterial3D.new()
	cyan_mat.albedo_color = Color(0.0, 0.85, 1.0)
	cyan_mat.emission_enabled = true
	cyan_mat.emission = Color(0.0, 0.85, 1.0)
	cyan_mat.emission_energy_multiplier = 1.4

	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(1.0, 0.2, 0.25)
	red_mat.emission_enabled = true
	red_mat.emission = Color(1.0, 0.15, 0.2)
	red_mat.emission_energy_multiplier = 1.4

	# Meshes
	var pillar_mesh = BoxMesh.new()
	pillar_mesh.size = Vector3(0.7, 1.1, 0.7)
	pillar_mesh.material = slate_mat

	var wall_mesh = BoxMesh.new()
	wall_mesh.size = Vector3(0.45, 0.7, PILLAR_STEP - 0.7)
	wall_mesh.material = slate_mat

	var cap_cyan_mesh = BoxMesh.new()
	cap_cyan_mesh.size = Vector3(0.6, 0.08, 0.6)
	cap_cyan_mesh.material = cyan_mat

	var cap_red_mesh = BoxMesh.new()
	cap_red_mesh.size = Vector3(0.6, 0.08, 0.6)
	cap_red_mesh.material = red_mat

	# Build along both sides: -WALL_X (left) and +WALL_X (right)
	for side in [-WALL_X, WALL_X]:
		var z = -LANE_HALF_LEN
		while z <= LANE_HALF_LEN + 0.1:
			# Pillar
			var pillar = MeshInstance3D.new()
			pillar.mesh = pillar_mesh
			pillar.position = Vector3(side, 0.55, z)
			add_child(pillar)

			# Glowing pillar cap
			if abs(z) > 1.0:
				var cap = MeshInstance3D.new()
				cap.mesh = cap_cyan_mesh if z > 0.0 else cap_red_mesh
				cap.position = Vector3(side, 1.14, z)
				add_child(cap)

			# Wall segment to next pillar
			if z < LANE_HALF_LEN:
				var wall = MeshInstance3D.new()
				wall.mesh = wall_mesh
				wall.position = Vector3(side, 0.35, z + (PILLAR_STEP * 0.5))
				add_child(wall)

			z += PILLAR_STEP

	# End walls across the ends of the bridge
	for end_z in [-LANE_HALF_LEN, LANE_HALF_LEN]:
		var end_wall_mesh = BoxMesh.new()
		end_wall_mesh.size = Vector3(WALL_X * 2.0, 0.7, 0.45)
		end_wall_mesh.material = slate_mat
		var end_wall = MeshInstance3D.new()
		end_wall.mesh = end_wall_mesh
		end_wall.position = Vector3(0, 0.35, end_z)
		add_child(end_wall)

func _build_colliders() -> void:
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)

	# Left wall collider
	var left_col = CollisionShape3D.new()
	var left_shape = BoxShape3D.new()
	left_shape.size = Vector3(1.0, 2.0, (LANE_HALF_LEN * 2.0) + 2.0)
	left_col.shape = left_shape
	left_col.position = Vector3(-WALL_X, 1.0, 0)
	body.add_child(left_col)

	# Right wall collider
	var right_col = CollisionShape3D.new()
	var right_shape = BoxShape3D.new()
	right_shape.size = Vector3(1.0, 2.0, (LANE_HALF_LEN * 2.0) + 2.0)
	right_col.shape = right_shape
	right_col.position = Vector3(WALL_X, 1.0, 0)
	body.add_child(right_col)

	# Enemy end collider (-Z)
	var enemy_end_col = CollisionShape3D.new()
	var enemy_end_shape = BoxShape3D.new()
	enemy_end_shape.size = Vector3((WALL_X * 2.0) + 2.0, 2.0, 1.0)
	enemy_end_col.shape = enemy_end_shape
	enemy_end_col.position = Vector3(0, 1.0, -LANE_HALF_LEN)
	body.add_child(enemy_end_col)

	# Allied end collider (+Z)
	var allied_end_col = CollisionShape3D.new()
	var allied_end_shape = BoxShape3D.new()
	allied_end_shape.size = Vector3((WALL_X * 2.0) + 2.0, 2.0, 1.0)
	allied_end_col.shape = allied_end_shape
	allied_end_col.position = Vector3(0, 1.0, LANE_HALF_LEN)
	body.add_child(allied_end_col)

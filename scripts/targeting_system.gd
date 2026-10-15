class_name TargetingSystem
extends RefCounted

## 1:1 port of TargetingSystem.ts from game-x0-moba
## Finds the best target using cursor distance priority (radius 5.0) or player distance priority.

static func find_best_target(
	player_pos: Vector3,
	cursor_world_pos: Variant,
	dummies: Array,
	max_attack_range: float
) -> Node3D:
	if dummies.is_empty():
		return null

	# 1. Tenta encontrar o alvo mais próximo do cursor do mouse (Wild Rift smart targeting)
	if cursor_world_pos is Vector3:
		var closest_dummy: Node3D = null
		var min_cursor_dist_sq := INF
		var select_threshold_sq := 5.0 * 5.0 # Raio de 5.0 unidades de tolerância ao redor do mouse

		for d in dummies:
			if d != null and is_instance_valid(d) and d.get("active") == true:
				var dx: float = d.global_position.x - cursor_world_pos.x
				var dz: float = d.global_position.z - cursor_world_pos.z
				var dist_sq: float = dx * dx + dz * dz

				if dist_sq < select_threshold_sq and dist_sq < min_cursor_dist_sq:
					min_cursor_dist_sq = dist_sq
					closest_dummy = d

		if closest_dummy != null:
			return closest_dummy

	# 2. Se não achar nada próximo do cursor, tenta achar o Dummy ativo mais próximo da Caitlyn
	var closest_to_player: Node3D = null
	var min_player_dist_sq := INF
	var max_range_sq: float = max_attack_range * max_attack_range

	for d in dummies:
		if d != null and is_instance_valid(d) and d.get("active") == true:
			var dx: float = d.global_position.x - player_pos.x
			var dz: float = d.global_position.z - player_pos.z
			var dist_sq: float = dx * dx + dz * dz

			if dist_sq <= max_range_sq and dist_sq < min_player_dist_sq:
				min_player_dist_sq = dist_sq
				closest_to_player = d

	return closest_to_player

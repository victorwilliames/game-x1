class_name MobaProjectile
extends Node3D

## 1:1 port of Projectile.ts from game-x0-moba
## Pink Hextech sphere (radius 0.12, color #ff007f), speed 25.0, damage 55.0

signal hit_target_signal(damage: float, hit_position: Vector3)

var active: bool = true
var target: Node3D = null
var direction: Vector3 = Vector3.ZERO
var has_direction: bool = false
var speed: float = 25.0
var damage: float = 55.0
var start_position: Vector3 = Vector3.ZERO
var max_range: float = 40.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func init_projectile(
	start_pos: Vector3,
	proj_speed: float,
	proj_damage: float,
	proj_target: Node3D,
	proj_dir: Variant = null
) -> void:
	global_position = start_pos
	start_position = start_pos
	speed = proj_speed
	damage = proj_damage
	target = proj_target

	if proj_dir is Vector3 and proj_dir.length_squared() > 0.0001:
		direction = proj_dir.normalized()
		has_direction = true
	else:
		has_direction = false

func update_projectile(dummies: Array, delta: float) -> void:
	if not active:
		return

	# 1. Deslocamento do Projétil
	if target != null and is_instance_valid(target):
		if not target.get("active"):
			var diff := target.global_position - global_position
			diff.y = 0.0
			if diff.length_squared() > 0.0001:
				direction = diff.normalized()
				has_direction = true
			target = null
		else:
			# Teleguiado: Move-se na direção do alvo em tempo real
			var diff := target.global_position - global_position
			diff.y = 0.0
			var dist := diff.length()
			var step := speed * delta

			if dist <= step:
				_hit(target)
				return
			else:
				global_position += diff.normalized() * step
	elif has_direction:
		# Direcional (Disparo Livre estilo Wild Rift)
		var step := speed * delta
		global_position += direction * step

		# Checa colisão com os Dummies ativos
		var hit_radius_sq := (0.7 + 0.12) * (0.7 + 0.12) # 0.6724

		for d in dummies:
			if d != null and is_instance_valid(d) and d.get("active") == true:
				var dx: float = d.global_position.x - global_position.x
				var dz: float = d.global_position.z - global_position.z
				var dist_sq: float = dx * dx + dz * dz

				if dist_sq <= hit_radius_sq:
					_hit(d)
					return

		# Destrói se ultrapassar o alcance máximo de segurança
		if global_position.distance_squared_to(start_position) >= max_range * max_range:
			_destroy()

func _hit(d: Node3D) -> void:
	if d.has_method("take_damage"):
		d.take_damage(damage)
	hit_target_signal.emit(damage, d.global_position)
	_destroy()

func _destroy() -> void:
	active = false
	queue_free()

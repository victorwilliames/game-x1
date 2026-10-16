class_name MobaDummy
extends Node3D

## 1:1 port of Dummy.ts from game-x0-moba
## Capsule dummy with outline, damage flash, 3.0m purple tolerance ring, and moving mode.

@export var mode: String = "static" # "static" or "moving"
@export var max_hp: float = 600.0

var hp: float = 600.0
var active: bool = true

var move_speed: float = 2.5
var move_dir: float = 1.0
var start_x: float = 0.0

var flash_timer: float = 0.0
var respawn_timer: float = 0.0

@onready var body_mesh: MeshInstance3D = $VisualGroup/Body
@onready var outline_mesh: MeshInstance3D = $VisualGroup/Outline
@onready var eye_left: MeshInstance3D = $VisualGroup/EyeLeft
@onready var eye_right: MeshInstance3D = $VisualGroup/EyeRight
@onready var visual_group: Node3D = $VisualGroup
@onready var tolerance_ring: Node3D = $ToleranceRing

var original_body_mat: Material
var original_eye_mat: Material
var flash_mat: StandardMaterial3D

func _ready() -> void:
	hp = max_hp
	start_x = global_position.x

	if body_mesh:
		original_body_mat = body_mesh.get_active_material(0)
	if eye_left:
		original_eye_mat = eye_left.get_active_material(0)

	flash_mat = StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = Color(1, 1, 1, 1)

	if outline_mesh:
		outline_mesh.visible = false

	if tolerance_ring:
		var border_node := tolerance_ring.get_node_or_null("Border") as MeshInstance3D
		if border_node:
			border_node.mesh = RingMeshBuilder.create_ring_mesh(2.85, 3.10, 96)
			border_node.material_override = RingMeshBuilder.create_smooth_ring_material(2.95, 3.00, Color(0.6667, 0.0, 1.0, 0.32))

func take_damage(amount: float) -> void:
	if not active:
		return

	hp = max(0.0, hp - amount)
	flash_timer = 0.1
	_apply_flash(true)

	if hp <= 0.0:
		_die()

func _die() -> void:
	active = false
	respawn_timer = 3.0
	# Damage flashes are not advanced while inactive. Clear them now, or the
	# corpse and the freshly respawned dummy can remain permanently white.
	flash_timer = 0.0
	_apply_flash(false)
	if tolerance_ring:
		tolerance_ring.visible = false
	if outline_mesh:
		outline_mesh.visible = false

	# Deita o Dummy no chão
	visual_group.rotation.z = PI / 2.0
	visual_group.position.y = 0.2

func _respawn() -> void:
	active = true
	hp = max_hp
	flash_timer = 0.0
	_apply_flash(false)
	visual_group.rotation.z = 0.0
	visual_group.position.y = 0.0
	global_position.x = start_x
	if tolerance_ring:
		tolerance_ring.visible = true

func _apply_flash(flashing: bool) -> void:
	if flashing:
		if body_mesh:
			body_mesh.material_override = flash_mat
		if eye_left:
			eye_left.material_override = flash_mat
		if eye_right:
			eye_right.material_override = flash_mat
	else:
		if body_mesh:
			body_mesh.material_override = null
		if eye_left:
			eye_left.material_override = null
		if eye_right:
			eye_right.material_override = null

func update_dummy(delta: float) -> void:
	# 1. Respawn timer
	if not active:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn()
		return

	# 2. Movimentação opcional (Modo Móvel)
	if mode == "moving":
		global_position.x += move_speed * move_dir * delta
		if abs(global_position.x - start_x) >= 8.0:
			move_dir *= -1.0
			visual_group.rotation.y = 0.0 if move_dir > 0.0 else PI

	# 3. Efeito de flash de dano
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			_apply_flash(false)

func set_outline_visible(vis: bool) -> void:
	if outline_mesh:
		var show := vis and active
		if outline_mesh.visible != show:
			outline_mesh.visible = show

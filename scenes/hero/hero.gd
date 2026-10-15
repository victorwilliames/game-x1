extends CharacterBody3D
class_name Hero

@export var move_speed: float = 7.0
@export var turn_speed: float = 14.0
@export var arrival_threshold: float = 0.15

@onready var visual: StickFigureVisual = $StickFigure

var target_position: Vector3 = Vector3.ZERO
var has_move_target: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

signal move_target_reached
signal move_target_changed(target: Vector3)

func _ready() -> void:
	target_position = global_position

func set_move_target(target: Vector3) -> void:
	target_position = target
	target_position.y = global_position.y
	has_move_target = true
	emit_signal("move_target_changed", target_position)

func stop() -> void:
	has_move_target = false
	velocity.x = 0.0
	velocity.z = 0.0

func _physics_process(delta: float) -> void:
	# Apply standard gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var horizontal_speed: float = 0.0

	if has_move_target:
		var diff = target_position - global_position
		diff.y = 0.0
		var distance = diff.length()

		if distance <= arrival_threshold:
			velocity.x = 0.0
			velocity.z = 0.0
			has_move_target = false
			emit_signal("move_target_reached")
		else:
			var dir = diff.normalized()
			# Cap speed to remaining distance per frame to prevent any overshoot at any framerate
			var step_speed = min(move_speed, distance / max(delta, 0.001))
			velocity.x = dir.x * step_speed
			velocity.z = dir.z * step_speed

			# Rotate facing direction smoothly towards movement vector
			var target_rot_y = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot_y, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 10.0 * delta)

	move_and_slide()

	horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if visual:
		visual.update_state(horizontal_speed > 0.1, horizontal_speed)

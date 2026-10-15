extends Node3D

@onready var hero: Hero = $Hero
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var target_marker: Node3D = $TargetMarker
@onready var fps_label: Label = $UI/MarginContainer/VBoxContainer/FPSLabel
@onready var info_label: Label = $UI/MarginContainer/VBoxContainer/InfoLabel
@onready var help_label: Label = $UI/MarginContainer/VBoxContainer/HelpLabel

# Playable lane boundaries (Issue #2 constraint)
const PLAYABLE_MIN_X: float = -5.0
const PLAYABLE_MAX_X: float = 5.0
const PLAYABLE_MIN_Z: float = -26.0
const PLAYABLE_MAX_Z: float = 26.0

# Configurable camera framing (closer MOBA zoom & isometric framing)
@export var camera_distance: float = 13.5
@export var camera_pitch_deg: float = 38.0
@export var camera_yaw_deg: float = 45.0
@export var camera_fov: float = 40.0
@export var camera_follow_speed: float = 7.0

var is_headless: bool = false
var right_mouse_held: bool = false
var ground_plane := Plane(Vector3.UP, 0.0)

func _ready() -> void:
	is_headless = DisplayServer.get_name() == "headless"

	if hero and not is_headless:
		hero.move_target_reached.connect(_on_hero_reached_target)
		# Start hero on allied side of the lane
		if hero.global_position == Vector3.ZERO:
			hero.global_position = Vector3(0, 0, 16.0)

	if not is_headless:
		_setup_camera_framing()
		var renderer_name = ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")
		info_label.text = "game-x1 | Combat Testing Lane\nRenderer: %s | Platform: %s" % [renderer_name, OS.get_name()]
		help_label.text = "Right Click on lane to move | Scroll to zoom | Allied (Blue) vs Enemy (Red)"
		if target_marker:
			target_marker.visible = false

	print("[game-x1] Main scene ready. Platform: %s, Headless: %s" % [OS.get_name(), str(is_headless)])

func _setup_camera_framing() -> void:
	if not camera or not camera_pivot:
		return

	camera.fov = camera_fov
	# Position camera at isometric offset (45 deg yaw, ~38 deg elevation)
	var yaw_rad = deg_to_rad(camera_yaw_deg)
	var pitch_rad = deg_to_rad(camera_pitch_deg)

	var cos_pitch = cos(pitch_rad)
	var sin_pitch = sin(pitch_rad)
	var sin_yaw = sin(yaw_rad)
	var cos_yaw = cos(yaw_rad)

	# Camera offset vector looking back at the pivot
	var offset = Vector3(
		sin_yaw * cos_pitch * camera_distance,
		sin_pitch * camera_distance,
		cos_yaw * cos_pitch * camera_distance
	)

	camera.position = offset
	camera.look_at_from_position(offset, Vector3.ZERO, Vector3.UP)

	if hero:
		camera_pivot.global_position = hero.global_position

func _unhandled_input(event: InputEvent) -> void:
	if is_headless or not hero or not camera:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_mouse_held = event.pressed
			if event.pressed:
				_order_movement_at_screen_pos(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_order_movement_at_screen_pos(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance = clamp(camera_distance - 1.0, 9.0, 22.0)
			_setup_camera_framing()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance = clamp(camera_distance + 1.0, 9.0, 22.0)
			_setup_camera_framing()

	elif event is InputEventMouseMotion and right_mouse_held:
		_order_movement_at_screen_pos(event.position)

func _order_movement_at_screen_pos(screen_pos: Vector2) -> void:
	# Physics raycast against actual arena ground collider (Issue #2 fix)
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)
	var ray_end = ray_origin + ray_dir * 300.0

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 1 # Floor and environment layer
	var result = space_state.intersect_ray(query)

	var target_pt: Vector3
	var valid_hit: bool = false

	if not result.is_empty():
		target_pt = result.position
		valid_hit = true
	else:
		# Fallback: ray against ground plane Y = 0, but strictly validated against arena bounds
		var plane_hit = ground_plane.intersects_ray(ray_origin, ray_dir)
		if plane_hit != null:
			# Only accept if within reasonable proximity of the arena
			if abs(plane_hit.x) <= PLAYABLE_MAX_X + 2.0 and abs(plane_hit.z) <= PLAYABLE_MAX_Z + 2.0:
				target_pt = plane_hit
				valid_hit = true

	if valid_hit:
		# Strictly constrain target position within finite playable lane bounds
		var clamped_pos = Vector3(
			clamp(target_pt.x, PLAYABLE_MIN_X, PLAYABLE_MAX_X),
			0.0,
			clamp(target_pt.z, PLAYABLE_MIN_Z, PLAYABLE_MAX_Z)
		)
		hero.set_move_target(clamped_pos)
		_show_target_marker(clamped_pos)

func _show_target_marker(pos: Vector3) -> void:
	if not target_marker:
		return
	target_marker.global_position = Vector3(pos.x, 0.03, pos.z)
	target_marker.visible = true
	target_marker.scale = Vector3(1.3, 1.3, 1.3)

func _on_hero_reached_target() -> void:
	if target_marker:
		target_marker.visible = false

func _process(delta: float) -> void:
	if is_headless:
		return

	# Smooth camera follow
	if hero and camera_pivot:
		camera_pivot.global_position = camera_pivot.global_position.lerp(
			hero.global_position,
			delta * camera_follow_speed
		)

	# Target marker visual pulse
	if target_marker and target_marker.visible:
		target_marker.scale = target_marker.scale.lerp(Vector3.ONE, delta * 8.0)
		target_marker.rotate_y(delta * 2.5)

	# HUD Diagnostics
	if fps_label and hero:
		var h_vel = Vector2(hero.velocity.x, hero.velocity.z).length()
		fps_label.text = "FPS: %d | Hero: (%.1f, %.1f) | Speed: %.1f m/s | Zoom: %.1fm" % [
			Engine.get_frames_per_second(),
			hero.global_position.x,
			hero.global_position.z,
			h_vel,
			camera_distance
		]

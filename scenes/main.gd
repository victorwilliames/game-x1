extends Node3D

@onready var hero: Hero = $Hero
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var target_marker: Node3D = $TargetMarker
@onready var fps_label: Label = $UI/MarginContainer/VBoxContainer/FPSLabel
@onready var info_label: Label = $UI/MarginContainer/VBoxContainer/InfoLabel
@onready var help_label: Label = $UI/MarginContainer/VBoxContainer/HelpLabel

var is_headless: bool = false
var ground_plane := Plane(Vector3.UP, 0.0)
var right_mouse_held: bool = false

func _ready() -> void:
	is_headless = DisplayServer.get_name() == "headless"

	if hero and not is_headless:
		hero.move_target_reached.connect(_on_hero_reached_target)

	if not is_headless:
		var renderer_name = ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")
		info_label.text = "game-x1 | Stage 1A: Stick Figure Movement\nRenderer: %s | Platform: %s" % [renderer_name, OS.get_name()]
		help_label.text = "Right Click on ground to move | Camera follows hero"
		if target_marker:
			target_marker.visible = false

	print("[game-x1] Main scene ready. Platform: %s, Headless: %s" % [OS.get_name(), str(is_headless)])

func _unhandled_input(event: InputEvent) -> void:
	if is_headless or not hero or not camera:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_mouse_held = event.pressed
			if event.pressed:
				_order_movement_at_screen_pos(event.position)
		# Support left click for web playtest convenience as fallback
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_order_movement_at_screen_pos(event.position)

	elif event is InputEventMouseMotion and right_mouse_held:
		_order_movement_at_screen_pos(event.position)

func _order_movement_at_screen_pos(screen_pos: Vector2) -> void:
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)
	var hit = ground_plane.intersects_ray(ray_origin, ray_dir)
	if hit != null:
		hero.set_move_target(hit)
		_show_target_marker(hit)

func _show_target_marker(pos: Vector3) -> void:
	if not target_marker:
		return
	target_marker.global_position = Vector3(pos.x, 0.03, pos.z)
	target_marker.visible = true
	target_marker.scale = Vector3(1.2, 1.2, 1.2)

func _on_hero_reached_target() -> void:
	if target_marker:
		target_marker.visible = false

func _process(delta: float) -> void:
	if is_headless:
		return

	# Smooth camera follow
	if hero and camera_pivot:
		camera_pivot.global_position = camera_pivot.global_position.lerp(hero.global_position, delta * 6.0)

	# Target marker visual pulse
	if target_marker and target_marker.visible:
		target_marker.scale = target_marker.scale.lerp(Vector3.ONE, delta * 8.0)
		target_marker.rotate_y(delta * 2.5)

	# HUD Diagnostics
	if fps_label and hero:
		var h_vel = Vector2(hero.velocity.x, hero.velocity.z).length()
		fps_label.text = "FPS: %d | Hero Pos: (%.1f, %.1f) | Speed: %.1f m/s" % [
			Engine.get_frames_per_second(),
			hero.global_position.x,
			hero.global_position.z,
			h_vel
		]

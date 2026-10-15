extends Node3D

@onready var hero: Hero = $Hero
@onready var camera_controller: MobaCamera = $CameraPivot
@onready var target_marker: Node3D = $TargetMarker
@onready var fps_label: Label = $UI/MarginContainer/VBoxContainer/FPSLabel
@onready var info_label: Label = $UI/MarginContainer/VBoxContainer/InfoLabel
@onready var help_label: Label = $UI/MarginContainer/VBoxContainer/HelpLabel

# Playable lane boundaries (Issue #2 constraint)
const PLAYABLE_MIN_X: float = -5.0
const PLAYABLE_MAX_X: float = 5.0
const PLAYABLE_MIN_Z: float = -26.0
const PLAYABLE_MAX_Z: float = 26.0

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

	if camera_controller and hero:
		camera_controller.target = hero
		if not is_headless:
			camera_controller.center_on_target(false)
			camera_controller.camera_mode_changed.connect(_on_camera_mode_changed)

	if not is_headless:
		var renderer_name = ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")
		info_label.text = "game-x1 | Combat Testing Lane\nRenderer: %s | Platform: %s" % [renderer_name, OS.get_name()]
		help_label.text = "Right Click: Move | Edge Pan / MMB Drag: Move Cam | Space (Hold): Center | Y: Lock | Scroll: Zoom"
		if target_marker:
			target_marker.visible = false

		# Web-specific integration for windowed browser play (prevents space & wheel from scrolling webpage)
		if OS.has_feature("web"):
			_install_web_scroll_preventer()

	print("[game-x1] Main scene ready. Platform: %s, Headless: %s" % [OS.get_name(), str(is_headless)])

func _install_web_scroll_preventer() -> void:
	if not OS.has_feature("web"):
		return
	var js_code = """
	(function() {
		if (window._godot_web_scroll_guard) return;
		window._godot_web_scroll_guard = true;
		function isCanvasTarget(e) {
			var canvas = document.getElementById('canvas');
			return canvas && (e.target === canvas || canvas.contains(e.target));
		}
		window.addEventListener('keydown', function(e) {
			if (e.code === 'Space' || e.keyCode === 32) {
				var canvas = document.getElementById('canvas');
				if (document.activeElement === canvas || document.activeElement === document.body || isCanvasTarget(e)) {
					e.preventDefault();
				}
			}
		}, { passive: false });
		window.addEventListener('wheel', function(e) {
			if (isCanvasTarget(e)) {
				e.preventDefault();
			}
		}, { passive: false });
	})();
	"""
	JavaScriptBridge.eval(js_code)

func _unhandled_input(event: InputEvent) -> void:
	if is_headless or not hero:
		return

	# 1. Camera controller handles Space, Y, MMB Drag and Scroll Wheel
	if camera_controller and camera_controller.handle_input(event):
		return

	# 2. Right Click moves the hero (click or drag); Left Click does NOT move
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_mouse_held = event.pressed
			if event.pressed:
				_order_movement_at_screen_pos(event.position)
		# Note: MOUSE_BUTTON_LEFT intentionally ignored for movement per LoL design

	elif event is InputEventMouseMotion and right_mouse_held:
		_order_movement_at_screen_pos(event.position)

func _order_movement_at_screen_pos(screen_pos: Vector2) -> void:
	if not camera_controller or not camera_controller.camera:
		return
	var active_cam = camera_controller.camera

	# Physics raycast against actual arena ground collider (Issue #2 fix)
	var space_state = get_world_3d().direct_space_state
	var ray_origin = active_cam.project_ray_origin(screen_pos)
	var ray_dir = active_cam.project_ray_normal(screen_pos)
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
		# Fallback: ray against ground plane Y = 0 if within proximity
		var plane_hit = ground_plane.intersects_ray(ray_origin, ray_dir)
		if plane_hit != null:
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

func _on_camera_mode_changed(_mode: MobaCamera.Mode, _mode_name: String) -> void:
	_update_hud()

func _process(delta: float) -> void:
	if is_headless:
		return

	# Target marker visual pulse
	if target_marker and target_marker.visible:
		target_marker.scale = target_marker.scale.lerp(Vector3.ONE, delta * 8.0)
		target_marker.rotate_y(delta * 2.5)

	_update_hud()

func _update_hud() -> void:
	if not fps_label or not hero:
		return
	var h_vel = Vector2(hero.velocity.x, hero.velocity.z).length()
	var cam_mode = camera_controller.get_mode_name() if camera_controller else "Unknown"
	var cam_zoom = camera_controller.current_distance if camera_controller else 13.5
	fps_label.text = "FPS: %d | Hero: (%.1f, %.1f) | Speed: %.1f m/s | Cam: [%s] | Zoom: %.1fm" % [
		Engine.get_frames_per_second(),
		hero.global_position.x,
		hero.global_position.z,
		h_vel,
		cam_mode,
		cam_zoom
	]

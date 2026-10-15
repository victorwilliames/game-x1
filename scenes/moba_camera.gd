extends Node3D
class_name MobaCamera

enum Mode {
	FREE,
	LOCKED
}

@export var target: Node3D
@export var current_mode: Mode = Mode.FREE

# Framing parameters (League of Legends style isometric angle)
@export var camera_pitch_deg: float = 38.0
@export var camera_yaw_deg: float = 45.0
@export var camera_fov: float = 40.0

# Zoom settings
@export var min_zoom: float = 9.0
@export var max_zoom: float = 22.0
@export var default_zoom: float = 13.5
@export var zoom_step: float = 1.5
@export var zoom_lerp_speed: float = 10.0

# Edge panning settings (responsive for windowed browser mode)
@export var edge_scroll_enabled: bool = true
@export var edge_margin_ratio_x: float = 0.05 # 5% of viewport width
@export var edge_margin_ratio_y: float = 0.07 # 7% of viewport height (more generous vertically)
@export var edge_margin_min_px: float = 36.0
@export var edge_margin_max_px: float = 80.0
@export var pan_speed: float = 20.0

# Middle Mouse Button Drag (alternative MOBA camera navigation)
@export var mmb_drag_enabled: bool = true
@export var mmb_drag_sensitivity: float = 1.0

# Smooth follow speed
@export var follow_speed: float = 7.0

# Arena boundary limits for camera pivot
@export var min_bound_x: float = -14.0
@export var max_bound_x: float = 14.0
@export var min_bound_z: float = -34.0
@export var max_bound_z: float = 34.0

@onready var camera: Camera3D = $Camera3D

var current_distance: float = 13.5
var target_distance: float = 13.5
var is_space_held: bool = false
var is_mmb_dragging: bool = false
var is_headless: bool = false

# Normalized direction from pivot to camera
var cam_dir: Vector3 = Vector3.ZERO
# World-space horizontal unit vectors for screen right and screen forward
var cam_screen_right: Vector3 = Vector3.ZERO
var cam_screen_fwd: Vector3 = Vector3.ZERO

signal camera_mode_changed(new_mode: Mode, mode_name: String)
signal zoom_changed(current_zoom: float)

func _ready() -> void:
	is_headless = DisplayServer.get_name() == "headless"
	current_distance = default_zoom
	target_distance = default_zoom
	_calculate_camera_vectors()

	if not is_headless and camera:
		camera.fov = camera_fov
		_apply_camera_offset()

	if target:
		global_position = target.global_position
		_clamp_pivot_position()

func _calculate_camera_vectors() -> void:
	var yaw_rad = deg_to_rad(camera_yaw_deg)
	var pitch_rad = deg_to_rad(camera_pitch_deg)

	var cos_pitch = cos(pitch_rad)
	var sin_pitch = sin(pitch_rad)
	var sin_yaw = sin(yaw_rad)
	var cos_yaw = cos(yaw_rad)

	# Unit vector from pivot to camera
	cam_dir = Vector3(
		sin_yaw * cos_pitch,
		sin_pitch,
		cos_yaw * cos_pitch
	).normalized()

	# In world space:
	# Screen right: perpendicular to yaw in XZ plane
	cam_screen_right = Vector3(cos_yaw, 0.0, -sin_yaw).normalized()
	# Screen forward (looking into the screen): opposite to camera horizontal projection
	cam_screen_fwd = Vector3(-sin_yaw, 0.0, -cos_yaw).normalized()

func _apply_camera_offset() -> void:
	if not camera:
		return
	var offset = cam_dir * current_distance
	camera.position = offset
	camera.look_at_from_position(offset, Vector3.ZERO, Vector3.UP)

func handle_input(event: InputEvent) -> bool:
	var handled = false

	# 1. Key inputs: Space (Hold to follow) and Y (Toggle Lock)
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_SPACE:
			is_space_held = event.pressed
			emit_signal("camera_mode_changed", current_mode, get_mode_name())
			handled = true
		elif event.keycode == KEY_Y and event.pressed:
			toggle_lock()
			handled = true

	# 2. Mouse buttons: MMB drag & Scroll zoom
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_mmb_dragging = event.pressed
			emit_signal("camera_mode_changed", current_mode, get_mode_name())
			handled = true
		elif event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
				handled = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()
				handled = true

	# 3. Mouse motion for MMB drag pan (alternative MOBA navigation without pointer lock)
	elif event is InputEventMouseMotion and is_mmb_dragging and mmb_drag_enabled:
		var drag_scale = (current_distance / 600.0) * mmb_drag_sensitivity
		var drag_world = (-cam_screen_right * event.relative.x + cam_screen_fwd * event.relative.y) * drag_scale
		global_position += drag_world
		_clamp_pivot_position()
		handled = true

	return handled

func zoom_in() -> void:
	target_distance = clamp(target_distance - zoom_step, min_zoom, max_zoom)

func zoom_out() -> void:
	target_distance = clamp(target_distance + zoom_step, min_zoom, max_zoom)

func toggle_lock() -> void:
	if current_mode == Mode.FREE:
		current_mode = Mode.LOCKED
	else:
		current_mode = Mode.FREE
	emit_signal("camera_mode_changed", current_mode, get_mode_name())

func set_mode(new_mode: Mode) -> void:
	if current_mode != new_mode:
		current_mode = new_mode
		emit_signal("camera_mode_changed", current_mode, get_mode_name())

func is_following_hero() -> bool:
	return is_space_held or current_mode == Mode.LOCKED

func get_mode_name() -> String:
	if is_mmb_dragging:
		return "Panning (MMB)"
	if is_space_held:
		return "Free (Space Centering)" if current_mode == Mode.FREE else "Locked"
	return "Locked" if current_mode == Mode.LOCKED else "Free"

func center_on_target(smooth: bool = false) -> void:
	if not target:
		return
	if smooth:
		global_position = global_position.lerp(target.global_position, 0.5)
	else:
		global_position = target.global_position
	_clamp_pivot_position()

func _process(delta: float) -> void:
	_update_zoom(delta)
	_update_position(delta)

func _update_zoom(delta: float) -> void:
	if abs(current_distance - target_distance) > 0.005:
		current_distance = lerp(current_distance, target_distance, delta * zoom_lerp_speed)
		_apply_camera_offset()
		emit_signal("zoom_changed", current_distance)

func _update_position(delta: float) -> void:
	# Priority 1: MMB Drag has manual control
	if is_mmb_dragging:
		return

	# Priority 2: Follow target if locked or Space is held
	if is_following_hero() and target:
		var target_pos = target.global_position
		target_pos.y = 0.0
		var speed = follow_speed * (1.5 if is_space_held else 1.0)
		global_position = global_position.lerp(target_pos, delta * speed)
		_clamp_pivot_position()
		return

	# Priority 3: Edge pan in Free mode
	if current_mode == Mode.FREE and edge_scroll_enabled:
		_process_edge_pan(delta)

func _process_edge_pan(delta: float) -> void:
	if is_headless:
		return

	var vp = get_viewport()
	if not vp:
		return

	var vp_rect = vp.get_visible_rect()
	var mouse_pos = vp.get_mouse_position()

	# Safety check: cursor must be inside the game window / canvas
	if not vp_rect.has_point(mouse_pos):
		return

	# Responsive margins tailored for browser windowed mode (prevents cursor from exiting canvas)
	var margin_x = clamp(vp_rect.size.x * edge_margin_ratio_x, edge_margin_min_px, edge_margin_max_px)
	var margin_y = clamp(vp_rect.size.y * edge_margin_ratio_y, edge_margin_min_px, edge_margin_max_px)

	var pan_factor_x: float = 0.0
	if mouse_pos.x < margin_x:
		pan_factor_x = -clamp((margin_x - mouse_pos.x) / margin_x, 0.0, 1.0)
	elif mouse_pos.x > vp_rect.size.x - margin_x:
		pan_factor_x = clamp((mouse_pos.x - (vp_rect.size.x - margin_x)) / margin_x, 0.0, 1.0)

	var pan_factor_y: float = 0.0
	if mouse_pos.y < margin_y:
		pan_factor_y = clamp((margin_y - mouse_pos.y) / margin_y, 0.0, 1.0) # Up on screen
	elif mouse_pos.y > vp_rect.size.y - margin_y:
		pan_factor_y = -clamp((mouse_pos.y - (vp_rect.size.y - margin_y)) / margin_y, 0.0, 1.0) # Down on screen

	if pan_factor_x != 0.0 or pan_factor_y != 0.0:
		var move_vector = (cam_screen_right * pan_factor_x) + (cam_screen_fwd * pan_factor_y)
		var speed_mult = move_vector.length()
		global_position += move_vector.normalized() * (pan_speed * speed_mult) * delta
		_clamp_pivot_position()

func _clamp_pivot_position() -> void:
	global_position.x = clamp(global_position.x, min_bound_x, max_bound_x)
	global_position.z = clamp(global_position.z, min_bound_z, max_bound_z)
	global_position.y = 0.0

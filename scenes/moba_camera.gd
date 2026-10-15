extends Node3D
class_name MobaCamera

# game-x0-moba 1:1 Camera Controller
# Source: jogo/src/Camera.ts
# FOV: 38°, OffsetBase: (0, 56, 48), Smoothing: 0.08, MapLimits: ±38
# Default mode: Locked with Mouse Ratio offset (max 6.0 units)

enum Mode {
	FREE,
	LOCKED
}

@export var target: Node3D
@export var current_mode: Mode = Mode.LOCKED

# Camera physical offset matching Camera.ts: Vector3(0, 56, 48)
const OFFSET_BASE := Vector3(0.0, 56.0, 48.0)
const CAMERA_FOV: float = 38.0
const MAP_LIMIT_X: float = 38.0
const MAP_LIMIT_Z: float = 38.0
const MAX_LOCK_OFFSET: float = 6.0
const SMOOTHING: float = 0.08
const EDGE_SCROLL_SPEED: float = 40.0
const DRAG_SPEED: float = 0.05

@export var edge_scroll_enabled: bool = true
# Windowed-mode comfortable edge margin (prevents cursor from leaving browser canvas)
@export var edge_margin_ratio_x: float = 0.04
@export var edge_margin_ratio_y: float = 0.06
@export var edge_margin_min_px: float = 24.0
@export var edge_margin_max_px: float = 60.0

@onready var camera: Camera3D = $Camera3D

var camera_target: Vector3 = Vector3.ZERO
var is_space_held: bool = false
var is_mmb_dragging: bool = false
var is_headless: bool = false
var mouse_screen_pos: Vector2 = Vector2.ZERO

signal camera_mode_changed(new_mode: Mode, mode_name: String)

func _ready() -> void:
	is_headless = DisplayServer.get_name() == "headless"
	current_mode = Mode.LOCKED

	if not is_headless and camera:
		camera.fov = CAMERA_FOV
		_apply_camera_transform()

	if target:
		camera_target = target.global_position
		global_position = camera_target
		_clamp_target()

func _apply_camera_transform() -> void:
	if not camera:
		return
	camera.position = OFFSET_BASE
	camera.look_at_from_position(OFFSET_BASE, Vector3.ZERO, Vector3.UP)

func handle_input(event: InputEvent) -> bool:
	var handled = false

	# 1. Key inputs: Space / Quote (Hold to center/follow) and Y (Toggle Lock)
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_APOSTROPHE or event.keycode == KEY_QUOTELEFT:
			is_space_held = event.pressed
			emit_signal("camera_mode_changed", current_mode, get_mode_name())
			handled = true
		elif event.keycode == KEY_Y and event.pressed:
			toggle_lock()
			handled = true

	# 2. Mouse buttons: MMB drag
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_mmb_dragging = event.pressed
			emit_signal("camera_mode_changed", current_mode, get_mode_name())
			handled = true

	# 3. Mouse motion for MMB drag
	elif event is InputEventMouseMotion:
		mouse_screen_pos = event.position
		if is_mmb_dragging:
			# In Camera.ts: cameraTarget.x -= dx; cameraTarget.z -= dy
			camera_target.x -= event.relative.x * DRAG_SPEED
			camera_target.z -= event.relative.y * DRAG_SPEED
			_clamp_target()
			handled = true

	return handled

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
		return "Center (Space)"
	return "Locked" if current_mode == Mode.LOCKED else "Free"

func center_on_target(smooth: bool = false) -> void:
	if not target:
		return
	if smooth:
		camera_target = camera_target.lerp(target.global_position, 0.5)
	else:
		camera_target = target.global_position
	_clamp_target()
	global_position = camera_target

func _process(delta: float) -> void:
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if is_headless:
		if target and is_following_hero():
			camera_target = target.global_position
			global_position = camera_target
		return

	var vp = get_viewport()
	if not vp:
		return

	var vp_size = vp.get_visible_rect().size
	var mouse_pos = vp.get_mouse_position()

	# 1. Modo Locked com Folga de Cursor (Camera.ts linhas 86-103)
	if is_following_hero() and target:
		if not is_mmb_dragging:
			var center_x = vp_size.x * 0.5
			var center_y = vp_size.y * 0.5

			var ratio_x = clamp((mouse_pos.x - center_x) / max(1.0, center_x), -1.0, 1.0)
			var ratio_y = clamp((mouse_pos.y - center_y) / max(1.0, center_y), -1.0, 1.0)

			var desired_target = target.global_position
			desired_target.x += ratio_x * MAX_LOCK_OFFSET
			desired_target.z += ratio_y * MAX_LOCK_OFFSET

			# CameraTarget lerps smoothly with factor 0.08
			camera_target = camera_target.lerp(desired_target, SMOOTHING)

	# 2. Modo Free com Edge Scrolling
	elif current_mode == Mode.FREE and edge_scroll_enabled and not is_mmb_dragging:
		var vp_rect = vp.get_visible_rect()
		if vp_rect.has_point(mouse_pos):
			var margin_x = clamp(vp_size.x * edge_margin_ratio_x, edge_margin_min_px, edge_margin_max_px)
			var margin_y = clamp(vp_size.y * edge_margin_ratio_y, edge_margin_min_px, edge_margin_max_px)

			var move_x: float = 0.0
			var move_z: float = 0.0

			if mouse_pos.x <= margin_x:
				move_x = -1.0
			elif mouse_pos.x >= vp_size.x - margin_x:
				move_x = 1.0

			if mouse_pos.y <= margin_y:
				move_z = -1.0
			elif mouse_pos.y >= vp_size.y - margin_y:
				move_z = 1.0

			if move_x != 0.0 or move_z != 0.0:
				var move_dir = Vector3(move_x, 0.0, move_z).normalized()
				camera_target += move_dir * (EDGE_SCROLL_SPEED * delta)

	# 3. Clamping nos limites do mapa (±38m)
	_clamp_target()

	# 4. Atualiza pivô no mundo
	global_position = camera_target

func _clamp_target() -> void:
	camera_target.x = clamp(camera_target.x, -MAP_LIMIT_X, MAP_LIMIT_X)
	camera_target.z = clamp(camera_target.z, -MAP_LIMIT_Z, MAP_LIMIT_Z)
	camera_target.y = 0.0

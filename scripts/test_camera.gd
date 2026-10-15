extends SceneTree

# Automated test for MobaCamera controller (1:1 port of game-x0-moba Camera.ts)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("[test_camera] Loading Main scene for camera controller verification...")
	var err = change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		printerr("[test_camera] FAILED: Could not load main scene, error: %d" % err)
		quit(1)
		return

	await process_frame
	await process_frame

	var main = current_scene
	var hero: Hero = main.get_node_or_null("Hero")
	var cam: MobaCamera = main.get_node_or_null("CameraPivot")

	if not hero or not cam:
		printerr("[test_camera] FAILED: Hero or CameraPivot not found in scene")
		quit(1)
		return

	# 1. Initial State: LOCKED mode by default (matching Camera.ts defaultLocked = true)
	print("[test_camera] Check 1: Initial state (Locked mode by default)...")
	if cam.current_mode != MobaCamera.Mode.LOCKED:
		printerr("[test_camera] FAILED: Camera should start in LOCKED mode, but was %d" % cam.current_mode)
		quit(1)
		return

	var dist_to_hero = cam.global_position.distance_to(hero.global_position)
	if dist_to_hero > 0.5:
		printerr("[test_camera] FAILED: Camera should start at hero, but dist was %.2f" % dist_to_hero)
		quit(1)
		return

	# 2. Toggle Lock (Y)
	print("[test_camera] Check 2: Toggle Lock (Y)...")
	cam.toggle_lock()
	if cam.current_mode != MobaCamera.Mode.FREE:
		printerr("[test_camera] FAILED: Mode should be FREE after first toggle")
		quit(1)
		return

	cam.toggle_lock()
	if cam.current_mode != MobaCamera.Mode.LOCKED:
		printerr("[test_camera] FAILED: Mode should return to LOCKED after second toggle")
		quit(1)
		return

	# Switch to FREE for remaining free camera tests
	cam.set_mode(MobaCamera.Mode.FREE)

	# 3. Space Bar centering
	print("[test_camera] Check 3: Space Bar centering...")
	cam.camera_target = Vector3(8.0, 0.0, 5.0)
	cam.global_position = cam.camera_target
	cam.is_space_held = true
	if not cam.is_following_hero():
		printerr("[test_camera] FAILED: is_following_hero should be true when space is held")
		quit(1)
		return

	# 4. Arena boundary clamping (±38m matching Camera.ts mapLimitX = 38, mapLimitZ = 38)
	print("[test_camera] Check 4: Arena boundary clamping (±38m)...")
	cam.camera_target = Vector3(100.0, 0.0, -100.0)
	cam._clamp_target()
	if cam.camera_target.x > MobaCamera.MAP_LIMIT_X or cam.camera_target.z < -MobaCamera.MAP_LIMIT_Z:
		printerr("[test_camera] FAILED: Camera target exceeded boundary limits: %s" % cam.camera_target)
		quit(1)
		return

	# 5. Event handling (Space, Quote, Y)
	print("[test_camera] Check 5: Event handling via handle_input()...")
	var key_y_event = InputEventKey.new()
	key_y_event.keycode = KEY_Y
	key_y_event.pressed = true
	var handled_y = cam.handle_input(key_y_event)
	if not handled_y or cam.current_mode != MobaCamera.Mode.LOCKED:
		printerr("[test_camera] FAILED: handle_input did not process KEY_Y")
		quit(1)
		return

	var key_space_event = InputEventKey.new()
	key_space_event.keycode = KEY_SPACE
	key_space_event.pressed = true
	var handled_space = cam.handle_input(key_space_event)
	if not handled_space or not cam.is_space_held:
		printerr("[test_camera] FAILED: handle_input did not process KEY_SPACE press")
		quit(1)
		return

	key_space_event.pressed = false
	cam.handle_input(key_space_event)
	if cam.is_space_held:
		printerr("[test_camera] FAILED: handle_input did not process KEY_SPACE release")
		quit(1)
		return

	# Test Quote key (' / Apostrophe) for centering
	var key_quote_event = InputEventKey.new()
	key_quote_event.keycode = KEY_APOSTROPHE
	key_quote_event.pressed = true
	var handled_quote = cam.handle_input(key_quote_event)
	if not handled_quote or not cam.is_space_held:
		printerr("[test_camera] FAILED: handle_input did not process KEY_APOSTROPHE press")
		quit(1)
		return
	key_quote_event.pressed = false
	cam.handle_input(key_quote_event)

	# Reset mode to FREE
	cam.set_mode(MobaCamera.Mode.FREE)

	# 6. Middle Mouse Button (MMB) Drag Navigation
	print("[test_camera] Check 6: Middle Mouse Drag (MMB) panning...")
	cam.camera_target = Vector3(0, 0, 0)
	var mmb_press = InputEventMouseButton.new()
	mmb_press.button_index = MOUSE_BUTTON_MIDDLE
	mmb_press.pressed = true
	var handled_mmb = cam.handle_input(mmb_press)
	if not handled_mmb or not cam.is_mmb_dragging:
		printerr("[test_camera] FAILED: MMB press did not start drag")
		quit(1)
		return

	if cam.get_mode_name() != "Panning (MMB)":
		printerr("[test_camera] FAILED: Expected mode name 'Panning (MMB)', got '%s'" % cam.get_mode_name())
		quit(1)
		return

	var mouse_motion = InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(80.0, -40.0)
	var handled_motion = cam.handle_input(mouse_motion)
	if not handled_motion or cam.camera_target == Vector3.ZERO:
		printerr("[test_camera] FAILED: Mouse motion during MMB drag did not move camera target")
		quit(1)
		return

	var mmb_release = InputEventMouseButton.new()
	mmb_release.button_index = MOUSE_BUTTON_MIDDLE
	mmb_release.pressed = false
	cam.handle_input(mmb_release)
	if cam.is_mmb_dragging:
		printerr("[test_camera] FAILED: MMB release did not stop drag")
		quit(1)
		return

	# 7. FOV and Offset validation
	print("[test_camera] Check 7: Camera FOV (38°) and Offset (0, 56, 48)...")
	if cam.camera.fov != 38.0:
		printerr("[test_camera] FAILED: Expected FOV 38.0, got %.1f" % cam.camera.fov)
		quit(1)
		return

	if cam.camera.position != MobaCamera.OFFSET_BASE:
		printerr("[test_camera] FAILED: Expected offset (0, 56, 48), got %s" % cam.camera.position)
		quit(1)
		return

	print("[test_camera] SUCCESS: All 7 MobaCamera checks passed cleanly!")
	quit(0)

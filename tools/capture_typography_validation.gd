extends SceneTree

func _init() -> void:
	print("[TypoValidation] Starting typography validation capture (Native)...")
	var main_packed = load("res://scenes/main.tscn") as PackedScene
	if not main_packed:
		quit(1)
		return

	var main = main_packed.instantiate()
	root.add_child(main)
	current_scene = main

	_run_capture(main)

func _run_capture(main: Node) -> void:
	var out_dir = "docs/migration/visual"

	# 1. Settle and capture Idle state
	for i in range(30):
		await process_frame

	var vp = main.get_viewport()

	var img_idle = vp.get_texture().get_image()
	img_idle.save_png("%s/typography_9px_after_native_idle.png" % out_dir)
	print("[TypoValidation] Saved %s/typography_9px_after_native_idle.png" % out_dir)

	# 2. Start moving Caitlyn towards target (10, 0, 10)
	var hero = main.get("hero")
	if hero and hero.has_method("set_move_target"):
		hero.set_move_target(Vector3(10, 0, 10))

	# Advance 20 frames into movement so velocity is at full 16 m/s
	for i in range(20):
		await process_frame

	var img_moving = vp.get_texture().get_image()
	img_moving.save_png("%s/typography_9px_after_native_moving.png" % out_dir)
	print("[TypoValidation] Saved %s/typography_9px_after_native_moving.png" % out_dir)

	# 3. Pan camera
	var cam = main.get("camera_controller")
	if cam:
		cam.global_position += Vector3(12, 0, 8)

	for i in range(15):
		await process_frame

	var img_cam = vp.get_texture().get_image()
	img_cam.save_png("%s/typography_9px_after_native_camera.png" % out_dir)
	print("[TypoValidation] Saved %s/typography_9px_after_native_camera.png" % out_dir)

	print("[TypoValidation] Native capture completed successfully!")
	quit(0)

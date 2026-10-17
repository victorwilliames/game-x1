extends SceneTree

func _init() -> void:
	print("[Verify] Starting visual verification for Dummy flash/death/respawn and typography...")
	var main_packed = load("res://scenes/main.tscn") as PackedScene
	if not main_packed:
		push_error("Failed to load main.tscn")
		quit(1)
		return

	var main = main_packed.instantiate()
	root.add_child(main)
	current_scene = main

	_run_verification(main)

func _run_verification(main: Node) -> void:
	var out_dir = "docs/migration/visual"

	# Settle scene
	for i in range(30):
		await process_frame

	var vp = root.get_viewport()

	# 1. Capture pristine idle state with floating bars & HUD
	var img_idle = vp.get_texture().get_image()
	img_idle.save_png("%s/verify_idle_ui.png" % out_dir)
	print("[Verify] Saved %s/verify_idle_ui.png" % out_dir)

	# 2. Get DummyStatic
	var dummy: MobaDummy = null
	for d in main.get("dummies"):
		if d is MobaDummy and d.mode == "static":
			dummy = d
			break

	if not dummy:
		push_error("DummyStatic not found")
		quit(1)
		return

	# 3. Apply non-lethal damage to trigger white flash
	dummy.take_damage(55.0)
	await process_frame
	var img_flash = vp.get_texture().get_image()
	img_flash.save_png("%s/verify_dummy_hit_flash.png" % out_dir)
	print("[Verify] Saved %s/verify_dummy_hit_flash.png (Hit flash active)" % out_dir)

	# 4. Apply lethal damage to trigger death
	dummy.take_damage(600.0)
	await process_frame
	var img_death = vp.get_texture().get_image()
	img_death.save_png("%s/verify_dummy_death_floor.png" % out_dir)
	print("[Verify] Saved %s/verify_dummy_death_floor.png (Dead dummy on floor - checking flash cleared)" % out_dir)

	# 5. Advance time by 3.1 seconds in steps to trigger respawn
	var elapsed := 0.0
	while elapsed < 3.2:
		var dt := 0.05
		dummy.update_dummy(dt)
		elapsed += dt
		await process_frame

	var img_respawn = vp.get_texture().get_image()
	img_respawn.save_png("%s/verify_dummy_respawned.png" % out_dir)
	print("[Verify] Saved %s/verify_dummy_respawned.png (Respawned dummy - checking material normal)" % out_dir)

	print("[Verify] All verification frames captured successfully!")
	quit(0)

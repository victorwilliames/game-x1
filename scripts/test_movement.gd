extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("[test_movement] Loading Main scene for movement verification...")
	var err = change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		printerr("[test_movement] FAILED: Could not load main scene, error: %d" % err)
		quit(1)
		return

	# Wait 2 frames for scene tree and physics space to be fully active
	await process_frame
	await process_frame

	var hero: Hero = current_scene.get_node_or_null("Hero")
	if not hero:
		printerr("[test_movement] FAILED: Hero not found in scene")
		quit(1)
		return

	# Position hero at known position on lane
	hero.global_position = Vector3(0, 0, 10.0)
	var destination = Vector3(0, 0, 2.0)

	print("[test_movement] Starting test: Hero at %s -> Target %s" % [hero.global_position, destination])
	hero.set_move_target(destination)

	var reached = false
	var max_frames = 180

	for frame in range(max_frames):
		await physics_frame
		if not hero.has_move_target:
			reached = true
			break

	var final_dist = Vector2(hero.global_position.x - destination.x, hero.global_position.z - destination.z).length()
	var final_speed = Vector2(hero.velocity.x, hero.velocity.z).length()

	print("[test_movement] Simulation done. Reached flag: %s, Distance to target: %.4f m, Final speed: %.4f m/s" % [
		str(reached), final_dist, final_speed
	])

	if not reached:
		printerr("[test_movement] FAILED: Hero did not reach target within %d physics frames" % max_frames)
		quit(1)
		return

	if final_dist > hero.arrival_threshold + 0.05:
		printerr("[test_movement] FAILED: Final distance %.4f exceeds threshold %.4f" % [final_dist, hero.arrival_threshold])
		quit(1)
		return

	if final_speed > 0.05:
		printerr("[test_movement] FAILED: Hero did not come to a full stop (speed: %.4f)" % final_speed)
		quit(1)
		return

	print("[test_movement] SUCCESS: Hero reached target accurately without oscillation and returned to IDLE!")
	quit(0)

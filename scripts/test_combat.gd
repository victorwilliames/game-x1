extends SceneTree

## Automated headless test suite for combat, dummies, projectiles, and targeting.

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("[test_combat] Loading Main scene for combat verification...")
	var err = change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		printerr("[test_combat] FAILED: Could not load main scene, error: %d" % err)
		quit(1)
		return

	# Wait 2 frames for scene to be ready
	await process_frame
	await process_frame

	var main_scene = current_scene
	var hero: Hero = main_scene.get_node_or_null("Hero")
	var dummy_static: MobaDummy = main_scene.get_node_or_null("Dummies/DummyStatic")
	var dummy_moving: MobaDummy = main_scene.get_node_or_null("Dummies/DummyMoving")

	if not hero or not dummy_static or not dummy_moving:
		printerr("[test_combat] FAILED: Hero or Dummies not found in scene")
		quit(1)
		return

	# Check 1: Initial Dummy attributes (600 HP, active, positions)
	print("[test_combat] Check 1: Dummy initial attributes...")
	assert_check(dummy_static.hp == 600.0, "DummyStatic HP is 600")
	assert_check(dummy_static.active == true, "DummyStatic is active")
	assert_check(dummy_moving.hp == 600.0, "DummyMoving HP is 600")
	assert_check(dummy_moving.active == true, "DummyMoving is active")

	# Check 2: Caitlyn initial combat attributes
	print("[test_combat] Check 2: Caitlyn initial combat attributes...")
	assert_check(hero.hp == 1072.0, "Caitlyn HP is 1072")
	assert_check(hero.attack_range == 18.0, "Caitlyn attack range is 18.0")
	assert_check(hero.attack_speed == 1.85, "Caitlyn attack speed is 1.85")
	assert_check(hero.speed == 16.0, "Caitlyn move speed is 16.0")

	# Check 3: Targeting System logic
	print("[test_combat] Check 3: Targeting System...")
	var dummies = [dummy_static, dummy_moving]
	var cursor_near_moving = Vector3(-6.5, 0, 6.8)
	var target1 = TargetingSystem.find_best_target(hero.global_position, cursor_near_moving, dummies, 18.0)
	assert_check(target1 == dummy_moving, "Targeting prioritizes dummy near cursor within 5.0m")

	var cursor_far = Vector3(30, 0, 30)
	dummy_static.global_position = Vector3(5, 0, 0)
	dummy_moving.global_position = Vector3(-10, 0, 0)
	var target2 = TargetingSystem.find_best_target(Vector3.ZERO, cursor_far, dummies, 18.0)
	assert_check(target2 == dummy_static, "Targeting fallbacks to closest dummy to hero")

	# Check 4: Melee Attack Detection (<= 3.2m triggers melee coronhada)
	print("[test_combat] Check 4: Melee attack threshold...")
	hero.attack_cooldown = 0.0
	hero.global_position = Vector3.ZERO
	dummy_static.global_position = Vector3(2.5, 0, 0) # Distance 2.5 <= 3.2
	hero.start_attack(dummy_static, null)
	assert_check(hero.is_melee_attack == true, "Attack within 3.2m marked as melee")
	hero.cancel_attack()

	# Distance > 3.2m triggers ranged attack
	hero.attack_cooldown = 0.0
	dummy_static.global_position = Vector3(8.0, 0, 0)
	hero.start_attack(dummy_static, null)
	assert_check(hero.is_melee_attack == false, "Attack beyond 3.2m marked as ranged")
	hero.cancel_attack()

	# Check 5: Attack windup and execution
	print("[test_combat] Check 5: Attack windup and execution...")
	hero.attack_cooldown = 0.0
	var shot_data := {"fired": false, "target": null}

	var shoot_cb = func(t, _d, _m):
		shot_data["fired"] = true
		shot_data["target"] = t

	hero.shoot.connect(shoot_cb)
	dummy_static.global_position = Vector3(6.0, 0, 0)
	hero.start_attack(dummy_static, null)

	# Wait for windup timer (0.04s = 3-5 physics frames)
	for i in range(5):
		await physics_frame

	assert_check(shot_data["fired"] == true, "Shoot emitted after 0.04s windup")
	assert_check(shot_data["target"] == dummy_static, "Shoot target matches dummy")
	hero.shoot.disconnect(shoot_cb)

	# Check 6: Dummy damage, death and respawn
	print("[test_combat] Check 6: Dummy take damage and death...")
	dummy_static.hp = 50.0
	dummy_static.take_damage(55.0)
	assert_check(dummy_static.hp == 0.0, "Dummy HP drops to 0")
	assert_check(dummy_static.active == false, "Dummy becomes inactive upon death")
	assert_check(dummy_static.respawn_timer == 3.0, "Dummy respawn timer set to 3.0s")

	# Check 7: Rapid click kiting bonus
	print("[test_combat] Check 7: Rapid click kiting bonus...")
	hero.attack_cooldown = 0.0
	hero.last_attack_click_time = (Time.get_ticks_msec() / 1000.0) - 0.20 # 200ms interval (between 0.10 and 0.42)
	hero.start_attack(dummy_moving, null)
	assert_check(hero.consecutive_fast_clicks == 1, "Consecutive fast clicks incremented to 1")
	assert_check(hero.attack_speed_bonus == 0.15, "Attack speed bonus is +15%")

	print("[test_combat] SUCCESS: All 7 Combat & Dummy checks passed cleanly!")
	quit(0)

func assert_check(condition: bool, description: String) -> void:
	if not condition:
		printerr("[test_combat] FAILED: %s" % description)
		quit(1)
	else:
		print("  ✓ %s" % description)

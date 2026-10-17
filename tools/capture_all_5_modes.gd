extends SceneTree

func _init() -> void:
	print("[Capture5] Capturing all 5 benchmark modes...")
	var main_packed = load("res://scenes/main.tscn") as PackedScene
	if not main_packed:
		quit(1)
		return

	var main = main_packed.instantiate()
	root.add_child(main)
	current_scene = main

	_run_capture(main)

func _run_capture(main: Node) -> void:
	for i in range(25):
		await process_frame

	var pb = root.get_node_or_null("PerfBench")
	if not pb:
		push_error("PerfBench autoload not found")
		quit(1)
		return

	pb.set("_main", main)

	var modes = ["full", "pass_only", "crop_draw", "crop_copy", "no_fxaa"]
	var vp = root.get_viewport()
	var out_dir = "docs/migration/visual"

	for m in modes:
		pb.call("_apply_config", m)
		for i in range(15):
			await process_frame
		var img = vp.get_texture().get_image()
		img.save_png("%s/mode_5_%s.png" % [out_dir, m])
		print("[Capture5] Saved %s/mode_5_%s.png" % [out_dir, m])

	# Restore full
	pb.call("_apply_config", "full")
	for i in range(5):
		await process_frame

	print("[Capture5] All 5 modes captured successfully without errors!")
	quit(0)

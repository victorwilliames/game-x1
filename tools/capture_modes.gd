extends SceneTree

func _init() -> void:
	print("[CaptureModes] Initializing mode visual capture...")
	var main_packed = load("res://scenes/main.tscn") as PackedScene
	if not main_packed:
		push_error("Failed to load main.tscn")
		quit(1)
		return

	var main = main_packed.instantiate()
	root.add_child(main)
	current_scene = main

	_run_capture(main)

func _run_capture(main: Node) -> void:
	# Wait for scene to settle
	for i in range(30):
		await process_frame

	var fxaa_rect = main.get_node_or_null("PostProcessLayer/FXAAEffect") as ColorRect
	var pp = main.get_node_or_null("PostProcessLayer") as CanvasLayer

	var baseline_mat = fxaa_rect.material if fxaa_rect else null
	var pass_mat = ShaderMaterial.new()
	pass_mat.shader = load("res://shaders/screen_passthrough.gdshader") as Shader

	var out_dir = "docs/migration/visual"

	# 1. Mode FULL
	if pp: pp.visible = true
	if fxaa_rect and baseline_mat: fxaa_rect.material = baseline_mat
	for i in range(15):
		await process_frame
	var img_full = root.get_viewport().get_texture().get_image()
	img_full.save_png("%s/mode_full.png" % out_dir)
	print("[CaptureModes] Saved %s/mode_full.png" % out_dir)

	# 2. Mode PASS_ONLY
	if pp: pp.visible = true
	if fxaa_rect: fxaa_rect.material = pass_mat
	for i in range(15):
		await process_frame
	var img_pass = root.get_viewport().get_texture().get_image()
	img_pass.save_png("%s/mode_pass_only.png" % out_dir)
	print("[CaptureModes] Saved %s/mode_pass_only.png" % out_dir)

	# 3. Mode NO_FXAA
	if pp: pp.visible = false
	if fxaa_rect and baseline_mat: fxaa_rect.material = baseline_mat
	for i in range(15):
		await process_frame
	var img_nofxaa = root.get_viewport().get_texture().get_image()
	img_nofxaa.save_png("%s/mode_no_fxaa.png" % out_dir)
	print("[CaptureModes] Saved %s/mode_no_fxaa.png" % out_dir)

	print("[CaptureModes] All 3 modes captured successfully!")
	quit(0)

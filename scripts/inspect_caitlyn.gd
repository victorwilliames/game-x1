extends SceneTree

func _init() -> void:
	print("[inspect_caitlyn] Loading CaitlynComplete.glb...")
	var scene = load("res://assets/characters/caitlyn/CaitlynComplete.glb")
	if not scene:
		printerr("[inspect_caitlyn] Failed to load CaitlynComplete.glb")
		quit(1)
		return

	var instance = scene.instantiate()
	print("[inspect_caitlyn] Instance root class: %s, name: %s" % [instance.get_class(), instance.name])

	var anim_player: AnimationPlayer = null
	for child in instance.get_children():
		print("  - Child: %s (%s)" % [child.name, child.get_class()])
		if child is AnimationPlayer:
			anim_player = child

	if anim_player:
		print("[inspect_caitlyn] AnimationPlayer found! Total animations: %d" % anim_player.get_animation_list().size())
		for anim_name in anim_player.get_animation_list():
			var anim = anim_player.get_animation(anim_name)
			print("    * Animation: %s (Length: %.2fs, Loop: %s)" % [
				anim_name, anim.length, str(anim.loop_mode)
			])
	else:
		print("[inspect_caitlyn] No direct AnimationPlayer child, searching recursively...")
		var found = _find_anim_player(instance)
		if found:
			print("[inspect_caitlyn] Recursive AnimationPlayer found on: %s, animations: %s" % [
				found.get_path(), str(found.get_animation_list())
			])

	# Also check pointTarget.glb
	print("[inspect_caitlyn] Loading pointTarget.glb...")
	var pt_scene = load("res://assets/ui/rts-target/pointTarget.glb")
	if pt_scene:
		var pt_inst = pt_scene.instantiate()
		print("[inspect_caitlyn] pointTarget root: %s (%s)" % [pt_inst.name, pt_inst.get_class()])

	quit(0)

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var res = _find_anim_player(child)
		if res:
			return res
	return null

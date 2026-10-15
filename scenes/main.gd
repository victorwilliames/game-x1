extends Node3D

@onready var fps_label: Label = $UI/MarginContainer/VBoxContainer/FPSLabel
@onready var info_label: Label = $UI/MarginContainer/VBoxContainer/InfoLabel
@onready var center_marker: MeshInstance3D = $Arena/CenterMarker

var is_headless: bool = false

func _ready() -> void:
	is_headless = DisplayServer.get_name() == "headless"
	if not is_headless:
		var renderer_name = ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")
		info_label.text = "game-x1 | Stage 0: Web Foundation\nRenderer: %s | Platform: %s" % [renderer_name, OS.get_name()]
	print("[game-x1] Main scene ready. Platform: %s, Headless: %s" % [OS.get_name(), str(is_headless)])

func _process(delta: float) -> void:
	if is_headless:
		return
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	if center_marker:
		center_marker.rotate_y(delta * 0.8)

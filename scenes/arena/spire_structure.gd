extends Node3D
class_name SpireStructure

@export var is_enemy: bool = false
@onready var crystal: MeshInstance3D = $Pedestal/Crystal

func _process(delta: float) -> void:
	if crystal:
		crystal.rotate_y(delta * 0.8)
		crystal.position.y = 2.6 + sin(Time.get_ticks_msec() / 1000.0 * 1.8) * 0.08

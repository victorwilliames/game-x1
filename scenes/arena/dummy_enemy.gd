extends Node3D
class_name DummyEnemy

@onready var hips_pivot: Node3D = $Visual/HipsPivot
@onready var left_arm: Node3D = $Visual/HipsPivot/SpinePivot/ChestPivot/LeftShoulderPivot
@onready var right_arm: Node3D = $Visual/HipsPivot/SpinePivot/ChestPivot/RightShoulderPivot
@onready var left_elbow: Node3D = $Visual/HipsPivot/SpinePivot/ChestPivot/LeftShoulderPivot/LeftElbowPivot
@onready var right_elbow: Node3D = $Visual/HipsPivot/SpinePivot/ChestPivot/RightShoulderPivot/RightElbowPivot
@onready var left_hip: Node3D = $Visual/HipsPivot/LeftHipPivot
@onready var right_hip: Node3D = $Visual/HipsPivot/RightHipPivot
@onready var left_knee: Node3D = $Visual/HipsPivot/LeftHipPivot/LeftKneePivot
@onready var right_knee: Node3D = $Visual/HipsPivot/RightHipPivot/RightKneePivot
@onready var spine: Node3D = $Visual/HipsPivot/SpinePivot

var time_offset: float = 0.0

func _ready() -> void:
	# Randomize phase so multiple dummies don't breathe in perfect unison
	time_offset = randf() * 10.0
	_apply_combat_ready_pose()

func _apply_combat_ready_pose() -> void:
	if not hips_pivot:
		return
	# Slightly crouched combat stance as in reference image
	hips_pivot.position.y = 0.88
	if spine:
		spine.rotation.x = 0.18
	if left_hip:
		left_hip.rotation.x = -0.25
	if right_hip:
		right_hip.rotation.x = -0.15
	if left_knee:
		left_knee.rotation.x = 0.45
	if right_knee:
		right_knee.rotation.x = 0.35
	if left_arm:
		left_arm.rotation.x = -0.5
		left_arm.rotation.z = -0.2
	if right_arm:
		right_arm.rotation.x = -0.45
		right_arm.rotation.z = 0.2
	if left_elbow:
		left_elbow.rotation.x = -0.6
	if right_elbow:
		right_elbow.rotation.x = -0.7

func _process(delta: float) -> void:
	if not hips_pivot:
		return
	# Gentle combat idle breathing
	var breath = sin((Time.get_ticks_msec() / 1000.0 + time_offset) * 2.2) * 0.02
	hips_pivot.position.y = 0.88 + breath * 0.4
	if spine:
		spine.rotation.x = 0.18 + breath * 0.3

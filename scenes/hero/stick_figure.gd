extends Node3D
class_name StickFigureVisual

# References to bone pivots for articulated animation
@onready var hips_pivot: Node3D = $HipsPivot
@onready var spine_pivot: Node3D = $HipsPivot/SpinePivot
@onready var chest_pivot: Node3D = $HipsPivot/SpinePivot/ChestPivot
@onready var head_pivot: Node3D = $HipsPivot/SpinePivot/ChestPivot/HeadPivot

@onready var left_shoulder_pivot: Node3D = $HipsPivot/SpinePivot/ChestPivot/LeftShoulderPivot
@onready var left_elbow_pivot: Node3D = $HipsPivot/SpinePivot/ChestPivot/LeftShoulderPivot/LeftElbowPivot

@onready var right_shoulder_pivot: Node3D = $HipsPivot/SpinePivot/ChestPivot/RightShoulderPivot
@onready var right_elbow_pivot: Node3D = $HipsPivot/SpinePivot/ChestPivot/RightShoulderPivot/RightElbowPivot

@onready var left_hip_pivot: Node3D = $HipsPivot/LeftHipPivot
@onready var left_knee_pivot: Node3D = $HipsPivot/LeftHipPivot/LeftKneePivot

@onready var right_hip_pivot: Node3D = $HipsPivot/RightHipPivot
@onready var right_knee_pivot: Node3D = $HipsPivot/RightHipPivot/RightKneePivot

var anim_time: float = 0.0
var current_speed: float = 0.0
var is_moving: bool = false

# Default base positions
var default_hips_y: float = 0.95

func _ready() -> void:
	if hips_pivot:
		default_hips_y = hips_pivot.position.y

func update_state(moving: bool, speed: float) -> void:
	is_moving = moving
	current_speed = speed

func _process(delta: float) -> void:
	if not hips_pivot:
		return

	if is_moving and current_speed > 0.1:
		_animate_run(delta)
	else:
		_animate_idle(delta)

func _animate_run(delta: float) -> void:
	# Running animation cycle: legs and arms swing in opposition
	anim_time += delta * current_speed * 2.2
	var stride_angle: float = 0.65
	var arm_angle: float = 0.5

	var leg_cycle: float = sin(anim_time)
	var opp_cycle: float = -leg_cycle

	# Legs swing
	left_hip_pivot.rotation.x = lerp_angle(left_hip_pivot.rotation.x, leg_cycle * stride_angle, 0.4)
	right_hip_pivot.rotation.x = lerp_angle(right_hip_pivot.rotation.x, opp_cycle * stride_angle, 0.4)

	# Knees bend more when trailing back
	var left_knee_target = max(0.0, -leg_cycle * 0.9)
	var right_knee_target = max(0.0, -opp_cycle * 0.9)
	left_knee_pivot.rotation.x = lerp_angle(left_knee_pivot.rotation.x, left_knee_target, 0.4)
	right_knee_pivot.rotation.x = lerp_angle(right_knee_pivot.rotation.x, right_knee_target, 0.4)

	# Arms swing in opposite direction to legs
	left_shoulder_pivot.rotation.x = lerp_angle(left_shoulder_pivot.rotation.x, opp_cycle * arm_angle, 0.4)
	right_shoulder_pivot.rotation.x = lerp_angle(right_shoulder_pivot.rotation.x, leg_cycle * arm_angle, 0.4)

	# Elbows slightly bent during run
	left_elbow_pivot.rotation.x = lerp_angle(left_elbow_pivot.rotation.x, -0.4, 0.2)
	right_elbow_pivot.rotation.x = lerp_angle(right_elbow_pivot.rotation.x, -0.4, 0.2)

	# Slight vertical bobbing and torso tilt forward
	hips_pivot.position.y = default_hips_y + abs(sin(anim_time)) * 0.05
	spine_pivot.rotation.x = lerp_angle(spine_pivot.rotation.x, 0.12, 0.2)
	head_pivot.rotation.x = lerp_angle(head_pivot.rotation.x, -0.08, 0.2)

func _animate_idle(delta: float) -> void:
	# Idle breathing and gentle sway
	anim_time += delta * 2.5
	var breath: float = sin(anim_time) * 0.04

	# Reset hips and legs smoothly
	hips_pivot.position.y = lerp(hips_pivot.position.y, default_hips_y + breath * 0.3, 0.15)
	left_hip_pivot.rotation.x = lerp_angle(left_hip_pivot.rotation.x, 0.0, 0.15)
	right_hip_pivot.rotation.x = lerp_angle(right_hip_pivot.rotation.x, 0.0, 0.15)
	left_knee_pivot.rotation.x = lerp_angle(left_knee_pivot.rotation.x, 0.0, 0.15)
	right_knee_pivot.rotation.x = lerp_angle(right_knee_pivot.rotation.x, 0.0, 0.15)

	# Spine breathing movement
	spine_pivot.rotation.x = lerp_angle(spine_pivot.rotation.x, breath * 0.5, 0.1)
	head_pivot.rotation.x = lerp_angle(head_pivot.rotation.x, -breath * 0.3, 0.1)

	# Arms relaxed at sides with gentle breathing swing
	left_shoulder_pivot.rotation.x = lerp_angle(left_shoulder_pivot.rotation.x, breath * 0.8, 0.1)
	right_shoulder_pivot.rotation.x = lerp_angle(right_shoulder_pivot.rotation.x, breath * 0.8, 0.1)
	left_elbow_pivot.rotation.x = lerp_angle(left_elbow_pivot.rotation.x, -0.15, 0.1)
	right_elbow_pivot.rotation.x = lerp_angle(right_elbow_pivot.rotation.x, -0.15, 0.1)

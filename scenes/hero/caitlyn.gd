class_name Hero
extends CharacterBody3D

## 1:1 port of Character.ts from game-x0-moba (Caitlyn)
## Handles 3D Caitlyn model, animations, movement (16.0 m/s), kiting mechanics, attack windup/cooldown.

enum State { IDLE, WALKING, ATTACKING }

@export var speed: float = 16.0
@export var height: float = 3.5
@export var max_hp: float = 1072.0
@export var attack_range: float = 18.0
@export var attack_speed: float = 1.85 # Attacks per second
@export var arrival_threshold: float = 0.05

var hp: float = 1072.0
var state: State = State.IDLE
var attack_cooldown: float = 0.0

var attack_windup_timer: float = 0.0
var attack_anim_timer: float = 0.0
var is_attack_windup_triggered: bool = false

var attack_target: Node3D = null
var attack_direction: Variant = null
var is_melee_attack: bool = false

var last_attack_click_time: float = 0.0
var consecutive_fast_clicks: int = 0
var attack_speed_bonus: float = 0.0
var bonus_timer: float = 0.0

var move_target: Variant = null
var has_move_target: bool = false

signal shoot(target: Node3D, direction: Variant, is_melee: bool)
signal move_target_changed(target: Vector3)
signal move_target_reached

@onready var model_group: Node3D = $ModelGroup
var anim_player: AnimationPlayer = null
var current_anim_name: String = ""

func _ready() -> void:
	hp = max_hp
	_setup_animations()
	_play_idle_anim()

func _setup_animations() -> void:
	anim_player = _find_anim_player(model_group)
	if anim_player:
		# Set loop mode on looping animations
		for anim_name in anim_player.get_animation_list():
			var lower = anim_name.to_lower()
			if "idle1" in lower or lower == "idle_anm":
				var a = anim_player.get_animation(anim_name)
				if a: a.loop_mode = Animation.LOOP_LINEAR
			elif "run" in lower and not "to_" in lower and not "_in" in lower:
				var a = anim_player.get_animation(anim_name)
				if a: a.loop_mode = Animation.LOOP_LINEAR

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var res = _find_anim_player(child)
		if res:
			return res
	return null

func set_move_target(target: Vector3) -> void:
	move_target = Vector3(target.x, global_position.y, target.z)
	has_move_target = true
	if state == State.ATTACKING:
		cancel_attack()
	move_target_changed.emit(move_target)

func stop() -> void:
	move_target = null
	has_move_target = false
	velocity = Vector3.ZERO
	if state == State.WALKING:
		state = State.IDLE
		_play_idle_anim()

func start_attack(target: Node3D, dir: Variant) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var click_interval := now - last_attack_click_time
	last_attack_click_time = now

	# Se já está em cooldown e o windup já passou (kiting), recompensa cliques rápidos
	if attack_cooldown > 0.0:
		if is_attack_windup_triggered:
			# Reduz o cooldown restante em 0.14s (140ms) por clique rápido, acelerando o kiting!
			attack_cooldown = max(0.0, attack_cooldown - 0.14)
		return

	# Acumula bônus de velocidade de ataque se clicar rápido e repetidamente
	if click_interval >= 0.10 and click_interval <= 0.42:
		consecutive_fast_clicks = min(3, consecutive_fast_clicks + 1)
		attack_speed_bonus = consecutive_fast_clicks * 0.15 # +15% AS por clique rápido (máximo +45%)
		bonus_timer = 1.0 # Bônus dura 1s
	elif click_interval > 0.42:
		consecutive_fast_clicks = 0
		attack_speed_bonus = 0.0

	move_target = null
	has_move_target = false
	velocity = Vector3.ZERO
	state = State.ATTACKING
	attack_target = target

	if dir is Vector3 and dir.length_squared() > 0.0001:
		attack_direction = dir.normalized()
	else:
		attack_direction = null

	# Se o inimigo estiver a menos de 3.2 unidades de distância, vira ataque melee (Coronhada de Rifle)
	if target != null and is_instance_valid(target) and global_position.distance_to(target.global_position) <= 3.2:
		is_melee_attack = true
	else:
		is_melee_attack = false

	is_attack_windup_triggered = false
	attack_windup_timer = 0.04 # Windup super ágil
	attack_anim_timer = 0.12   # Animação super rápida

	# Cooldown efetivo aplicando o bônus de clique rápido do kiting mecânico
	var effective_attack_speed = attack_speed * (1.0 + attack_speed_bonus)
	attack_cooldown = 1.0 / effective_attack_speed

	_play_attack_anim()

func cancel_attack() -> void:
	state = State.IDLE
	attack_target = null
	attack_direction = null
	attack_anim_timer = 0.0
	attack_windup_timer = 0.0
	is_attack_windup_triggered = false
	_play_idle_anim()

func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)

func _physics_process(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# Decai o bônus de velocidade por cliques rápidos
	if bonus_timer > 0.0:
		bonus_timer -= delta
		if bonus_timer <= 0.0:
			attack_speed_bonus = 0.0
			consecutive_fast_clicks = 0

	# 1. Simulação do Estado de Ataque
	if state == State.ATTACKING:
		if attack_anim_timer > 0.0:
			attack_anim_timer -= delta

			if attack_target != null and is_instance_valid(attack_target):
				var tdir := attack_target.global_position - global_position
				tdir.y = 0.0
				if tdir.length_squared() > 0.0001:
					rotation.y = atan2(tdir.x, tdir.z)
			elif attack_direction is Vector3:
				rotation.y = atan2(attack_direction.x, attack_direction.z)

			if attack_windup_timer > 0.0:
				attack_windup_timer -= delta
				if attack_windup_timer <= 0.0 and not is_attack_windup_triggered:
					is_attack_windup_triggered = true
					shoot.emit(attack_target, attack_direction, is_melee_attack)

			if attack_anim_timer <= 0.0:
				state = State.IDLE
				_play_idle_anim()

	# 2. Simulação da Movimentação
	if state != State.ATTACKING and move_target != null:
		var diff: Vector3 = move_target - global_position
		diff.y = 0.0
		var dist := diff.length()
		var move_dist := speed * delta

		if dist <= max(move_dist, arrival_threshold):
			global_position = Vector3(move_target.x, global_position.y, move_target.z)
			move_target = null
			has_move_target = false
			velocity = Vector3.ZERO
			state = State.IDLE
			_play_idle_anim()
			move_target_reached.emit()
		else:
			var dir := diff.normalized()
			var step_speed = min(speed, dist / max(delta, 0.001))
			velocity = dir * step_speed
			global_position += dir * move_dist

			var target_angle = atan2(dir.x, dir.z)
			var angle_diff = wrapf(target_angle - rotation.y, -PI, PI)
			rotation.y += angle_diff * 0.25

			state = State.WALKING
			_play_run_anim()
	elif state != State.ATTACKING:
		velocity = Vector3.ZERO

func _play_idle_anim() -> void:
	if anim_player and current_anim_name != "idle":
		current_anim_name = "idle"
		if anim_player.has_animation("idle1_anm"):
			anim_player.play("idle1_anm", 0.15, 1.0)
		elif anim_player.has_animation("idle_anm"):
			anim_player.play("idle_anm", 0.15, 1.0)

func _play_run_anim() -> void:
	if anim_player and current_anim_name != "run":
		current_anim_name = "run"
		if anim_player.has_animation("run_anm"):
			anim_player.play("run_anm", 0.1, 2.5) # 2.5x timescale

func _play_attack_anim() -> void:
	if anim_player:
		current_anim_name = "attack"
		var speed_scale := 3.5 * (1.0 + attack_speed_bonus)
		if anim_player.has_animation("attack1_anm"):
			anim_player.play("attack1_anm", 0.08, speed_scale)
		elif anim_player.has_animation("attack2_anm"):
			anim_player.play("attack2_anm", 0.08, speed_scale)

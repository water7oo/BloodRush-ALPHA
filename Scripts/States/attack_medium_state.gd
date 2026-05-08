extends LimboState

@onready var camera = get_tree().get_first_node_in_group("camera")

@export var hiteffect1 = preload("res://FX/swordslash_1.tscn")
@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")

@export var attack_box: Node
@export var attack_box_col: Node
@export var attack_box_debug: Node
@export var ComboConfirmFX: GPUParticles3D

@export var attackData: Resource

@onready var gameJuice = get_node("/root/GameJuice")

@export var Medium1Sound: AudioStreamPlayer
@export var hit5GuardSound: AudioStreamPlayer

const smear = preload("res://FX/smear_effect_horizontal.tscn")
# -------------------------
# STATE
# -------------------------
var attack_timer: float = 0.0
var combo_timer: float = 0.0

var buffered_input := false
var buffered_medium := false
var buffered_heavy := false

var enemies_hit := {}

var startup_timer := 0.0
var in_startup := true

# 🔥 FIXED SYSTEM FLAGS
var hit_confirmed := false
var cancel_window_active := false


@onready var PlayerUI = $PlayerUI


# -------------------------
# ENTER
# -------------------------
func _enter(msg := {}) -> void:
	enemies_hit.clear()

	buffered_input = false
	buffered_medium = false
	buffered_heavy = false

	Global.is_attacking = true
	Global.can_cancel = false
	Global.isHit = false

	hit_confirmed = false
	cancel_window_active = false

	var data = agent.get_transition_data()
	handle_startup(data.get("skip_startup", false))
	agent.transition_data.clear()

	if animation_player:
		animation_player.speed_scale = attackData.animationSpeedScale
		animation_player.play(attackData.attackAnimation)


# -------------------------
# STARTUP
# -------------------------
func handle_startup(skip_startup: bool):
	if skip_startup:
		startup_timer = 0.0
		in_startup = false
		_enable_hitbox()
		_start_attack()
		attack_timer = attackData.active_duration + attackData.recovery_duration
	else:
		startup_timer = attackData.startup_duration
		in_startup = true
		attack_timer = 0.0


# -------------------------
# UPDATE
# -------------------------
func _update(delta: float) -> void:

	combo_timer -= delta

	if Input.is_action_just_pressed("attack_medium_1"):
		buffered_medium = true
		buffered_input = true

	if Input.is_action_just_pressed("attack_heavy_1"):
		buffered_heavy = true
		buffered_input = true


	# STARTUP
	if in_startup:
		startup_timer -= delta
		if startup_timer <= 0:
			in_startup = false
			attack_timer = attackData.active_duration + attackData.recovery_duration
			_enable_hitbox()
			_start_attack()
		return


	# ACTIVE / RECOVERY
	attack_timer -= delta

	_process_cancel_window()

	if attack_timer <= 0.0:
		if buffered_input and cancel_window_active:
			_chain_attack()
		else:
			_exit_attack_state()
			agent.state_machine.dispatch("to_idle")


	_comboKnockBack()
	_apply_physics(delta)
	agent.move_and_slide()

func _comboKnockBack():
	if Global.combo_hits.size() >= 2:
		attackData.knockback_force = attackData.comboknockbackForce
	else:
		attackData.knockback_force = attackData.Default_knockback_force
		
		
		
# -------------------------
# START ATTACK
# -------------------------
func _start_attack() -> void:
	combo_timer = attackData.combo_window_duration
	cancel_window_active = true
	Global.can_cancel = true


# -------------------------
# CANCEL WINDOW
# -------------------------
func _process_cancel_window():
	if buffered_input and cancel_window_active:
		_chain_attack()


# -------------------------
# CHAIN (FIXED)
# -------------------------
func _chain_attack():
	if animation_player.is_playing():
		animation_player.stop()

	_exit_attack_state()
	attack_timer = 0.0

	if combo_timer >= 0.0:
		if buffered_heavy:
			agent.set_transition_data({"skip_startup": true})
			agent.state_machine.dispatch(attackData.next_attack_state)
		else:
			agent.state_machine.dispatch("to_idle")


# -------------------------
# HITBOX ENABLE
# -------------------------
func _enable_hitbox():
	Global.stretch_forward($"../../RootNode/player2")
	VFX.smearEffectOverhead(agent, false, smear, $"../../RootNode/player2", 0.0)
	if attack_box:
		attack_box_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true

		if not attack_box.is_connected("area_entered", Callable(self, "_on_attack_box_area_entered")):
			attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

func rotate_to_target(areaParent):
	var playerMesh = agent.get_node("RootNode")
	
	if playerMesh:
		var dir = areaParent.global_position - playerMesh.global_position
		
		dir.y = 0
		
		if dir.length() < 0.001:
			return
		
		dir = dir.normalized()
		
		# Compute yaw (Y rotation)
		var target_yaw = atan2(-dir.x, -dir.z)
		
		# Smoothly rotate only Y
		playerMesh.rotation.y = lerp_angle(
			playerMesh.rotation.y,
			target_yaw,
			1
		)
	else:
		print("no visual node")

func rotateEnemy_to_player(agent, areaParent):
	var enemyMesh = areaParent
	
	if enemyMesh:
		var dir = agent.global_position - enemyMesh.global_position
		
		dir.y = 0
		
		if dir.length() < 0.001:
			return
		
		dir = dir.normalized()
		
		# Compute yaw (Y rotation)
		var target_yaw = atan2(-dir.x, -dir.z)
		
		# Smoothly rotate only Y
		enemyMesh.rotation.y = lerp_angle(
			enemyMesh.rotation.y,
			target_yaw,
			1
		)
	else:
		print("no visual node")
		
		

func playHitSound():
	Medium1Sound.pitch_scale = randf_range(.8, 1.1)
	Medium1Sound.play()

	
# -------------------------
# HIT LOGIC (FIXED)
# -------------------------
func _on_attack_box_area_entered(area):

	var areaParent = area.get_parent()

	# per-target protection
	if enemies_hit.has(areaParent):
		return

	enemies_hit[areaParent] = true

	if areaParent.has_method("takeDamageEnemy") \
	and areaParent.enemyStats.current_health > 0 \
	and not areaParent.enemyStats.isDead \
	and not areaParent.enemyStats.isGuarding:

		hit_confirmed = true
		Global.isHit = true
		Global.can_cancel = true
		cancel_window_active = true

		areaParent.takeDamageEnemy(attackData.attackDamage)

		rotateEnemy_to_player(agent, areaParent)
		rotate_to_target(areaParent)

		Global.combo_hits.append({
			"enemy": area,
			"damage": attackData.attackDamage,
			"attack_type": "attackMedium",
			"timestamp": Time.get_ticks_msec()
		})

		agent.updateComboCounterInstant(Global.combo_hits.size())
		Global.combo_timer = Global.combo_reset_time

		attack_box.monitoring = false

		var enemy = areaParent
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()

		playHitSound()

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO

		gameJuice.objectShake(enemy, attackData.enemyTargetLength, attackData.enemyTargetMagnitude)
		gameJuice.camShake(camera, attackData.camShakeLength, attackData.camShakeMagnitude)
		gameJuice.hitstop(attackData.enemyTargetHitStop, [agent, enemy])

		agent.velocity = saved_velocity

		var combo_count = Global.combo_hits.size()

		if enemy is CharacterBody3D:
			if combo_count == 1:
				gameJuice.knockback(enemy, agent, attackData.knockback_force, attackData.knockback_direction)
			else:
				gameJuice.knockback(enemy, agent, attackData.comboknockbackForce, attackData.knockback_direction)


	elif areaParent.has_method("takeGuardDamageEnemy") \
	and areaParent.enemyStats.isGuarding \
	and areaParent.enemyStats.current_health > 0 \
	and not areaParent.enemyStats.isDead:

		areaParent.takeDamageEnemy(attackData.attackDamage * 0.5)

		rotateEnemy_to_player(agent, areaParent)
		rotate_to_target(areaParent)

		Global.isHit = true
		Global.can_cancel = true
		cancel_window_active = true

		attack_box.monitoring = false

		hit5GuardSound.pitch_scale = randf_range(0.3, 1.5)
		hit5GuardSound.play()

		var enemy = areaParent
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO

		gameJuice.objectShake(enemy, attackData.enemyTargetGuardLength, attackData.enemyTargetGuardMagnitude)
		gameJuice.hitstop(attackData.enemyTargetGuardedHitstop, [agent, enemy])

		agent.velocity = saved_velocity


# -------------------------
# PHYSICS
# -------------------------
func _apply_physics(delta: float):
	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta

	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, attackData.ATTACK_DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, attackData.ATTACK_DECELERATION * delta)


# -------------------------
# EXIT
# -------------------------
func _exit_attack_state():
	animation_player.speed_scale = 1.0
	animation_player.stop()

	Global.is_attacking = false
	Global.can_cancel = false
	Global.isHit = false

	buffered_input = false
	buffered_medium = false
	buffered_heavy = false

	hit_confirmed = false
	cancel_window_active = false

	combo_timer = 0.0

	_disable_hitbox()


# -------------------------
# HITBOX DISABLE
# -------------------------
func _disable_hitbox():
	if attack_box:
		attack_box.monitoring = false
		attack_box_debug.visible = false
		attack_box_col.visible = false

		if attack_box.is_connected("area_entered", Callable(self, "_on_attack_box_area_entered")):
			attack_box.disconnect("area_entered", Callable(self, "_on_attack_box_area_entered"))

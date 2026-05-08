extends LimboState

@onready var camera = get_tree().get_first_node_in_group("camera")
@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@export var attack_box: Node
@export var attack_box_col: Node
@export var attack_box_debug: Node
@export var ComboConfirmFX: GPUParticles3D

@export var attackData: Resource

@onready var gameJuice = get_node("/root/GameJuice")

@export var AirMediumAttackSound1: AudioStreamPlayer
@export var hit5GuardSound: AudioStreamPlayer

var attack_timer: float = 0.0
var combo_timer: float = 0.0
var buffered_input := false
var enemies_hit := {}
var preserved_velocity: Vector3 = Vector3.ZERO
var startup_timer := 0.0
var in_startup := true

@onready var AttackAnimation = attackData.attackAnimation


func _enter() -> void:
	enemies_hit.clear()
	buffered_input = false
	
	Global.is_attacking = true
	Global.isHit = false
	
	startup_timer = attackData.startup_duration
	in_startup = true
	attack_timer = 0.0

	if animation_player:
		animation_player.speed_scale = attackData.animationSpeedScale
		animation_player.play(attackData.attackAnimation)

func _update(delta: float) -> void:
	# buffer input
	if Input.is_action_just_pressed("attack_heavy_1") && !agent.is_on_floor():
		buffered_input = true
	
	
	attack_timer = max(attack_timer - delta, 0.0)
	if attack_timer <= 0.0:
		if (buffered_input || Global.isHit) && Global.can_cancel:
			_chain_attack()
		else:
			_exit_attack_state()
			agent.state_machine.dispatch("to_idle")
	

	if in_startup:
		startup_timer -= delta
		if startup_timer <= 0:
			in_startup = false
			attack_timer = attackData.active_duration + attackData.recovery_duration
			_enable_hitbox()
			_start_attack()
		return
		
	_process_cancel_window()	
	_comboKnockBack()
	_apply_physics(delta)
	agent.move_and_slide()

func _landCancel():
	if Global.is_attacking == true:
		if agent.is_on_floor():
			_exit_attack_state()
			agent.state_machine.dispatch("to_idle")
		else:
			return
			

func _process_cancel_window():
	if buffered_input and Global.can_cancel:
		buffered_input = false
		_chain_attack()


func _end_or_chain():
	if (buffered_input || Global.isHit) && Global.can_cancel:
		_chain_attack()
	else:
		_exit_attack_state()
		agent.state_machine.dispatch("to_idle")


func _chain_attack():
	_exit_attack_state()
	attackData.startup_duration = 0.0
	attack_timer = 0.0
	if buffered_input:
		agent.state_machine.dispatch(attackData.next_attack_state)

func _start_attack() -> void:
	Global.combo_timer = attackData.combo_window_duration
	Global.can_chain_attack = false
	Global.can_cancel = false


func _enable_hitbox():
	Global.stretch_forward($"../../RootNode/player2")
	if attack_box:
		attack_box_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)


func _disable_hitbox():
	if attack_box:
		attack_box.monitoring = false
		attack_box_debug.visible = false
		attack_box_col.visible = false
		
		if attack_box.is_connected("area_entered", Callable(self, "_on_attack_box_area_entered")):
			attack_box.disconnect("area_entered", Callable(self, "_on_attack_box_area_entered"))


func _comboKnockBack():
	if Global.combo_hits.size() >= 2:
		attackData.knockback_force = attackData.comboknockbackForce
	else:
		attackData.knockback_force = attackData.Default_knockback_force
		

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
	AirMediumAttackSound1.pitch_scale = randf_range(.8, 1.1)
	AirMediumAttackSound1.play()
		
func hitFinisher(area):
	var is_finishing_blow = area.enemyStats.current_health <= 0

	if is_finishing_blow:
		attackData.knockback_force = attackData.knockback_force_finisher
		attackData.knockback_direction = attackData.knockback_direction_finisher
		attackData.enemyTargetLength = attackData.enemyTargetFinisher
		attackData.enemyTargetMagnitude = attackData.enemyTargetMagnitudeFinisher
		attackData.enemyTargetHitStop = attackData.enemyHitstopFinisher
	else:
		attackData.knockback_force = attackData.knockback_force_default
		attackData.knockback_direction = attackData.knockback_direction_default
		attackData.enemyTargetLength = attackData.DefaultenemyTargetLength
		attackData.enemyTargetMagnitude = attackData.DefaultenemyTargetMagnitude
		attackData.enemyTargetHitStop = attackData.DefaultenemyTargetHitStop
		pass
		
		
func _on_attack_box_area_entered(area):
	var areaParent = area.get_parent()

	if Global.isHit:
		return

	if areaParent.has_method("takeDamageEnemy") \
	and areaParent.enemyStats.current_health > 0 \
	and not areaParent.enemyStats.isDead \
	and not areaParent.enemyStats.isGuarding:

		areaParent.takeDamageEnemy(attackData.attackDamage)
		hitFinisher(areaParent)
		rotateEnemy_to_player(agent, areaParent)
		rotate_to_target(areaParent)
		
		
		Global.combo_hits.append({
			"enemy": area,
			"damage": attackData.attackDamage,
			"attack_type": "attackLight",
			"timestamp": Time.get_ticks_msec()
		})


		agent.updateComboCounterInstant(Global.combo_hits.size())
		Global.combo_timer = Global.combo_reset_time
		Global.isHit = true
		Global.can_chain_attack = true
		Global.can_cancel = true
		Global.cancel_timer = attackData.combo_window_duration

		attack_box.monitoring = false

		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()

		if area in enemies_hit:
			return

		enemies_hit[area] = true
		playHitSound()


		if enemy.has_method("damageAnimation"):
			enemy.airDamageAnimation(.9, false)
				
		if enemy.has_node("EnemyMesh"):
			var enemyScene = enemy.get_node("EnemyMesh")
			enemyScene.trigger_flash()
			await get_tree().process_frame

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO

		areaParent.enemyStats.enemyWasHit = true

		gameJuice.objectShake(enemy, attackData.enemyTargetLength, attackData.enemyTargetMagnitude)
		gameJuice.camShake(camera, attackData.camShakeLength, attackData.camShakeMagnitude)
		gameJuice.hitstop(attackData.enemyTargetHitStop, [agent, enemy])

		areaParent.enemyStats.enemyWasHit = false

		
		
		agent.velocity = saved_velocity

		var combo_count = Global.combo_hits.size()
		if enemy is CharacterBody3D:
			if combo_count == 1:
				gameJuice.knockback(
					enemy,
					agent,
					attackData.knockback_force,
					attackData.knockback_direction
				)
			elif combo_count >= 2:
				gameJuice.knockback(
					enemy,
					agent,
					attackData.comboknockbackForce,
					attackData.knockback_direction
				)

	elif areaParent.has_method("takeGuardDamageEnemy") and areaParent.enemyStats.isGuarding and areaParent.enemyStats.current_health > 0 and not areaParent.enemyStats.isDead:
			areaParent.takeDamageEnemy(attackData.attackDamage * .5)

			rotateEnemy_to_player(agent, areaParent)
			rotate_to_target(areaParent)
			Global.isHit = true
			Global.can_chain_attack = true
			Global.can_cancel = true
			Global.cancel_timer = attackData.combo_window_duration

			attack_box.monitoring = false

			var enemy = area
			while enemy and not (enemy is CharacterBody3D):
				enemy = enemy.get_parent()

			if area in enemies_hit:
				return

			enemies_hit[area] = true

			hit5GuardSound.pitch_scale = randf_range(.3, 1.5)
			hit5GuardSound.play()
	#		change this so it doesnt rely on the node name, only the node type
			if enemy.has_node("EnemyMesh"):
				var mesh = enemy.get_node("EnemyMesh")
				mesh.trigger_guardFlash()
				await get_tree().process_frame

			var saved_velocity = agent.velocity
			agent.velocity = Vector3.ZERO

			areaParent.enemyStats.enemyWasHit = true

			gameJuice.objectShake(enemy, attackData.enemyTargetGuardLength, attackData.enemyTargetGuardMagnitude)
			gameJuice.hitstop(attackData.enemyTargetGuardedHitstop, [agent, enemy])
			areaParent.enemyStats.enemyWasHit = false

			var hit1Effect = enemy.find_child("hit1", true, false)
			if hit1Effect is GPUParticles3D:
				hit1Effect.restart()
				hit1Effect.emitting = true
				hit1Effect.process_mode = Node.PROCESS_MODE_ALWAYS
			
			var hit2Effect = enemy.find_child("hit2", true, false)
			if hit2Effect is GPUParticles3D:
				hit2Effect.restart()
				hit2Effect.emitting = true
				hit2Effect.process_mode = Node.PROCESS_MODE_ALWAYS

			agent.velocity = saved_velocity

			var combo_count = Global.combo_hits.size()
			if enemy is CharacterBody3D:
				if combo_count == 1:

					gameJuice.knockback(
						enemy,
						agent,
						attackData.guardedknockbackForce,
						attackData.guardedknockbackDirection
					)


func _apply_physics(delta: float):
	# gravity
	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta

	# deceleration
	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, attackData.ATTACK_DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, attackData.ATTACK_DECELERATION * delta)

func _exit_attack_state() -> void:
	animation_player.speed_scale = 1.0
	animation_player.stop()
	Global.is_attacking = false
	Global.isHit = false
	combo_timer = 0.0
	_disable_hitbox()

extends LimboState

@onready var camera = get_tree().get_first_node_in_group("camera")
@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@export var attack_box: Node
@export var attack_box_col: Node
@export var attack_box_debug: Node

@export var attack_box2: Node
@export var attack_box_col2: Node
@export var attack_box_debug2: Node

@export var ComboConfirmFX: GPUParticles3D
@export var jumpCancelFX: GPUParticles3D
@export var attackData: Resource

@onready var gameJuice = get_node("/root/GameJuice")

@export var Upper1Sound: AudioStreamPlayer
@export var hit5GuardSound: AudioStreamPlayer

@export var multiHit1Sound: AudioStreamPlayer
@export var multiHit1FinishSound: AudioStreamPlayer

var attack_timer: float = 0.0
var combo_timer: float = 0.0
var jumpCancelDelay: float = 0.0
var jump_cancel_timer: float = 0.0


var buffered_input := false
var enemies_hit := {}
var preserved_velocity: Vector3 = Vector3.ZERO
var startup_timer := 0.0
var in_startup := true
var isJumpCancel = false
var canJumpCancel = false

@onready var AttackAnimation = attackData.attackAnimation

const DustLandEffect = preload("res://FX/vfxWave/GroundWaveEffect1.tscn")

const DustMultiEffect = preload("res://FX/vfxWave/VerticalWaveEffect1.tscn")


var is_multi_hit := false

func _enter() -> void:
	is_multi_hit = attackData.has_meta("multi_hit") && attackData.get_meta("multi_hit")
	
	
	if is_multi_hit:
		Global.isMultiHitUpper = true
		animation_player.speed_scale = attackData.animationSpeedScale
		animation_player.play(attackData.attackAnimation)
	else:
		Global.isMultiHitUpper = false
		animation_player.speed_scale = attackData.animationSpeedScale
		animation_player.play(attackData.attackAnimation)

	if is_multi_hit:
		attack_box = $"../../RootNode/AttackUpperBox2"
		attack_box_col = $"../../RootNode/AttackUpperBox2/CollisionShape3D"
		attack_box_debug = $"../../RootNode/AttackUpperBox2/Attack_Debug"
		print("Multi-hit upper attack")
		
	else:
		attack_box = $"../../RootNode/AttackUpperBox"
		attack_box_col = $"../../RootNode/AttackUpperBox/CollisionShape3D"
		attack_box_debug = $"../../RootNode/AttackUpperBox/Attack_Debug"
		print("Single-hit upper attack")

	enemies_hit.clear()
	buffered_input = false

	Global.is_attacking = true
	Global.isHit = false
	isJumpCancel = false
	canJumpCancel = false

	attackStartupSkip()
	startup_timer = max(attackData.startup_duration, 0.01) 
	attack_timer = 0.0
	in_startup = true
	jumpCancelDelay = attackData.jumpCancelDelayDuration
	jump_cancel_timer = attackData.jumpCancelTimerDuration

	agent.jump_state.jumpResource.JUMP_VELOCITY = agent.jump_state.jumpResource.DEFAULT_JUMP_VELOCITY
	
	
func attackStartupSkip():
	if Global.skip_startup:
		print("skip startup")

		Global.skip_startup = false

		startup_timer = 0.0
		in_startup = false

		_enable_hitbox()
		_start_attack()

		attack_timer = attackData.active_duration + attackData.recovery_duration

	else:
		startup_timer = attackData.startup_duration
		in_startup = true
		attack_timer = 0.0
		
		
func _update(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump"):
		buffered_input = true

	if in_startup:
		startup_timer -= delta
		if startup_timer <= 0:
			if !is_multi_hit:
				in_startup = false
				attack_timer = attackData.active_duration + attackData.recovery_duration
				_enable_hitbox()
				_start_attack()
			else:
				in_startup = false
				attack_timer = attackData.active_duration + attackData.recovery_duration
				_enable_hitbox()
				_start_attack()
				

	_process_cancel_window()
	
	attack_timer -= delta
	if attack_timer <= 0.0:
		if (buffered_input || Global.isHit) && Global.can_cancel:
			_chain_attack()
		else:
			_exit_attack_state()
			agent.state_machine.dispatch("to_idle")
	

	
	
	
	if Global.can_chain_attack == true:
		runJumpTimers(delta)
	
	
	_comboKnockBack()
	_apply_physics(delta)
	agent.move_and_slide()


func _comboKnockBack():
	if Global.combo_hits.size() >= 2:
		attackData.knockback_force = attackData.comboknockbackForce
	else:
		attackData.knockback_force = attackData.Default_knockback_force
		
func runJumpTimers(delta: float):

	jumpCancelDelay = max(jumpCancelDelay - delta, 0.0)
	
	
	if jumpCancelDelay <= 0:
		jump_cancel_timer = max(jump_cancel_timer - delta, 0.0)
		canJumpCancel = true
		

func _process_cancel_window():
	if buffered_input and Global.can_cancel:
		_chain_attack()


func _end_or_chain():
	if combo_timer >= 0.0:
		if (buffered_input || Global.isHit) && Global.can_cancel:
			_chain_attack()
	else:
		Global.can_cancel = false
		_exit_attack_state()
		agent.state_machine.dispatch("to_idle")


func _chain_attack():
	_exit_attack_state()
	attack_timer = 0.0
	
	_jumpCancel()


func jumpCancelWave():
	var normal = agent.get_floor_normal()
	
	if agent.is_on_floor():
		var jumpCancelWave = DustLandEffect.instantiate()
		get_tree().root.add_child(jumpCancelWave)
		var xform = jumpCancelWave.global_transform
		xform.origin = agent.global_transform.origin + Vector3(0,1,0)
		xform = align_with_y(xform, agent.get_floor_normal())
		jumpCancelWave.global_transform = xform

func multiHitEffectWaves():
	var instanceBurstEffect = DustMultiEffect.instantiate()
	get_tree().root.add_child(instanceBurstEffect)
	
	var player_forward = -$"../../RootNode".global_transform.basis.z
	var xform = instanceBurstEffect.global_transform
	
	var spawn_offset = player_forward * 4.0 
	xform.origin = $"../../RootNode".global_transform.origin + spawn_offset + Vector3(0,2,0)




	var random_angle = randf_range(0, TAU) 
	xform = xform.rotated_local(Vector3.UP, random_angle)

	
	instanceBurstEffect.global_transform = xform
	
func align_with_y_multi(xform, new_y, player_forward):
	new_y = new_y.normalized()
	

	var right = player_forward.cross(new_y).normalized()
	var forward = new_y.cross(right).normalized()

	xform.basis = Basis(right, new_y, forward)
	return xform
	
func align_with_y(xform, new_y):
	new_y = new_y.normalized()

	var forward = -xform.basis.z.normalized()
	var right = forward.cross(new_y).normalized()
	forward = new_y.cross(right).normalized()

	xform.basis = Basis(right, new_y, forward)
	return xform
	
	
func _jumpCancel():
	if Input.is_action_just_pressed("move_jump") && canJumpCancel == true && jumpCancelFX:
		jumpCancelWave()
		agent.jump_state.jumpResource.JUMP_VELOCITY += 5
		jumpCancelFX.emitting = true
		agent.state_machine.dispatch(attackData.next_attack_state)
	else:
		agent.jump_state.jumpResource.JUMP_VELOCITY = agent.jump_state.jumpResource.DEFAULT_JUMP_VELOCITY

func _start_attack() -> void:
	
	Global.combo_timer = attackData.combo_window_duration
	Global.can_chain_attack = false
	Global.can_cancel = false


func _enable_hitbox():
	if attack_box:
		if !is_multi_hit:
			Global.stretch_forward($"../../RootNode/player2")
			attack_box_debug.visible = true
			attack_box_col.visible = true
			attack_box.monitoring = true
			attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)
		else:
			multi_hit()
			

func _OnHitbox():
	if attack_box:
		Global.stretch_forward($"../../RootNode/player2")
		attack_box_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

func multi_hit():
	for i in range(attackData.max_hits):
		
		enemies_hit.clear()
		Global.isHit = false
		_OnHitbox()
		for frame in range(3): 
			await get_tree().physics_frame

		if Global.isHit:
			multiHitEffectWaves()
			if multiHit1Sound && multiHit1FinishSound:
				if i >= attackData.max_hits - 1:

					Global.shakeTween($"../../PlayerUI".get_node("ComboCounter2"))
					multiHit1FinishSound.pitch_scale = randf_range(0.2, 1.1)
					multiHit1FinishSound.play()
					
					#animation_player.play("player|multiFinish")
				else:
					multiHit1Sound.pitch_scale = randf_range(0.6, 1.2)
					multiHit1Sound.play()

					
					
		_disable_hitbox()
		await get_tree().create_timer(attackData.time_between_hits).timeout
		
func _disable_hitbox():
	if attack_box:

		attack_box.monitoring = false
		attack_box_debug.visible = false
		attack_box_col.visible = false
		
		if attack_box.is_connected("area_entered", Callable(self, "_on_attack_box_area_entered")):
			attack_box.disconnect("area_entered", Callable(self, "_on_attack_box_area_entered"))


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

	if enemies_hit.has(areaParent):
			return
			
	enemies_hit[areaParent] = true
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

		
		if !Global.isMultiHitUpper:
			Upper1Sound.play()
		
		if enemy.has_method("damageAnimation"):
			enemy.airDamageAnimation(.9, true)
				
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
					attackData.knockback_force,
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
	animation_player.speed_scale = 7.0
	Global.is_attacking = false
	Global.isHit = false
	Global.can_cancel = false
	combo_timer = 0.0
	agent.jump_state.jumpResource.JUMP_VELOCITY = agent.jump_state.jumpResource.DEFAULT_JUMP_VELOCITY
	_disable_hitbox()

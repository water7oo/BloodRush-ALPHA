extends LimboState

@export var hiteffect1 = preload("res://FX/swordslash_1.tscn")
@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@export var attack_box: Node
@export var attack_box_col: Node
@export var attack_box_debug: Node
@export var ComboConfirmFX: GPUParticles3D

@export var attackData: Resource

@onready var gameJuice = get_node("/root/GameJuice")

@export var hit1Sound: AudioStreamPlayer
@export var hit2Sound: AudioStreamPlayer


var attack_timer: float = 0.0
var combo_timer: float = 0.0
var buffered_input := false
var enemies_hit := {}
var preserved_velocity: Vector3 = Vector3.ZERO
var startup_timer := 0.0
var in_startup := true



var grab_timer := 0.0

var can_grab = true
var isGrabbed = false
var buffered_medium := false

var grabbed_enemy: CharacterBody3D = null
@onready var grab_point = $"../../RootNode/grabPoint"


@onready var PlayerUI = $PlayerUI

@onready var AttackAnimation = attackData.attackAnimation
const DustLandEffect = preload("res://FX/dustEffect1.tscn")


func _enter() -> void:
	enemies_hit.clear()
	buffered_input = false
	buffered_medium = false
	Global.is_attacking = true
	Global.isHit = false
	Global.can_cancel = false
	isGrabbed = false
	grabbed_enemy = null


	var forward_dir = -agent.global_transform.basis.z.normalized()
	var back_dir = agent.global_transform.basis.z.normalized()

	if Global.skip_startup:
		print("skip startup")
		startup_timer = 0.0
		in_startup = false
		Global.skip_startup = false 

		_enable_hitbox()
		_start_attack()
		attack_timer = attackData.active_duration + attackData.recovery_duration
	else:
		startup_timer = attackData.startup_duration
		in_startup = true
		attack_timer = 0.0

	if animation_player:
		animation_player.speed_scale = 0.0
		animation_player.play("player|upperCut")


func _update(delta: float) -> void:
	combo_timer -= delta

	if Input.is_action_just_pressed("attack_medium_1"):
		buffered_medium = true
		buffered_input = true
		
	if in_startup:
		startup_timer -= delta
		if startup_timer <= 0:
			in_startup = false
			attack_timer = attackData.active_duration + attackData.recovery_duration
			_enable_hitbox()
			_start_attack()
		return




	if isGrabbed:
		if not grabbed_enemy:
			isGrabbed = false
			return
		
		grab_timer += delta


		if isGrabbed and grabbed_enemy:
			if Input.is_action_just_pressed("move_crouch"):
				slam_down()
			elif Input.is_action_just_pressed("attack_light_1") \
			or Input.is_action_just_pressed("attack_medium_1"):
				throw_forward()
			elif Input.is_action_just_pressed("move_back"):
				throw_back()

		if grab_timer > attackData.max_grab_time:
			release_enemy()
			throw_forward()
			
			
			_exit_attack_state()
			agent.state_machine.dispatch("to_idle")

		return
		
	_process_cancel_window()
	
	attack_timer -= delta
	if attack_timer <= 0.0:
		if (buffered_input || Global.isHit) && Global.can_cancel:
			_end_or_chain()
		else:
			_exit_attack_state()
			agent.state_machine.dispatch("to_idle")
	
		
		
	_apply_physics(delta)
	agent.move_and_slide()
	


func throwSoundPlay():
	if hit2Sound:
		hit2Sound.pitch_scale = randf_range(.8, 1.1)
		hit2Sound.play()
	
func grabSoundPlay():
	if hit1Sound:
		hit1Sound.pitch_scale = randf_range(.8, 1.1)
		hit1Sound.play()
	
func throw_back():
	var enemy = grabbed_enemy
	var playerMesh = agent
	var back_dir = (playerMesh.global_position - enemy.global_position).normalized()
	back_dir.y = 0
	
	rotate_to_target(enemy, true)
	




	# Animation
	animation_player.speed_scale = 1.0
	animation_player.play("player|multi")


	attackEnemy(grabbed_enemy)
	release_enemy()
	
	throwSoundPlay()
	throwEffect()
	gameJuice.knockback(enemy, agent, attackData.knockback_force, attackData.knockback_backDirection)
	
	
func rotate_to_target(areaParent, invert := false):
	var playerMesh = agent.get_node("RootNode")
	
	if playerMesh:
		var dir
		
		if invert:
			dir = playerMesh.global_position - areaParent.global_position
		else:
			dir = areaParent.global_position - playerMesh.global_position
		
		dir.y = 0
		
		if dir.length() < 0.001:
			return
		
		dir = dir.normalized()
		
		var target_yaw = atan2(-dir.x, -dir.z)
		
		playerMesh.rotation.y = lerp_angle(
			playerMesh.rotation.y,
			target_yaw,
			1
		)

func throw_forward():
	var enemy = grabbed_enemy
	var forward_dir = agent.global_transform.basis.z.normalized()
	
	animation_player.speed_scale = 1.0
	animation_player.play("player|Launcher")



	attackEnemy(grabbed_enemy)
	release_enemy()
	
	throwSoundPlay()
	gameJuice.knockback(enemy, agent, attackData.knockback_force, attackData.knockback_direction)

func slam_down():
	var enemy = grabbed_enemy
	release_enemy()
	
	
	await get_tree().create_timer(0.2).timeout
	
	attackEnemy(grabbed_enemy)
	release_enemy()
	
	throwSoundPlay()
	gameJuice.knockback(enemy, agent, attackData.knockback_force, attackData.knockback_UpDirection)
	
	
func release_enemy():
	if not grabbed_enemy:
		return

	var global_xform = grabbed_enemy.global_transform

	var root = get_tree().current_scene
	grabbed_enemy.get_parent().remove_child(grabbed_enemy)
	root.add_child(grabbed_enemy)

	grabbed_enemy.global_transform = global_xform

	grabbed_enemy = null
	isGrabbed = false
	
	
func _comboKnockBack():
	if Global.combo_hits.size() >= 2:
		attackData.knockback_force = attackData.comboknockbackForce
	else:
		attackData.knockback_force = attackData.Default_knockback_force
		

func _process_cancel_window():
	if buffered_input and Global.can_cancel:
		_chain_attack()


func _end_or_chain():
	if combo_timer >= 0.0:
		if (buffered_input || Global.isHit) && Global.can_cancel:
			$"../../ComboConfirm1".emitting = true
			_chain_attack()
	else:
		Global.can_cancel = false
		_exit_attack_state()
		agent.state_machine.dispatch("to_idle")


func _chain_attack():
	_exit_attack_state()
	
	Global.skip_startup = true
	attack_timer = 0.0

	if combo_timer >= 0.0:
		if buffered_medium:
			agent.state_machine.dispatch(attackData.next_attack_state)
		else:
			agent.state_machine.dispatch("to_idle")

func _start_attack() -> void:
	combo_timer = attackData.combo_window_duration
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
		attackData.knockback_direction = Vector3(0, 0, 1)
		attackData.enemyTargetLength = attackData.DefaultenemyTargetLength
		attackData.enemyTargetMagnitude = attackData.DefaultenemyTargetMagnitude
		attackData.enemyTargetHitStop = attackData.DefaultenemyTargetHitStop
		pass

func attackEnemy(areaParent):
	if grabbed_enemy != null:
		areaParent.takeDamageEnemy(attackData.attackDamage)
		hitFinisher(areaParent)

		areaParent.takeDamageEnemy(attackData.attackDamage)
		rotateEnemy_to_player(agent, areaParent)
		rotate_to_target(areaParent)
		
		Global.combo_hits.append({
			"enemy": areaParent,
			"damage": attackData.attackDamage,
			"attack_type": "grabAttack",
			"timestamp": Time.get_ticks_msec()
		})
		
		agent.updateComboCounterInstant(Global.combo_hits.size())
		Global.combo_timer = Global.combo_reset_time
		
		Global.isHit = true
		Global.can_chain_attack = true
		Global.can_cancel = true
		Global.cancel_timer = attackData.combo_window_duration

		attack_box.monitoring = false

		var enemy = areaParent
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()

		if areaParent in enemies_hit:
			return

		enemies_hit[areaParent] = true


		if enemy.has_node("EnemyMesh"):
			var mesh = enemy.get_node("EnemyMesh")
			mesh.trigger_flash()
			await get_tree().process_frame

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO

		areaParent.enemyStats.enemyWasHit = true

		gameJuice.objectShake(enemy, attackData.enemyTargetLength, attackData.enemyTargetMagnitude)
		gameJuice.hitstop(attackData.enemyTargetHitStop, [agent, enemy])

		areaParent.enemyStats.enemyWasHit = false
		
		
		#var hit1Effect = enemy.find_child("hit1", true, false)
		#if hit1Effect is GPUParticles3D:
			#hit1Effect.restart()
			#hit1Effect.emitting = true
			#hit1Effect.process_mode = Node.PROCESS_MODE_ALWAYS
#
		#var hit2Effect = enemy.find_child("hit2", true, false)
		#if hit2Effect is GPUParticles3D:
			#hit2Effect.restart()
			#hit2Effect.emitting = true
			#hit2Effect.process_mode = Node.PROCESS_MODE_ALWAYS
			
		agent.velocity = saved_velocity

func throwEffect():
	var is_on_floor = agent.is_on_floor()
	var normal = agent.get_floor_normal()
	
	if is_on_floor:
		var landEffectInstance = DustLandEffect.instantiate()
		get_tree().root.add_child(landEffectInstance)
		var xform = landEffectInstance.global_transform
		
		xform.origin = agent.global_transform.origin + Vector3(0, 1.0, 0)

		xform = align_with_y(xform, agent.get_floor_normal())

		landEffectInstance.global_transform = xform

		



func align_with_y(xform, new_y):
	new_y = new_y.normalized()

	var forward = -xform.basis.z.normalized()
	var right = forward.cross(new_y).normalized()
	forward = new_y.cross(right).normalized()

	xform.basis = Basis(right, new_y, forward)
	return xform
	
	

func grabEnemy(area):
	_disable_hitbox()
	grab_timer = 0.0

	grabSoundPlay()

		
	var enemy = area.get_parent()
	grabbed_enemy = enemy

	var grab_point = $"../../RootNode/grabPoint"

	var global_xform = enemy.global_transform


	enemy.get_parent().remove_child(enemy)
	grab_point.add_child(enemy)

	enemy.global_transform = global_xform

	enemy.transform.origin = Vector3(0, 0, -1.5)

	isGrabbed = true
	
	
func _on_attack_box_area_entered(area):
	
#	
	var areaParent = area.get_parent()
	if Global.isHit:
		return


	if areaParent.has_method("takeDamageEnemy") \
	and areaParent.enemyStats.current_health > 0 \
	and not areaParent.enemyStats.isDead \
	and not areaParent.enemyStats.isGuarding:
		grabEnemy(area)
	else:
		return



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
	Global.can_cancel = false
	buffered_input = false
	buffered_medium = false
	combo_timer = 0.0
	
	
	_disable_hitbox()

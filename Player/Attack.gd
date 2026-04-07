extends LimboState

@export var attack_box: Node
@export var attack_box_col: Node
@export var attack_box_debug: Node
@export var ComboConfirmFX: GPUParticles3D

@export var attackData: Resource

@onready var gameJuice = get_node("/root/GameJuice")

@export var hit1Sound: AudioStreamPlayer
@export var hit2Sound: AudioStreamPlayer
@export var hit3Sound: AudioStreamPlayer
@export var hit4Sound: AudioStreamPlayer
@export var hit5GuardSOund: AudioStreamPlayer

var attack_timer: float = 0.0
var combo_timer: float = 0.0
var buffered_input := false
var enemies_hit := {}
var preserved_velocity: Vector3 = Vector3.ZERO
var startup_timer := 0.0
var in_startup := true

func _enter() -> void:
	print("entering attack state")
	enemies_hit.clear()
	buffered_input = false
	
	Global.is_attacking = true
	Global.isHit = false
	
	startup_timer = attackData.startup_duration
	in_startup = true
	attack_timer = 0.0


func _update(delta: float) -> void:
	# buffer input
	if Input.is_action_just_pressed("attack_medium_1"):
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
	_apply_physics(delta)
	agent.move_and_slide()

func is_in_attack_phase() -> bool:
	return attack_timer > attackData.recovery_duration

func is_in_recovery_phase() -> bool:
	return attack_timer <= attackData.recovery_duration and attack_timer > 0

func _process_cancel_window():
	if buffered_input and Global.can_cancel:
		buffered_input = false
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
	attackData.startup_duration = 0.0
	attack_timer = 0.0
	if buffered_input && combo_timer:
		agent.state_machine.dispatch(attackData.next_attack_state)

func _start_attack() -> void:
	combo_timer = attackData.combo_window_duration
	Global.can_chain_attack = false
	Global.can_cancel = false


func _enable_hitbox():
	if attack_box:
		print("active")
		attack_box_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)


func _disable_hitbox():
	if attack_box:
		print("inactive")
		attack_box.monitoring = false
		attack_box_debug.visible = false
		attack_box_col.visible = false
		
		if attack_box.is_connected("area_entered", Callable(self, "_on_attack_box_area_entered")):
			attack_box.disconnect("area_entered", Callable(self, "_on_attack_box_area_entered"))



func _on_attack_box_area_entered(area):
	var areaParent = area.get_parent()

	if Global.isHit:
		return

	if areaParent.has_method("takeDamageEnemy") \
	and areaParent.enemyStats.current_health > 0 \
	and not areaParent.enemyStats.isDead \
	and not areaParent.enemyStats.isGuarding:

		areaParent.takeDamageEnemy(attackData.attackDamage)

		Global.combo_hits.append({
			"enemy": area,
			"damage": attackData.attackDamage,
			"attack_type": "attackLight",
			"timestamp": Time.get_ticks_msec()
		})

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

		hit1Sound.play()
#		change this so it doesnt rely on the node name, only the node type
		if enemy.has_node("EnemyMesh"):
			var mesh = enemy.get_node("EnemyMesh")
			mesh.trigger_flash()
			await get_tree().process_frame

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO

		areaParent.enemyStats.enemyWasHit = true

		gameJuice.objectShake(enemy, attackData.enemyTargetLength, attackData.enemyTargetMagnitude)
		gameJuice.hitstop(attackData.enemyTargetHitStop)

		areaParent.enemyStats.enemyWasHit = false

		var hit1Effect = enemy.find_child("hit1", true, false)
		if hit1Effect is GPUParticles3D:
			hit1Effect.restart()
			hit1Effect.emitting = true
			hit1Effect.process_mode = Node.PROCESS_MODE_ALWAYS

		agent.velocity = saved_velocity

		if enemy is CharacterBody3D:
			gameJuice.knockback(
				enemy,
				agent,
				attackData.knockback_force,
				attackData.knockback_direction
			)

	elif areaParent.has_method("takeGuardDamageEnemy") and areaParent.enemyStats.isGuarding:
		areaParent.takeGuardDamageEnemy(attackData.attackDamage)


func _apply_physics(delta: float):
	# gravity
	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta

	# deceleration
	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, attackData.ATTACK_DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, attackData.ATTACK_DECELERATION * delta)

func _exit_attack_state() -> void:
	print("clearing attack state")
	Global.is_attacking = false
	Global.isHit = false
	combo_timer = 0.0
	_disable_hitbox()

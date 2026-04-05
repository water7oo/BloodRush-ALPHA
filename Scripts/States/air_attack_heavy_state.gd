extends LimboState

@export var attack_box: Node
@export var attack_box_col: Node
@export var attack_box_debug: Node
@export var ComboConfirmFX: GPUParticles3D

@onready var gameJuice = get_node("/root/GameJuice")
@export var attackData: Resource

var enemies_hit:= {}
var preserved_velocity: Vector3 = Vector3.ZERO


@export var hit1Sound: AudioStreamPlayer
@export var hit2Sound: AudioStreamPlayer
@export var hit3Sound: AudioStreamPlayer
@export var hit4Sound: AudioStreamPlayer

var buffered_input := false
var current_combo_count = Global.combo_hits.size()
var last_enemy_hit = Global.combo_hits[-1]["enemy"] if current_combo_count > 0 else null


func _enter() -> void:
	attackData.enemies_hit.clear()
	Global.is_attacking = true
	
	if attack_box:
		attack_box_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

	preserved_velocity = agent.velocity
	print("Current Attack State:", agent.state_machine.get_active_state())
	_start_attack()

func _update(delta: float) -> void:
	_process_attack(delta)
	if Input.is_action_just_pressed("attack_heavy_1") && Input.is_action_just_pressed("attack_medium_1"):
		buffered_input = true
	agent.move_and_slide()

func can_start_attack() -> bool:
	return attackData.attack_cooldown_timer <= 0.0 and not Global.is_attacking
	
func _process_attack(delta: float) -> void:
	if attackData.attack_cooldown_timer > 0.0:
		attackData.attack_cooldown_timer -= delta
	if attackData.recovery_timer > 0.0:
		attackData.recovery_timer -= delta
	if Global.combo_timer > 0.0:
		Global.combo_timer -= delta
	if Global.can_cancel:
		Global.cancel_timer -= delta
		if Global.cancel_timer <= 0:
			Global.can_cancel = false

	if attackData.buffered_input and Global.can_cancel:
		attackData.buffered_input = false
		_exit_attack_state()
		agent.state_machine.dispatch(attackData.next_attack_state)
		return
		
	if attackData.attack_cooldown_timer <= 0.0 and attackData.recovery_timer <= 0.0:
		attackData.buffered_input = false
		Global.can_chain_attack = true
		if Global.can_chain_attack && Input.is_action_just_pressed("attack_heavy_1") && Input.is_action_just_pressed("attack_medium_1"):
			_exit_attack_state()
			agent.state_machine.dispatch(attackData.next_attack_state)
		else:
			_exit_attack_state()
			agent.state_machine.dispatch("to_idle")
	
		attackData.buffered_input = false
		return

	# Apply gravity
	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta

	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, attackData.ATTACK_DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, attackData.ATTACK_DECELERATION * delta)
			

	

func _start_attack() -> void:
	attackData.enemies_hit.clear()
	#animationTree.set("parameters/AttackShot/request", 1)

	Global.is_attacking = true
	Global.isHit = false
	attackData.attack_cooldown_timer = attackData.attack_duration
	Global.combo_timer = attackData.combo_window_duration
	attackData.recovery_timer = attackData.recovery_duration  

	Global.can_chain_attack = false
	Global.can_cancel = false

	# Set next attack in combo chain
	attackData.next_attack_state = "to_airSlamAttack"  # Light -> Medium

func _on_attack_box_area_entered(area):
	var areaParent = area.get_parent()
	if Global.isHit:
		return

	if areaParent.has_method("takeDamageEnemy") && areaParent.enemyStats.current_health > 0 && areaParent.enemyStats.isDead == false && areaParent.enemyStats.isGuarding == false:
		print("Enemy Health: " + str(areaParent.enemyStats.current_health))
		areaParent.takeDamageEnemy(attackData.attackDamage)
		Global.combo_hits.append({
	"enemy": area,
	"damage": attackData.attackDamage ,
	"attack_type": "attackLight",
	"timestamp": Time.get_ticks_msec()
})
		Global.isHit = true
		Global.can_chain_attack = true
		attackData.recovery_timer = attackData.hit_recovery_duration
		Global.cancel_timer = attackData.cancel_window
		Global.can_cancel = true
		Global.cancel_timer = attackData.cancel_window
		attack_box.monitoring = false
		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()
		if area in attackData.enemies_hit:
			return
		attackData.enemies_hit[area] = true 
		Global.isHit = true
		hit1Sound.play()
		attackData.attack_cooldown_timer = min(attackData.attack_cooldown_timer, attackData.hit_cooldown_amount)

#		change this so it doesnt rely on the node name, only the node type
		if enemy.has_node("EnemyMesh"):
			var mesh = enemy.get_node("EnemyMesh")
			mesh.trigger_flash()
			await get_tree().process_frame
			
		if area.has_method("set_monitoring"):
			area.monitoring = false


		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO
		Global.can_cancel = true
		
		areaParent.enemyStats.enemyWasHit = true
		
		gameJuice.objectShake(enemy, attackData.enemyTargetLength, attackData.enemyTargetMagnitude)
		await gameJuice.hitstop(attackData.enemyTargetHitStop)

		areaParent.enemyStats.enemyWasHit = false

		var hit1Effect = enemy.find_child("hit1", true, false)
				
		if hit1Effect is GPUParticles3D:
			hit1Effect.restart()
			hit1Effect.emitting = true
			hit1Effect.process_mode = Node.PROCESS_MODE_ALWAYS
		elif hit1Effect == null:
			print("Warning: No GPUParticles3D found on " + enemy.name)	
		agent.velocity = saved_velocity

		if area.has_method("set_monitoring"):
			area.monitoring = true
			
		if enemy is CharacterBody3D:
			print("Applying knockback to:", enemy.name)
			gameJuice.knockback(
				enemy,
				agent,
				attackData.knockback_force,
				attackData.knockback_direction
			)
	elif areaParent.has_method("takeGuardDamageEnemy") && areaParent.enemyStats.isGuarding:
		areaParent.takeGuardDamageEnemy(PlayerAttackManager.lightAttackDamage)
		print("GUARDING!!")
		pass

func _exit_attack_state() -> void:
	Global.is_attacking = false
	attackData.attack_cooldown_timer = 0.0
	if attack_box and attack_box.is_connected("area_entered", Callable(self, "_on_attack_box_area_entered")):
		attack_box.disconnect("area_entered", Callable(self, "_on_attack_box_area_entered"))

	attack_box_debug.visible = false
	attack_box_col.visible = false
	Global.isHit = false
	if attack_box:
		attack_box.monitoring = false

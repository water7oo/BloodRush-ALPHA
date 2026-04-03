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



func _enter() -> void:
	attackData.enemies_hit.clear()
	if attack_box:
		attack_box_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true  # Enable hitbox
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

	attackData.preserved_velocity = agent.velocity
	print("Current Attack State:", agent.state_machine.get_active_state())
	_start_attack()

func _update(delta: float) -> void:
	attackData._process_attack(delta,agent)
	if Input.is_action_just_pressed("attack_medium_1"):
		attackData.buffered_input = true

	agent.move_and_slide()

func can_start_attack() -> bool:
	return Global.attack_cooldown_timer <= 0.0 and not Global.is_attacking





func _start_attack() -> void:
	attackData.enemies_hit.clear()
	#animationTree.set("parameters/AttackShot/request", 1)

	Global.is_attacking = true
	attackData.isHit = false
	Global.attack_cooldown_timer = attackData.attack_duration
	attackData.combo_timer = attackData.combo_window_duration
	attackData.recovery_timer = attackData.recovery_duration  

	attackData.can_chain_attack = false
	attackData.can_cancel = false

	# Set next attack in combo chain
	attackData.next_attack_state = "to_mediumAttack"  # Light -> Medium

func show_combo_fx() -> void:
	if ComboConfirmFX:
		ComboConfirmFX.restart()
		ComboConfirmFX.emitting = true
		
		
func _on_attack_box_area_entered(area):
	var areaParent = area.get_parent()
	if attackData.isHit:
		return

	if areaParent.has_method("takeDamageEnemy") && areaParent.enemyStats.current_health > 0 && areaParent.enemyStats.isDead == false && areaParent.enemyStats.isGuarding == false:
		print("Enemy Health: " + str(areaParent.enemyStats.current_health))
		areaParent.takeDamageEnemy(PlayerAttackManager.lightAttackDamage)
		Global.combo_hits.append({
	"enemy": area,
	"damage": PlayerAttackManager.lightAttackDamage ,
	"attack_type": "attackLight",
	"timestamp": Time.get_ticks_msec()
})
		attackData.isHit = true
		attackData.can_chain_attack = true
		attackData.recovery_timer = attackData.hit_recovery_duration
		attackData.cancel_timer = attackData.cancel_window
		attackData.can_cancel = true
		attackData.cancel_timer = attackData.cancel_window
		attack_box.monitoring = false
		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()
		if area in attackData.enemies_hit:
			return
		attackData.enemies_hit[area] = true 
		Global.isHit = true
		hit1Sound.play()
		Global.attack_cooldown_timer = min(Global.attack_cooldown_timer, attackData.hit_cooldown_amount)

#		change this so it doesnt rely on the node name, only the node type
		if enemy.has_node("EnemyMesh"):
			var mesh = enemy.get_node("EnemyMesh")
			mesh.trigger_flash()
			await get_tree().process_frame
			
		if area.has_method("set_monitoring"):
			area.monitoring = false


		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO
		attackData.can_cancel = true
		
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

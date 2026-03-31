extends LimboState

@export var attack_box: Node
@export var attack_box_col: Node
@export var attack_box_debug: Node
@export var ComboConfirmFX: GPUParticles3D

@onready var playerCharScene =  $"../../RootNode/COWBOYPLAYER_V4"
@onready var gameJuice = get_node("/root/GameJuice")
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)
@export var next_attack_state: StringName 

@export var recovery_duration: float = 0.45   
@export var hit_recovery_duration: float = 0.15
var recovery_timer: float = 0.0

var can_cancel: bool = false
var cancel_timer: float = 0.0
@export var cancel_window: float = 0.2

@export var DECELERATION: float = Global.DECELERATION + 100
@export var attack_power: float = 10.0
@export var combo_window_duration: float = 0.4  
@export var attack_duration: float = 0.4  
@export var hit_cooldown_amount: float = 0.2
@export var attack_cooldown_duration: float = 0.5

@export var enemyTargetLength: float = 0.4
@export var enemyTargetMagnitude: float = 0.01
@export var enemyTargetHitStop: float = 0.4

@export var knockback_force: float = 12.0
@export var knockback_direction: Vector3 = Vector3(0, 1, 0.5)


@export var hit1Sound: AudioStreamPlayer
@export var hit2Sound: AudioStreamPlayer
@export var hit3Sound: AudioStreamPlayer
@export var hit4Sound: AudioStreamPlayer


var enemies_hit := {}
var preserved_velocity: Vector3 = Vector3.ZERO

var attack_cooldown: float = 0.0
var combo_timer: float = 0.0
var can_chain_attack: bool = false  
var isHit: bool = false

var jump_cancel_timer: float = 0.0
@export var jump_cancel_window: float = 0.25

var buffered_input := false

func _enter() -> void:
	enemies_hit.clear()
	if attack_box:
		attack_box_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

	preserved_velocity = agent.velocity
	_start_attack()

func _update(delta: float) -> void:
	_process_attack(delta)
	if Input.is_action_just_pressed("attack_heavy_1"):
		buffered_input = true
	agent.move_and_slide()

func _process_attack(delta: float) -> void:
	if Global.attackMedium_cooldown_timer > 0.0:
		Global.attackMedium_cooldown_timer -= delta
	if recovery_timer > 0.0:
		recovery_timer -= delta
	if combo_timer > 0.0:
		combo_timer -= delta
	if can_cancel:
		cancel_timer -= delta
		if cancel_timer <= 0:
			can_cancel = false

	if buffered_input and can_cancel:
		agent.state_machine.dispatch(next_attack_state)
		
	if Global.attackMedium_cooldown_timer <= 0.0 and recovery_timer <= 0.0:
		if buffered_input and can_chain_attack:
			agent.state_machine.dispatch(next_attack_state)
		else:
			agent.state_machine.dispatch("to_idle")

		buffered_input = false
		_exit_attack_state()


	# Gravity and velocity
	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta
	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)
	else:
		agent.velocity.x = lerp(agent.velocity.x, preserved_velocity.x, 0.1)
		agent.velocity.z = lerp(agent.velocity.z, preserved_velocity.z, 0.1)

	agent.move_and_slide()

func _start_attack() -> void:
	enemies_hit.clear()
	animationTree.set("parameters/AttackShot/request", 1)
	Global.is_attacking = true
	attack_cooldown = attack_duration
	combo_timer = combo_window_duration
	can_chain_attack = false
	
	
	next_attack_state = "to_heavyAttack"  # Light -> Medium

func _on_attack_box_area_entered(area):
	if isHit:
		return
	if area.has_method("takeDamageEnemy"):
		isHit = true
		can_chain_attack = true
		recovery_timer = hit_recovery_duration
		cancel_timer = cancel_window
		attack_box.monitoring = false
		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()
		if area in enemies_hit:
			return
		enemies_hit[area] = true 
		Global.isHit = true
		hit1Sound.play()
		Global.attackMedium_cooldown_timer = min(Global.attackMedium_cooldown_timer, hit_cooldown_amount)
		
		
		
		if enemy.has_node("MeshInstance3D"):
			var mesh = enemy.get_node("MeshInstance3D")
			mesh.trigger_flash()
			await get_tree().process_frame
			
		if area.has_method("set_monitoring"):
			area.monitoring = false

		var hit1Effect = enemy.find_child("hit1", true, false)
				
		if hit1Effect is GPUParticles3D:
			hit1Effect.restart()
			hit1Effect.emitting = true
		elif hit1Effect == null:
			print("Warning: No GPUParticles3D found on " + enemy.name)
			
			
		hit1Effect.process_mode = Node.PROCESS_MODE_ALWAYS
		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO
		can_cancel = true
		gameJuice.objectShake(enemy, enemyTargetLength, enemyTargetMagnitude)
		await gameJuice.hitstop(enemyTargetHitStop)
		agent.velocity = saved_velocity

		if area.has_method("set_monitoring"):
			area.monitoring = true
			
		if enemy is CharacterBody3D:
			#print("Applying knockback to:", enemy.name)
			gameJuice.knockback(
				enemy,
				agent,
				knockback_force,
				knockback_direction
			)

func _exit_attack_state() -> void:
	Global.is_attacking = false
	attack_box_debug.visible = false
	attack_box_col.visible = false
	isHit = false
	if attack_box:
		attack_box.monitoring = false

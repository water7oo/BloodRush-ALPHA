extends LimboState

@export var attack_box: Node
@export var attack_box_col: Node
@export var attack_box_debug: Node
@export var hit1: PackedScene
@onready var playerCharScene =  $"../../RootNode/COWBOYPLAYER_V4"
@onready var gameJuice = get_node("/root/GameJuice")

@onready var animationTree = playerCharScene.find_child("AnimationTree", true)


@export var DECELERATION: float = Global.DECELERATION + 100
@export var attack_power: float = 10.0
@export var animation_request: StringName
@export var next_attack_state: StringName  
@export var combo_window_duration: float = 0.4  
@export var attack_duration: float = 0.4  
@export var hit_cooldown_amount: float = 0.2
@export var attack_cooldown_duration: float = 0.5
var attack_cooldown_timer: float = 0.0

@export var enemyTargetLength: float = 0.4
@export var enemyTargetMagnitude: float = 0.01
@export var enemyTargetHitStop: float = 0.4

@export var knockback_force: float = 12.0
@export var knockback_direction: Vector3 = Vector3(0, 1, 0.5) 

var enemies_hit:= {}

var jump_cancel_timer: float = 0.0
@export var jump_cancel_window: float = 0.25

var preserved_velocity: Vector3 = Vector3.ZERO
var attack_cooldown: float = 0.0
var combo_timer: float = 0.0
var can_chain_attack: bool = false  
var isHit: bool = false

@export var recovery_timer: float = 0.0
@export var recovery_duration: float = 0.6   
@export var hit_recovery_duration: float = 0.2  

var can_cancel: bool = false
var cancel_timer: float = 0.0
@export var cancel_window: float = 0.15  # shorter than light/medium

@export var hit1Sound: AudioStreamPlayer
@export var hit2Sound: AudioStreamPlayer
@export var hit3Sound: AudioStreamPlayer
@export var hit4Sound: AudioStreamPlayer

func _enter() -> void:
	enemies_hit.clear()
	if attack_box:
		attack_box_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true  # Enable hitbox
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

	preserved_velocity = agent.velocity
	print("Current Attack State:", agent.state_machine.get_active_state())
	_start_attack()

func _update(delta: float) -> void:
	_process_attack(delta)
	agent.move_and_slide()

func can_start_attack() -> bool:
	return attack_cooldown_timer <= 0.0 and not Global.is_attacking

func _process_attack(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if recovery_timer > 0.0:
		recovery_timer -= delta
	if combo_timer > 0.0:
		combo_timer -= delta

	if attack_cooldown <= 0.0 and recovery_timer <= 0.0:
		_exit_attack_state()
		if can_chain_attack and next_attack_state:
			agent.state_machine.dispatch(next_attack_state)
		else:
			agent.state_machine.dispatch("to_idle")

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
	isHit = false

	attack_cooldown = attack_duration
	combo_timer = combo_window_duration
	recovery_timer = recovery_duration  

	can_chain_attack = false
	can_cancel = false
	next_attack_state = "to_attackUpper"  # Heavy -> Launcher / Upper

func _on_attack_box_area_entered(area):
	if isHit:
		return

	if area.has_method("takeDamageEnemy"):
		isHit = true

		# ✅ shorten recovery on hit
		recovery_timer = hit_recovery_duration

		# ✅ small cancel window (heavy = restrictive)
		can_cancel = true
		cancel_timer = cancel_window

		attack_box.monitoring = false

		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()

		if area in enemies_hit:
			return
		enemies_hit[area] = true 

		Global.isHit = true
		hit4Sound.play()

		attack_cooldown = min(attack_cooldown, hit_cooldown_amount)
		
		var hit1Effect = enemy.find_child("hit1", true, false)
				
		if hit1Effect is GPUParticles3D:
			#print("HIT EFFECT")
			hit1Effect.restart()
			hit1Effect.emitting = true
		elif hit1Effect == null:
			print("Warning: No GPUParticles3D found on " + enemy.name)

			
		if enemy.has_node("MeshInstance3D"):
			var mesh = enemy.get_node("MeshInstance3D")
			mesh.trigger_flash()
			await get_tree().process_frame
			
		if area.has_method("set_monitoring"):
			area.monitoring = false

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO
		gameJuice.objectShake(area.get_parent(), enemyTargetLength, enemyTargetMagnitude)
		await gameJuice.hitstop(enemyTargetHitStop * 1.5)
		agent.velocity = saved_velocity
		#await get_tree().create_timer(enemyTargetHitStop).timeout

		



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





func pause():
	process_mode = PROCESS_MODE_DISABLED

func unpause():
	process_mode = PROCESS_MODE_INHERIT

func _exit_attack_state() -> void:
	Global.is_attacking = false
	attack_box_debug.visible = false
	attack_box_col.visible = false
	isHit = false
	if attack_box:
		attack_box.monitoring = false

	# Reset cooldown timers
	Global.attackHeavy_cooldown_timer = Global.attackHeavy_cooldown_duration
	attack_cooldown_timer = attack_cooldown_duration

	# DO NOT force idle; let input and state machine decide next state
	# agent.state_machine.dispatch("to_idle")

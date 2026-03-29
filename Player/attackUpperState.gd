extends LimboState

@export var attack_box: Node
@export var attack_box_col: Node
@export var attackUpper_debug: Node
@export var hit1: PackedScene
@onready var playerCharScene =  $"../../RootNode/COWBOYPLAYER_V4"
@onready var gameJuice = get_node("/root/GameJuice")

@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var attackPush: float = 10.0
@export var DECELERATION: float = Global.DECELERATION + 100
@export var attack_power: float = 10.0
@export var animation_request: StringName
@export var next_attack_state: StringName
@export var combo_window_duration: float = 0.4
@export var attack_duration: float = 0.4
@export var hit_cooldown_amount: float = 0.2

@export var enemyTargetLength: float = 0.4
@export var enemyTargetMagnitude: float = 0.01
@export var enemyTargetHitStop: float = 0.4

@export var knockback_force: float = 12.0
@export var knockback_direction: Vector3 = Vector3(0, 1, 0.5) 

@export var hit1Sound: AudioStreamPlayer
@export var hit2Sound: AudioStreamPlayer
@export var hit3Sound: AudioStreamPlayer
@export var jump_cancel_window: float = 0.25
@export var attack_startup: float = 0.1

var enemies_hit:= {}

var preserved_velocity: Vector3 = Vector3.ZERO
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var combo_timer: float = 0.0
var can_chain_attack: bool = false


var jump_cancel_timer: float = 0.0
var isHit: bool = false

func _enter() -> void:
	enemies_hit.clear()
	if attack_box:
		attackUpper_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

	preserved_velocity = agent.velocity

	print("Current Attack State:", agent.state_machine.get_active_state())
	print("SHORYUKEN")
	_start_attack()

func _update(delta: float) -> void:
	_process_attack(delta)
	agent.move_and_slide()

func _process_attack(delta: float) -> void:
	if is_attacking == false:
		return
	if is_attacking:
		attack_cooldown -= delta
		combo_timer -= delta
	if Global.attack_cooldown_timer > 0.0:
		Global.attack_cooldown_timer -= delta
		
	if jump_cancel_timer > 0.0:
		jump_cancel_timer -= delta
		
		if Input.is_action_just_pressed("move_jump"):
			print("Jump Cancel")
			agent.velocity.y = Global.JUMP_VELOCITY
			agent.velocity.x *= 1.1
			agent.velocity.z *= 1.1
			isHit = false
			jump_cancel_timer = 0.0
			
			_exit_attack_state()
			agent.state_machine.dispatch("to_jump")
			return
	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta


	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)
	else:

		agent.velocity.x = lerp(agent.velocity.x, preserved_velocity.x, 0.1)
		agent.velocity.z = lerp(agent.velocity.z, preserved_velocity.z, 0.1)

	if jump_cancel_timer > 0.0:
		jump_cancel_timer -= delta

		if Input.is_action_just_pressed("move_jump"):
			print("JUMP CANCEL")
			agent.velocity.y = Global.JUMP_VELOCITY

			#agent.velocity.x *= 10
			#agent.velocity.z *= 10

			jump_cancel_timer = 0.0
			isHit = false

			agent.state_machine.dispatch("to_jump")
			return

	# Combo chain
	if combo_timer > 0 and Input.is_action_just_pressed("attack_light_1"):
		can_chain_attack = true
		print("Attack chain triggered!")

	# Exit
	if attack_cooldown <= 0.0:
		if can_chain_attack and next_attack_state:
			agent.state_machine.dispatch(next_attack_state)
		else:
			_exit_attack_state()

func _start_attack() -> void:
	enemies_hit.clear()
	animationTree.set("parameters/AttackShot/request", 1)
	is_attacking = true
	attack_cooldown = attack_duration
	combo_timer = combo_window_duration
	can_chain_attack = false

	# reset hit state
	isHit = false
	jump_cancel_timer = 0.0

func _on_attack_box_area_entered(area):
	if area.has_method("takeDamageEnemy"):
		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()
				
		if area in enemies_hit:
			return
		enemies_hit[area] = true 
		
		print("Enemy hit:", area.name)
		isHit = true
		Global.isHit = true
		hit1Sound.play()
		jump_cancel_timer = jump_cancel_window
		attack_cooldown = min(attack_cooldown, hit_cooldown_amount)

		gameJuice.objectShake(area.get_parent(), enemyTargetLength, enemyTargetMagnitude)
		
		if enemy.has_node("MeshInstance3D"):
			var mesh = enemy.get_node("MeshInstance3D")
			mesh.trigger_flash()
			await get_tree().process_frame
			
		if area.has_method("set_monitoring"):
			area.monitoring = false

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO
		pause()
		await get_tree().create_timer(enemyTargetHitStop).timeout

		unpause()
		
		agent.velocity = saved_velocity


		if area.has_method("set_monitoring"):
			area.monitoring = true
			


			
			
		if enemy is CharacterBody3D:
			print("Applying knockback to:", enemy.name)
			gameJuice.knockback(
				enemy,
				agent,
				knockback_force,
				knockback_direction
			)

	# Hit effect
	if hit1 and enemy:
		var hit_effect = hit1.instantiate()
		get_tree().current_scene.add_child(hit_effect)

		if hit_effect is GPUParticles3D:
			hit_effect.restart()
		elif hit_effect.has_method("restart"):
			hit_effect.call("restart")
		elif hit_effect.has_method("set_emitting"):
			hit_effect.set("emitting", true)

		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(hit_effect):
			hit_effect.queue_free()

func pause():
	process_mode = PROCESS_MODE_DISABLED

func unpause():
	process_mode = PROCESS_MODE_INHERIT

func _exit_attack_state() -> void:
	is_attacking = false
	attackUpper_debug.visible = false
	attack_box_col.visible = false
	attack_cooldown = 0.0
	Global.attack_cooldown_timer = Global.attack_cooldown_duration
	if attack_box:
		attack_box.monitoring = false

	print("Attack ended, hitbox disabled:", attack_box.monitoring)
	agent.state_machine.dispatch("to_idle")

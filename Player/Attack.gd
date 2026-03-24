extends LimboState

@export var attack_box: Node
@export var attack_box_col: Node
@export var hit1: PackedScene
@onready var playerCharScene =  $"../../RootNode/COWBOYPLAYER_V4"
@onready var gameJuice = get_node("/root/GameJuice")

@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var attackPush: float = 10.0
@export var DECELERATION: float = Global.DECELERATION + 100
@export var attack_power: float = 10.0
@export var animation_request: StringName
@export var next_attack_state: StringName  # State name for chaining attacks
@export var combo_window_duration: float = 0.4  # Time frame for chaining attacks
@export var attack_cooldown_amount: float = 0.2  # Cooldown between attacks

var preserved_velocity: Vector3 = Vector3.ZERO
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var combo_timer: float = 0.0
var can_chain_attack: bool = false  # Tracks if chaining is allowed

func _enter() -> void:
	if attack_box:
		attack_box_col.visible = true
		attack_box.monitoring = true  # Enable hitbox
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

	print("Current Attack State:", agent.state_machine.get_active_state())
	_start_attack()

func _update(delta: float) -> void:
	_process_attack(delta)
	agent.move_and_slide()

func _process_attack(delta: float) -> void:
	if is_attacking:
		attack_cooldown -= delta
		combo_timer -= delta

		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)

		# Allow chaining attack
		if combo_timer > 0 and Input.is_action_just_pressed("attack_light_1"):
			can_chain_attack = true
			print("Attack chain triggered!")

		# If attack animation ends and no chain attack is triggered, return to idle
		if attack_cooldown <= 0.0:
			if can_chain_attack and next_attack_state:
				agent.state_machine.dispatch(next_attack_state)
			else:
				_exit_attack_state()

func _start_attack() -> void:
	animationTree.set("parameters/AttackShot/request", 1)
	is_attacking = true
	attack_cooldown = attack_cooldown_amount
	combo_timer = combo_window_duration
	can_chain_attack = false

func _on_attack_box_area_entered(area):
	if area.has_method("takeDamageEnemy"):
		print("Enemy hit:", area.name)
		gameJuice.objectShake(area.get_parent(), 0.1, .2)
		pause()
		await get_tree().create_timer(.3).timeout
		unpause()

		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()

		if enemy is CharacterBody3D:
			print("Applying knockback to:", enemy.name)
			gameJuice.knockback(enemy, agent, 9)
			
	# Assuming the 'hit1' scene is a one-shot particle and has a finite lifetime
	if hit1 and enemy:
		var hit_effect = hit1.instantiate()
		var offset = Vector3.UP
		
		get_tree().current_scene.add_child(hit_effect)

		# Set global position *after* adding
		hit_effect.global_transform.origin = enemy.global_transform.origin + offset
		
		# Try to start the particle manually (assumes root node is a GPUParticles3D or similar)
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
	attack_box_col.visible = false
	attack_cooldown = 0.0
	if attack_box:
		attack_box.monitoring = false

	print("Attack ended, hitbox disabled:", attack_box.monitoring)
	agent.state_machine.dispatch("to_idle")

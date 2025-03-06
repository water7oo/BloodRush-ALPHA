extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM
@onready var swordKatana = $"../../RootNode/COWBOYPLAYER_V4/Armature_001/Skeleton3D/BoneAttachment3D/BloodKatana"
@export var playerCharScene: Node
@export var attack_box: Node
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var attackPush: float = 10.0
@export var DECELERATION: float = Global.DECELERATION + 100  # Smooth stop during attack
@export var attack_power: float = 10.0
var preserved_velocity: Vector3 = Vector3.ZERO
var is_attacking: bool = false
var attack_cooldown: float = 0.0  # Cooldown timer
var attack_cooldown_amount: float = 0.2
var current_speed: float = 0.0
var target_speed: float = Global.MAX_SPEED
var attack_proccessing: bool = false
var can_attack: bool = true

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	preserved_velocity = agent.velocity  # Preserve movement before attack
	_start_attack()  # Immediately trigger attack on state entry

func _update(delta: float) -> void:
	_process_attack(delta)
	agent.move_and_slide()

func _process_attack(delta: float) -> void:
	# Handle attack cooldown
	if is_attacking:
		attack_cooldown -= delta

		# Smoothly stop movement using DECELERATION
		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)

		# Check if attack animation is no longer active
		if attack_cooldown <= 0.0 and animationTree.get("parameters/Attack_Shot/request") == 0:
			_exit_attack_state(delta)

func _start_attack() -> void:
	animationTree.set("parameters/Attack_Shot/request", 1)
	if attack_box:
		attack_box.monitoring = true

	is_attacking = true
	attack_cooldown = attack_cooldown_amount  # Set cooldown



func _on_attack_box_area_entered(area):
	if area.has_method("takeDamageEnemy") && !attack_proccessing && can_attack:
		Global.enemyHealthMan.takeDamageEnemy(Global.enemyHealthMan.health , attack_power)
		print("Enemy got hit")
		$AudioStreamPlayer.play()
		Global.gameJuice.hitStop(0.25, area)
		attack_cooldown = 0.1
		
		attack_box.monitoring = false
		Global.gameJuice.knockback(area.get_parent(), attack_box, 6)
		

func _exit_attack_state(delta: float) -> void:
	is_attacking = false
	attack_cooldown = 0.0  # Reset cooldown

	# Stop attack box and reset animation state
	if attack_box:
		attack_box.monitoring = false  

	# Transition to idle or movement depending on input
	if Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
		current_speed = move_toward(current_speed, target_speed, Global.run_momentum_acceleration * delta)
		agent.state_machine.dispatch("to_walk")
	else:
		agent.state_machine.dispatch("to_idle")

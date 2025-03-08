extends LimboState
@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM
@onready var swordKatana = $"../../RootNode/COWBOYPLAYER_V4/Armature_001/Skeleton3D/BoneAttachment3D/BloodKatana"
@export var playerCharScene: Node
@export var attack_box: Node
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var attackPush: float = 10.0
@export var DECELERATION: float = Global.DECELERATION + 100
@export var attack_power: float = 10.0

var preserved_velocity: Vector3 = Vector3.ZERO
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var attack_cooldown_amount: float = 0.2
var combo_window_duration: float = 0.4  # Time frame for second attack
var combo_timer: float = 0.0
var can_attack: bool = true
var can_chain_attack: bool = false  # Tracks if second attack is allowed

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	preserved_velocity = agent.velocity  
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

		# Allow chaining to the second attack
		if combo_timer > 0 and Input.is_action_just_pressed("attack_light_1"):
			can_chain_attack = true
			print("Second impact detected!")

		# End attack state if animation is over and no second attack
		if attack_cooldown <= 0.0 and animationTree.get("parameters/Attack_Shot/request") == 0:
			if can_chain_attack:
				_trigger_second_attack()
			else:
				_exit_attack_state()

func _start_attack() -> void:
	animationTree.set("parameters/Attack_Shot/request", 1)
	if attack_box:
		attack_box.monitoring = true

	is_attacking = true
	attack_cooldown = attack_cooldown_amount  
	combo_timer = combo_window_duration  # Start the combo timer
	can_chain_attack = false  # Reset chain attack flag

func _trigger_second_attack() -> void:
	print("Second attack triggered!")
	animationTree.set("parameters/Attack_Shot2/request", 1)  # Change to second attack animation
	can_chain_attack = false
	combo_timer = 0.0  
	attack_cooldown = attack_cooldown_amount  

func _on_attack_box_area_entered(area):
	if area.has_method("takeDamageEnemy") and can_attack:
		Global.enemyHealthMan.takeDamageEnemy(Global.enemyHealthMan.health, attack_power)
		print("Enemy got hit")
		$AudioStreamPlayer.play()
		Global.gameJuice.hitStop(0.25, area)
		attack_box.monitoring = false
		Global.gameJuice.knockback(area.get_parent(), attack_box, 6)

func _exit_attack_state() -> void:
	is_attacking = false
	attack_cooldown = 0.0

	if attack_box:
		attack_box.monitoring = false  

	if Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
		agent.state_machine.dispatch("to_walk")
	else:
		agent.state_machine.dispatch("to_idle")

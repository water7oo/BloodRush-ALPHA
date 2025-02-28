extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM

@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var attackPush = 10.0

var preserved_velocity: Vector3 = Vector3.ZERO
var is_attacking: bool = false  # Track attack state

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	preserved_velocity = agent.velocity
	player_attack()

func _update(delta: float) -> void:
	if is_attacking and not animationTree.get("parameters/Attack_Shot/request"):
		_exit_attack_state()  # Transition out when the attack request is done

	agent.move_and_slide()

func player_attack() -> void:
	if Input.is_action_just_pressed("attack_light_1"):
		animationTree.set("parameters/Attack_Shot/request", 1)
		is_attacking = true

func _exit_attack_state() -> void:
	is_attacking = false
	# Transition to idle or movement depending on input
	if Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
		agent.state_machine.dispatch("to_walk")
	else:
		agent.state_machine.dispatch("to_idle")

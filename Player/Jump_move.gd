extends LimboState


@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM

var JUMP_VELOCITY: float = 10.0
const CUSTOM_GRAVITY: float = 30.0  


var BASE_SPEED: float = 6.0  

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())

func _update(delta: float) -> void:
	# Apply gravity
	if not agent.is_on_floor():
		agent.velocity.y -= CUSTOM_GRAVITY * delta

	# Landing transition
	if agent.is_on_floor():
		print("Landed!")
		agent.state_machine.dispatch("to_walk" if Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO else "to_idle")

	agent.move_and_slide()

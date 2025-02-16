extends LimboState

@export var animation_player : AnimationPlayer
@export var animation : StringName
@onready var state_machine: LimboHSM = $LimboHSM

var BASE_SPEED = 6.0

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())

func _update(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Move the player if there's input
	if direction:
		agent.velocity.x = direction.x * BASE_SPEED
		agent.velocity.z = direction.z * BASE_SPEED
	else:
		# If no input, slow down and transition to idle
		agent.velocity.x = move_toward(agent.velocity.x, 0, BASE_SPEED)
		agent.velocity.z = move_toward(agent.velocity.z, 0, BASE_SPEED)
		if agent.velocity.length() < 0.1:
			agent.state_machine.dispatch("to_idle")  

	# Jump transition
	if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
		agent.state_machine.dispatch("to_jump")

	agent.move_and_slide()

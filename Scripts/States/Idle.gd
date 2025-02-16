extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM

var BASE_SPEED = 6.0  

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())

func _update(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Move the player if there's input
	if direction.length() > 0:
		agent.velocity.x = direction.x * BASE_SPEED
		agent.velocity.z = direction.z * BASE_SPEED
		agent.state_machine.dispatch("to_walk")  # Transition to WalkState

	else:
		# Slow down if no input
		agent.velocity.x = move_toward(agent.velocity.x, 0, BASE_SPEED)
		agent.velocity.z = move_toward(agent.velocity.z, 0, BASE_SPEED)

	# Jump only when on the floor
	if Input.is_action_just_pressed("move_jump"):
		agent.state_machine.dispatch("to_jump")  # Correct transition name

	# Apply movement
	agent.move_and_slide()

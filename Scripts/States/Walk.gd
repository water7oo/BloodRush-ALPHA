extends LimboState

@export var animation_player : AnimationPlayer
@export var animation : StringName

func _enter() -> void:
	print("Entered Walk State")

func _update(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		agent.velocity.x = direction.x * agent.SPEED
		agent.velocity.z = direction.z * agent.SPEED
	else:
		agent.state_machine.dispatch("to_idle")  
		agent.velocity.x = move_toward(agent.velocity.x, 0, agent.SPEED)
		agent.velocity.z = move_toward(agent.velocity.z, 0, agent.SPEED)

	agent.move_and_slide()

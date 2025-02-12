extends LimboState

@export var animation_player : AnimationPlayer
@export var animation : StringName

func _enter() -> void:
	print("Entered Idle State")

func _update(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if input_dir != Vector2.ZERO:
		agent.state_machine.dispatch("to_walk")  # Switch to walking

extends LimboState

@onready var armature = $"../../RootNode"
@onready var state_machine: LimboHSM = $LimboHSM

var velocity = Vector3.ZERO
var is_moving: bool = false

@export var GuardActivateSound: AudioStreamPlayer
@export var guardResource: Resource


func _enter() -> void:
	if agent:
		velocity = agent.velocity
		
		velocity.x = 0
		velocity.z = 0
		
	GuardActivateSound.play()
	print("Current State:", agent.state_machine.get_active_state())

	# Preserve momentum from the previous state
	velocity = agent.velocity
	velocity.y = 0  

func _update(delta: float) -> void:
	player_movement(delta)
	agent.move_and_slide()

func player_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	var has_input = direction != Vector3.ZERO and Global.can_move

	if has_input:
		Global.is_moving = true

		armature.rotation.y = lerp_angle(
			armature.rotation.y,
			atan2(-direction.x, -direction.z),
			.1
		)

		Global.current_speed = move_toward(
			Global.current_speed,
			guardResource.GUARD_BASE_SPEED,
			guardResource.GUARD_ACCELERATION * delta
		)

	else:
		Global.is_moving = false

		Global.current_speed = move_toward(
			Global.current_speed,
			0,
			guardResource.GUARD_DECELERATION * delta
		)

	var target_velocity = direction * Global.current_speed

	var t = 1.0 - exp(-guardResource.inertia_blend * delta)
	velocity = velocity.lerp(target_velocity, t)

	velocity.y = agent.velocity.y
	agent.velocity = velocity

	if Input.is_action_just_released("defend_guard"):
		if Global.current_speed < 0.1:
			agent.state_machine.dispatch("to_idle")
		else:
			agent.state_machine.dispatch("to_walk")

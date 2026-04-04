extends LimboState

@onready var state_machine: LimboHSM = $LimboHSM
@onready var armature = $"../../RootNode"


var velocity = Vector3.ZERO


@export var runJumpResource: Resource


func _enter() -> void:
	if agent:
		velocity = agent.velocity
	print("Current State:", agent.state_machine.get_active_state())
	agent.velocity.y = runJumpResource.JUMP_VELOCITY
	#animationTree.set("parameters/Jump_Blend/blend_amount", 1)
	# Reset timers and jump counter
	Global.air_timer = 0.0
	Global.jump_timer = 0.0
	Global.jump_counter = 0

func _update(delta: float) -> void:
	player_runjump(delta)
	agent.move_and_slide()


func player_runjump(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	# Rotate armature in air if moving
	if direction != Vector3.ZERO:
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-direction.x, -direction.z), Global.armature_rot_speed)

	# Handle jumping mechanics
	if Input.is_action_pressed("move_jump") and Global.can_jump:
		Global.jump_timer += delta
		Global.air_timer += delta
		if Global.jump_timer <= 0.4:  # Short-duration jump
			agent.velocity.y = runJumpResource.JUMP_VELOCITY  # Apply jump force
			Global.target_blend_amount = 0.0
			Global.current_blend_amount = lerp(Global.current_blend_amount, Global.target_blend_amount, Global.blend_lerp_speed * delta)

			Global.can_jump = false
			Global.jump_counter += 1

	# Preserve momentum and blend movement mid-air
	if direction != Vector3.ZERO:
		var target_rotation = atan2(direction.x, direction.z)

		if velocity.length() > 0.1:
			var angle_diff = velocity.normalized().dot(direction)
			if angle_diff < 0:
				velocity *= 0.8
		# Blend smoothly towards new direction
		agent.velocity.x = lerp(agent.velocity.x, direction.x * Global.BASE_SPEED, runJumpResource.air_momentum_acceleration * delta)
		agent.velocity.z = lerp(agent.velocity.z, direction.z * Global.BASE_SPEED, runJumpResource.air_momentum_acceleration * delta)


	if not agent.is_on_floor() and agent.velocity.y < 0:
		#animationTree.set("parameters/Jump_Blend/blend_amount", 0)
		pass
		
	# Landing logic
	if agent.is_on_floor():
		Global.jump_timer = 0.0
		Global.air_timer = 0.0
		#animationTree.set("parameters/Jump_Blend/blend_amount", -1)
		# Gradually slow down after landing instead of an abrupt stop
		agent.velocity.x = move_toward(agent.velocity.x, 0, 100 * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, 100 * delta)

		# Transition to walk or idle based on input
		if input_dir != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
		else:
			agent.state_machine.dispatch("to_idle")

extends LimboState


@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@onready var armature = $"../../RootNode"
@onready var state_machine: LimboHSM = $LimboHSM

@export var jump1Sound: AudioStreamPlayer
@export var land1Sound: AudioStreamPlayer

var velocity = Vector3.ZERO

@export var moveDust: GPUParticles3D
@export var landDust: GPUParticles3D


@export var jumpResource: Resource

func _enter() -> void:
	Global.stretch_up($"../../RootNode/player2")
	jumpSound()
	if agent:
		velocity = agent.velocity
	if moveDust.emitting:
		moveDust.emitting = false
	if agent.is_on_floor():
		agent.velocity.y = jumpResource.JUMP_VELOCITY
	
	Global.air_timer = 0.0
	Global.jump_timer = 0.0
	Global.jump_counter = 0
	jumpResource.JUMP_VELOCITY = jumpResource.DEFAULT_JUMP_VELOCITY
	

func jumpSound():
	jump1Sound.pitch_scale = randf_range(0.6, 1.2)
	jump1Sound.play()
	
func landSound():
	land1Sound.pitch_scale = randf_range(0.6, 1.2)
	land1Sound.play()
	
func landCheck():
	var is_on_floor = agent.is_on_floor()

	if agent.state_machine.get_active_state() == self:
		if is_on_floor and not Global.was_on_floor:
			landSound()
			landDust.restart()
			landDust.emitting = true
			Global.squash_land($"../../RootNode/player2")
			agent.state_machine.dispatch("to_idle")
		

	Global.was_on_floor = is_on_floor
	
func _update(delta: float) -> void:
	player_jump(delta)
	agent.move_and_slide()
	if animation_player:
		animation_player.play("jumpIdle")

	landCheck()

func player_jump(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	var has_input = direction != Vector3.ZERO

	if has_input:
		armature.rotation.y = lerp_angle(
			armature.rotation.y,
			atan2(-direction.x, -direction.z),
			Global.armature_rot_speed
		)

		var target_velocity = direction * jumpResource.AIR_MAX_SPEED

		var t = 1.0 - exp(-jumpResource.air_momentum_acceleration * delta)

		velocity.x = lerp(velocity.x, target_velocity.x, t)
		velocity.z = lerp(velocity.z, target_velocity.z, t)
	if not has_input:
		velocity.x = move_toward(velocity.x, 0, jumpResource.AIR_DRAG * delta)
		velocity.z = move_toward(velocity.z, 0, jumpResource.AIR_DRAG * delta)
		
		
	var horizontal = Vector2(velocity.x, velocity.z)
	if horizontal.length() > jumpResource.AIR_MAX_SPEED:
		horizontal = horizontal.normalized() * jumpResource.AIR_MAX_SPEED
		velocity.x = horizontal.x
		velocity.z = horizontal.y
		
		
	# Preserve gravity
	velocity.y = agent.velocity.y
	agent.velocity = velocity

	if agent.is_on_floor():
		velocity.x *= jumpResource.LANDING_DAMPING
		velocity.z *= jumpResource.LANDING_DAMPING

		# Transition
		if Input.is_action_pressed("move_crouch"):
			animation_player.play("IDLE")
			agent.state_machine.dispatch("to_crouch")
		elif has_input:
			animation_player.play("IDLE")
			agent.state_machine.dispatch("to_walk")
		else:
			animation_player.play("IDLE")
			agent.state_machine.dispatch("to_idle")


# Falling check
	if not agent.is_on_floor() and agent.velocity.y < 0:
		#animationTree.set("parameters/Jump_Blend/blend_amount", 0)
		pass
		

extends LimboState

@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@export var animation : StringName
@onready var armature = $"../../RootNode"



var sprinting = Input.is_action_pressed("move_sprint")
var velocity = Vector3.ZERO


@onready var Stamina_bar = $"UI Cooldowns"
@export var runResource: Resource


func _enter() -> void:
	if agent:
		velocity = agent.velocity
		
		velocity.x = 0
		velocity.z = 0
	
	if animation_player:
		animation_player.play("Run")
	pass
	
func _update(delta: float) -> void:
	player_run(delta)
	initialize_runJump(delta)
	initialize_attack(delta)
	initialize_crouch(delta)
	initialize_guard(delta)
	agent.move_and_slide()

# Smooth run (Mario-esque momentum)
func player_run(delta: float) -> void:
	if !Global.can_move:
		return
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	var has_input = direction != Vector3.ZERO and agent.is_on_floor()

	if has_input and Global.can_sprint:
		Global.is_sprinting = true
		Global.sprint_timer += delta

		armature.rotation.y = lerp_angle(
			armature.rotation.y,
			atan2(-direction.x, -direction.z),
			runResource.RUN_armature_rot_speed
		)

		# FAST acceleration
		Global.current_speed = move_toward(
			Global.current_speed,
			runResource.RUN_MAX_SPEED,
			runResource.run_momentum_acceleration * delta
		)

	else:
		Global.is_sprinting = false

		Global.current_speed = move_toward(
			Global.current_speed,
			0,
			runResource.RUN_DECELERATION * delta
		)

	# Apply movement DIRECTLY (no double smoothing)
	var target_velocity = direction * Global.current_speed
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z

	velocity.y = agent.velocity.y
	agent.velocity = velocity
	
	var target_rotation = atan2(direction.x, direction.z)

	if velocity.length() > 0.1:
		var angle_diff = velocity.normalized().dot(direction)
		if angle_diff < 0:
			velocity *= 0.2
				
				
	if Input.is_action_pressed("move_crouch") && agent.is_on_floor():
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_crouch")
		

	elif Input.is_action_just_released("move_sprint") && has_input && agent.is_on_floor():
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_walk")

	elif not has_input && agent.is_on_floor():
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_idle")


func initialize_runJump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
		#animationTree.set("parameters/Ground_Blend2/blend_amount", -1)
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_runJump")
	pass

func initialize_crouch(delta: float) -> void:
	if Input.is_action_pressed("move_crouch"):
		#animationTree.set("parameters/Ground_Blend/blend_amount", 0)
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_crouch")

func initialize_attack(delta: float) -> void:
	#pressing attack unsheathes katana and player is in attackmode
	if Input.is_action_just_pressed("attack_light_1"):
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_attack")

func initialize_guard(delta: float) -> void:
	if Input.is_action_just_pressed("defend_guard"):
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_guard")

func _exit() -> void:
	pass

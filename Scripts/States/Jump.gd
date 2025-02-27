extends LimboState

@onready var armature = $"../../RootNode"
@onready var state_machine: LimboHSM = $LimboHSM

@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree =  playerCharScene.find_child("AnimationTree", true)

@export var BASE_SPEED: float = 6.0  # Retained for ground speed consistency

@export var air_timer: float = 0.0
@export var jump_timer: float = 0.0
@export var jump_counter: int = 0
@export var can_jump: bool = true
var last_ground_position = Vector3.ZERO

@export var MAX_SPEED: float = Global.MAX_SPEED - 3
@export var ACCELERATION: float = Global.ACCELERATION - 5
@export var DECELERATION: float = Global.DECELERATION + 100  # Higher deceleration for more "floaty" air control


@export var momentum_deceleration: float = 1  # Reduced to allow smoother air momentum



var current_speed: float = 0.0
var is_moving: bool = false
var target_speed: float = MAX_SPEED
var velocity = Vector3.ZERO

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	agent.velocity.y = Global.JUMP_VELOCITY
	# Reset timers and jump counter
	air_timer = 0.0
	jump_timer = 0.0
	jump_counter = 0

func _update(delta: float) -> void:
	player_jump(delta)
	agent.move_and_slide()


func player_jump(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	# Rotate armature in air if moving
	if direction != Vector3.ZERO:
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-direction.x, -direction.z), Global.armature_rot_speed)

	if Input.is_action_pressed("move_jump") and can_jump:
		jump_timer += delta
		air_timer += delta
		if jump_timer <= 0.4:  # Jump if held for a short duration
			agent.velocity.y = Global.JUMP_VELOCITY  # Apply jump force
			Global.target_blend_amount = 0.0
			Global.current_blend_amount = lerp(Global.current_blend_amount, Global.target_blend_amount, Global.blend_lerp_speed * delta)
			animationTree.set("parameters/Ground_Blend/blend_amount", 0)

			can_jump = false
			jump_counter += 1

	# Preserve momentum and blend movement mid-air
	if direction != Vector3.ZERO:
		var angle_diff = agent.velocity.normalized().dot(direction)

		# If changing direction sharply mid-air, slow down slightly for smoother transition
		if angle_diff < 0 and agent.velocity.length() >= BASE_SPEED * 0.9:
			agent.velocity.x = move_toward(agent.velocity.x, 0, Global.air_momentum_deceleration * delta)
			agent.velocity.z = move_toward(agent.velocity.z, 0, Global.air_momentum_deceleration * delta)

		# Blend smoothly towards new direction
		agent.velocity.x = lerp(agent.velocity.x, direction.x * BASE_SPEED, Global.air_momentum_acceleration * delta)
		agent.velocity.z = lerp(agent.velocity.z, direction.z * BASE_SPEED, Global.air_momentum_acceleration * delta)

	# Landing logic
	if agent.is_on_floor():
		print("Landed!")

		# Gradually slow down after landing instead of an abrupt stop
		agent.velocity.x = move_toward(agent.velocity.x, 0, 100 * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, 100 * delta)

		# Transition to walk or idle based on input
		if input_dir != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
		else:
			agent.state_machine.dispatch("to_idle")



 

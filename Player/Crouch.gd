extends LimboState

@onready var armature = $"../../RootNode"
@onready var state_machine: LimboHSM = $LimboHSM
@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var BASE_SPEED: float = Global.BASE_SPEED - 2  # Slightly slower than walking
@export var DECELERATION: float = Global.DECELERATION - 5  

var velocity = Vector3.ZERO
var is_moving: bool = false

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())

	# Preserve momentum from the previous state
	velocity = agent.velocity
	velocity.y = 0  # Keep vertical movement separate

func _update(delta: float) -> void:
	player_movement(delta)
	agent.move_and_slide()

func player_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	animationTree.set("parameters/Ground_Blend/blend_amount", 0)  # Crouch animation

	if direction != Vector3.ZERO:
		is_moving = true
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)

		# Smooth transition into crouch movement, blending previous momentum
		velocity = velocity.lerp(direction * BASE_SPEED, Global.inertia_blend * delta)
	else:
		is_moving = false
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

	velocity.y = agent.velocity.y  # Preserve vertical movement
	agent.velocity = velocity

	# Transition back to standing
	if Input.is_action_just_released("move_crouch"):
		animationTree.set("parameters/Ground_Blend/blend_amount", 1)  # Return to standing animation
		if input_dir == Vector2.ZERO:
			agent.state_machine.dispatch("to_idle")
		else:
			agent.state_machine.dispatch("to_walk")

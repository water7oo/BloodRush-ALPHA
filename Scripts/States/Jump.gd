extends LimboState

@onready var armature = $"../../RootNode"
@onready var state_machine: LimboHSM = $LimboHSM
@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var BASE_SPEED: float = 6.0  
@export var MAX_SPEED: float = Global.MAX_SPEED - 3
@export var ACCELERATION: float = Global.ACCELERATION - 5
@export var DECELERATION: float = Global.DECELERATION + 50  # Adjusted to allow smoother momentum retention
@export var momentum_deceleration: float = 1  

var air_timer: float = 0.0
var jump_timer: float = 0.0
var jump_counter: int = 0
var can_jump: bool = true

var velocity = Vector3.ZERO

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	agent.velocity.y = Global.JUMP_VELOCITY
	animationTree.set("parameters/Jump_Blend/blend_amount", 1)
	
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

	# Preserve momentum mid-air
	if direction != Vector3.ZERO:
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-direction.x, -direction.z), Global.armature_rot_speed)

		# Maintain forward momentum but allow direction blending
		agent.velocity.x = lerp(agent.velocity.x, direction.x * BASE_SPEED, Global.air_momentum_acceleration * delta)
		agent.velocity.z = lerp(agent.velocity.z, direction.z * BASE_SPEED, Global.air_momentum_acceleration * delta)

	# Landing logic with smooth deceleration instead of hard stop
	if agent.is_on_floor():
		print("Landed!")
		animationTree.set("parameters/Jump_Blend/blend_amount", -1)
		
		# Reduce velocity smoothly rather than stopping immediately
		agent.velocity.x = move_toward(agent.velocity.x, agent.velocity.x * 0.5, 20 * delta)
		agent.velocity.z = move_toward(agent.velocity.z, agent.velocity.z * 0.5, 20 * delta)

		# Transition to appropriate state
		if input_dir != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
		elif Input.is_action_pressed("move_crouch"):
			agent.state_machine.dispatch("to_crouch")
		#elif input_dir == Vector2.ZERO:
			#agent.state_machine.dispatch("to_idle")



	if not agent.is_on_floor() and agent.velocity.y < 0:
		animationTree.set("parameters/Jump_Blend/blend_amount", 0)
		#print("Falling!")

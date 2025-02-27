extends LimboState

@export var animation_player : AnimationPlayer
@export var animation : StringName
@onready var armature = $"../../RootNode"

@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree =  playerCharScene.find_child("AnimationTree", true)

var sprinting = Input.is_action_pressed("move_sprint")
var is_in_air: bool = false
var is_moving: bool = false
var can_sprint: bool = true
var can_move: bool = true
var is_sprinting: bool = false
var current_speed: float = 0.0
var sprint_timer: float = 0.0

@export var runMultiplier: float = 1.5
@export var runAdditive: float = 3
@export var MAX_SPEED: float = Global.MAX_SPEED + runAdditive
@export var BASE_SPEED: float = Global.BASE_SPEED + runAdditive
var target_speed: float = MAX_SPEED

@onready var Stamina_bar = $"UI Cooldowns"

@export var ACCELERATION: float = 1
@export var DECELERATION: float = Global.DECELERATION - 5
@export var BASE_ACCELERATION: float = 1
@export var BASE_DECELERATION: float = Global.DECELERATION - 5

@export var BASE_DASH_ACCELERATION: float = Global.ACCELERATION - 2
@export var BASE_DASH_DECELERATION: float = Global.DECELERATION - 5

@export var DASH_ACCELERATION: float = Global.ACCELERATION - 2
@export var DASH_DECELERATION: float = Global.DECELERATION - 5
var DASH_MAX_SPEED: float = Global.MAX_SPEED + 2  # Slightly above MAX_SPEED for extra burst

@export var momentum_deceleration: float = 0.6  # Lowered for smoother momentum control
@export var momentum_acceleration: float = 1.2  # Allows faster adaptation to direction changes
@export var speed_threshold: float = BASE_SPEED - 2

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	pass
	
func _update(delta: float) -> void:
	player_run(delta)
	initialize_runJump(delta)
	agent.move_and_slide()

# Smooth run (Mario-esque momentum)
func player_run(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)
	var velocity = agent.velocity 
	
	
	print(current_speed)
	if direction != Vector3.ZERO && can_sprint && can_move && agent.is_on_floor():
		sprint_timer += delta
		is_sprinting = true
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)

		# Smooth acceleration (Mario-esque)
		target_speed = MAX_SPEED
		ACCELERATION = DASH_ACCELERATION
		DECELERATION = DASH_DECELERATION

		# Gradual speed-up, like Mario
		current_speed = move_toward(current_speed, target_speed, ACCELERATION * delta)

		# Apply movement velocity
		agent.velocity.x = direction.x * current_speed
		agent.velocity.z = direction.z * current_speed

	else:
		is_sprinting = false
		target_speed = BASE_SPEED
		ACCELERATION = BASE_ACCELERATION
		DECELERATION = BASE_DECELERATION
		
		# Smooth deceleration when not sprinting
		current_speed = move_toward(current_speed, target_speed, DECELERATION * delta)

		# Apply deceleration
		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)

		# Sliding effect when no input
		if direction == Vector3.ZERO:
			agent.velocity.x = move_toward(agent.velocity.x, 0, momentum_deceleration * delta)
			agent.velocity.z = move_toward(agent.velocity.z, 0, momentum_deceleration * delta)

	# Transition to idle state smoothly if no movement
	if agent.velocity.length() <= 0:
		agent.state_machine.dispatch("to_idle")

	if Input.is_action_just_released("move_sprint") && direction != Vector3.ZERO:
		agent.state_machine.dispatch("to_walk")

func initialize_runJump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
		agent.state_machine.dispatch("to_runJump")
	pass

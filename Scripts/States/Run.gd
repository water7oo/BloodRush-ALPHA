extends LimboState

@export var animation_player : AnimationPlayer
@export var animation : StringName
@onready var armature = $"../../RootNode/Armature"

var sprinting = Input.is_action_pressed("move_sprint")
var is_in_air: bool = false
var is_moving: bool = false
var can_sprint: bool = true
var can_move: bool = true
var is_sprinting: bool = false
var current_speed: float = 0.0
var sprint_timer: float = 0.0


@export var MAX_SPEED: float = 15.0
@export var BASE_SPEED: float = 6.0
var target_speed: float = BASE_SPEED
@onready var Stamina_bar = $"UI Cooldowns"

@export var ACCELERATION: float = 50.0 #the higher the value the faster the acceleration
@export var DECELERATION: float = 25.0 #the lower the value the slippier the stop
@export var BASE_ACCELERATION: float = 50
@export var BASE_DECELERATION: float = 25
@export var BASE_DASH_ACCELERATION: float = 45
@export var BASE_DASH_DECELERATION: float = 30
@export var DASH_ACCELERATION: float = 45
@export var DASH_DECELERATION: float = 30
var DASH_MAX_SPEED: float = BASE_SPEED * 3
@export var momentum_deceleration: float = 1
@export var momentum_acceleration: float = 1
@export var speed_threshold: float = BASE_SPEED - 3


@export var dash_duration: float = 0.04
@export var SECOND_DASH_ACCELERATION: float = 300
@export var SECOND_DASH_DECELERATION: float = 25
var INITIAL_DASH_ACCELERATION: float = ACCELERATION
var INITIAL_DASH_DECELERATION: float = DECELERATION
var INITIAL_MAX_SPEED: float = MAX_SPEED
var SECOND_MAX_SPEED: float = MAX_SPEED + 1.5
var is_second_sprint: bool = false

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	pass
	

func _update(delta: float) -> void:
	print(current_speed)
	player_run(delta)
	initialize_runJump(delta)
	agent.move_and_slide()
	
	
	
func player_run(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)
	var velocity = agent.velocity 
	
	if direction != Vector3.ZERO && can_sprint && can_move && agent.is_on_floor():
		sprint_timer += delta
		is_sprinting = true
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)


		# Increase target speed and acceleration
		target_speed = MAX_SPEED
		ACCELERATION = DASH_ACCELERATION
		DECELERATION = DASH_DECELERATION

		# Smoothly adjust the player's current speed
		current_speed = move_toward(current_speed, target_speed, ACCELERATION * delta)

		# Apply movement velocity
		agent.velocity.x = direction.x * current_speed
		agent.velocity.z = direction.z * current_speed

	else:
		# Stop sprinting when sprint key is released
		is_sprinting = false
		target_speed = BASE_SPEED
		ACCELERATION = BASE_ACCELERATION
		DECELERATION = BASE_DECELERATION
		sprint_timer = 0.0

	if Input.is_action_just_released("move_sprint") ||  direction == Vector3.ZERO:
		agent.state_machine.dispatch("to_walk")


	if agent.velocity.length() <= 0:
		agent.state_machine.dispatch("to_idle")
		

func initialize_runJump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
		agent.state_machine.dispatch("to_runJump")
	pass

extends LimboState

@onready var armature = $RootNode
@onready var state_machine: LimboHSM = $LimboHSM

@export var BASE_SPEED = 6.0
@export var MAX_SPEED = 11.0
@export var ACCELERATION = 10.0 #the higher the value the faster the acceleration
@export var DECELERATION = 5.0 #the lower the value the slippier the stop
@export var BASE_DECELERATION = 10.0
@export var momentum_deceleration = 10.0
@export var armature_rot_speed = 0.1
@export var armature_default_rot_speed = 0.07


@export var JUMP_VELOCITY = 10.0
@export var CUSTOM_GRAVITY = 30.0
@export var air_timer = 0.0
@export var jump_timer = 0.0
@export var jump_counter = 0
@export var can_jump = true
var last_ground_position = Vector3.ZERO

var current_speed = 0.0
var is_moving = false
var target_speed = MAX_SPEED
var velocity = Vector3.ZERO

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())

func _update(delta: float) -> void:
	player_movement(delta)
	player_jump(delta)
	agent.move_and_slide()

func player_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Handle movement if there's input
	if direction != Vector3.ZERO:
		print(current_speed)
		is_moving = true
		# Update speed and direction based on movement input
		if velocity.dot(direction) < 0:
			# If the velocity is in the opposite direction, apply deceleration
			current_speed = move_toward(current_speed, 0, momentum_deceleration * delta)
		if current_speed < target_speed:
			current_speed = move_toward(current_speed, target_speed, ACCELERATION * delta)
		else:
			current_speed = move_toward(current_speed, target_speed, DECELERATION * delta)

		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		#agent.rotation.y = lerp_angle(agent.rotation.y, atan2(-velocity.x, -velocity.z), armature_rot_speed)

	else:
		# No movement input, slow down and transition to idle
		is_moving = false
		current_speed = 0
		agent.state_machine.dispatch("to_idle")
		velocity.x = move_toward(velocity.x, 0, BASE_DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, BASE_DECELERATION * delta)

	# Apply movement to the character
	agent.velocity = velocity


func player_jump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
		agent.state_machine.dispatch("to_jump")
		#agent.velocity.y = JUMP_VELOCITY

extends LimboState

@onready var armature = $"../../RootNode/Armature"

var is_dodging: bool = false
var can_dodge: bool = true
var dodge_cooldown_timer: float = 0.0
var spinDodge_timer_cooldown: float = 0.0
var last_ground_position = Vector3.ZERO

@export var BASE_SPEED: float = 6.0
@export var DODGE_SPEED: float = 20.0
@export var ACCELERATION: float = 50.0
@export var DECELERATION: float = 25.0
@export var DODGE_ACCELERATION: float = 100.0
@export var DODGE_DECELERATION: float = 50.0
@export var DODGE_LERP_VAL: float = 3
@export var BASE_DECELERATION: float = 25.0

@export var dodge_cooldown: float = 0.5
@export var spinDodge_reset: float = 0.3

var dodge_direction = Vector3.ZERO

func _enter() -> void:
	print("Entering Burst State")
	is_dodging = true
	can_dodge = false
	last_ground_position = agent.global_transform.origin
	# Get movement input for dodge direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	dodge_direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	dodge_direction = dodge_direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)
	
	# If no input, dodge forward
	if dodge_direction == Vector3.ZERO:
		dodge_direction = -agent.transform.basis.z

	# Apply Dodge Velocity
	agent.velocity = dodge_direction * DODGE_SPEED
	
	ACCELERATION = DODGE_ACCELERATION
	DECELERATION = DODGE_DECELERATION
	dodge_cooldown_timer = dodge_cooldown  
	spinDodge_timer_cooldown = spinDodge_reset
	
	AirWaveEffect()
	GroundSparkEffect()

func _update(delta: float) -> void:
	player_burst(delta)
	agent.move_and_slide()

func player_burst(delta: float) -> void:
	dodge_cooldown_timer -= delta
	spinDodge_timer_cooldown -= delta

	# Gradually slow down the dodge
	agent.velocity = agent.velocity.lerp(Vector3.ZERO, DODGE_LERP_VAL * delta)

	# End dodge and transition based on input
	if dodge_cooldown_timer <= 0:
		if Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
		else:
			agent.state_machine.dispatch("to_idle")

func _exit() -> void:
	print("Exiting Burst State")

func AirWaveEffect():
	print("Air wave effect triggered")

func GroundSparkEffect():
	print("Ground spark effect triggered")

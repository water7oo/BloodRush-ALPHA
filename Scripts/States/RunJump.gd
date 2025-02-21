extends LimboState

@onready var armature = $"../../RootNode/Armature"
@onready var state_machine: LimboHSM = $LimboHSM

@export var JUMP_VELOCITY: float = 20.0
@export var BASE_SPEED: float = 6.0
@export var air_timer: float = 0.0
@export var jump_timer: float = 0.0
@export var jump_counter: int = 0
@export var can_jump: bool = true
var last_ground_position = Vector3.ZERO

@export var MAX_SPEED: float = 11.0
@export var ACCELERATION: float = 5.0 #the higher the value the faster the acceleration
@export var DECELERATION: float = 1.0 #the lower the value the slippier the stop
@export var BASE_DECELERATION: float = 1.0
@export var momentum_deceleration: float = 1.0


var current_speed: float = 0.0
var is_moving: bool = false
var target_speed: float = MAX_SPEED
var velocity = Vector3.ZERO

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	agent.velocity.y = JUMP_VELOCITY
	# Reset timers and jump counter
	air_timer = 0.0
	jump_timer = 0.0
	jump_counter = 0

func _update(delta: float) -> void:
	player_runjump(delta)
	agent.move_and_slide()


func player_runjump(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	if Input.is_action_pressed("move_jump") and can_jump:
		jump_timer += delta
		air_timer += delta
		if jump_timer <= 0.4:  # Jump if held for a short duration
			agent.velocity.y = JUMP_VELOCITY  # Apply jump force
			can_jump = false
			jump_counter += 1

	
	
	if direction != Vector3.ZERO:
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-direction.x, -direction.z), Global.armature_rot_speed)

	if direction != Vector3.ZERO:
		agent.velocity.x = direction.x * BASE_SPEED
		agent.velocity.z = direction.z * BASE_SPEED
		#armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)
	
	

	if agent.is_on_floor():
		print("Landed!")
		jump_timer = 0.0
		air_timer = 0.0
		if air_timer >= 0.2:
			pass
		if input_dir != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
		else:
			agent.state_machine.dispatch("to_idle")

 

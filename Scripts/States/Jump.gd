extends LimboState

@onready var armature = $RootNode
@onready var state_machine: LimboHSM = $LimboHSM

@export var JUMP_VELOCITY = 10.0
@export var CUSTOM_GRAVITY = 30.0
@export var BASE_SPEED = 6.0
@export var air_timer = 0.0
@export var jump_timer = 0.0
@export var jump_counter = 0
@export var can_jump = true
var last_ground_position = Vector3.ZERO

func _enter() -> void:
	print("Entered Jump State")
	# Set initial jump velocity when entering the state
	agent.velocity.y = JUMP_VELOCITY
	# Reset timers and jump counter
	air_timer = 0.0
	jump_timer = 0.0
	jump_counter = 0

func _update(delta: float) -> void:
	
	player_jump(delta)
	# Ensure physics are applied and character moves
	agent.move_and_slide()


func player_jump(delta: float) -> void:

	# Get movement input (can move freely in the air)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		agent.velocity.x = direction.x * BASE_SPEED
		agent.velocity.z = direction.z * BASE_SPEED
		#agent.rotation.y = lerp_angle(agent.rotation.y, atan2(-agent.velocity.x, -agent.velocity.z), 0.07)

	# Handle Jump Input
	if Input.is_action_pressed("move_jump") and can_jump:
		jump_timer += delta
		air_timer += delta
		if jump_timer <= 0.4:  # Jump if held for a short duration
			agent.velocity.y = JUMP_VELOCITY  # Apply jump force
			can_jump = false
			jump_counter += 1

	# Handle the landing transition
	if agent.is_on_floor():
		print("Landed!")
		# Reset jump and air timers
		jump_timer = 0.0
		air_timer = 0.0
		# Play landing effect (optional)
		if air_timer >= 0.2:
			# Place for landing effect if needed (e.g., wave effect)
			# You can instantiate or play audio effects here
			pass
		# Transition to walk or idle based on movement
		if input_dir != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
		else:
			agent.state_machine.dispatch("to_idle")

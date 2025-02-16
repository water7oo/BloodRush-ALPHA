extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM

const JUMP_VELOCITY = 10.0
var CUSTOM_GRAVITY = 30.0  

var BASE_SPEED = 6.0  

func _enter() -> void:
	print("Entered Jump State")
	# Set initial jump velocity
	agent.velocity.y = JUMP_VELOCITY  

func _update(delta: float) -> void:
	# Apply gravity while in the air
	agent.velocity.y -= CUSTOM_GRAVITY * delta

	# Get input for movement (both on the ground and in the air)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		agent.velocity.x = direction.x * BASE_SPEED
		agent.velocity.z = direction.z * BASE_SPEED

	# Landing transition: Check if the player is on the floor
	if agent.is_on_floor():
		print("Landed!")
		
		# Transition to WalkState if moving, otherwise to IdleState
		if input_dir != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
		else:
			agent.state_machine.dispatch("to_idle")

	# Ensure physics are applied
	agent.move_and_slide()

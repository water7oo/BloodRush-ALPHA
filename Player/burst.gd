extends LimboState

@onready var armature = $"../../RootNode/Armature"
@export var Dodge1Sound: AudioStreamPlayer

@export var dodgeResource: Resource
var velocity = Vector3.ZERO

func _enter() -> void:
	if agent:
		velocity = agent.velocity
		
	Dodge1Sound.play()
	#animationTree.set("parameters/Ground_Blend2/blend_amount", 1)
	Global.is_dodging = true
	Global.can_dodge = false
	Global.last_ground_position = agent.global_transform.origin
	# Get movement input for dodge direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	dodgeResource.dodge_direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	dodgeResource.dodge_direction = dodgeResource.dodge_direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)
	
	# If no input, dodge forward
	if dodgeResource.dodge_direction == Vector3.ZERO:
		dodgeResource.dodge_direction = -agent.transform.basis.z

	# Apply Dodge Velocity
	agent.velocity = dodgeResource.dodge_direction * dodgeResource.DODGE_SPEED
	
	Global.ACCELERATION = dodgeResource.DODGE_ACCELERATION
	Global.DECELERATION = dodgeResource.DODGE_DECELERATION
	dodgeResource.dodge_cooldown_timer = dodgeResource.dodge_cooldown  
	dodgeResource.spinDodge_timer_cooldown = dodgeResource.spinDodge_reset
	
	AirWaveEffect()
	GroundSparkEffect()

func _update(delta: float) -> void:
	player_burst(delta)
	agent.move_and_slide()

func player_burst(delta: float) -> void:
	dodgeResource.dodge_cooldown_timer -= delta
	dodgeResource.spinDodge_timer_cooldown -= delta

	# Gradually slow down the dodge
	agent.velocity = agent.velocity.lerp(Vector3.ZERO, dodgeResource.DODGE_LERP_VAL * delta)

	# End dodge and transition based on input
	if dodgeResource.dodge_cooldown_timer <= 0:
		if Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
		else:
			agent.state_machine.dispatch("to_idle")

func _exit() -> void:
	#animationTree.set("parameters/Ground_Blend2/blend_amount", -1)
	print("Exiting Burst State")

func AirWaveEffect():
	print("Air wave effect triggered")

func GroundSparkEffect():
	print("Ground spark effect triggered")

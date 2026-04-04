extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM

var hitstun_timer: float = .3  # Time player is stunned before regaining control

var preserved_velocity: Vector3 = Vector3.ZERO
@export var playerResource: Resource


func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	#animationTree.set("parameters/Ground_Blend/blend_amount", 0)
	# Preserve momentum when entering idle state
	#playerResource.can_move = false
	preserved_velocity = agent.velocity

func _update(delta: float) -> void:
	initialize_idle(delta)
	initialize_walk(delta)
	#initialize_jump(delta)
	#initialize_crouch(delta)
	#initialize_attack(delta)
	agent.move_and_slide()

func initialize_idle(delta: float) -> void:
	await get_tree().create_timer(hitstun_timer).timeout
	playerResource.can_move = true
	agent.state_machine.dispatch("to_idle")


func initialize_walk(delta: float) -> void:
	await get_tree().create_timer(hitstun_timer).timeout
	playerResource.can_move = true
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0:
		# Player is moving, switch to walk state
		agent.velocity.x = direction.x * playerResource.BASE_SPEED
		agent.velocity.z = direction.z * playerResource.BASE_SPEED
		agent.state_machine.dispatch("to_walk")  
	
	
func initialize_jump(delta: float) -> void:
	await get_tree().create_timer(hitstun_timer).timeout
	playerResource.can_move = true
	if Input.is_action_just_pressed("move_jump"):
		agent.state_machine.dispatch("to_jump")
		
func initialize_crouch(delta: float) -> void:
	await get_tree().create_timer(hitstun_timer).timeout
	playerResource.can_move = true
	if Input.is_action_pressed("move_crouch"):
		agent.state_machine.dispatch("to_crouch")

func initialize_attack(delta: float) -> void:
	await get_tree().create_timer(hitstun_timer).timeout
	playerResource.can_move = true
	if Input.is_action_just_pressed("attack_light_1"):
		agent.state_machine.dispatch("to_attack")

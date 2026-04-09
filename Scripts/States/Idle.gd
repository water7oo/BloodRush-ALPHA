extends LimboState


@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM
@onready var armature = $"../../RootNode/Armature"


@export var idleResource: Resource

var preserved_velocity: Vector3 = Vector3.ZERO
var velocity = Vector3.ZERO

func _enter() -> void:
	if agent:
		velocity = agent.velocity
	print("Current State:", agent.state_machine.get_active_state())
	# Preserve momentum when entering idle state
	preserved_velocity = agent.velocity
	
	
	if animation_player:
		animation_player.play("Idle")

func _update(delta: float) -> void:
	player_idle(delta)
	initialize_jump(delta)
	initialize_crouch(delta)
	initialize_guard(delta)


func player_idle(delta: float) -> void:
	
	if Global.can_move:
		agent.move_and_slide()
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0:
		# Player is moving, switch to walk state
		agent.velocity.x = direction.x * Global.BASE_SPEED
		agent.velocity.z = direction.z * Global.BASE_SPEED
		agent.state_machine.dispatch("to_walk")  
	else:
		# Apply sliding effect by gradually reducing velocity
		agent.velocity.x = move_toward(agent.velocity.x, 0, Global.DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, Global.DECELERATION * delta)

		# Ensure the transition looks smooth
		Global.target_blend_amount = 0.0
		Global.current_blend_amount = lerp(Global.current_blend_amount, Global.target_blend_amount, Global.blend_lerp_speed * delta)
		#animationTree.set("parameters/Ground_Blend/blend_amount", -1)

func initialize_jump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump"):
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_jump")
		
func initialize_crouch(delta: float) -> void:
	if Input.is_action_pressed("move_crouch"):
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_crouch")

func initialize_guard(delta: float) -> void:
	if Input.is_action_just_pressed("defend_guard"):
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_guard")

	
func _process(delta: float) -> void:
	pass

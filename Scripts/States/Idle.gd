extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM

@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var BASE_SPEED: float = Global.BASE_SPEED - 5
@export var DECELERATION: float = Global.DECELERATION - 5 

var preserved_velocity: Vector3 = Vector3.ZERO

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	# Preserve momentum when entering idle state
	preserved_velocity = agent.velocity

func _update(delta: float) -> void:
	player_idle(delta)
	initialize_jump(delta)
	initialize_crouch(delta)
	handle_attack_input()

func player_idle(delta: float) -> void:
	
	if Global.can_move:
		agent.move_and_slide()
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0:
		# Player is moving, switch to walk state
		agent.velocity.x = direction.x * BASE_SPEED
		agent.velocity.z = direction.z * BASE_SPEED
		agent.state_machine.dispatch("to_walk")  
	else:
		# Apply sliding effect by gradually reducing velocity
		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)

		# Ensure the transition looks smooth
		Global.target_blend_amount = 0.0
		Global.current_blend_amount = lerp(Global.current_blend_amount, Global.target_blend_amount, Global.blend_lerp_speed * delta)
		animationTree.set("parameters/Ground_Blend/blend_amount", -1)

func initialize_jump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump"):
		agent.state_machine.dispatch("to_jump")
		
func initialize_crouch(delta: float) -> void:
	if Input.is_action_pressed("move_crouch"):
		agent.state_machine.dispatch("to_crouch")

func _process(delta: float) -> void:
	if Global.attack_cooldown_timer > 0:
		Global.attack_cooldown_timer -= delta
	if Global.attackMedium_cooldown_timer > 0:
		Global.attackMedium_cooldown_timer -= delta
	if Global.attackHeavy_cooldown_timer > 0:
		Global.attackHeavy_cooldown_timer -= delta
	if Global.attackUpper_cooldown_timer > 0:
		Global.attackUpper_cooldown_timer -= delta
	
func handle_attack_input() -> void:
	# Combo takes priority (just_pressed + pressed)
	if (Input.is_action_just_pressed("attack_medium_1") and Input.is_action_pressed("attack_heavy_1")) \
	or (Input.is_action_just_pressed("attack_heavy_1") and Input.is_action_pressed("attack_medium_1")):
		if Global.attackUpper_cooldown_timer <= 0:
			agent.state_machine.dispatch("to_attackUpper")
		return  # only trigger one attack per frame

	# Single attacks
	if Input.is_action_just_pressed("attack_light_1") and Global.attack_cooldown_timer <= 0:
		agent.state_machine.dispatch("to_attack")
	elif Input.is_action_just_pressed("attack_medium_1") and Global.attackMedium_cooldown_timer <= 0:
		agent.state_machine.dispatch("to_mediumAttack")
	elif Input.is_action_just_pressed("attack_heavy_1") and Global.attackHeavy_cooldown_timer <= 0:
		agent.state_machine.dispatch("to_heavyAttack")

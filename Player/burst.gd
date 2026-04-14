extends LimboState

@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@onready var armature = $"../../RootNode/Armature"
@export var Dodge1Sound: AudioStreamPlayer
@onready var dodgeDust = $"../../dodge_dust"
@export var dodgeResource: Resource
var velocity = Vector3.ZERO

func _enter() -> void:
	if agent:
		velocity = agent.velocity
		
		velocity.x = 0
		velocity.z = 0
	
	
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
	


func _update(delta: float) -> void:
	player_burst(delta)
	agent.move_and_slide()

func player_burst(delta: float) -> void:
	dodgeResource.dodge_cooldown_timer -= delta
	dodgeResource.spinDodge_timer_cooldown -= delta
	dodgeDust.emitting = true
	# Gradually slow down the dodge
	agent.velocity = agent.velocity.lerp(Vector3.ZERO, dodgeResource.DODGE_LERP_VAL * delta)
	if animation_player:
		animation_player.play("SLIDE")


	if dodgeResource.dodge_cooldown_timer <= 0:
		if Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
			dodgeDust.emitting = false
		else:
			agent.state_machine.dispatch("to_idle")
			dodgeDust.emitting = false

func _exit() -> void:
	dodgeDust.emitting = false
	pass

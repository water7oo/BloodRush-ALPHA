extends LimboState

@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@onready var armature = $"../../RootNode/Armature"
@export var Dodge1Sound: AudioStreamPlayer
@onready var dodgeDust = $"../../dodge_dust"
@export var dodgeResource: Resource
var velocity = Vector3.ZERO


const DustWaveEffect = preload("res://FX/dustEffect2.tscn")
var effectSpawned = false

func _enter() -> void:
	Global.squash_land($"../../RootNode/player2")
	if agent:
		velocity = agent.velocity
		
		velocity.x = 0
		velocity.z = 0
	
	
	DodgeSoundplay()
	effectSpawned = false
	Global.is_dodging = true
	Global.can_dodge = false
	Global.last_ground_position = agent.global_transform.origin
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
	

func DodgeSoundplay():
	if Dodge1Sound:
		Dodge1Sound.pitch_scale = randf_range(.5, .7)
		Dodge1Sound.play()


func BurstEffectWave():
	var is_on_floor = agent.is_on_floor()
	if agent.state_machine.get_active_state() == self:
		if is_on_floor && effectSpawned == false:
			var instanceBurstEffect = DustWaveEffect.instantiate()
			effectSpawned = true
			get_tree().root.add_child(instanceBurstEffect)
			
			var xform = instanceBurstEffect.global_transform
			
			xform.origin = agent.global_transform.origin

			xform = align_with_y(xform, agent.get_floor_normal())

			instanceBurstEffect.global_transform = xform

func align_with_y(xform, new_y):
	new_y = new_y.normalized()

	var forward = -xform.basis.z.normalized()
	var right = forward.cross(new_y).normalized()
	forward = new_y.cross(right).normalized()

	xform.basis = Basis(right, new_y, forward)
	return xform
	
	
func _update(delta: float) -> void:
	player_burst(delta)
	agent.move_and_slide()
	
	BurstEffectWave()

func player_burst(delta: float) -> void:
	dodgeResource.dodge_cooldown_timer -= delta
	dodgeResource.spinDodge_timer_cooldown -= delta
	dodgeDust.emitting = true
	# Gradually slow down the dodge
	agent.velocity = agent.velocity.lerp(Vector3.ZERO, dodgeResource.DODGE_LERP_VAL * delta)
	if animation_player:
		animation_player.play("player|SLIDE")


	if dodgeResource.dodge_cooldown_timer <= 0:
		if Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
			agent.state_machine.dispatch("to_walk")
			dodgeDust.emitting = false
		else:
			agent.state_machine.dispatch("to_idle")
			dodgeDust.emitting = false

	if agent.is_on_floor():
		var target_up = agent.get_floor_normal().normalized()
		var current_up = agent.global_transform.basis.y.normalized()

		var dot = clamp(current_up.dot(target_up), -1.0, 1.0)

		# Only rotate if there's a meaningful difference
		if dot < 0.999 && target_up.y > 0.5:
			var axis = current_up.cross(target_up).normalized()
			var angle = acos(dot)

			# Smooth rotation (frame-rate independent)
			var t = 1.0 - exp(-10.0 * delta)
			agent.rotate(axis, angle * t)
			
func _exit() -> void:
	dodgeDust.emitting = false
	pass

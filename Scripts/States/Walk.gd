extends LimboState


@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
@onready var armature = $"../../RootNode"
@onready var state_machine: LimboHSM = $LimboHSM
@export var playerAudio: Node
@onready var walkingSound = playerAudio.get_node("walkingSoundGrass")


@onready var moveDust = $"../../move_dust"


@export var walkResource: Resource

var velocity = Vector3.ZERO

func _enter() -> void:
	Global.stretch_forward($"../../RootNode/player2")
	if agent:
		velocity = agent.velocity
		
		velocity.x = 0
		velocity.z = 0
	


func _update(delta: float) -> void:
	player_movement(delta)
	initialize_jump(delta)
	initialize_run(delta)
	initialize_burst(delta)
	initialize_crouch(delta)
	initialize_guard(delta)
	playWalkingSound()
	
	if animation_player && Global.is_moving:
		animation_player.speed_scale = velocity.length() * .2
		animation_player.play("player|walking")
	agent.move_and_slide()


func player_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	if direction != Vector3.ZERO and Global.can_move:
		Global.is_moving = true
		moveDust.emitting = true

		# Smooth rotation (FIXED)
		armature.rotation.y = lerp_angle(
			armature.rotation.y,
			atan2(-direction.x, -direction.z),
			Global.armature_rot_speed
		)

		# Frame-rate independent smoothing
		var t = 1.0 - exp(-walkResource.inertia_blend * delta)
		velocity = velocity.lerp(direction * Global.BASE_SPEED, t)
		
		var target_rotation = atan2(direction.x, direction.z)

		if velocity.length() > 0.1:
			var angle_diff = velocity.normalized().dot(direction)
			if angle_diff < 0:
				Global.stretch_forward($"../../RootNode/player2")
				velocity *= 0.8
		
	else:
		Global.is_moving = false
		moveDust.emitting = false

		velocity.x = move_toward(velocity.x, 0, Global.BASE_DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, Global.BASE_DECELERATION * delta)
		animation_player.stop()
		agent.state_machine.dispatch("to_idle")

	velocity.y = agent.velocity.y
	agent.velocity = velocity
	
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
		
func align_with_y(xform, new_y):
	new_y = new_y.normalized()

	var forward = -xform.basis.z.normalized()
	var right = forward.cross(new_y).normalized()
	forward = new_y.cross(right).normalized()

	xform.basis = Basis(right, new_y, forward)
	return xform
	
var left_foot_down = false
var right_foot_down = false

func playWalkingSound():
	var left_ray = $player/Skeleton3D/BoneAttachment3D/leftFootRaycast
	var right_ray = $player/Skeleton3D/BoneAttachment3D2/rightFootRaycast

	if left_ray && left_ray.is_colliding():
		print("left foot collide")
		if not left_foot_down: 
			walkingSound.pitch_scale = randf_range(0.9, 1.1)
			walkingSound.play()
			left_foot_down = true
	else:
		left_foot_down = false 

	if right_ray && right_ray.is_colliding():
		if not right_foot_down:
			walkingSound.pitch_scale = randf_range(0.9, 1.1)
			walkingSound.play()
			right_foot_down = true
	else:
		right_foot_down = false
		
func _unhandled_input(event):
	if event is InputEventMouseMotion:

		var rotation_x = Global.spring_arm_pivot.rotation.x - event.relative.y * Global.mouse_sensitivity
		var rotation_y = Global.spring_arm_pivot.rotation.y - event.relative.x * Global.mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))

		Global.spring_arm_pivot.rotation.x = rotation_x
		Global.spring_arm_pivot.rotation.y = rotation_y

func initialize_jump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_jump")
		moveDust.emitting = false

func initialize_run(delta: float)-> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)
	
	if Input.is_action_pressed("move_sprint") && direction != Vector3.ZERO:
		animation_player.speed_scale = 1.0
		moveDust.emitting = false
		agent.state_machine.dispatch("to_run")

func initialize_burst(delta: float) -> void:
	if Input.is_action_just_pressed("move_dodge"):
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_burst")
		
		
func initialize_crouch(delta: float) -> void:
	if Input.is_action_pressed("move_crouch"):
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_crouch")
		
func initialize_guard(delta: float) -> void:
	if Input.is_action_just_pressed("defend_guard"):
		animation_player.speed_scale = 1.0
		agent.state_machine.dispatch("to_guard")

extends LimboState

@onready var armature = $"../../RootNode"
@onready var state_machine: LimboHSM = $LimboHSM

@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree =  playerCharScene.find_child("AnimationTree", true)

@export var JUMP_VELOCITY: float = 12.0  # Increased for better jump height
const CUSTOM_GRAVITY: float = 30.0  # Keeps the character from feeling too floaty
@export var air_timer: float = 0.0
@export var jump_timer: float = 0.0
@export var jump_counter: float = 0
@export var can_jump: bool = true
var last_ground_position = Vector3.ZERO

var current_speed: float = 0.0
var is_moving: bool = false
var target_speed: float = Global.MAX_SPEED
var velocity = Vector3.ZERO

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())

func _update(delta: float) -> void:
	player_movement(delta)
	initialize_jump(delta)
	initialize_run(delta)
	initialize_burst(delta)
	initialize_crouch(delta)
	initialize_attack(delta)
	#print(velocity.length())
	agent.move_and_slide()

func player_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

	if direction != Vector3.ZERO:
		is_moving = true
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)
		Global.target_blend_amount = 0.0
		Global.current_blend_amount = lerp(Global.current_blend_amount, Global.target_blend_amount, Global.blend_lerp_speed * delta)
		animationTree.set("parameters/Ground_Blend/blend_amount", 1)

		var target_rotation = atan2(direction.x, direction.z)

		# **Calculate the angle between current velocity and new direction**
		var angle_diff = velocity.normalized().dot(direction)
		
		# If the dot product is negative (angle > 90°), apply stronger deceleration
		if angle_diff < 0:
			current_speed = move_toward(current_speed, 0, Global.momentum_deceleration * delta)

		# Blend movement instead of instantly switching direction
		velocity = velocity.lerp(direction * target_speed, Global.inertia_blend * delta)

	else:
		is_moving = false
		current_speed = 0
		velocity.x = move_toward(velocity.x, 0, Global.BASE_DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, Global.BASE_DECELERATION * delta)

	velocity.y = agent.velocity.y  

	if velocity.length() <= 0:
		agent.state_machine.dispatch("to_idle")
	elif Input.is_action_pressed("move_crouch"):
		agent.state_machine.dispatch("to_crouch")

	agent.velocity = velocity


func _unhandled_input(event):
	if event is InputEventMouseMotion:

		var rotation_x = Global.spring_arm_pivot.rotation.x - event.relative.y * Global.mouse_sensitivity
		var rotation_y = Global.spring_arm_pivot.rotation.y - event.relative.x * Global.mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))

		Global.spring_arm_pivot.rotation.x = rotation_x
		Global.spring_arm_pivot.rotation.y = rotation_y

func initialize_jump(delta: float) -> void:
	if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
		agent.state_machine.dispatch("to_jump")
		#agent.velocity.y = Global.JUMP_VELOCITY

func initialize_run(delta: float)-> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)
	
	if Input.is_action_pressed("move_sprint") && direction != Vector3.ZERO:
		agent.state_machine.dispatch("to_run")

func initialize_burst(delta: float) -> void:
	if Input.is_action_just_pressed("move_dodge"):
		agent.state_machine.dispatch("to_burst")
		
		
func initialize_crouch(delta: float) -> void:
	if Input.is_action_pressed("move_crouch"):
		agent.state_machine.dispatch("to_crouch")
		

func initialize_attack(delta: float) -> void:
	
	#pressing attack unsheathes katana and player is in attackmode
	if Input.is_action_just_pressed("attack_light_1"):
		agent.state_machine.dispatch("to_attack")

extends Node3D

@onready var gameJuice = get_node("/root/GameJuice")
@onready var enemy = get_node("/root/EnemyHealthManager")
@export var target: NodePath
@export var speed := 1.0
@export var enabled: bool
@export var spring_arm_pivot: Node3D
@export var mouse_sensitivity = 0.005
@export var joystick_sensitivity = 0.005 
@onready var camera = $SpringArmPivot/SpringArm3D/Margin/Camera3D
var cam_lerp_speed = .005


@export var period = .04
@export var magnitude = 0.08

var y_cam_rot_dist = -80
var x_cam_rot_dist = 1

var original_global_transform: Transform3D
var target_node: Node3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_node = get_node(target) as Node3D
	
	#original_global_transform = target_node.global_transform

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	#if event is InputEventMouseMotion:
		#var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		#var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity
		#
		#
		#rotation_x = clamp(rotation_x, deg_to_rad(y_cam_rot_dist), deg_to_rad(x_cam_rot_dist))
		##rotation_x = clamp(rotation_x, deg_to_rad(-1), deg_to_rad(0))
		#
		#spring_arm_pivot.rotation.x = rotation_x
		#spring_arm_pivot.rotation.y = rotation_y
		
		
		#if rotation_x <= -1:
			#camera.set_fov(40)
		#elif rotation_x >= 0:
			#camera.set_fov(30)
		#else:
			#camera.set_fov(40)
		
	#if Input.get_action_strength("cam_down"):
		#spring_arm_pivot.rotation.x -= joystick_sensitivity
	#if Input.get_action_strength("cam_up"):
		#spring_arm_pivot.rotation.x += joystick_sensitivity 
	#if Input.get_action_strength("cam_right"):
		#spring_arm_pivot.rotation.y -= joystick_sensitivity 
	#if Input.get_action_strength("cam_left"):
		#spring_arm_pivot.rotation.y += joystick_sensitivity 

func _physics_process(delta):
	followTarget(delta)

func _process(delta: float) -> void:
	_unhandled_input(delta)
	playShake()
	if Input.is_action_just_pressed("shake_test"):
		applyShake(.04,0.08)
		
	
	
func followTarget(delta):
	if not enabled or not target_node:
		return

	var new_global_transform = global_transform.interpolate_with(target_node.global_transform, speed * delta)
	global_transform.origin = new_global_transform.origin
	

func applyShake(period, magnitude):
	var initial_transform = self.transform
	var elapsed_time = 0.0
	
	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)

		self.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame

	self.transform = initial_transform

func playShake():
	if EnemyHealthManager.taking_damage == true:
		applyShake(.02,0.08)
		pass
	if PlayerHealthManager.taking_damage == true:
		applyShake(.02,0.08)
		pass

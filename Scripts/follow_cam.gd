extends Node3D

@onready var gameJuice = get_node("/root/GameJuice")
@onready var enemy = get_node("/root/EnemyHealthManager")
@export var target: NodePath
@export var speed := 1.0
@export var enabled: bool
@export var spring_arm_pivot: Node3D
@export var mouse_sensitivity: float = 0.005
@export var joystick_sensitivity: float = 0.005 
@onready var camera = $SpringArmPivot/SpringArm3D/Margin/Camera3D
var cam_lerp_speed: float = .005

var is_mouse_visible: bool = true

@export var period: float = .04
@export var magnitude: float = 0.08

var y_cam_rot_dist: float = -80
var x_cam_rot_dist: float = 10

var original_global_transform: Transform3D
var target_node: Node3D


@export var enemyStats: Resource
var isLookingAtTarget = false
func _ready():
	Global.spring_arm_pivot = $SpringArmPivot
	Global.spring_arm = $SpringArmPivot/SpringArm3D
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_node = get_node(target) as Node3D
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	#original_global_transform = target_node.global_transform

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		print("Quit Game")
		get_tree().quit()
		
	if Input.is_action_just_pressed("mouse_show"):
		# Toggle the visibility of the mouse
		if is_mouse_visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		# Update the state
		is_mouse_visible = !is_mouse_visible
		
	if event is InputEventMouseMotion && Global.spring_arm_pivot && Global.game_paused == false:
			var rotation_x = Global.spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
			var rotation_y = Global.spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity
			
			
			rotation_x = clamp(rotation_x, deg_to_rad(y_cam_rot_dist), deg_to_rad(x_cam_rot_dist))
			
			Global.spring_arm_pivot.rotation.x = rotation_x
			Global.spring_arm_pivot.rotation.y = rotation_y

func _physics_process(delta):
	var real_delta = delta / Engine.time_scale if Engine.time_scale > 0 else 0.016
	followTarget(real_delta)

func _process(delta: float) -> void:
	playShake()
	
	#if Global.isHit:
		#applyShake(.04,0.08)
	if Input.is_action_just_pressed("shake_test"):
		applyShake(.04,0.08)
		
	
	
func followTarget(delta):
	if not enabled or not target_node:
		return

	var pivot = Global.spring_arm_pivot
	var player_pos = target_node.global_transform.origin

	if Global.isHit and Global.combo_hits.size() > 0:
		var last_hit = Global.combo_hits[Global.combo_hits.size() - 1]
		var enemy = last_hit["enemy"]

		if enemy:
			var enemy_pos = enemy.global_transform.origin
			
			var midpoint = enemy_pos.lerp(player_pos, 0.4)

			var distance = player_pos.distance_to(enemy_pos)
			distance = clamp(distance, 2.0, 20.0)

			var desired_position = midpoint

			# Move pivot (NOT camera)
			pivot.global_transform.origin = pivot.global_transform.origin.lerp(desired_position, speed * delta)

			# Rotate pivot only on Y
			var direction = pivot.global_transform.origin - midpoint
			direction.y = 0

			#if direction.length() > 0.01:
				#var target_yaw = atan2(direction.x, direction.z)
				#pivot.rotation.y = lerp_angle(pivot.rotation.y, target_yaw, speed * delta)
#
			## Lock tilt
			#pivot.rotation.x = deg_to_rad(-10)

			return

	# Normal follow
	pivot.global_transform.origin = pivot.global_transform.origin.lerp(player_pos, speed * delta)

	

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
	if enemyStats:
		if enemyStats.taking_damage == true:
			applyShake(.02,0.08)
			pass
		if enemyStats.taking_damage == true:
			applyShake(.02,0.08)
			pass


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.name == "enemyBox":
		isLookingAtTarget = true
		#var averagePosX = (position.x + area.position.x)/2
		#var averagePosY = (position.y + area.position.y)/2
		#spring_arm_pivot.rotation.x = move_toward(spring_arm_pivot.rotation.x, averagePosX, delta)
		#spring_arm_pivot.rotation.y = move_toward(spring_arm_pivot.rotation.y, averagePosY, delta)
		#
		$"Current Target".text = ("current target: " + str(area))
		$Reticle.text = "༝"


func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.name == "enemyBox":
		isLookingAtTarget = false
		$Reticle.text = "⊙"
		$"Current Target".text = ("current target: none")
	pass # Replace with function body.

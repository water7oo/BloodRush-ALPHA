#class_name Player
extends CharacterBody3D

@onready var combatScript = get_node("/root/Combat")
@onready var health = combatScript.health
@onready var gameJuice = get_node("/root/GameJuice")
@onready var followcam = get_node("/root/FollowCam")

@onready var fps_label = $FPS_LABEL
var FPS = Engine.get_frames_per_second()

var last_ground_position = Vector3()
var last_ground_rotation = Basis()

var waveEffect = preload("res://FX/DustWave2.tscn")
var AirWave = preload("res://FX/AirDustWave2.tscn")
var GroundSpark = preload("res://FX/GroundSPark.tscn")

@onready var AirWavePos = $AirWavePos

@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")
@onready var speedDebug = $CurrentSpeedDebug
@onready var spinDodgeDebug = $SpinDodgeDebug


var camera = preload("res://Player/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
@onready var dodge_node_timer = $Dodge_Cooldown
@onready var dodge_cooldown_label = $Dodge_Cooldown_Label
#@onready var blend_space = Animationtree.get('parameters/Combat/Ground_Blend/blend_position')
#@onready var blend_space2 = Animationtree.get('parameters/Combat/MoveStrafe/blend_position')
@onready var Stamina_bar = $"UI Cooldowns"
@onready var health_bar = $player_health
@onready var controllerDebug = $ControllerDebug
@onready var playerHealthLabel = $player_health_label


var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 10.0  # Adjust the speed of blending


@onready var armature = $"3rdPassAnimations"
@onready var Animationtree
@onready var jump_wave = get_tree().get_nodes_in_group("Jump_wave")
@onready var dust_trail = get_tree().get_nodes_in_group("dust_trail")
@onready var jump_dust = get_tree().get_nodes_in_group("jump_dust")
@onready var move_dust = get_tree().get_nodes_in_group("move_dust")
@onready var burst_dust = get_tree().get_nodes_in_group("burst_dust")
@onready var wall_wave = get_tree().get_nodes_in_group("wall_wave")
@onready var punch_dust = get_tree().get_nodes_in_group("punch_dust")
@onready var InputBuffer = get_node("/root/InputBuffer")

#Basic Movement
@export var mouse_sensitivity = 0.005
@export var joystick_sensitivity = 0.005
@export var BASE_SPEED = 6
@export var MAX_SPEED = 15
@export var  STAMINA_DEPLETED_SPEED = 1
var SPEED = BASE_SPEED
var target_speed = BASE_SPEED
var current_speed = 0.0

var is_moving = false

@export var JUMP_VELOCITY = 9
@export var SHORT_JUMP = 4
@export var LONG_JUMP = 8
@export var RUNJUMP_MULTIPLIER = .9
var jump_timer = 0.0
var jump_tap_timer = 0.1
var jump_height = 128
var jump_counter = 1

#Acceleration and Speed
var can_move = true
var can_process_input = true
@export var armature_default_rot_speed = 0.09
var armature_rot_speed 
@export var armature_turn = 0.07
@export var ACCELERATION = 50.0 #the higher the value the faster the acceleration
@export var DECELERATION = 25.0 #the lower the value the slippier the stop
@export var BASE_ACCELERATION = 50
@export var BASE_DECELERATION = 25
@export var BASE_DASH_ACCELERATION = 45
@export var BASE_DASH_DECELERATION = 30
@export var DASH_ACCELERATION = 45
@export var DASH_DECELERATION = 30
var DASH_MAX_SPEED = BASE_SPEED * 3
@export var momentum_deceleration = 1
@export var momentum_acceleration = 1
@export var speed_threshold = BASE_SPEED - 3

@export var stamina = 100
@export var sprinting_deplete_rate = 10
@export var sprinting_refill_rate = 30
@export var sprinting_refill_rate_zero = 20
var is_dodging = false
var can_dodge = true
var can_sprint = true
var dash_timer = 0.0
var dodge_cooldown_timer = 0.0
@export var DODGE_SPEED = 20
@export var SPIN_DODGE_SPEED = DODGE_SPEED * 1.05

var spinDodge_timer_cooldown = 0.0
@export var spinDodge_reset = .8
var air_spin = false

@export var dash_duration = 0.04
@export var SECOND_DASH_ACCELERATION = 300
@export var SECOND_DASH_DECELERATION = 25
var INITIAL_DASH_ACCELERATION = ACCELERATION
var INITIAL_DASH_DECELERATION = DECELERATION
var INITIAL_MAX_SPEED = MAX_SPEED
var SECOND_MAX_SPEED = MAX_SPEED + 1.5
var is_second_sprint = false

@export var DODGE_ACCELERATION = 100
@export var DODGE_DECELERATION = 5


var WALL_JUMP_VELOCITY_MULTIPLIER = 2.5

var air_time = 0.0
var air_timer = 0.0
var sprint_timer = 0.0


var landing_animation_threshold = 1.0
var WALL_STAY_DURATION = 0.5  # Adjust this value to control how long the player stays on the wall after a jump
var wall_stay_timer = 0.0
var ORIGINAL_JUMP_VEL = JUMP_VELOCITY
var RUN_JUMP_VELOCITY = JUMP_VELOCITY * RUNJUMP_MULTIPLIER
var LERP_VAL = 0.2
var DODGE_LERP_VAL = 1
var wall_jump_position = Vector3.ZERO

var custom_gravity = 30.0 #The lower the value the floatier
var sprinting = false
var dodging = false
var dodge_timer = 0.0
@export var dodge_cooldown = 0.0
var is_in_air = false
var can_jump = true

var is_sprinting = false
var light_attack1 = false
var light_attack2 = false
var medium_attack1 = false
var landing_position = Vector3.ZERO
var can_wall_jump = true
var has_wall_jumped = false
var attack_proccessing = false
var cancel_timer = 0.0
var cancel_timer_reset = 0.3


var fall = Vector3()
var wall_normal
var direction = Vector3()

#Attacking

@onready var playerEditScene: PackedScene = preload("res://Animations/PlayerEdit.tscn")
var playerEditInstance: Node
var Attack_Box: Node


@onready var Hurt_Box = $HurtBox
var attacklight_1 = Input.is_action_just_pressed("attack_light_1")
var attacklight1_timer = 0.0
var attack_cooldown = 0.0
var attacklight2_timer = 0.0
var attack_signal = false
var can_attack = true


# Hitbox variables
var hitbox = null
var hitbox_active = false
var hitbox_duration = 0.2  # Adjust the duration of the hitbox here
var is_attacking = false
var jumping = Input.is_action_pressed("move_jump")


var attack_power = 1.0
var current_ground_spark = null

var is_controller = false
var is_key = false

func _ready():
# Instancing player into scene and adds the child to the current scene
	playerEditInstance = playerEditScene.instantiate()
	add_child(playerEditInstance) 
	
# Establishes the attack box
	Attack_Box = playerEditInstance.get_node("Armature/Skeleton3D/BoneAttachment3D/Attack_Box")
	armature = playerEditInstance.get_node("Armature")
	Animationtree = playerEditInstance.get_node("AnimationTree")
	armature_rot_speed = armature_default_rot_speed
	controllerDebug.text = "Keyboard Connected"
	playerHealthLabel.value = playerHealthMan.max_health
	spinDodgeDebug.value = spinDodge_timer_cooldown
	
	var animation_player = playerEditInstance.get_node("$AnimationPlayer")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _on_custom_animation_finished(anim_name):
	print("Custom signal received for animation:", anim_name)

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:

		var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))

		spring_arm_pivot.rotation.x = rotation_x
		spring_arm_pivot.rotation.y = rotation_y
		
	if Input.is_action_pressed("cam_down"):
		spring_arm_pivot.rotation.x -= joystick_sensitivity
	if Input.is_action_pressed("cam_up"):
		spring_arm_pivot.rotation.x += joystick_sensitivity
	if Input.is_action_pressed("cam_right"):
		spring_arm_pivot.rotation.y -= joystick_sensitivity
	if Input.is_action_pressed("cam_left"):
		spring_arm_pivot.rotation.y += joystick_sensitivity
		

func controller_switch(delta):
	if is_controller:
		_proccess_movement(delta)
	elif is_key:
		_proccess_movement(delta)

func _input(event):
	# Check for controller input
	if event is InputEventJoypadButton:
		is_controller = true
		is_key = false
		controllerDebug.text = "Controller Connected"
	
	# Check for keyboard or mouse input
	elif event is InputEventKey || event is InputEventMouseMotion:
		is_controller = false
		is_key = true
		controllerDebug.text = "Keyboard Connected"

func _proccess_controller_movement(delta):
	if not can_process_input:
		return  # Do not process any movement if input is disabled

	# Get keyboard input
	var input_dir = Input.get_vector("move_right", "move_left", "move_back", "move_forward")

	# Get joystick input from the left stick (assuming the first controller)
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)

	# Convert joystick input to a Vector2
	var joy_dir = Vector2(joy_x, joy_y)  # Invert Y-axis

	# Combine joystick input with keyboard input
	input_dir += joy_dir

	# Normalize the direction vector
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)

	if direction and can_move:
		is_moving = true
		if current_speed < target_speed:
			current_speed = move_toward(current_speed, target_speed, ACCELERATION * delta)
		else:
			current_speed = move_toward(current_speed, target_speed, DECELERATION * delta)

		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		if direction and not is_sprinting and is_on_floor():
			target_blend_amount = 0.0
			current_blend_amount = lerp(current_blend_amount, target_blend_amount, blend_lerp_speed * delta)
			Animationtree.set("parameters/Ground_Blend/blend_amount", 0)
		else:
			target_blend_amount = -1.0

		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), 0.07)
	elif not direction and is_on_floor():
		is_moving = false
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)
		current_speed = sqrt(velocity.x * velocity.x + velocity.z * velocity.z)
		Animationtree.set("parameters/Ground_Blend/blend_amount", -1)
		Animationtree.set("parameters/Ground_Blend2/blend_amount", -1)
		Animationtree.set("parameters/Jump_Blend/blend_amount", -1)
		Animationtree.set("parameters/Blend3/blend_amount", -1)

	particle_emitt(input_dir)

func _proccess_movement(delta):
	if not can_process_input:
		return

	var input_dir = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)

	var speed_threshold = 5.0
	var max_speed_threshold = MAX_SPEED  # Define your speed threshold here

	if direction != Vector3.ZERO && can_move:
		is_moving = true
		if velocity.dot(direction) < 0:
			if current_speed >= 11:
				Animationtree.set("parameters/Ground_Blend2/blend_amount", 0)
				print("skid")
			else:
				Animationtree.set("parameters/Ground_Blend2/blend_amount", -1)
			if current_speed > speed_threshold:
				print("player is changing directions")
					
				current_speed = move_toward(current_speed, 0, momentum_deceleration * delta)  
				if current_speed >= 0:
					armature_rot_speed = armature_turn
					current_speed = 0
				if current_speed == 0 && direction:
					move_toward(ACCELERATION, BASE_ACCELERATION, delta)
					move_toward(DECELERATION, BASE_ACCELERATION, delta)
					await get_tree().create_timer(.2).timeout
					armature_rot_speed = armature_default_rot_speed
				
				if sprinting && current_speed >= 11:
					DASH_DECELERATION = momentum_deceleration
					DASH_ACCELERATION = momentum_acceleration
				else:
					DASH_DECELERATION = BASE_DASH_DECELERATION
					DASH_ACCELERATION = BASE_DASH_ACCELERATION
					
		if current_speed < target_speed:
			current_speed = move_toward(current_speed, target_speed, ACCELERATION * delta)
		else:
			current_speed = move_toward(current_speed, target_speed, DECELERATION * delta)

		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		if direction && !is_sprinting && is_on_floor():
			Animationtree.set("parameters/Ground_Blend/blend_amount", 0)
		#else:
			#Animationtree.set("parameters/Ground_Blend/blend_amount", -1)
			#print("mario")

		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), armature_rot_speed)

	elif direction == Vector3.ZERO && is_on_floor():
		is_moving = false
		velocity.x = move_toward(velocity.x, 0, BASE_DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, BASE_DECELERATION * delta)
		current_speed = sqrt(velocity.x * velocity.x + velocity.z * velocity.z)
		Animationtree.set("parameters/Ground_Blend/blend_amount", -1)
		Animationtree.set("parameters/Ground_Blend2/blend_amount", -1)
		Animationtree.set("parameters/Jump_Blend/blend_amount", -1)
		Animationtree.set("parameters/Blend3/blend_amount", -1)

	particle_emitt(input_dir)

	if !is_on_floor():
		armature_rot_speed = armature_default_rot_speed
		pass

func disable_inputs():
	can_process_input = false
	#print("cannot move")

func enable_inputs():
	can_process_input = true
	#print("can move")
	
func particle_emitt(input_dir):
	for node in dust_trail:
			var particle_emitter = node.get_node("Dust")
			if particle_emitter && input_dir != Vector2.ZERO && is_on_floor():
				var should_emit_particles = is_sprinting && !is_in_air && current_speed >= MAX_SPEED || is_dodging
				particle_emitter.set_emitting(should_emit_particles)
				
			if jumping || velocity.y > 0:
				particle_emitter.set_emitting(false)
				
	for node in jump_dust:
		var particle_emitter = node.get_node("jump_dust")
		if particle_emitter && Input.is_action_just_pressed("move_jump"):
			particle_emitter.set_emitting(true)
		else:
			particle_emitter.set_emitting(false)

	for node in move_dust:
		var particle_emitter = node.get_node("move_dust")
		if particle_emitter && is_on_floor() && direction && !sprinting:
			particle_emitter.set_emitting(true)
		else:
			particle_emitter.set_emitting(false)
			
			
	for node in burst_dust:
		var particle_emitter = node.get_node("burst_dust")
		if particle_emitter && is_on_floor() && dodging && Stamina_bar.value >= 20 && direction:
			particle_emitter.set_emitting(true)
		else:
			particle_emitter.set_emitting(false)
			

func GroundSParkEffect():
		var GroundSpark = GroundSpark.instantiate()
		get_parent().add_child(GroundSpark)
		GroundSpark.global_transform.origin = last_ground_position
		GroundSpark.global_transform.basis = global_transform.basis
		await get_tree().create_timer(.4).timeout
		GroundSpark.queue_free()
		

func AirWaveEffect():
		var AirWave = AirWave.instantiate()
		get_parent().add_child(AirWave)
		AirWave.global_transform.origin = last_ground_position + Vector3(0,1,0)
		AirWave.global_transform.basis = last_ground_rotation.basis
		await get_tree().create_timer(.6).timeout
		AirWave.queue_free()
		
func GeneralwaveEffect():
		# Instantiate the wind shockwave at the last ground position
		var waveEffect = waveEffect.instantiate()
		get_parent().add_child(waveEffect)
		waveEffect.global_transform.origin = last_ground_position
		await get_tree().create_timer(.7).timeout
		waveEffect.queue_free()

func LandingGroundEffect(delta):
	if is_on_floor():
		if (is_in_air == true):
			is_in_air = false
			if air_timer >= 0.2:
				var waveEffect = waveEffect.instantiate()
				$AudioStreamPlayer4.play()
				get_parent().add_child(waveEffect)
				waveEffect.global_transform.origin = last_ground_position
				await get_tree().create_timer(.7).timeout
				waveEffect.queue_free()
		air_timer = 0.0
	else:
		is_in_air = true

func _proccess_sprinting(delta):
	if sprinting:
		if Input.is_action_just_pressed("move_jump"):
			is_in_air = true
			if is_on_floor():
				current_speed -= 1
			
	if sprinting && is_moving && Stamina_bar.value > 0 && can_sprint && can_move == true && is_on_floor():
		sprint_timer += delta
		is_sprinting = true
		Animationtree.set("parameters/Ground_Blend/blend_amount", 1)
		Stamina_bar.value -= sprinting_deplete_rate * delta
		target_speed = MAX_SPEED
		ACCELERATION = DASH_ACCELERATION
		DECELERATION = DASH_DECELERATION
		target_blend_amount = 1.0
		current_blend_amount = lerp(current_blend_amount, target_blend_amount, blend_lerp_speed * delta)
		
		#if sprint_timer >= 0.2:
			#Animationtree.set("parameters/Ground_Blend2/blend_amount", 0)
			#print("skid")
		
		if sprint_timer >= 3.5:
			DASH_ACCELERATION = SECOND_DASH_ACCELERATION
			DASH_DECELERATION = SECOND_DASH_DECELERATION
			target_speed = SECOND_MAX_SPEED
			Animationtree.set("parameters/Ground_Blend2/blend_amount", 0)
		else:
			Animationtree.set("parameters/Ground_Blend2/blend_amount", -1)
		
		if Input.is_action_just_released("move_sprint") || sprint_timer >= 3 && jumping || jumping:
			is_sprinting = false
			target_speed = BASE_SPEED
			ACCELERATION = BASE_ACCELERATION
			DECELERATION = BASE_DECELERATION
			sprint_timer = 0.0
			Animationtree.set("parameters/Jump_Blend/blend_amount", 1)
			GroundSParkEffect()

		if Stamina_bar.value <= 0:
			is_sprinting = false
			can_sprint = false
			sprinting_refill_rate = sprinting_refill_rate_zero
			sprint_timer = 0.0
			
			
			if Stamina_bar.value >= 0:
				if is_moving:
					current_speed = STAMINA_DEPLETED_SPEED
		else:
			sprinting_refill_rate = sprinting_refill_rate
			
			
			
	else:
		is_sprinting = false
		target_speed = BASE_SPEED
		ACCELERATION = BASE_ACCELERATION
		DECELERATION = BASE_DECELERATION
		Animationtree.set("parameters/Ground_Blend2/blend_amount", -1)
		
		if Stamina_bar.value < stamina:
			Stamina_bar.value += sprinting_refill_rate * delta
			
		if Stamina_bar.value == stamina:
			can_sprint = true
			
		if velocity.dot(direction) < 0 && is_sprinting:
			print("working on sprinting")

func _proccess_dodge(delta):
	#print("SpinDodge Timer " + str(spinDodge_timer_cooldown))
	#print(current_speed)
	
	if dodging && is_on_floor() && can_dodge && Stamina_bar.value > 0 && current_speed >= BASE_SPEED && is_moving:
		is_dodging = true
		$AudioStreamPlayer2.play()
		armature_rot_speed = 1
		last_ground_position = global_transform.origin 
		current_speed = DODGE_SPEED
		ACCELERATION = DODGE_ACCELERATION
		DECELERATION = DODGE_DECELERATION
		LERP_VAL = DODGE_LERP_VAL
		Stamina_bar.value -= 10
		dodge_cooldown_timer = dodge_cooldown  
		can_dodge = false  # Disable dodging until cooldown finishes
		#disable_inputs()
		AirWaveEffect()
		GroundSParkEffect()
		Animationtree.set("parameters/Ground_Blend3/blend_amount", 0)
		
	if Stamina_bar.value <= 0 && is_dodging:
		#Animationtree.set("parameters/Ground_Blend3/blend_amount", 1)
		current_speed = BASE_SPEED
		print("UNABLE TO DODGE")
			
	if is_dodging && is_moving:
		dodge_cooldown_timer -= delta
		#await get_tree().create_timer(.2).timeout
		spinDodge_timer_cooldown -= delta

		if dodge_cooldown_timer <= 0:
			enable_inputs()
			can_move = true
			LERP_VAL = .2
			is_dodging = false
			spinDodge_timer_cooldown = spinDodge_reset
			await get_tree().create_timer(.1).timeout
			Animationtree.set("parameters/Ground_Blend3/blend_amount", -1)
		
		if spinDodge_timer_cooldown <= 0 && dodge_cooldown_timer <= 0:
			spinDodge_timer_cooldown = spinDodge_reset
			
		
	#if spinDodge_timer_cooldown <= spinDodge_reset && !air_spin && dodging && is_moving && is_on_floor():
		##Animationtree.set("parameters/Ground_Blend3/blend_amount", 1)
		#armature_rot_speed = armature_default_rot_speed
		#velocity.y = 6
		#air_spin = true
		#jump_counter = 1
		#current_speed = SPIN_DODGE_SPEED
		#spinDodge_timer_cooldown = spinDodge_reset
		#ACCELERATION = DODGE_ACCELERATION
		#DECELERATION = DODGE_DECELERATION
		#LERP_VAL = DODGE_LERP_VAL
		#Stamina_bar.value -= 10
		#can_move = false
		#can_jump = false
			
	if is_on_floor():
		if is_in_air:
			is_in_air = false
			if air_timer >= 0.2:
				if air_spin:
					air_spin = false
					spinDodge_timer_cooldown = spinDodge_reset
					print("Player has landed after spin dodge")
					can_move = true
					can_jump = true
					ACCELERATION = BASE_ACCELERATION
					DECELERATION = BASE_DECELERATION
			air_timer = 0.0
	else:
		is_in_air = true
		air_timer += delta



func _proccess_cooldown(delta):
	if !can_dodge:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0:
			can_dodge = true
			dodge_cooldown_timer = 0

	if Input.is_action_just_released("move_dodge"):
		#Animationtree.set("parameters/Ground_Blend3/blend_amount", -1)
		ACCELERATION = BASE_ACCELERATION
		DECELERATION = BASE_DECELERATION
		if can_dodge:
			dodge_cooldown_timer = dodge_cooldown
			can_dodge = false

func jump(delta):
	if Input.is_action_just_pressed("move_jump") && is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_released("move_jump") && velocity.y < 0:
		velocity.y = 10
		
	if !is_on_floor():
		velocity.y -= custom_gravity * delta
	pass

func _proccess_jump(delta):
	if velocity.y <= 0:
		Animationtree.set("parameters/Jump_Blend/blend_amount", 1)
	if !is_on_floor():
		air_timer += delta
		can_jump = false
		velocity.y -= custom_gravity * delta
		
		#if !direction:
			#current_speed -= 20 *  delta
			#if current_speed <= -1:
				#current_speed = 0
			#print("working")
			
	elif is_on_floor(): 
		can_jump = true
		Animationtree.set("parameters/Jump_Blend/blend_amount", -1)
		jump_counter = 0  # Reset jump counter when landing on the ground
		last_ground_position = global_transform.origin 
		
		if air_timer >= 0.2:
			var waveEffect = waveEffect.instantiate()
			$AudioStreamPlayer4.play()
			get_parent().add_child(waveEffect)
			waveEffect.global_transform.origin = last_ground_position
			await get_tree().create_timer(.7).timeout
			waveEffect.queue_free()

	if velocity.y > 0 && jump_timer >= 0.01:
		Animationtree.set("parameters/Jump_Blend/blend_amount", 1)

	if Input.is_action_pressed("move_jump") && jump_counter <= 0:
		jump_timer += delta
		air_timer += delta
		$AudioStreamPlayer3.play()
		LandingGroundEffect(delta)

		if jump_timer <= 0.4:
			velocity.y = JUMP_VELOCITY
			can_jump = false
			jump_counter += 1  # Increase jump counter when jumping
			#GeneralwaveEffect()

		else:
			velocity.y -= custom_gravity * delta
			Animationtree.set("parameters/Jump_Blend/blend_amount", 0)
			can_jump = false

	if !is_on_floor() && jump_timer >= 0.4:
		jump_timer = 0.0
		can_jump = false

	if Input.is_action_just_pressed("move_jump"):
		air_timer = 0.0
		jump_timer = 0.0

	if Input.is_action_just_released("move_jump"):
		air_timer = 0.0
		jump_timer = 0.0
		Animationtree.set("parameters/Jump_Blend/blend_amount", 0)

func _process_walljump(delta):
	if is_on_wall():
		if Input.is_action_just_pressed("move_jump"):
			var wall_normal = get_wall_normal()
			if wall_normal != null && wall_normal != Vector3.ZERO:
				wall_normal = wall_normal.normalized() 
				velocity = wall_normal * (JUMP_VELOCITY * WALL_JUMP_VELOCITY_MULTIPLIER)
				velocity.y += WALL_JUMP_VELOCITY_MULTIPLIER

				has_wall_jumped = true
				can_wall_jump = false
				wall_jump_position = global_transform.origin
				if has_wall_jumped:
					for node in wall_wave:
							node.global_transform.origin = wall_jump_position
							if node.has_node("AnimationPlayer"):
								node.get_node("AnimationPlayer").play("Landing_strong_001|CircleAction_002")

func _proccess_attack(delta):
	
	if is_attacking:
		attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		is_attacking = false
	if Input.is_action_just_pressed("attack_light_1") && attack_cooldown <= 0.0 && is_on_floor() && can_attack:
		Animationtree.set("parameters/Sword1_Shot/request" , 1)
		print("Attack")
		current_speed = 0
		Attack_Box.monitoring = true
		is_attacking = true
		attack_cooldown = 0.5 
		#await get_tree().create_timer(1).timeout
		#Attack_Box.monitoring = false
		
	else:
		Attack_Box.monitoring = false
		
	if Input.is_action_just_released("attack_light_1") && is_on_floor():
		Attack_Box.monitoring = false
		Animationtree.set("parameters/Attack_Shot/request", 2)
	


func _physics_process(delta):
	_proccess_jump(delta)
	_unhandled_input(delta)
	_proccess_dodge(delta)
	_proccess_cooldown(delta)
	_proccess_sprinting(delta)
	_proccess_attack(delta)
	#jump(delta)
	
	controller_switch(delta)
	LandingGroundEffect(delta)
	
			
	fps_label.text = ("FPS: " + str(Engine.get_frames_per_second()))
	
	if is_on_floor():
		if is_in_air:
			is_in_air = false
			if air_timer >= 0.2:
				print("landing")
			air_timer = 0.0
	else:
		is_in_air = true
		air_timer += delta
	
	if is_on_floor():
		last_ground_position = global_transform.origin
		last_ground_rotation = global_transform
		
	speedDebug.value = current_speed
	playerHealthLabel.value = playerHealthMan.max_health
	
	if Input.is_action_just_pressed("mouse_left"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	sprinting = Input.is_action_pressed("move_sprint")
	dodging = Input.is_action_just_pressed("move_dodge")
	jumping = Input.is_action_pressed("move_jump")
	
	if is_on_floor():
		if sprinting && jumping:
			velocity.y = JUMP_VELOCITY * RUNJUMP_MULTIPLIER

	move_and_slide()


func _on_refill_cooldown_timeout():
	pass # Replace with function body.


#Attacking objects and enemies
func _on_attack_box_area_entered(area):
	if area.has_method("takeDamageEnemy") && !attack_proccessing && can_attack:
		enemyHealthMan.takeDamageEnemy(enemyHealthMan.health , attack_power)
		print("Enemy got hit")
		$AudioStreamPlayer.play()
		gameJuice.hitStop(0.25, area)
		attack_cooldown = 0.1
		
		Attack_Box.monitoring = false
		gameJuice.knockback(area.get_parent(), Attack_Box, 6)
		



func pause():
	process_mode = PROCESS_MODE_DISABLED

func unpause():
	process_mode = PROCESS_MODE_INHERIT

#things entering the players hurtbox
func _on_hurt_box_area_entered(area):
		#if area.name != "HurtBox" || "Attack_Box":
			#if !is_on_floor():
				#print("got hit in the air")
				#disable_inputs()
				#can_jump = false
				#await get_tree().create_timer(.5).timeout
				#can_jump = true
				#enable_inputs()
			#
			#elif is_on_floor():
				#print("got hit in the floor")
				#disable_inputs()
				#can_jump = false
				#await get_tree().create_timer(.5).timeout
				#can_jump = true
				#enable_inputs()
				#
			#else:
				#enable_inputs()
		pass

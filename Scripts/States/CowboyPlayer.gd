extends CharacterBody3D
class_name Player

@onready var animations = $animations
@onready var state_machine = $StateMachine

@onready var followcam = get_node("/root/FollowCam")
@onready var armature = $RootNode
var camera = preload("res://Player/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

@export var custom_gravity = 20.0

#func _ready():
	#state_machine.init(self)
	#
#
#func _unhandled_input(event: InputEvent):
	#state_machine.proccess_input(event)
#
#
#func _physics_process(delta):
	#
	#state_machine.proccess_physics(delta)
	#
	## Add the gravity.
	#if not is_on_floor():
		#velocity.y -= custom_gravity * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
		#armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), .9)
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
#
	#move_and_slide()
#
#func _proccess(delta):
	#state_machine.proccess_frame(delta)

class_name PlayerInput
extends Node

@export var player_actions : PlayerActions
@export var limbo_hsm : LimboHSM

var blackboard : Blackboard 

var input_dir : Vector3

func _ready() -> void:
	blackboard = limbo_hsm.blackboard
	#blackboard.bind_var_to_property("direction", self, "input_dir", true)

func _process(delta: float) -> void:
	
	#print(main_sm.get_active_state())
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("move_jump") && is_on_floor():
		#isPressJump = true
		##main_sm.dispatch(&"to_jump")
	#else:
		#isPressJump = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir = Input.get_vector(player_actions.move_left, player_actions.move_right, player_actions.move_forward,player_actions.move_back)
	blackboard.set_var(BBNAMES.direction_var, input_dir)
	print(blackboard.get_var("direction"))
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	
	#if direction:
		#isPressMove = true
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#isPressMove = false
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
	#
	#move_and_slide()

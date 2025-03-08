extends CharacterBody3D
#class_name Player
#
#@export var stats : PlayerStats
#@export var player_actions : PlayerActions
#
#@onready var animations = $animations
##@onready var state_machine = $StateMachine
##
##@onready var state_machine: LimboHSM = $LimboHSM
##@export var state_machine = LimboHSM
#
#@onready var idle_state = $LimboHSM/IdleState
#@onready var run_state = $LimboHSM/RunState
#@onready var walk_state = $LimboHSM/WalkState
#@onready var jump_state = $LimboHSM/JumpState
#
#@onready var followcam = get_node("/root/FollowCam")
#@onready var armature = $RootNode
#var camera = preload("res://Player/PlayerCamera.tscn").instantiate()
#var spring_arm_pivot = camera.get_node("SpringArmPivot")
#var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
#
#var isPressMove := false
#var isPressJump := false
#
##var main_sm: LimboHSM
#
#
#
##SECOND METHOD STATE MACHINE
#
##LIMBO AI A METHOD ---------------
##func _ready():
	##initiate_state_machine()
##
##
##func initiate_state_machine():
	##main_sm = LimboHSM.new()
	##add_child(main_sm)
	##
	##
	##var idle_state = LimboState.new().named("IdleState").call_on_enter(idle_start).call_on_update(idle_update)
	##var walk_state = LimboState.new().named("walkState").call_on_enter(walk_start).call_on_update(walk_update)
	##var jump_state = LimboState.new().named("jumpState").call_on_enter(jump_start).call_on_update(jump_update)
	##var run_state = LimboState.new().named("runState").call_on_enter(run_start).call_on_update(run_update)
	##
	##main_sm.add_child(idle_state)
	##main_sm.add_child(walk_state)
	##main_sm.add_child(jump_state)
	##main_sm.add_child(run_state)
	##
	##main_sm.initial_state = idle_state
	##
	##
###	#ANYSTATE = can go from ANY state into the corresponding state
	##main_sm.add_transition(idle_state, walk_state, &"to_walk")
	##main_sm.add_transition(main_sm.ANYSTATE, idle_state, &"state_ended")
	##main_sm.add_transition(idle_state, jump_state, &"to_jump")
	##main_sm.add_transition(walk_state, jump_state, &"to_jump")
	###main_sm.add_transition(main_sm.ANYSTATE, attack_state, &"to_attack")
	##
	##main_sm.initialize(self)
	##main_sm.set_active(true)
##
#func _physics_process(delta):
	#
	##print(main_sm.get_active_state())
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("move_jump") && is_on_floor():
		#isPressJump = true
		##main_sm.dispatch(&"to_jump")
	#else:
		#isPressJump = false
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	##var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	##var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	##
	##
	##if direction:
		#
		##velocity.x = direction.x * SPEED
		##velocity.z = direction.z * SPEED
	##else:
		#
		##velocity.x = move_toward(velocity.x, 0, SPEED)
		##velocity.z = move_toward(velocity.z, 0, SPEED)
	#
	#move_and_slide()
#
##func idle_start():
	##print("IDLE START")
	##pass
##func idle_update(delta: float):
	##if velocity.x != 0 || velocity.z != 0 && isPressMove:
		##main_sm.dispatch(&"to_walk")
	##else:
		##velocity.x = move_toward(velocity.x, 0, SPEED)
		##velocity.z = move_toward(velocity.z, 0, SPEED)
	##
	##pass
	##
##func walk_start():
	##print("WALK START")
	##
##func walk_update(delta: float):
	##
	##if !isPressMove:
		##main_sm.dispatch(&"state_ended")  # Return to idle if no input
	##pass
	##
##func run_start():
	##print("RUN START")
	##pass
##func run_update(delta: float):
	##print("RUN UPDATE")
	##pass
	##
##func jump_start():
	##print("JUMP START")
	##velocity.y = JUMP_VELOCITY
	##pass
##func jump_update(delta: float):
	##print("JUMP UPDATE")
	##if is_on_floor():
		##main_sm.dispatch(&"state_ended")
	##pass
##LIMBO AI A METHOD -------------

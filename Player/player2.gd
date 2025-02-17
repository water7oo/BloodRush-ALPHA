extends CharacterBody3D

@onready var state_machine: LimboHSM = $LimboHSM
@onready var idle_state = $LimboHSM/IdleState
@onready var walk_state = $LimboHSM/WalkState
@onready var jump_state = $LimboHSM/JumpState  # Single Jump State, no jump_idle or jump_moving

#var camera = preload("res://Player/PlayerCamera.tscn").instantiate()
#var spring_arm_pivot = camera.get_node("SpringArmPivot")
#var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
#@export var mouse_sensitivity: float = 0.005




func _ready():
	initialize_state_machine()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func initialize_state_machine():
	# General transitions
	state_machine.add_transition(state_machine.ANYSTATE, idle_state, "to_idle")
	state_machine.add_transition(state_machine.ANYSTATE, walk_state, "to_walk")
	state_machine.add_transition(state_machine.ANYSTATE, jump_state, "to_jump")  # Transition to JumpState

	# Walk and Idle transitions
	state_machine.add_transition(idle_state, walk_state, "to_walk")
	state_machine.add_transition(walk_state, idle_state, "to_idle")

	# Jump state transition
	state_machine.add_transition(idle_state, jump_state, "to_jump")  # Transition to JumpState when jumping from Idle
	state_machine.add_transition(walk_state, jump_state, "to_jump")  # Transition to JumpState when jumping from Walk

	# Landing transitions
	state_machine.add_transition(jump_state, walk_state, "to_walk")  # Land and move to WalkState
	state_machine.add_transition(jump_state, idle_state, "to_idle")  # Land and move to IdleState if no movement

	state_machine.initial_state = idle_state  # Start in the IdleState
	state_machine.initialize(self)
	state_machine.set_active(true)

func _physics_process(delta: float) -> void:
	playerGravity(delta)
	
func playerCamera(delta: float) -> void:
	pass

func playerGravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta


#func _unhandled_input(event):
	#if event is InputEventMouseMotion:
#
		#var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		#var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity
#
		#rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))
#
		#spring_arm_pivot.rotation.x = rotation_x
		#spring_arm_pivot.rotation.y = rotation_y

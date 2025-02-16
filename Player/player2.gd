extends CharacterBody3D

@onready var state_machine: LimboHSM = $LimboHSM
@onready var idle_state = $LimboHSM/IdleState
@onready var walk_state = $LimboHSM/WalkState
@onready var jump_state = $LimboHSM/JumpState  # Single Jump State, no jump_idle or jump_moving

func _ready():
	initialize_state_machine()

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

func _physics_process(delta):
	#print("Current State:", state_machine.get_active_state())  # Uncomment to see active state in console
	pass

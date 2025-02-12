extends CharacterBody3D

@onready var state_machine: LimboHSM = $LimboHSM

@onready var idle_state = $LimboHSM/IdleState
@onready var walk_state = $LimboHSM/WalkState

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready():
	initialize_state_machine()

func initialize_state_machine():
	state_machine.add_transition(idle_state, walk_state, "to_walk")
	state_machine.add_transition(walk_state, idle_state, "to_idle")

	state_machine.initial_state = idle_state
	state_machine.initialize(self)
	state_machine.set_active(true)

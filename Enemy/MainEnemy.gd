extends CharacterBody3D

@onready var state_machine: LimboHSM = $LimboHSM
@onready var idle_state: LimboState = $LimboHSM/IdleState
@onready var attack_state: LimboState = $LimboHSM/AttackState
@onready var airAttack_state: LimboState = $LimboHSM/AirAttackState
@onready var walk_state: LimboState = $LimboHSM/WalkState
@onready var jump_state: LimboState = $LimboHSM/JumpState
@onready var run_state: LimboState = $LimboHSM/RunState
@onready var dodge_state: LimboState = $LimboHSM/DodgeState
@onready var hitstun_state: LimboState = $LimboHSM/HitStunState
@onready var guard_state: LimboState = $LimboHSM/GuardState
@onready var death_state: LimboState = $LimboHSM/DeathState

@export var isDeathDebug: bool = false
@export var isAlwaysAttackDebug: bool = false
@export var isAlwaysGuardDebug: bool = false
@export var isAlwaysDodgeDebug: bool = false
@export var isAlwaysAliveDebug: bool = false

@onready var stateDebug = $StateDebug

func _ready():
	if state_machine:
		initialize_state_machine()
	pass
	
func initialize_state_machine():
	state_machine.add_transition(state_machine.ANYSTATE, idle_state, "to_idle")
	state_machine.add_transition(state_machine.ANYSTATE, walk_state, "to_walk")
	state_machine.add_transition(state_machine.ANYSTATE, run_state, "to_run")
	state_machine.add_transition(state_machine.ANYSTATE, jump_state, "to_jump")
	state_machine.add_transition(state_machine.ANYSTATE, attack_state, "to_attack")
	state_machine.add_transition(state_machine.ANYSTATE, death_state, "to_death")
	state_machine.add_transition(jump_state, airAttack_state, "to_airAttack")
	state_machine.add_transition(state_machine.ANYSTATE, hitstun_state, "to_hitstun")
	state_machine.add_transition(state_machine.ANYSTATE, guard_state, "to_guard")
	
	state_machine.initial_state = idle_state  
	state_machine.initialize(self)
	state_machine.set_active(true)
	pass

func _process(delta: float) -> void:
	if state_machine:
		updateStateMachineDebug()
		stateDebugging()
		

	
func updateStateMachineDebug():
	stateDebug.text = str(state_machine.get_active_state())
		

func stateDebugging():
	if EnemyHealthManager.enemyWasHit == true:
		state_machine.dispatch("to_hitstun")

	if EnemyHealthManager.isDead == true || isDeathDebug == true:
		state_machine.dispatch("to_death")
		
	if isAlwaysGuardDebug == true:
		EnemyHealthManager.isGuarding = true
		state_machine.dispatch("to_guard")

	if isAlwaysAliveDebug == true:
		EnemyHealthManager.current_health = EnemyHealthManager.max_health

func _physics_process(delta: float) -> void:
	Gravity(delta)
	move_and_slide()

func Gravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta

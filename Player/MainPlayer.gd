extends CharacterBody3D

@onready var state_machine: LimboHSM = $LimboHSM
@onready var idle_state = $LimboHSM/IdleState
@onready var walk_state = $LimboHSM/WalkState
@onready var jump_state = $LimboHSM/JumpState 
@onready var run_state = $LimboHSM/RunState
@onready var runJump_state = $LimboHSM/RunJumpState
@onready var burst_state = $LimboHSM/BurstState
@onready var crouch_state = $LimboHSM/CrouchState
@onready var groundDive_state = $LimboHSM/GroundDiveState
@onready var airDive_state = $LimboHSM/AirDiveState
@onready var slide_state = $LimboHSM/SlideState


@onready var attack_state = $LimboHSM/AttackState
@onready var attackMedium_state = $LimboHSM/AttackMediumState
@onready var attackHeavy_state = $LimboHSM/AttackHeavyState
@onready var attack_upper_state = $LimboHSM/AttackUpperState
@onready var attack_slamAir_state = $LimboHSM/AttackAirSlamState
@onready var air_attack_state = $LimboHSM/AirAttackState
@onready var air_attackMedium_state = $LimboHSM/AirAttackMediumState
@onready var air_attackHeavy_state = $LimboHSM/AirAttackHeavyState

@onready var guard_state = $LimboHSM/GuardState


@onready var take_damage_state = $LimboHSM/TakeDamageState
@onready var recover_state = $LimboHSM/RecoverState
@onready var stateDebugLabel = $"State debug"
@onready var playerSpeedLabel = $PlayerSpeedLabel/PlayerSpeed
var input_buffer := {}
var input_buffer_time := 0.2
var input_queue: Array = []


@onready var AttackCooldownLabel = $AttackCooldown


func _ready():
	initialize_state_machine()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func initialize_state_machine():
	state_machine.add_transition(state_machine.ANYSTATE, idle_state, "to_idle")
	state_machine.add_transition(state_machine.ANYSTATE, walk_state, "to_walk")
	state_machine.add_transition(state_machine.ANYSTATE, run_state, "to_run")
	state_machine.add_transition(state_machine.ANYSTATE, jump_state, "to_jump")
	
	

	state_machine.add_transition(state_machine.ANYSTATE, air_attack_state, "to_airAttack")
	state_machine.add_transition(state_machine.ANYSTATE, air_attackMedium_state, "to_airMediumAttack")
	state_machine.add_transition(state_machine.ANYSTATE, air_attackHeavy_state, "to_airHeavyAttack")
	state_machine.add_transition(state_machine.ANYSTATE, attack_slamAir_state, "to_airSlamAttack")
	
	
	state_machine.add_transition(state_machine.ANYSTATE, guard_state, "to_guard")
	
	state_machine.add_transition(idle_state, attack_state, "to_attack")       # L
	state_machine.add_transition(idle_state, attackMedium_state, "to_mediumAttack") # M
	state_machine.add_transition(idle_state, attackHeavy_state, "to_heavyAttack")   # H
	state_machine.add_transition(idle_state, attack_upper_state, "to_attackUpper")  


	state_machine.add_transition(walk_state, attack_state, "to_attack")       # L
	state_machine.add_transition(walk_state, attackMedium_state, "to_mediumAttack") # M
	state_machine.add_transition(walk_state, attackHeavy_state, "to_heavyAttack")   # H
	state_machine.add_transition(walk_state, attack_upper_state, "to_attackUpper")  

	state_machine.add_transition(run_state, attack_state, "to_attack")       # L
	state_machine.add_transition(run_state, attackMedium_state, "to_mediumAttack") # M
	state_machine.add_transition(run_state, attackHeavy_state, "to_heavyAttack")   # H
	state_machine.add_transition(run_state, attack_upper_state, "to_attackUpper")  
	
	# THE COMBO CHAIN (Gatling Rules)
	state_machine.add_transition(attack_state, attackMedium_state, "to_mediumAttack") # L -> M
	state_machine.add_transition(attackMedium_state, attackHeavy_state, "to_heavyAttack") # M -> H
	state_machine.add_transition(attackHeavy_state, attack_upper_state, "to_attackUpper") # H -> Launch


	# THE FINISHER
	state_machine.add_transition(attack_upper_state, jump_state, "to_jump")
	
	state_machine.add_transition(run_state, runJump_state, "to_runJump")
	state_machine.add_transition(walk_state, burst_state, "to_burst")
	state_machine.add_transition(run_state, burst_state, "to_burst")
	
	state_machine.add_transition(idle_state, crouch_state, "to_crouch")
	state_machine.add_transition(run_state, crouch_state, "to_crouch")
	state_machine.add_transition(walk_state, crouch_state, "to_crouch")
	
	
	state_machine.add_transition(take_damage_state, recover_state, "to_recover")


	state_machine.initial_state = idle_state  
	state_machine.initialize(self)
	state_machine.set_active(true)
	
	
	


func _process(delta: float) -> void:
	if Global.combo_hits.size() >= 2:
		$ComboCounter2.visible = true
		$ComboCounter2.text = "X" + str(Global.combo_hits.size())
	else:
		$ComboCounter2.visible = false
		
	if Global.combo_hits.size() > 0:
		Global.combo_timer += delta
		if Global.combo_timer > Global.combo_reset_time:
			Global.combo_hits.clear()
			Global.combo_timer = 0.0
			
			
func _physics_process(delta: float) -> void:
	playerGravity(delta)
	stateDebugLabel.text = ("STATE DEBUG: " + str(state_machine.get_active_state()).to_upper())
	playerSpeedLabel.value = velocity.length()
	playerSpeedLabel.max_value = Global.MAX_SPEED
	
	AttackCooldownLabel.text = "attack cooldown timer: " + str(attack_state.attackData.attack_cooldown_timer)
	handle_attack_input()
	

func record_inputs():
	var time = Time.get_ticks_msec() / 1000.0

	if Input.is_action_just_pressed("attack_light_1"):
		input_queue.append({"type": "light", "time": time})

	if Input.is_action_just_pressed("attack_medium_1"):
		input_queue.append({"type": "medium", "time": time})

	if Input.is_action_just_pressed("attack_heavy_1"):
		input_queue.append({"type": "heavy", "time": time})
		

func clean_inputs():
	var current_time = Time.get_ticks_msec() / 1000.0
	
	input_queue = input_queue.filter(func(i):
		return current_time - i.time <= input_buffer_time
	)

func has_input(type: String) -> bool:
	for i in input_queue:
		if i.type == type:
			return true
	return false
	
func consume_inputs(types: Array):
	input_queue = input_queue.filter(func(i):
		return not i.type in types
	)

func can_buffer_attack() -> bool:
	var state = state_machine.get_active_state()

	if state.has_method("can_cancel") and state.can_cancel:
		return true
		
	return false

func handle_attack_input() -> void:
	record_inputs()
	clean_inputs()

	var is_air = not is_on_floor()
	
	if has_input("medium") and has_input("heavy") and attack_state.attackData.attack_cooldown_timer <= 0:
		if not Global.is_attacking or can_buffer_attack():
			
			state_machine.dispatch("to_attackUpper" if not is_air else "to_airSLamAttack")
			attack_state.attackData.attack_cooldown_timer = attack_state.attackData.attack_cooldown_duration
			consume_inputs(["medium", "heavy"])
			return

	if has_input("light") and attack_state.attackData.attack_cooldown_timer <= 0:
		if not Global.is_attacking or can_buffer_attack():
			state_machine.dispatch("to_airAttack" if is_air else "to_attack")
			attack_state.attackData.attack_cooldown_timer = attack_state.attackData.attack_cooldown_duration
			consume_inputs(["light"])
			return

	if has_input("medium") and attack_state.attackData.attack_cooldown_timer <= 0:
		if not Global.is_attacking or can_buffer_attack():
			state_machine.dispatch("to_airMediumAttack" if is_air else "to_mediumAttack")
			attack_state.attackData.attack_cooldown_timer = attack_state.attackData.attack_cooldown_duration
			consume_inputs(["medium"])
			return

	if has_input("heavy") and attack_state.attackData.attack_cooldown_timer<= 0:
		if not Global.is_attacking or can_buffer_attack():
			state_machine.dispatch("to_airHeavyAttack" if is_air else "to_heavyAttack")
			attack_state.attackData.attack_cooldown_timer = attack_state.attackData.attack_cooldown_duration
			consume_inputs(["heavy"])
			return
		
func playerCamera(delta: float) -> void:
	pass

func playerGravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta



func _on_hurt_box_area_entered(area):
	if area.name == "enemyBox":
		#Global.last_enemy_hit = area.get_parent()  # Set the enemy that hit the player
		
		# Optionally, transition to TakeDamage state
		state_machine.dispatch("to_damaged")


func _on_targeting_area_entered(area: Area3D) -> void:
	if area.name == "enemyBox":
		print("Locking on enemy")
	pass # Replace with function body.

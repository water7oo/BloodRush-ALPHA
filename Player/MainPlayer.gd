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
var input_buffer := {}
var input_buffer_time := .7
var input_queue: Array = []

@onready var PlayerUI = $PlayerUI
@onready var stateDebugLabel = PlayerUI.get_node("State debug")
@onready var playerSpeedLabel = PlayerUI.get_node("PlayerSpeedLabel/PlayerSpeed")
@onready var lightAttackTimer = PlayerUI.get_node("AttackCooldown")
@onready var mediumAttackTimer = PlayerUI.get_node("AttackCooldownMedium")
@onready var heavyAttackTimer = PlayerUI.get_node("AttackCooldownHeavy")
@onready var upperAttackTimer = PlayerUI.get_node("AttackCooldownUpper")
@onready var CanCancelDebug = PlayerUI.get_node("CanCancelDebug")
@onready var jumpCancelTimer = PlayerUI.get_node("JumpCancelTimer")
@onready var jumpCancelDelay = PlayerUI.get_node("JumpCancelDelay")
@onready var UpperSwapDebug = PlayerUI.get_node("UpperSwapDebug")
@onready var comboCounter = PlayerUI.get_node("ComboCounter2")

@onready var comboCounterSound = $ComboSound1

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
	state_machine.add_transition(state_machine.ANYSTATE, take_damage_state, "to_damage")

	state_machine.initial_state = idle_state  
	state_machine.initialize(self)
	state_machine.set_active(true)
	
	
	


func _process(delta: float) -> void:
	pass
			

func updateComboCounter(delta: float):

	if Global.combo_hits.size() >= 2:
		print(Global.combo_hits.size())
		comboCounter.get_child(0).visible = true
		comboCounter.get_child(0).text = "X" + str(Global.combo_hits.size())
		comboCounterSound.pitch_scale = clamp(
			1.0 + (Global.combo_hits.size() * 0.2),
			1.0,
			2.0
		)
		comboCounterSound.play()
		if Global.isHit:
			Global.shakeTween(comboCounter)
	else:
		comboCounter.get_child(0).visible = false
		
	if Global.combo_hits.size() > 0:
		Global.combo_timer += delta
		if Global.combo_timer > Global.combo_reset_time:
			Global.combo_hits.clear()
			Global.combo_timer = 0.0
			comboCounterSound.pitch_scale = 1.0

func updateComboCounterInstant(count):
	if count >= 2 && Global.combo_timer > 0:
		comboCounter.get_child(0).visible = true
		comboCounter.get_child(0).text = "X" + str(count)
		Global.shakeTween(comboCounter)
		
	else:
		comboCounter.get_child(0).visible = false


func comboTimerCountdown(delta: float):
	if Global.combo_hits.size() > 0:
		Global.combo_timer -= delta

		if Global.combo_timer <= 0:
			Global.combo_hits.clear()
			Global.combo_timer = 0.0

			updateComboCounterInstant(0)
			
func _physics_process(delta: float) -> void:
	playerGravity(delta)
	comboTimerCountdown(delta)
	stateDebugLabel.text = ("state debug: " + str(state_machine.get_active_state()).to_upper())
	playerSpeedLabel.value = velocity.length()
	playerSpeedLabel.max_value = Global.MAX_SPEED
	CanCancelDebug.text = ("can attack Cancel: " + str(Global.can_cancel))
	lightAttackTimer.text = ("light attack timer: " + str(attack_state.attack_timer))
	mediumAttackTimer.text = ("medium attack timer: " + str(attackMedium_state.attack_timer))
	heavyAttackTimer.text = ("heavy attack timer: " + str(attackHeavy_state.attack_timer))
	upperAttackTimer.text = ("upper attack timer: " + str(attack_upper_state.attack_timer))
	jumpCancelTimer.text = ("jump cancel timer: " + str(attack_upper_state.jump_cancel_timer))
	jumpCancelDelay.text = ("jump cancel delay: " + str(attack_upper_state.jumpCancelDelay))
	
	var clean_name = attack_upper_state.attackData.resource_path.get_file().get_basename().to_lower()
	UpperSwapDebug.text = "upperswap: " + clean_name
	
	#playerHitStun()
	handle_attack_input()
	

const ATTACK_TYPES = {
	"attack_light_1":  { "ground": "light",  "air": "airlight" },
	"attack_medium_1": { "ground": "medium", "air": "airmedium" },
	"attack_heavy_1":  { "ground": "heavy",  "air": "airheavy" }
}

func record_inputs():
	var time := Time.get_ticks_msec() / 1000.0
	var is_air := not is_on_floor()

	for action in ATTACK_TYPES.keys():
		if Input.is_action_just_pressed(action):
			var types = ATTACK_TYPES[action]
			input_queue.append({ "type": types.ground, "time": time })
			
			if is_air:
				input_queue.append({ "type": types.air, "time": time })


func clean_inputs():
	var current_time := Time.get_ticks_msec() / 1000.0
	
	input_queue = input_queue.filter(func(i):
		return current_time - i.time <= input_buffer_time
	)


func has_input(type: String) -> bool:
	return input_queue.any(func(i): return i.type == type)

func has_inputs(types: Array) -> bool:
	# Return true if ALL types exist in the input_queue
	for t in types:
		if not has_input(t):
			return false
	return true

func consume_inputs(types: Array):
	input_queue = input_queue.filter(func(i):
		return not i.type in types)


func can_buffer_attack() -> bool:
	var state = state_machine.get_active_state()
	return state.has_method("can_cancel") and state.can_cancel


func try_attack(data: Dictionary, is_air: bool) -> bool:
	var type = data.air if is_air else data.ground
	var state = data.air_state if is_air else data.ground_state
	
	if has_input(type) and state.attack_timer <= 0:
		if not Global.is_attacking or can_buffer_attack():
			state_machine.dispatch(data.air_transition if is_air else data.ground_transition)
			state.attack_timer = state.attackData.recovery_duration
			
			consume_inputs([data.air, data.ground] if is_air else [data.ground])
			return true
			
	return false


func handle_attack_input() -> void:
	record_inputs()
	clean_inputs()

	var is_air := not is_on_floor()


	if has_inputs(["medium", "heavy"]):
		if not Global.is_attacking or can_buffer_attack():
			if is_air:
				state_machine.dispatch("to_airSlamAttack")
				attack_slamAir_state.attack_timer = attack_slamAir_state.attackData.recovery_duration
				consume_inputs(["airmedium", "airheavy", "medium", "heavy"])
			else:
				state_machine.dispatch("to_attackUpper")
				attack_upper_state.attack_timer = attack_upper_state.attackData.recovery_duration
				consume_inputs(["medium", "heavy"])
			return  # exit after success
			
			
	var attacks = [
		{
			"ground": "heavy",
			"air": "airheavy",
			"ground_state": attackHeavy_state,
			"air_state": air_attackHeavy_state,
			"ground_transition": "to_heavyAttack",
			"air_transition": "to_airHeavyAttack"
		},
		{
			"ground": "medium",
			"air": "airmedium",
			"ground_state": attackMedium_state,
			"air_state": air_attackMedium_state,
			"ground_transition": "to_mediumAttack",
			"air_transition": "to_airMediumAttack"
		},
		{
			"ground": "light",
			"air": "airlight",
			"ground_state": attack_state,
			"air_state": air_attack_state,
			"ground_transition": "to_attack",
			"air_transition": "to_airAttack"
		}
	]

	for attack in attacks:
		if try_attack(attack, is_air):
			return
		
func playerCamera(delta: float) -> void:
	pass

func playerGravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta


func _on_hurt_box_area_entered(area):
	if area.name == "enemyBox" && !Global.is_taking_damage:
		print("OW!")
		#state_machine.dispatch("to_damage")


func _on_targeting_area_entered(area: Area3D) -> void:
	if area.name == "enemyBox":
		pass # Replace with function body.

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

@onready var take_damage_state = $LimboHSM/TakeDamageState
@onready var recover_state = $LimboHSM/RecoverState


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
	state_machine.add_transition(state_machine.ANYSTATE, attack_slamAir_state, "to_airSLamAttack")
	
	
	
	
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
	
	
	




func _physics_process(delta: float) -> void:
	playerGravity(delta)
	handle_attack_input()
	


func handle_attack_input() -> void:
	if Global.is_attacking:
		return  # Prevent input until attack recovery allows cancel or hit confirm

	var is_air = not is_on_floor()

	# Light attack
	if Input.is_action_just_pressed("attack_light_1") and Global.attack_cooldown_timer <= 0:
		state_machine.dispatch("to_airAttack" if is_air else "to_attack")
		return

	# Medium attack
	if Input.is_action_just_pressed("attack_medium_1") and Global.attackMedium_cooldown_timer <= 0:
		state_machine.dispatch("to_airMediumAttack" if is_air else "to_mediumAttack")
		return

	# Heavy attack
	if Input.is_action_just_pressed("attack_heavy_1") and Global.attackHeavy_cooldown_timer <= 0:
		state_machine.dispatch("to_airHeavyAttack" if is_air else "to_heavyAttack")
		return
		
func playerCamera(delta: float) -> void:
	pass

func playerGravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta





func _on_hurt_box_area_exited(area):
	pass # Replace with function body.


func _on_attack_box_area_entered(area):
	pass # Replace with function body.



func _on_hurt_box_area_entered(area):
	if area.name == "enemyBox":
		Global.last_enemy_hit = area.get_parent()  # Set the enemy that hit the player

		# Optionally, transition to TakeDamage state
		state_machine.dispatch("to_damaged")


func _on_attack_box_area_exited(area):
	pass # Replace with function body.

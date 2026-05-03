extends CharacterBody3D


@onready var gameJuice = get_node("/root/GameJuice")
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

@export var enemyHealthManagerNode: Area3D
@export var deathSound = AudioStreamPlayer
@onready var EnemyHealthBar = $HealthBar/SubViewport/ProgressBar
@onready var enemyHurtBox = $enemyHurtBox


@export var enemyStats: Resource
@onready var enemyNameLabel = $enemyNameLabel

const DAMAGE_NUM = preload("uid://cotsnmovmqwww")

const DustWaveEffect = preload("res://FX/dustEffect3.tscn")
var effectSpawned = false

func _ready():
	if enemyStats:
		startHealth()

		
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
	



	if enemyStats.isDead == true:
		enemyStats.current_health = 0.0
		enemyStats.max_health = 0.0
		EnemyHealthBar.value = 0.0

		state_machine.initial_state = death_state
	elif enemyStats.isGuarding == true:

		enemyStats.enemyWasHit = false
		state_machine.initial_state = guard_state
	else:

		state_machine.initial_state = idle_state  


	state_machine.initialize(self)
	state_machine.set_active(true)
	

func _process(delta: float) -> void:
	
	if state_machine:
		updateStateMachineDebug()
		stateDebugging()
		

	
func updateStateMachineDebug():
	stateDebug.text = str(state_machine.get_active_state())
	
	if enemyNameLabel.text:
		enemyNameLabel.text = enemyStats.Name
	else:
		enemyNameLabel.text = "NO NAME GIVEN"
		
func stateDebugging():
	if enemyStats.enemyWasHit == true && enemyStats.isGuarding == false:
		state_machine.dispatch("to_hitstun")

	if enemyStats.isDead == true || isDeathDebug == true:
		state_machine.dispatch("to_death")
		
	if isAlwaysGuardDebug == true:
		enemyStats.isGuarding = true
		state_machine.dispatch("to_guard")

	if isAlwaysAliveDebug == true:
		enemyStats.current_health = enemyStats.max_health

func startHealth():
		enemyStats.max_health = enemyStats.current_health
		
		if EnemyHealthBar:
			EnemyHealthBar.max_value = enemyStats.max_health
			EnemyHealthBar.value = enemyStats.current_health
			EnemyHealthBar.min_value = 0.0
		else:
			print("Health bar not found")
			

func BurstEffectWave(damage):
		if effectSpawned == false && damage > 15.0:
			var instanceBurstEffect = DustWaveEffect.instantiate()
			effectSpawned = true
			get_tree().root.add_child(instanceBurstEffect)
			
			var player_forward = -$EnemyMesh.global_transform.basis.z
			var xform = instanceBurstEffect.global_transform
			
			var spawn_offset = player_forward * 4.0 
			xform.origin = $EnemyMesh.global_transform.origin + spawn_offset

			xform = align_with_y(xform, get_floor_normal(), player_forward)
			
			instanceBurstEffect.global_transform = xform

func align_with_y(xform, new_y, player_forward):
	new_y = new_y.normalized()
	

	var right = player_forward.cross(new_y).normalized()
	var forward = new_y.cross(right).normalized()

	xform.basis = Basis(right, new_y, forward)
	return xform

func damageAnimation():
		var randomNum = randi_range(1, 3)
		if randomNum == 1:
			$AnimationPlayer.play("takeDamage1")
			await get_tree().create_timer(.5).timeout
			$AnimationPlayer.play("IDLE")
		elif randomNum == 2:
			$AnimationPlayer.play("takeDamage2")
			await get_tree().create_timer(.5).timeout
			$AnimationPlayer.play("IDLE")
		elif randomNum == 3:
			$AnimationPlayer.play("takeDamage3")
			await get_tree().create_timer(.5).timeout
			$AnimationPlayer.play("IDLE")
			
func takeDamageEnemy(damage: float) -> void:
		if enemyStats.isDead == false:
			damageAnimation()
			enemyStats.current_health = clamp(enemyStats.current_health - damage, 0.0, enemyStats.max_health)
			state_machine.dispatch("to_hitstun")
			Global.squash_land($EnemyMesh)
			BurstEffectWave(damage)
			effectSpawned = false
			if EnemyHealthBar:
				EnemyHealthBar.value = enemyStats.current_health
			
			
			var newDamageLabel = DAMAGE_NUM.instantiate() as Label3D
			
			newDamageLabel.text = str(damage)
			newDamageLabel.global_position = global_position + Vector3(-1,2,0)
			get_tree().current_scene.call_deferred("add_child", newDamageLabel)
			
			
			if enemyStats.current_health <= 0:
				state_machine.dispatch("to_death")
				enemyHurtBox.monitoring = false
				enemyHurtBox.monitorable = false
			else:
				enemyHurtBox.monitoring = true
				enemyHurtBox.monitorable = true
		else:
			damage -= damage
			$AnimationPlayer.play("IDLE")
		

func takeGuardDamageEnemy(damage: float) -> void:
	if enemyStats.isDead == false:
		if enemyStats.isGuarding == true:
			damage -= enemyStats.GuardDamage
			enemyStats.current_health = clamp(enemyStats.current_health - damage, 0.0, enemyStats.max_health)
		
		if EnemyHealthBar:
			EnemyHealthBar.value = enemyStats.current_health

		if enemyStats.current_health <= 0:
			state_machine.dispatch("to_death")
			enemyHurtBox.monitoring = false
			enemyHurtBox.monitorable = false
			$deathSound.play()
		else:
			enemyHurtBox.monitoring = true
			enemyHurtBox.monitorable = true
			

func _physics_process(delta: float) -> void:
	Gravity(delta)
	move_and_slide()

func Gravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta

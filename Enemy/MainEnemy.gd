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

const DustWaveEffect = preload("res://FX/vfxWave/VerticalWaveEffect1.tscn")
const GroundDustEffect = preload("res://FX/vfxWave/GroundWaveEffect1.tscn")
var effectSpawned = false

@export var enemyMeshScene: Node3D
#var animation_player: AnimationPlayer

var in_air_damage := false
var previous_on_floor := false
var is_being_slammed := false
var waiting_for_bounce_land := false
var upwardSlamForce: float = 15.0
var horizontalSlamForce: float = 20.0

var is_slam_sequence := false

@onready var animation_player: AnimationPlayer = $EnemyMesh/Armature/AnimationPlayer

func _ready():
	if enemyMeshScene:
		animation_player = enemyMeshScene.get_node("AnimationPlayer")
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
			

func damageAnimation(animationDuration):
		var randomNum = randi_range(1, 3)
		if randomNum == 1:
			animation_player.play("Armature|Hurt")
			await get_tree().create_timer(animationDuration).timeout
			animation_player.play("Armature|RESET")
		elif randomNum == 2:
			animation_player.play("Armature|HurtMedium")
			await get_tree().create_timer(animationDuration).timeout
			animation_player.play("Armature|RESET")
		elif randomNum == 3:
			animation_player.play("Armature|HurtCrush")
			await get_tree().create_timer(animationDuration).timeout
			animation_player.play("Armature|RESET")

func airDamageAnimation(animationDuration, isUpper):
	if isUpper == true:
		in_air_damage = true
		previous_on_floor = false
		animation_player.play("Armature|CrushSpinningBack")
	else:
		in_air_damage = true
		previous_on_floor = false
		animation_player.play("Armature|Juggling")

func grabAnimation():
	animation_player.play("Armature|Grabbed")

func slamCrush1():
	animation_player.speed_scale = 1.0
	animation_player.play("Armature|GroundBounce")
	print("slamCrush1")
	
func slamCrushAnimation():

	in_air_damage = false
	
	animation_player.speed_scale = 0.2
	animation_player.play("Armature|GroundBounce")
	var tween = create_tween()
	tween.tween_property(
		$EnemyMesh,
		"rotation:x",
		0.0,
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	
	await get_tree().create_timer(0.1).timeout
	animation_player.speed_scale = 1
	animation_player.play("Armature|CrushSpinningBack")
	
func grabReleaseAnimation():
	animation_player.play("Armature|GrabReleased")
	
	
func takeDamageEnemy(damage: float) -> void:
		if enemyStats.isDead == false:

			enemyStats.current_health = clamp(enemyStats.current_health - damage, 0.0, enemyStats.max_health)
			state_machine.dispatch("to_hitstun")
			Global.squash_land($EnemyMesh)
			VFX.BurstEffectWave($".", effectSpawned, DustWaveEffect, $EnemyMesh, 4.0)
			
			
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
			animation_player.play("RESET")
		

func grabbedEnemy():
	Global.squash_land($EnemyMesh)
	
	
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
			


func start_slam_sequence():
	is_slam_sequence = true
	in_air_damage = false

	animation_player.play("Armature|GroundBounce")

func apply_air_rotation(delta):
	var target_rotation = remap(
		velocity.y,
		-40.0, 40.0,
		deg_to_rad(90),
		deg_to_rad(-90)
	)

	$EnemyMesh.rotation.x = lerp(
		$EnemyMesh.rotation.x,
		target_rotation,
		delta * 10.0
	)
	
func _handle_slam_land():

	is_slam_sequence = false

	animation_player.play("Armature|GroundRecover")

	VFX.landEffect($".", GroundDustEffect, $EnemyMesh)

	await get_tree().create_timer(0.25).timeout

	animation_player.play("Armature|RESET")
	
func _handle_normal_land():

	in_air_damage = false

	var tween = create_tween()
	tween.tween_property(
		$EnemyMesh,
		"rotation:x",
		0.0,
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	animation_player.play("Armature|GroundBounce")

	await get_tree().create_timer(2).timeout
	animation_player.play("Armature|GroundRecover")

func _physics_process(delta):

	# Store floor state BEFORE movement
	var was_on_floor = is_on_floor()

	# Apply gravity
	Gravity(delta)

	# =========================
	# AIR ROTATION
	# =========================
	if is_slam_sequence or in_air_damage:
		if !is_on_floor():
			apply_air_rotation(delta)

	# =========================
	# MOVE
	# =========================
	move_and_slide()

	# Detect landing AFTER movement
	var just_landed = is_on_floor() and !was_on_floor

	# =========================
	# SLAM LANDING
	# =========================
	if is_slam_sequence:

		if just_landed:
			_handle_normal_land()

		return

	# =========================
	# NORMAL AIR DAMAGE LANDING
	# =========================
	if in_air_damage:

		if just_landed:
			_handle_normal_land()

		return

	## =========================
	## NORMAL GROUND/AIR STATES
	## =========================
	#if is_on_floor():
#
		## Reset mesh rotation smoothly
		#$EnemyMesh.rotation.x = lerp(
			#$EnemyMesh.rotation.x,
			#0.0,
			#delta * 10.0
		#)
#
		#if enemyStats.isGuarding:
			#animation_player.play("Armature|RESET")
		#else:
			#animation_player.play("Armature|RESET")
#
	#else:
		#animation_player.play("Armature|Juggling")

func Gravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= Global.CUSTOM_GRAVITY * delta

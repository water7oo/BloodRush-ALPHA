extends LimboState

@export var attack_box: Node
@export var attack_box_col: Node
@export var attackUpper_debug: Node
@export var hit1: PackedScene
@onready var playerCharScene =  $"../../RootNode/COWBOYPLAYER_V4"
@onready var gameJuice = get_node("/root/GameJuice")

@onready var animationTree = playerCharScene.find_child("AnimationTree", true)

@export var attackPush: float = 10.0
@export var DECELERATION: float = Global.DECELERATION + 100
@export var attack_power: float = 10.0
@export var animation_request: StringName
@export var next_attack_state: StringName
@export var combo_window_duration: float = 0.4
@export var attack_duration: float = 0.4
@export var hit_cooldown_amount: float = 0.2

@export var enemyTargetLength: float = 0.4
@export var enemyTargetMagnitude: float = 0.01
@export var enemyTargetHitStop: float = 0.4

@export var knockback_force: float = 12.0
@export var knockback_direction: Vector3 = Vector3(0, 1, 0.5) 

@export var hit1Sound: AudioStreamPlayer
@export var hit2Sound: AudioStreamPlayer
@export var hit3Sound: AudioStreamPlayer
@export var hit4Sound: AudioStreamPlayer

@export var recovery_timer: float = 0.0
@export var recovery_duration: float = 0.45   
@export var hit_recovery_duration: float = 0.15

var can_cancel: bool = false
var cancel_timer: float = 0.0
@export var cancel_window: float = 0.25

@export var jump_cancel_window: float = enemyTargetHitStop + 0.15
@export var attack_startup: float = 0.1

@export var jumpCancelFX = GPUParticles3D
var enemies_hit:= {}

var preserved_velocity: Vector3 = Vector3.ZERO
var attack_cooldown: float = 0.0
var combo_timer: float = 0.0
var can_chain_attack: bool = false


var jump_cancel_timer: float = 0.0
var isHit: bool = false

func _enter() -> void:
	enemies_hit.clear()
	if attack_box:
		attackUpper_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

	preserved_velocity = agent.velocity

	print("Current Attack State:", agent.state_machine.get_active_state())
	print("SHORYUKEN")
	_start_attack()
	match agent.state_machine.get_active_state():
		"to_attack":
			Global.attack_cooldown_timer = Global.attack_cooldown_duration
		"to_mediumAttack":
			Global.attackMedium_cooldown_timer = Global.attackMedium_cooldown_duration
		"to_heavyAttack":
			Global.attackHeavy_cooldown_timer = Global.attackHeavy_cooldown_duration
		"to_attackUpper":
			Global.attackUpper_cooldown_timer = Global.attackUpper_cooldown_duration


func _update(delta: float) -> void:
	_process_attack(delta)
	print(can_cancel)
	agent.move_and_slide()

func _process_attack(delta: float) -> void:
	if !Global.is_attacking:
		return

	attack_cooldown -= delta
	combo_timer -= delta
	recovery_timer -= delta

	# gravity
	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta

	# movement
	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)
	else:
		agent.velocity.x = lerp(agent.velocity.x, preserved_velocity.x, 0.1)
		agent.velocity.z = lerp(agent.velocity.z, preserved_velocity.z, 0.1)


	if can_cancel:
		cancel_timer -= delta

		
		if Input.is_action_just_pressed("move_jump"):
			print("Jump Cancel")
			can_cancel = false
			_exit_attack_state()
			jumpCancelFX.emitting = true
			agent.state_machine.dispatch("to_jump")
			return

		# Optional: allow follow-up attack
		if Input.is_action_just_pressed("attack_light_1") and next_attack_state:
			can_cancel = false
			agent.state_machine.dispatch(next_attack_state)
			return

		if cancel_timer <= 0:
			can_cancel = false

	if attack_cooldown <= 0.0 and recovery_timer <= 0.0:
		_exit_attack_state()

func _start_attack() -> void:
	enemies_hit.clear()
	animationTree.set("parameters/AttackShot/request", 1)

	Global.is_attacking = true
	isHit = false

	attack_cooldown = attack_duration
	combo_timer = combo_window_duration
	recovery_timer = recovery_duration  

	can_chain_attack = false

	can_cancel = false
	cancel_timer = 0.0

	jump_cancel_timer = 0.0

func _on_attack_box_area_entered(area):
	if isHit:
		return
	if area.has_method("takeDamageEnemy"):
		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()
				
		if area in enemies_hit:
			return
		enemies_hit[area] = true 
		# ENABLE CANCEL WINDOW
		can_cancel = true
		cancel_timer = cancel_window

		# shorten recovery on hit
		recovery_timer = hit_recovery_duration
		isHit = true
		Global.isHit = true
		hit3Sound.play()
		attack_cooldown = min(attack_cooldown, hit_cooldown_amount)

		gameJuice.objectShake(area.get_parent(), enemyTargetLength, enemyTargetMagnitude)
		
		if enemy.has_node("MeshInstance3D"):
			var mesh = enemy.get_node("MeshInstance3D")
			mesh.trigger_flash()
			await get_tree().process_frame
			
		if area.has_method("set_monitoring"):
			area.monitoring = false

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO
		gameJuice.objectShake(area.get_parent(), enemyTargetLength, enemyTargetMagnitude)
		await gameJuice.hitstop(enemyTargetHitStop)
		agent.velocity = saved_velocity


		if area.has_method("set_monitoring"):
			area.monitoring = true
			
		if enemy is CharacterBody3D:
			#print("Applying knockback to:", enemy.name)
			gameJuice.knockback(
				enemy,
				agent,
				knockback_force,
				knockback_direction
			)


func pause():
	process_mode = PROCESS_MODE_DISABLED

func unpause():
	process_mode = PROCESS_MODE_INHERIT

func _exit_attack_state() -> void:
	Global.is_attacking = false
	attackUpper_debug.visible = false
	attack_box_col.visible = false

	attack_cooldown = 0.0
	recovery_timer = 0.0

	isHit = false
	can_cancel = false

	Global.attackAirSlam_cooldown_timer = Global.attackAirSlam_cooldown_duration

	if attack_box:
		attack_box.monitoring = false

	agent.state_machine.dispatch("to_idle")

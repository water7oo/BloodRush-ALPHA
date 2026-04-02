extends LimboState

@export var attack_box: Node
@export var attack_box_col: Node
@export var attackUpper_debug: Node
@export var ComboConfirmFX: GPUParticles3D


@onready var gameJuice = get_node("/root/GameJuice")


@export var DECELERATION: float = Global.DECELERATION + 100

@export var combo_window_duration: float = 0.4
@export var attack_duration: float = 0.45
@export var hit_cooldown_amount: float = 0.25

@export var recovery_duration: float = 0.45   
@export var hit_recovery_duration: float = 0.15

@export var cancel_window: float = 0.25

@export var enemyTargetLength: float = 0.4
@export var enemyTargetMagnitude: float = 0.01
@export var enemyTargetHitStop: float = 0.4

@export var knockback_force: float = 16.0
@export var knockback_direction: Vector3 = Vector3(0, 1.5, 0.3)

@export var hit1Sound: AudioStreamPlayer
@export var hit2Sound: AudioStreamPlayer
@export var hit3Sound: AudioStreamPlayer
@export var hit4Sound: AudioStreamPlayer
@export var jumpCancelSound: AudioStreamPlayer


var jump_cancel_timer: float = 0.0
@export var jump_cancel_window: float = 0.25
@export var jumpCancelFX: GPUParticles3D

# -----------------------

var enemies_hit := {}
var preserved_velocity: Vector3 = Vector3.ZERO

var combo_timer: float = 0.0
var recovery_timer: float = 0.0

var can_chain_attack: bool = false
var can_cancel: bool = false
var cancel_timer: float = 0.0
var isHit: bool = false

var next_attack_state: StringName
var buffered_input := false

var current_combo_count = Global.combo_hits.size()
var last_enemy_hit = Global.combo_hits[-1]["enemy"] if current_combo_count > 0 else null
# -----------------------

func _enter() -> void:
	enemies_hit.clear()

	if attack_box:
		attackUpper_debug.visible = true
		attack_box_col.visible = true
		attack_box.monitoring = true
		attack_box.connect("area_entered", Callable(self, "_on_attack_box_area_entered"), CONNECT_DEFERRED)

	preserved_velocity = agent.velocity
	_start_attack()

# -----------------------

func _update(delta: float) -> void:
	_process_attack(delta)
	agent.move_and_slide()

# -----------------------

func _process_attack(delta: float) -> void:
	if Global.attackAirSlam_cooldown_timer > 0.0:
		Global.attackAirSlam_cooldown_timer -= delta
	if recovery_timer > 0.0:
		recovery_timer -= delta
	if combo_timer > 0.0:
		combo_timer -= delta
	if can_cancel:
		cancel_timer -= delta
		if cancel_timer <= 0:
			can_cancel = false


	if recovery_timer > 0.0:
		recovery_timer -= delta
	if combo_timer > 0.0:
		combo_timer -= delta

	if buffered_input and can_cancel:
		buffered_input = false
		_exit_attack_state()
		agent.state_machine.dispatch(next_attack_state)
		return

	if Global.attackUpper_cooldown_timer <= 0.0 and recovery_timer <= 0.0 || agent.is_on_floor():
		isHit = false
		buffered_input = false
		jump_cancel_timer = 0.0
		print("AirSlam exited")
		_exit_attack_state()
		agent.state_machine.dispatch("to_idle")

	# =========================

	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta

	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)
	else:
		agent.velocity.x = lerp(agent.velocity.x, preserved_velocity.x, 0.1)
		agent.velocity.z = lerp(agent.velocity.z, preserved_velocity.z, 0.1)

# -----------------------

func _start_attack() -> void:
	enemies_hit.clear()

	#animationTree.set("parameters/AttackShot/request", 1)

	Global.is_attacking = true
	isHit = false

	# ✅ GLOBAL COOLDOWN START
	Global.attackAirSlam_cooldown_timer = attack_duration

	combo_timer = combo_window_duration
	recovery_timer = recovery_duration  

	can_chain_attack = false
	can_cancel = false

	# Launcher → jump follow-up
	next_attack_state = "to_idle"

# -----------------------

func _on_attack_box_area_entered(area):
	if isHit:
		return

	if area.has_method("takeDamageEnemy") && area.current_health > 0:
		area.takeDamageEnemy(PlayerAttackManager.AirSlamAttackDamage)
		Global.combo_hits.append({
	"enemy": area,
	"damage": PlayerAttackManager.AirSlamAttackDamage,
	"attack_type": "attackAirSlam",
	"timestamp": Time.get_ticks_msec()
})
		isHit = true

		jump_cancel_timer = jump_cancel_window

		recovery_timer = hit_recovery_duration
		can_cancel = true
		cancel_timer = cancel_window

		var enemy = area
		while enemy and not (enemy is CharacterBody3D):
			enemy = enemy.get_parent()

		if area in enemies_hit:
			return
		enemies_hit[area] = true 

		Global.isHit = true
		hit4Sound.play()

		Global.attackAirSlam_cooldown_timer = min(Global.attackAirSlam_cooldown_timer, hit_cooldown_amount)

		if enemy.has_node("EnemyMesh"):
			var mesh = enemy.get_node("EnemyMesh")
			mesh.trigger_flash()
			await get_tree().process_frame

		if area.has_method("set_monitoring"):
			area.monitoring = false

		var saved_velocity = agent.velocity
		agent.velocity = Vector3.ZERO

		var hit1Effect = enemy.find_child("hit1", true, false)
				
		if hit1Effect is GPUParticles3D:
			hit1Effect.restart()
			hit1Effect.emitting = true
			hit1Effect.process_mode = Node.PROCESS_MODE_ALWAYS
		elif hit1Effect == null:
			print("Warning: No GPUParticles3D found on " + enemy.name)
			
		EnemyHealthManager.enemyWasHit = true
		gameJuice.objectShake(enemy, enemyTargetLength, enemyTargetMagnitude)
		await gameJuice.hitstop(enemyTargetHitStop)
		EnemyHealthManager.enemyWasHit = true
		
		agent.velocity = saved_velocity

		if area.has_method("set_monitoring"):
			area.monitoring = true

		if enemy is CharacterBody3D:
			gameJuice.knockback(enemy, agent, knockback_force, knockback_direction)

# -----------------------

func _exit_attack_state() -> void:
	Global.is_attacking = false
	if attack_box and attack_box.is_connected("area_entered", Callable(self, "_on_attack_box_area_entered")):
		attack_box.disconnect("area_entered", Callable(self, "_on_attack_box_area_entered"))

	attackUpper_debug.visible = false
	attack_box_col.visible = false
	isHit = false

	if attack_box:
		attack_box.monitoring = false

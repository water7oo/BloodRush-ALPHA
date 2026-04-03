extends Resource

@export var attack_cooldown_timer: float = 0.0
@export var attack_cooldown_duration: float = 1
@export var attack_power: float = 10.0
@export var animation_request: StringName
@export var next_attack_state: StringName  
@export var combo_window_duration: float = 0.4  
@export var attack_duration: float = 0.4  
@export var hit_cooldown_amount: float = 0.2
@export var DECELERATION: float = Global.DECELERATION + 100

@export var enemyTargetLength: float = 0.4
@export var enemyTargetMagnitude: float = 0.01
@export var enemyTargetHitStop: float = 0.4

@export var knockback_force: float = 12.0
@export var knockback_direction: Vector3 = Vector3(0, 1, 0.5) 

var enemies_hit:= {}

var jump_cancel_timer: float = 0.0
@export var jump_cancel_window: float = 0.25

var preserved_velocity: Vector3 = Vector3.ZERO
var combo_timer: float = 0.0
var can_chain_attack: bool = false  
var isHit: bool = false

@export var recovery_timer: float = 0.0
@export var recovery_duration: float = 0.3
@export var hit_recovery_duration: float = 0.1

var can_cancel: bool = false
var cancel_timer: float = 0.0
@export var cancel_window: float = 0.2


var buffered_input := false

var current_combo_count = Global.combo_hits.size()
var last_enemy_hit = Global.combo_hits[-1]["enemy"] if current_combo_count > 0 else null

@export var attack_box: PackedScene
@export var attack_box_col: PackedScene
@export var attack_box_debug: PackedScene

func _process_attack(delta: float, agent: Node3D) -> void:
	if Global.attack_cooldown_timer > 0.0:
		Global.attack_cooldown_timer -= delta
	if recovery_timer > 0.0:
		recovery_timer -= delta
	if combo_timer > 0.0:
		combo_timer -= delta
	if can_cancel:
		cancel_timer -= delta
		if cancel_timer <= 0:
			can_cancel = false

	if buffered_input and can_cancel:
		buffered_input = false
		_exit_attack_state(attack_box, attack_box_debug, attack_box_col)
		agent.state_machine.dispatch(next_attack_state)
		return
		
	if Global.attack_cooldown_timer <= 0.0 and recovery_timer <= 0.0:
		buffered_input = false
		can_chain_attack = true
		if can_chain_attack && Input.is_action_just_pressed("attack_medium_1"):
			_exit_attack_state(attack_box, attack_box_debug, attack_box_col)
			agent.state_machine.dispatch(next_attack_state)
		else:
			_exit_attack_state(attack_box, attack_box_debug, attack_box_col)
			agent.state_machine.dispatch("to_idle")
		
		return

		buffered_input = false

	# Gravity and velocity
	agent.velocity.y -= Global.CUSTOM_GRAVITY * delta
	if agent.is_on_floor():
		agent.velocity.x = move_toward(agent.velocity.x, 0, DECELERATION * delta)
		agent.velocity.z = move_toward(agent.velocity.z, 0, DECELERATION * delta)
	else:
		agent.velocity.x = lerp(agent.velocity.x, preserved_velocity.x, 0.1)
		agent.velocity.z = lerp(agent.velocity.z, preserved_velocity.z, 0.1)

	agent.move_and_slide()


func _exit_attack_state(attack_box, attack_box_debug, attack_box_col) -> void:
	Global.is_attacking = false
	
	if attack_box and attack_box.is_connected("area_entered", Callable(self, "_on_attack_box_area_entered")):
		attack_box.disconnect("area_entered", Callable(self, "_on_attack_box_area_entered"))

	attack_box_debug.visible = false
	attack_box_col.visible = false
	isHit = false
	if attack_box:
		attack_box.monitoring = false

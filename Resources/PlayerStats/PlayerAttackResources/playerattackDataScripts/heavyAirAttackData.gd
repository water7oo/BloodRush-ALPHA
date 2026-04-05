extends Resource

@export var attack_cooldown_timer: float = 0.0
@export var attack_cooldown_duration: float = .3
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

@export var jump_cancel_window: float = 0.25

@export var recovery_duration: float = 0.3
@export var hit_recovery_duration: float = 0.1

@export var cancel_window: float = 0.2
@export var ATTACK_DECELERATION:float = 60.0

@export var attackDamage: float = 5.0

var preserved_velocity: Vector3 = Vector3.ZERO
var combo_timer: float = 0.0
var enemies_hit:= {}

var jump_cancel_timer: float = 0.0
var recovery_timer: float = 0.0
var buffered_input := false

var current_combo_count = Global.combo_hits.size()
var last_enemy_hit = Global.combo_hits[-1]["enemy"] if current_combo_count > 0 else null


var is_attacking: bool = false

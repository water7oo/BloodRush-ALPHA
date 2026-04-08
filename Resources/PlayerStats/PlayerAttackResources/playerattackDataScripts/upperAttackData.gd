class_name UpperAttackData
extends Resource


@export var startup_duration: float = 0.1
@export var active_duration: float = 0.4
@export var recovery_duration: float = 0.3
@export var attackDamage: float = 10.0

@export var combo_window_duration: float = 0.4
@export var enemyTargetLength: float = 0.4
@export var enemyTargetMagnitude: float = 0.01
@export var enemyTargetHitStop: float = 0.4

@export var Default_knockback_force: float = 3.0
@export var knockback_force: float = 3.0
@export var knockback_direction: Vector3 = Vector3(0, 0, 1)

@export var jump_cancel_window: float = 0.25
@export var ATTACK_DECELERATION: float = 60.0

@export var next_attack_state: StringName

@export var jumpCancelDelayDuration: float = 0.1
@export var jumpCancelTimerDuration: float = 0.3

var enemyTargetGuardLength: float = enemyTargetLength * .2
var enemyTargetGuardMagnitude: float = enemyTargetMagnitude * .1
var enemyTargetGuardedHitstop: float = enemyTargetHitStop * .1

@export var guardedknockbackDirection: Vector3 = Vector3(0, 0, .5)
@export var knockback_force_guardRate = .7
var guardedknockbackForce: float = knockback_force * knockback_force_guardRate

var comboknockbackForce: float = knockback_force * comboknockbackForceRate
@export var comboknockbackForceRate: float = .2

var isMultiHit = false

@export var max_hits: int = 5
@export var time_between_hits: float = .15

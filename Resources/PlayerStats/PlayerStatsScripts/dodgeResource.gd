extends Resource


@export var dodge_cooldown_timer: float = 0.0
@export var spinDodge_timer_cooldown: float = 0.0

@export var DODGE_SPEED: float = 20.0
@export var DODGE_ACCELERATION: float = 100.0
@export var DODGE_DECELERATION: float = 50.0
@export var DODGE_LERP_VAL: float = 3

@export var dodge_cooldown: float = 0.5
@export var spinDodge_reset: float = 0.3

var dodge_direction = Vector3.ZERO

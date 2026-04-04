extends Resource


var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 10.0  

@export var mouse_sensitivity: float = 0.005

@export var armature_rot_speed: float = .7
@export var armature_default_rot_speed: float = .7

# Walk
@export var BASE_SPEED: float = 11.0
@export var MAX_SPEED: float = 15.0  # Reduce slightly for better control
@export var ACCELERATION: float = 50.0  # Slightly higher for snappier movement
@export var DECELERATION: float = 60.0  # Increase for quicker stopping
@export var BASE_DECELERATION: float = 60.0  # Matches normal deceleration
@export var momentum_deceleration: float = DECELERATION - 5
@export var momentum_acceleration: float = ACCELERATION + 100
@export var inertia_blend: float = 4



@export var air_momentum_acceleration: float = momentum_acceleration - 2
@export var air_momentum_deceleration: float = momentum_deceleration - 2

# Run

@export var runMultiplier: float = 1.5
@export var runAdditive: float = 7
@export var RUN_MAX_SPEED: float = MAX_SPEED + runAdditive
@export var RUN_BASE_SPEED: float = BASE_SPEED + runAdditive
@export var target_speed: float = MAX_SPEED
@export var RUN_ACCELERATION: float = 1
@export var RUN_DECELERATION: float = DECELERATION - 5
@export var RUN_BASE_ACCELERATION: float = 1
@export var RUN_BASE_DECELERATION: float = DECELERATION - 5

@export var RUN_BASE_DASH_ACCELERATION: float = ACCELERATION - 2
@export var RUN_BASE_DASH_DECELERATION: float = DECELERATION - 5


@export var DASH_ACCELERATION: float = ACCELERATION - 2
@export var DASH_DECELERATION: float = DECELERATION - 5
@export var DASH_MAX_SPEED: float = MAX_SPEED + 5 

@export var run_inertia_blend: float = inertia_blend/1.5

@export var run_momentum_acceleration: float = momentum_acceleration - 2
@export var run_momentum_deceleration: float = momentum_deceleration - 2

@export var speed_threshold: float = BASE_SPEED - 2





@export var dodge_cooldown_timer: float = 0.0
@export var spinDodge_timer_cooldown: float = 0.0

@export var DODGE_SPEED: float = 20.0
@export var DODGE_ACCELERATION: float = 100.0
@export var DODGE_DECELERATION: float = 50.0
@export var DODGE_LERP_VAL: float = 3

@export var dodge_cooldown: float = 0.5
@export var spinDodge_reset: float = 0.3

var dodge_direction = Vector3.ZERO


# Jumping
@export var JUMP_VELOCITY: float = 12.0  # Increased for better jump height
@export var CUSTOM_GRAVITY: float = 30.0  # Keeps the character from feeling too floaty


# Run jumping
@export var runJumpMultiplier: float = 1.5

# Crouch
var CROUCH_DECELERATION = DECELERATION - 2
var CROUCH_BASE_SPEED =  BASE_SPEED - 22

# Guarding
@export var GUARD_BASE_SPEED = BASE_SPEED - 40
@export var GUARD_DECELERATION = BASE_DECELERATION - 40

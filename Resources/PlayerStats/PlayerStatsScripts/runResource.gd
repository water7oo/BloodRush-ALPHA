extends Resource


var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 10.0  
@export var RUN_MAX_SPEED: float = Global.MAX_SPEED + 5
@export var RUN_BASE_SPEED: float = Global.BASE_SPEED + 5
var target_speed: float = Global.MAX_SPEED

@export var mouse_sensitivity: float = 0.005

@export var RUN_armature_rot_speed: float = .1
@export var armature_default_rot_speed: float = .1


@export var runAdditive: float = 10
@export var runSubtractive: float = -10
var runMultiplier: float = 1.5

@export var RUN_ACCELERATION: float = Global.ACCELERATION
@export var RUN_DECELERATION: float = Global.DECELERATION
@export var RUN_BASE_ACCELERATION: float = Global.BASE_ACCELERATION
@export var RUN_BASE_DECELERATION: float = Global.DECELERATION
@export var RUN_BASE_DASH_ACCELERATION: float = Global.ACCELERATION 
@export var RUN_BASE_DASH_DECELERATION: float = Global.DECELERATION

@export var DASH_ACCELERATION: float = Global.ACCELERATION
@export var DASH_DECELERATION: float = Global.DECELERATION
@export var DASH_MAX_SPEED: float = Global.MAX_SPEED

@export var run_momentum_acceleration: float = 40.0
@export var run_momentum_deceleration: float = 20.0

@export var inertia_blend: float = 12

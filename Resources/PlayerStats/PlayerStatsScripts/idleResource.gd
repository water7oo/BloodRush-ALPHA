extends Resource



@export var armature_rot_speed: float = .7
@export var armature_default_rot_speed: float = .7

# Walk
var BASE_SPEED: float = Global.BASE_SPEED
var MAX_SPEED: float = Global.MAX_SPEED
var ACCELERATION: float = Global.ACCELERATION
var DECELERATION: float = Global.DECELERATION


@export var BASE_DECELERATION: float = Global.BASE_DECELERATION
@export var momentum_deceleration: float = DECELERATION - 5
@export var momentum_acceleration: float = ACCELERATION + 100
@export var inertia_blend: float = 4



@export var air_momentum_acceleration: float = momentum_acceleration - 2
@export var air_momentum_deceleration: float = momentum_deceleration - 2

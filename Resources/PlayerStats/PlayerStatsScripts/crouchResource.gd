extends Resource


var BASE_SPEED: float = Global.BASE_SPEED
var MAX_SPEED: float = Global.MAX_SPEED
var ACCELERATION: float = Global.ACCELERATION
var DECELERATION: float = Global.DECELERATION


@export var CROUCH_SPEED: float = BASE_SPEED - crouchSpeedSubtract
@export var crouchSpeedSubtract: float = 10
var BASE_DECELERATION: float = Global.BASE_DECELERATION

@export var CROUCH_ACCELERATION: float = Global.BASE_ACCELERATION - 10
@export var momentum_deceleration: float = DECELERATION - 5
@export var momentum_acceleration: float = ACCELERATION + 5
@export var inertia_blend: float = 4


var air_momentum_acceleration: float = momentum_acceleration - 2
var air_momentum_deceleration: float = momentum_deceleration - 2

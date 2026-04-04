extends Resource


var BASE_SPEED: float = Global.BASE_SPEED
var MAX_SPEED: float = Global.MAX_SPEED
var ACCELERATION: float = Global.ACCELERATION
var DECELERATION: float = Global.DECELERATION


@export var GUARD_BASE_SPEED: float = BASE_SPEED - guardSpeedSubtract
@export var guardSpeedSubtract: float = 10
var GUARD_DECELERATION: float = Global.BASE_DECELERATION 

var GUARD_ACCELERATION: float = Global.BASE_ACCELERATION

@export var momentum_deceleration: float = DECELERATION - 5
@export var momentum_acceleration: float = ACCELERATION + 100
@export var inertia_blend: float = 4
@export var GuardDamage: float = 10


@export var air_momentum_acceleration: float = momentum_acceleration - 2
@export var air_momentum_deceleration: float = momentum_deceleration - 2

extends Resource


# Walk
var BASE_SPEED: float = Global.BASE_SPEED
var MAX_SPEED: float = Global.MAX_SPEED
var ACCELERATION: float = Global.ACCELERATION
var DECELERATION: float = Global.DECELERATION


var momentum_deceleration: float = DECELERATION - 10
var momentum_acceleration: float = ACCELERATION + 5
var inertia_blend: float = 4


var air_momentum_acceleration: float = momentum_acceleration - 2
var air_momentum_deceleration: float = momentum_deceleration - 2

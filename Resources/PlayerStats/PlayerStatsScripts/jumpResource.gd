extends Resource

# Jumping
@export var JUMP_VELOCITY: float = 12.0 
@export var DEFAULT_JUMP_VELOCITY: float = 12.0  
@export var CUSTOM_GRAVITY: float = 30.0  # Keeps the character from feeling too floaty
@export var can_jump: bool = true

@export var air_momentum_acceleration: float = Global.momentum_acceleration - 2
@export var air_momentum_deceleration: float = Global.momentum_deceleration - 2
@export var inertia_blend: float = 4
@export var LANDING_DAMPING: float = .6
@export var AIR_DRAG: float = .5

@export var AIR_MAX_SPEED: float = 5.0

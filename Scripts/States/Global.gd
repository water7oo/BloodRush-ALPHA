extends Node

#Global Variables 
@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")
@onready var gameJuice = get_node("/root/GameJuice")


var global_data = GlobalResource.new()
@export var CUSTOM_GRAVITY: float = 35.0
var camera = preload("res://Player/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")

var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 10.0  

@export var mouse_sensitivity: float = 0.005

@export var armature_rot_speed: float = 1
@export var armature_default_rot_speed: float = 1
@onready var armature = $Armature_001

#Walk State Base movement values
@export var BASE_SPEED: float = 6.0
@export var MAX_SPEED: float = 10.0  # Reduce slightly for better control
@export var ACCELERATION: float = 40.0  # Slightly higher for snappier movement
@export var DECELERATION: float = 25.0  # Increase for quicker stopping
@export var BASE_DECELERATION: float = 20.0  # Matches normal deceleration
@export var momentum_deceleration: float = DECELERATION - 5
@export var momentum_acceleration: float = ACCELERATION + 10
@export var inertia_blend: float = 7

@export var run_inertia_blend: float = inertia_blend/1.5

@export var run_momentum_acceleration: float = momentum_acceleration - 2
@export var run_momentum_deceleration: float = momentum_deceleration - 2
@export var air_momentum_acceleration: float = momentum_acceleration - 2
@export var air_momentum_deceleration: float = momentum_deceleration - 2

#Jump State Base movement values:
@export var JUMP_VELOCITY: float = 11.0  

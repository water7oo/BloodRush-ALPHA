extends Node

#Global Variables 
@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")
@onready var gameJuice = get_node("/root/GameJuice")

var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 10.0  

@export var mouse_sensitivity: float = 0.005

@export var armature_rot_speed: float = .1
@export var armature_default_rot_speed: float = .001

@export var CUSTOM_GRAVITY: float = 35.0
var camera = preload("res://Player/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")



var can_move: bool = true
var is_in_air: bool = false
var can_sprint: bool = true
var is_sprinting: bool = false
var sprint_timer: float = 0.0
var is_dodging: bool = false
var can_dodge: bool = true
var last_ground_position = Vector3.ZERO
var current_speed: float = 0.0

var is_moving: bool = false
var was_on_floor: bool = false

var is_attacking: bool = false
var can_chain_attack: bool = false  
var isHit: bool = false
var can_cancel: bool = false
var cancel_timer: float = 0.0
var has_attacked: bool = false

var air_timer: float = 0.0
var jump_timer: float = 0.0
var jump_counter: float = 0
var can_jump: bool = true

# Move these to playerAttackManager
var combo_hits: Array = []
@export var combo_reset_time: float = 1
var combo_timer: float = 0.0


@export var BASE_SPEED: float = 15.0
@export var MAX_SPEED: float = 30.0  # Reduce slightly for better control
@export var ACCELERATION: float = 60.0  # Slightly higher for snappier movement
@export var DECELERATION: float = 70.0  # Increase for quicker stopping
@export var BASE_ACCELERATION: float = 70.0  # Matches normal deceleration
@export var BASE_DECELERATION: float = 70.0

@export var momentum_deceleration: float = DECELERATION
@export var momentum_acceleration: float = ACCELERATION

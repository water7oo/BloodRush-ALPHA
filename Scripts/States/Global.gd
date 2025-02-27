extends Node


var global_data = GlobalResource.new()
@export var CUSTOM_GRAVITY: float = 35.0
var camera = preload("res://Player/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")

var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 10.0  

@export var mouse_sensitivity: float = 0.005

@export var armature_rot_speed: float = .1
@export var armature_default_rot_speed: float = .1
@onready var armature = $Armature_001

#Walk State Base movement values
@export var BASE_SPEED: float = 6.0
@export var MAX_SPEED: float = 10.0  # Reduce slightly for better control
@export var ACCELERATION: float = 20.0  # Slightly higher for snappier movement
@export var DECELERATION: float = 20.0  # Increase for quicker stopping
@export var BASE_DECELERATION: float = 20.0  # Matches normal deceleration
@export var momentum_deceleration: float = .5  # Lower means smoother momentum shifts

#Jump State Base movement values:
@export var JUMP_VELOCITY: float = 11.0  

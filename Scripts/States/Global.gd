extends Node


var global_data = GlobalResource.new()
@export var CUSTOM_GRAVITY: float = 35.0
var camera = preload("res://Player/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
@export var mouse_sensitivity: float = 0.005

@export var armature_rot_speed: float = .1
@export var armature_default_rot_speed: float = 0.07

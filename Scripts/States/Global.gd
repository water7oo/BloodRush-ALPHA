extends Node

#Global Variables 
@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")
@onready var gameJuice = get_node("/root/GameJuice")

var game_paused = false
var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 10.0  

@export var mouse_sensitivity: float = 0.005

@export var armature_rot_speed: float = .1
@export var armature_default_rot_speed: float = .001

@export var CUSTOM_GRAVITY: float = 30.0
var spring_arm_pivot: Node3D = null
var spring_arm: Node3D = null



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
var is_taking_damage: bool = false
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
@export var combo_reset_time: float = .8
var combo_timer: float = 0.0

var isMultiHitUpper = false

@export var BASE_SPEED: float = 15.0
@export var MAX_SPEED: float = 30.0  # Reduce slightly for better control
@export var ACCELERATION: float = 60.0  # Slightly higher for snappier movement
@export var DECELERATION: float = 70.0  # Increase for quicker stopping
@export var BASE_ACCELERATION: float = 70.0  # Matches normal deceleration
@export var BASE_DECELERATION: float = 70.0

@export var momentum_deceleration: float = DECELERATION
@export var momentum_acceleration: float = ACCELERATION

var isComboUiShake = false
var waslastframehit = false

var playerHitstop: float = 0.5
var TargetLength: float = 0.3
var TargetMagnitude: float = 0.5

var isRecovering = false

func shakeTween(node):
	FollowCam.applyShake(0.1,0.1)
	var strength = clamp(Global.combo_hits.size() * 2, 5, 20)
	TweenFX.shake(node)
	TweenFX.shake(node, 0.1, 8, strength)
		

func stretch_up(node: Node3D):
	var base_scale = get_base_scale(node)
	var tween = start_tween(node)

	var stretch = Vector3(0.9, 1.2, 0.9)
	var target_scale = base_scale * stretch

	var height_offset = (target_scale.y - base_scale.y) * 0.5

	tween.parallel().tween_property(node, "scale", target_scale, 0.15)
	tween.parallel().tween_property(node, "position:y", 0, 0.15)

	tween.tween_property(node, "scale", base_scale, 0.12)
	tween.parallel().tween_property(node, "position:y", 0.0, 0.12)

func squash_land(node: Node3D):
	var base_scale = get_base_scale(node)
	var tween = start_tween(node)

	var squash = Vector3(1.08, 0.75, 1.08)
	var target_scale = base_scale * squash

	tween.tween_property(node, "scale", target_scale, 0.08)
	tween.tween_property(node, "scale", base_scale, 0.1)

func stretch_forward(node: Node3D):
	var base_scale = get_base_scale(node)
	var tween = start_tween(node)

	var stretch = Vector3(0.9, 0.9, 1.2)
	var target_scale = base_scale * stretch

	tween.tween_property(node, "scale", target_scale, 0.12)
	tween.tween_property(node, "scale", base_scale, 0.1)

func get_base_scale(node: Node3D) -> Vector3:
	if node:
		if not node.has_meta("base_scale"):
			node.set_meta("base_scale", node.scale)
	return node.get_meta("base_scale")

func get_base_y(node: Node3D) -> float:
	if not node.has_meta("base_y"):
		node.set_meta("base_y", node.position.y)
	return node.get_meta("base_y")
	
func start_tween(node: Node) -> Tween:
	if node.has_meta("active_tween"):
		var old_tween: Tween = node.get_meta("active_tween")
		if old_tween and old_tween.is_running():
			old_tween.kill()

	var tween = create_tween()
	node.set_meta("active_tween", tween)
	return tween
